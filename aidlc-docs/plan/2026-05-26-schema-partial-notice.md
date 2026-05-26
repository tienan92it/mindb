# Visible notice when schema context is partial (large DB)

**Issue:** #47  
**Explore brief:** `aidlc-docs/explore/2026-05-26-schema-partial-notice.md` (product brief PR https://github.com/tienan92it/mindb/pull/46; same scope as `aidlc-docs/explore/2026-05-24-schema-partial-notice.md`)

## Summary

`SchemaSummaryFormatter.formatSystemIndex` already caps the session catalog sent to the model (`systemIndexMaxChars` = 48 000) and appends `... (N more tables not shown)` in the **system prompt only** — the transcript stays silent while NL answers can omit unseen tables. Smallest fix: return truncation metadata from the formatter, emit a dedicated `AgentSchemaPartialEvent` when index load succeeds but the catalog is partial, and map it to a muted `SystemLine` at the start of each NL `run()` (before tool markers and assistant text). Do not change caps, `SchemaService` SQL, or tool-path `formatForTool` truncation (model already gets recovery suffix there).

## Files to touch

| File | Change |
|------|--------|
| `lib/domain/schema/schema_summary_formatter.dart` | Add `SchemaIndexFormatResult` (text + counts + `isPartial`); refactor `formatSystemIndex` to return it; keep `_truncateLines` behavior unchanged for model text. |
| `lib/domain/models/models.dart` | Add `AgentSchemaPartialEvent` on `AgentEvent` sealed hierarchy (`shownTables`, `totalTables`). |
| `lib/domain/ai/ai_agent_orchestrator.dart` | Use `SchemaIndexFormatResult` in `_loadSchemaIndex`; emit partial event when `isPartial && error == null` (once per `run()`). |
| `lib/features/session/session_providers.dart` | Handle `AgentSchemaPartialEvent`; export `transcriptLineForSchemaPartial(int shown, int total)` for tests. |
| `test/schema_summary_formatter_test.dart` | Assert `isPartial`, counts, and model text still contains `more tables not shown` when forced. |
| `test/ai_agent_orchestrator_schema_partial_test.dart` | **New** — fake client with many tables + stub LLM: first event is `AgentSchemaPartialEvent`; system message still contains truncated index. |
| `test/schema_partial_transcript_test.dart` | **New** — mapper → `SystemLine` with expected prefix and counts. |
| `aidlc-docs/qa-smoke.md` | Manual step: large-DB NL prompt shows partial-index notice; targeted `get_schema` still works. |

**Out of scope:** Raising `systemIndexMaxChars`, new introspection, persisted schema sync, multi-DB, connect-time banner, tool `formatForTool` user notices, Kimi/provider changes, new `WarningLine` type, session persistence of notices, deduping across multiple NL turns in one session (each `submitPrompt` → one `run()` → at most one notice is acceptable).

## Approach

### 1. Formatter — expose truncation metadata

Add a small value type in `schema_summary_formatter.dart`:

```dart
class SchemaIndexFormatResult {
  const SchemaIndexFormatResult({
    required this.text,
    required this.totalTables,
    required this.shownTables,
  });

  final String text;
  final int totalTables;
  final int shownTables;

  bool get isPartial => shownTables < totalTables;
}
```

Refactor `_truncateLines` to return `({String text, int shown})` (or inline counts in `formatSystemIndex`):

```dart
static SchemaIndexFormatResult formatSystemIndex(
  DatabaseSchema schema, {
  int maxChars = systemIndexMaxChars,
}) {
  if (schema.tables.isEmpty) {
    return const SchemaIndexFormatResult(
      text: 'No tables found.',
      totalTables: 0,
      shownTables: 0,
    );
  }
  final header = 'Database has ${schema.tables.length} tables. '
      'Use get_schema with schema, table, or search for column details.\n';
  final lines = schema.tables
      .map((t) => '${t.qualifiedName} (${t.columns.length} cols)')
      .toList();
  final truncated = _truncateLines(lines, maxChars: maxChars, header: header);
  return SchemaIndexFormatResult(
    text: truncated.text,
    totalTables: schema.tables.length,
    shownTables: truncated.shown,
  );
}
```

**Do not** change the existing omission line in model text (`... ($omitted more tables not shown)`). `isPartial` must match that line (`shownTables < totalTables`).

Empty schema: `isPartial` is false (no notice).

### 2. New agent event

```dart
class AgentSchemaPartialEvent extends AgentEvent {
  const AgentSchemaPartialEvent({
    required this.shownTables,
    required this.totalTables,
  });

  final int shownTables;
  final int totalTables;
}
```

Update exhaustive `switch` on `AgentEvent` in `session_providers.dart` and any test switches.

### 3. Orchestrator — emit after successful index load

Change `_loadSchemaIndex()` to return `({SchemaIndexFormatResult index, Object? error})`:

- **Success:** `index = SchemaIndexFormatResult` from `formatSystemIndex(schema)`, `error = null`.
- **Failure:** keep today’s model fallback string in `index.text` via a synthetic result or separate `summary` string; `error = e` (unchanged `Schema unavailable: $e` behavior).

At the start of `run()`, after `emitSchemaDegraded` for `indexLoad.error`:

```dart
if (indexLoad.error == null && indexLoad.index.isPartial) {
  events.add(AgentSchemaPartialEvent(
    shownTables: indexLoad.index.shownTables,
    totalTables: indexLoad.index.totalTables,
  ));
}
```

Use `schemaSummary = indexLoad.index.text` in system parts (same string as today).

**Mutual exclusion:** Partial event only when introspection **succeeds**. Index failure continues to use `AgentSchemaDegradedEvent` only.

**Order:** `AgentSchemaPartialEvent` (if any) → then existing tool loop events. On a run with both partial index and later `get_schema` failure, user may see partial notice then schema-unavailable line — acceptable.

### 4. Session transcript mapping

```dart
TranscriptLine transcriptLineForSchemaPartial({
  required int shownTables,
  required int totalTables,
}) {
  return SystemLine(
    'Schema index partial — showing $shownTables of $totalTables tables. '
    'Use get_schema with schema, table, or search for tables not listed.',
  );
}
```

In `submitPrompt` event loop:

```dart
case AgentSchemaPartialEvent(:final shownTables, :final totalTables):
  newLines.add(transcriptLineForSchemaPartial(
    shownTables: shownTables,
    totalTables: totalTables,
  ));
```

Place the new `case` adjacent to `AgentSchemaDegradedEvent` (both before tool markers). Reuse existing muted `SystemLine` styling in `TranscriptView` — no widget changes.

### 5. Forcing partial index in tests

`systemIndexMaxChars` (48 000) fits ~1.5k–2k typical index lines before omission. For deterministic unit tests:

- Prefer `formatSystemIndex(schema, maxChars: 2000)` with `_largeSchema(tableCount: 200)` from `schema_summary_formatter_test.dart`, **or**
- `tableCount: 2500` at default `maxChars` (slower but no param change in production code).

Assert `isPartial == true`, `shownTables < totalTables`, and `text` contains `more tables not shown`.

### 6. Orchestrator integration test sketch

New `test/ai_agent_orchestrator_schema_partial_test.dart`:

- `_LargeSchemaClient` implements `DatabaseClient`: `execute` returns 2500 table rows + minimal column rows for `SchemaService` SQL (copy column/table SQL shape from `schema_service_test` / `query_executor_schema_cache_test` fakes).
- `_StubLlmProvider` returns immediate text (no tools).
- `run(userPrompt: 'list all tables', …)` → `events.first` is `AgentSchemaPartialEvent` with `totalTables == 2500` and `shownTables < 2500`.
- Captured system `ChatMessage` still contains `Schema index:` and `more tables not shown` (model path unchanged).
- Separate case: index failure (`_FailingSchemaClient` from schema-warning test) → **no** `AgentSchemaPartialEvent`; first event remains `AgentSchemaDegradedEvent`.

## Tests

### Unit — `schema_summary_formatter_test.dart`

1. **Partial index** — `formatSystemIndex(_largeSchema(tableCount: 200), maxChars: 2000)` → `isPartial`, `shownTables < 200`, text contains `more tables not shown`.
2. **Full index** — small 2-table schema → `isPartial == false`, `shownTables == totalTables`.
3. **Regression** — existing “stays compact for large schemas” test updated to use `.text` on result object (or keep calling wrapper if Dev adds `formatSystemIndexText` alias — prefer single API).

### Unit — `schema_partial_transcript_test.dart`

- `transcriptLineForSchemaPartial(shownTables: 10, totalTables: 500)` → `SystemLine` containing `Schema index partial —` and `10 of 500`.

### Unit — `ai_agent_orchestrator_schema_partial_test.dart`

- Large DB → first event `AgentSchemaPartialEvent`; LLM system message includes truncated index.
- Failing schema → no partial event; degraded event only.

### Regression

- `flutter analyze` + `flutter test` clean.
- `ai_agent_orchestrator_schema_warning_test.dart` unchanged behavior for failure path.

## Acceptance criteria

1. NL prompt on a DB whose table count exceeds the compact index cap shows a transcript `SystemLine` with `Schema index partial — showing X of Y tables` **before** the assistant reply on that turn.
2. Same session: `get_schema` with `table` / `search` for a table **not** in the truncated index returns column details without app restart (tool path unchanged).
3. Small DB (all tables fit in index) → **no** partial notice.
4. Schema introspection failure → `Schema unavailable — …` only; **no** partial notice.

## Risks

| Risk | Mitigation |
|------|------------|
| Notice on every NL turn on large DBs | Acceptable for trust (mirrors per-run schema reload); cross-session dedup deferred |
| `shownTables` vs header line “Database has N tables” | Counts refer to listed index lines vs `schema.tables.length`; copy uses explicit X of Y |
| Large orchestrator test slow | Fake in-memory client only; no real PG required |
| Confusion with `AgentSchemaDegradedEvent` | Distinct event + prefix; partial only on successful fetch |

## Rollback

Revert PR: remove `SchemaIndexFormatResult`, `AgentSchemaPartialEvent`, orchestrator emission, session `case`, and tests. Model index text reverts to string-only API (update call sites in one file).

## Ready for dev

- [x] Single-PR scope confirmed (formatter metadata + orchestrator event + session line + tests + qa-smoke)
- [x] No new infra / deps
- [x] Matches existing patterns (`AgentSchemaDegradedEvent` + `transcriptLineFor*` helpers + `SystemLine`)
