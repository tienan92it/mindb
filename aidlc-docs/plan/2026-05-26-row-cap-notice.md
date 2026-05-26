# Row-cap notice on truncated result tables

**Issue:** #43  
**Explore brief:** `aidlc-docs/explore/2026-05-26-row-cap-notice.md` (product brief PR https://github.com/tienan92it/mindb/pull/42; same scope as `aidlc-docs/explore/2026-05-24-row-cap-notice.md`)

## Summary

`QueryExecutor` already injects `LIMIT maxRows` via `SafetyPolicy.injectLimit` and returns capped rows to `TableResultBlock` on both direct `sql:` and agent `execute_sql` paths, but the UI renders the table with no indication that a safety cap applied. Smallest fix: record cap metadata on `QueryResult` when mindb injects a limit, render a muted one-line footer under SELECT tables when that flag is set, and add unit/widget tests. No settings UI, pagination, or changes to LLM `ToolResultFormatter` evidence (already marks `truncated: true` at 20 rows for the model).

## Files to touch

| File | Change |
|------|--------|
| `lib/domain/models/models.dart` | Add optional `rowCapApplied` (default `false`) and `appliedRowCap` (`int?`) on `QueryResult`. |
| `lib/domain/query/query_executor.dart` | After `injectLimit`, set cap fields on returned `QueryResult` for SELECT paths. |
| `lib/features/session/table_result_block.dart` | Below `DataTable`, show footer when `result.showsRowCapNotice` (getter on model or local check). |
| `test/query_executor_row_cap_test.dart` | **New** — fake `DatabaseClient`: injected LIMIT sets metadata; pre-existing `LIMIT` does not. |
| `test/table_result_block_row_cap_test.dart` | **New** — widget test: footer visible when cap applied; absent when not. |
| `aidlc-docs/qa-smoke.md` | Manual step: capped SELECT shows footer (rows shown vs cap). |

**Out of scope:** Parsing or re-capping user-written `LIMIT` when `injectLimit` leaves SQL unchanged; server `statement_timeout` UX; pagination/export; changing `maxRows` settings UI; `ToolResultFormatter` copy; non-SELECT `rowsAffected` messages; persisting cap metadata in `SessionContext`.

## Approach

### 1. Extend `QueryResult`

```dart
class QueryResult {
  const QueryResult({
    required this.columns,
    required this.rows,
    this.rowsAffected,
    required this.duration,
    this.sql,
    this.rowCapApplied = false,
    this.appliedRowCap,
  });
  // ...
  final bool rowCapApplied;
  final int? appliedRowCap;

  bool get showsRowCapNotice =>
      isSelect && rowCapApplied && appliedRowCap != null;

  String? get rowCapNoticeText {
    if (!showsRowCapNotice) return null;
    final cap = appliedRowCap!;
    final shown = rows.length;
    if (shown >= cap) {
      return 'Showing first $cap rows · row cap $cap applied · results may be partial';
    }
    return 'Row cap $cap applied · showing $shown rows';
  }
}
```

Use `showsRowCapNotice` / `rowCapNoticeText` in UI and tests so copy stays in one place.

### 2. `QueryExecutor` — set metadata only when mindb injects LIMIT

After `limitedSql = _safetyPolicy.injectLimit(trimmed, _maxRows)`:

```dart
final limitInjected = limitedSql != trimmed;
// ...
return QueryResult(
  columns: result.columns,
  rows: result.rows,
  rowsAffected: result.rowsAffected,
  duration: result.duration,
  sql: limitedSql,
  rowCapApplied: limitInjected && result.isSelect,
  appliedRowCap: limitInjected && result.isSelect ? _maxRows : null,
);
```

**Rationale:** `injectLimit` is a no-op for non-SELECT and for SELECT that already contains `LIMIT` (see `SafetyPolicy._limitPattern`). Those paths keep `rowCapApplied: false` — user-authored limits are not in scope for this PR.

`PostgresDatabaseClient` and test fakes do **not** set cap fields; only `QueryExecutor` is the safety wrapper for session/agent/direct SQL.

### 3. `TableResultBlock` — footer under table

For SELECT branch, wrap existing `Container` child in a `Column` (`crossAxisAlignment: start`):

1. Existing horizontal `SingleChildScrollView` + `DataTable` (unchanged).
2. If `result.rowCapNoticeText != null`, `Padding` with top 8, child `Text` using `ConnectionsScreen.muted`, `fontSize: 11`, same mono family as table headers (or `Theme.of(context).textTheme.bodySmall` tinted muted — match transcript secondary text).

Do not show footer for non-SELECT (`rowsAffected` block).

### 4. Paths covered (no session wiring changes)

| Path | Already uses `QueryExecutor`? | Footer |
|------|------------------------------|--------|
| `SessionController.executeSqlDirect` | Yes → `ResultLine` → `TableResultBlock` | Yes when injected |
| Agent `execute_sql` via orchestrator | Yes → `ResultLine` | Yes when injected |
| `testConnection` / raw client | No | N/A |

No changes to `session_providers.dart`, `transcript_view.dart`, or `AgentToolResultEvent`.

## Tests

### Unit — `test/query_executor_row_cap_test.dart`

Reuse `_RecordingDatabaseClient` pattern from `test/query_executor_schema_cache_test.dart`:

1. **Injects LIMIT and sets metadata** — `execute('SELECT * FROM users')` with `maxRows: 5`:
   - Client receives SQL containing `LIMIT 5`.
   - Returned `QueryResult` has `rowCapApplied: true`, `appliedRowCap: 5`.
2. **Existing LIMIT unchanged** — `execute('SELECT * FROM users LIMIT 50')` with `maxRows: 100`:
   - Client SQL unchanged (no double inject).
   - `rowCapApplied: false`, `appliedRowCap: null`.
3. **INSERT no cap** — `execute('INSERT INTO t VALUES (1)')` → `rowCapApplied: false`.

Fake client for (1) may return any row list; metadata assertion is on executor output, not row count.

### Unit — `rowCapNoticeText` (in `query_executor_row_cap_test.dart` or small `query_result_row_cap_test.dart`)

- `shown < cap` → copy contains `showing` and cap value.
- `shown >= cap` → copy contains `may be partial`.

### Widget — `test/table_result_block_row_cap_test.dart`

`testWidgets`:

1. Pump `TableResultBlock` with SELECT `QueryResult(rowCapApplied: true, appliedRowCap: 100, rows: List.generate(100, ...), columns: ['id'])` → finds text matching `row cap 100`.
2. Same widget with `rowCapApplied: false` → finds no `row cap` footer.

Use `MaterialApp` + dark scaffold if needed for `GoogleFonts` (follow any existing widget test harness in repo; if none, minimal `MaterialApp(home: Scaffold(body: ...))`).

### Regression

- `flutter analyze` + `flutter test` clean.
- Existing `agent_tool_result_transcript_test.dart` / `query_executor_schema_cache_test.dart` pass after optional `QueryResult` constructor args added (defaults preserve behavior).

## Acceptance criteria

1. `sql: SELECT * FROM generate_series(1, 500)` (or large table) with default `maxRows` 200 → table shows ≤200 rows **and** footer with cap 200; when 200 rows returned, copy indicates results may be partial.
2. `sql: SELECT * FROM t LIMIT 10` → **no** footer (mindb did not inject).
3. Agent NL `execute_sql` on a large SELECT → same footer on `TableResultBlock` as direct SQL.
4. DML / non-SELECT → no row-cap footer.

## Risks

- **False “partial” hint:** When exactly `maxRows` rows exist in DB, footer still says “may be partial” — acceptable for trust (prefer over silent completeness).
- **User `LIMIT` > `maxRows`:** `injectLimit` does not tighten existing LIMIT; large result sets possible without footer — pre-existing behavior; do not fix in this PR.
- **Constructor churn:** Many test `const QueryResult(...)` remain valid via defaults; grep `QueryResult(` if analyzer complains.

## Rollback

Revert PR: remove `QueryResult` cap fields, executor assignment, and `TableResultBlock` footer. No migrations or persisted state.

## Ready for dev

- [x] Single-PR scope confirmed (`QueryResult` + `QueryExecutor` + `TableResultBlock` + tests + qa-smoke)
- [x] No new infra / deps
- [x] Matches existing patterns (`ResultLine` / `TableResultBlock`; metadata on domain model)
