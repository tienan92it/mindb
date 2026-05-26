# Invalidate schema cache after DDL

**Issue:** #35  
**Explore brief:** `aidlc-docs/explore/2026-05-26-schema-cache-ddl-invalidation.md` (PR https://github.com/tienan92it/mindb/pull/34)

## Summary

`SchemaService` caches introspection in memory; `clearCache()` exists but is never called, so after `CREATE` / `ALTER` / `DROP` the agent and direct SQL paths keep serving stale table/column lists until app restart. Smallest fix: after a **successful** `QueryExecutor.execute`, if the original SQL (pre-`LIMIT`) is schema-mutating DDL, call `SchemaService.clearCache()`. Wire `SchemaService` into `QueryExecutor` at session connect so agent `execute_sql`, `sql:` direct input, and `executeSqlDirect` all share one hook. Do not invalidate on DML (`INSERT` / `UPDATE` / `DELETE`) or on `EXPLAIN …` wrappers.

## Files to touch

| File | Change |
|------|--------|
| `lib/domain/safety/safety_policy.dart` | Add `bool affectsSchemaStructure(String sql)` — DDL regex (`CREATE`, `ALTER`, `DROP`); return false when trimmed SQL starts with `EXPLAIN` (case-insensitive). |
| `lib/domain/query/query_executor.dart` | Accept optional `SchemaService? schemaService`; after successful `_client.execute`, if `affectsSchemaStructure(trimmed)` then `schemaService?.clearCache()`. |
| `lib/features/session/session_providers.dart` | Pass `_schemaService` into `QueryExecutor(...)` constructor (~line 172). |
| `test/safety_policy_test.dart` | Cases for DDL vs DML vs `EXPLAIN` prefix. |
| `test/query_executor_schema_cache_test.dart` | **New** — fake `DatabaseClient` + real `SchemaService` with stub client: DDL execute clears cache; `SELECT` / `INSERT` do not. |
| `test/schema_service_test.dart` | Optional: `clearCache` then `fetchSchema` hits client again (if easy with fake client). |
| `aidlc-docs/qa-smoke.md` | Add manual step: after DDL, NL “what columns does X have?” matches live DB. |

**Out of scope:** FK/index catalog, persisted cache, polling, multi-DB, invalidating on failed/cancelled executes, orchestrator system-prompt refresh mid-turn, `GRANT` / `REVOKE` / `COMMENT` (no column drift), new deps.

## Approach

### 1. DDL detector on `SafetyPolicy`

Add a focused helper (name per codebase taste, e.g. `affectsSchemaStructure`):

```dart
static final _ddlPattern = RegExp(
  r'\b(CREATE|ALTER|DROP)\b',
  caseSensitive: false,
);

bool affectsSchemaStructure(String sql) {
  final trimmed = sql.trim();
  if (trimmed.isEmpty) return false;
  if (RegExp(r'^\s*EXPLAIN\b', caseSensitive: false).hasMatch(trimmed)) {
    return false;
  }
  return _ddlPattern.hasMatch(trimmed);
}
```

**Rationale:** Issue scope is DDL patterns, not all `SqlClassification.destructive` tokens (`TRUNCATE`, `GRANT`, `COMMENT` do not change `information_schema` columns). DML stays cached.

### 2. Invalidate in `QueryExecutor.execute` (success path only)

After `final result = await _client.execute(limitedSql, …)` succeeds:

```dart
if (_schemaService != null &&
    _safetyPolicy.affectsSchemaStructure(trimmed)) {
  _schemaService!.clearCache();
}
```

Use **`trimmed`** (user/model SQL before `injectLimit`), not `limitedSql`, so `SELECT` + `LIMIT` is never mistaken for DDL.

**Do not** clear on: empty SQL, read-only block, confirmation cancel, execute exception, or `EXPLAIN …` statements (detector returns false).

### 3. Wire `SchemaService` at session connect

In `SessionController._connect`:

```dart
_schemaService = SchemaService(_client);
_queryExecutor = QueryExecutor(
  client: _client,
  safetyPolicy: safetyPolicy,
  schemaService: _schemaService,
  maxRows: settings.maxRows,
  queryTimeout: Duration(seconds: settings.queryTimeoutSeconds),
  confirmationHandler: _handleConfirmation,
);
```

No orchestrator changes required — it already calls `_queryExecutor.execute` for `execute_sql`.

### 4. Behavior expectations

| Path | After DDL success |
|------|-------------------|
| Next `submitPrompt` (NL) | Orchestrator `_loadSchemaIndex()` → `fetchSchema()` refetches |
| `get_schema` tool in same agent run | `fetchSchema()` refetches (cache was cleared) |
| `sql:` / `executeSqlDirect` | Same executor hook |
| Same NL turn system prompt | May still show pre-DDL index until **next** user message — acceptable per issue (“next plain-language question”) |

### 5. QA doc

Add to `aidlc-docs/qa-smoke.md` (after schema or safety step):

- Run `sql: CREATE TABLE mindb_smoke_cols (id int);` (or `ALTER` / `DROP` a throwaway object).
- Ask NL: “what columns does mindb_smoke_cols have?” — answer lists `id` without restart.

## Tests

- **Unit (`safety_policy_test.dart`):**
  - `CREATE TABLE t (id int)` → true
  - `ALTER TABLE t ADD COLUMN c text` → true
  - `DROP TABLE t` → true
  - `INSERT INTO t VALUES (1)` → false
  - `SELECT * FROM t` → false
  - `EXPLAIN CREATE TABLE t (id int)` → false
- **Unit (`query_executor_schema_cache_test.dart`):**
  - Fake client records execute count; seed `SchemaService` cache via one `fetchSchema` (or set cache via package-visible path if needed — prefer executing introspection SQL twice on fake, then DDL `CREATE …`, assert third introspection round-trip or `cachedSchema == null` after DDL execute).
  - `SELECT 1` execute leaves cache populated (second `fetchSchema` does not re-hit client if using cache — mirror existing `schema_service` patterns).
- **Regression:** `flutter analyze`; full `flutter test`; existing safety/orchestrator/transcript tests unchanged.
- **Manual (QA smoke):** DDL then column question matches live schema (step above).

## Risks

- **False positive DDL in string literals:** Same limitation as existing `SafetyPolicy` regexes — acceptable v1.
- **`EXPLAIN` guard:** Prevents cache clear when agent runs `explain_sql` on DDL text without executing DDL.
- **Multi-statement scripts:** Single string with `;`-separated DDL + DML — only tested for single statement v1; document if unsupported.
- **Mid-turn stale system index:** First NL turn after DDL in-tool may still cite old index in final assistant text; next turn fixes — matches success metric.

## Rollback

Revert PR. Cache never clears; behavior returns to pre-change (restart required after DDL). No migrations.

## Ready for dev

- [x] Single-PR scope confirmed (policy helper + executor hook + session wire + tests + QA line)
- [x] No new infra / deps
- [x] Matches existing patterns (`SafetyPolicy` classification, `QueryExecutor` as execution choke point, `clearCache()` already on `SchemaService`)
