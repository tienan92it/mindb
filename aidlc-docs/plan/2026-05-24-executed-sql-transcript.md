# Show executed SQL in agent transcript

**Issue:** #21  
**Explore brief:** `aidlc-docs/explore/2026-05-24-executed-sql-transcript.md` (PR https://github.com/tienan92it/mindb/pull/20)

## Summary

Agent NL turns already emit `tool → execute_sql` and (after #14) `ResultLine` tables, but the statement text is invisible—users cannot audit what ran. Smallest fix: carry the executed statement on `AgentToolResultEvent`, emit one muted mono `SystemLine` with that SQL immediately before the existing result/error line, and stop emitting the redundant `tool → execute_sql` call marker. Success path uses `QueryResult.sql` (post-`injectLimit`, what actually ran); error path uses the tool argument SQL. No persistence, new deps, or transcript widget types.

## Files to touch

| File | Change |
|------|--------|
| `lib/domain/models/models.dart` | Add optional `String? executedSql` on `AgentToolResultEvent`. |
| `lib/domain/ai/ai_agent_orchestrator.dart` | For every `execute_sql` outcome, set `executedSql`: success → `queryResult.sql`; error/empty-arg → trimmed `sql` from tool args. |
| `lib/features/session/session_providers.dart` | Skip `SystemLine('tool → execute_sql')` on `AgentToolCallEvent`; extend mapping helper to prepend SQL line before result/error line for `execute_sql`. |
| `test/agent_tool_result_transcript_test.dart` | Extend tests for SQL line ordering and `execute_sql` call-line suppression logic. |
| `aidlc-docs/qa-smoke.md` | Step 4: verify executed SQL appears before result table on NL path. |

**Out of scope:** New `TranscriptLine` subtype, SQL editor, explain plans, query history persistence, session restore of tool lines (`SessionContextBuilder` still user/assistant only), `ToolResultFormatter` / LLM tool messages, `explain_sql` statement display.

## Approach

### 1. Extend `AgentToolResultEvent`

```dart
class AgentToolResultEvent extends AgentEvent {
  const AgentToolResultEvent({
    required this.toolName,
    required this.result,
    this.queryResult,
    this.executedSql,
  });
  // ...
  final String? executedSql;
}
```

`result` and `queryResult` behavior unchanged for LLM history and table rendering.

### 2. Orchestrator: populate `executedSql` for `execute_sql` only

In `_executeTool` `execute_sql` branch:

- **Success:** after `QueryExecutor.execute`, `executedSql: result.sql` (limited SQL from executor—matches rows shown).
- **Error** (executor throw, safety block, empty arg): `executedSql: sql.trim()` when non-empty; `queryResult: null`.
- **Other tools:** omit `executedSql` (default null).

Emit in existing `AgentToolResultEvent` construction (~line 107); no extra events.

### 3. Session transcript wiring

**Tool call line** (`submitPrompt` loop ~286–287):

```dart
case AgentToolCallEvent(:final toolName):
  if (toolName != 'execute_sql') {
    newLines.add(SystemLine('tool → $toolName'));
  }
```

**Tool result lines** — replace single-line `transcriptLineForAgentToolResult` with a small helper returning `List<TranscriptLine>`:

```dart
List<TranscriptLine> transcriptLinesForAgentToolResult(AgentToolResultEvent event) {
  final lines = <TranscriptLine>[];
  if (event.toolName == 'execute_sql') {
    final sql = event.executedSql?.trim();
    if (sql != null && sql.isNotEmpty) {
      lines.add(SystemLine(sql));
    }
  }
  lines.add(transcriptLineForAgentToolResult(event)); // existing ResultLine / SystemLine
  return lines;
}
```

Loop becomes `newLines.addAll(transcriptLinesForAgentToolResult(event))`.

Transcript order per `execute_sql` round:

1. `SystemLine` — executed SQL (mono muted, same style as other system lines)
2. `ResultLine` (success) or `SystemLine` formatter error dump (failure)
3. (later) `AssistantLine` when turn completes

`get_schema` / `explain_sql` still show `tool → …` then formatter `SystemLine`.

### 4. QA alignment

Update `aidlc-docs/qa-smoke.md` step 4: after an NL prompt that triggers `execute_sql`, transcript shows the statement text immediately above the result table (or error block), not only `tool → execute_sql`.

## Tests

- **Unit:** `test/agent_tool_result_transcript_test.dart`
  - `execute_sql` success event with `executedSql` + `queryResult` → helper returns two lines: `SystemLine(sql)`, then `ResultLine`.
  - `execute_sql` error with `executedSql`, `queryResult: null` → `SystemLine(sql)` then `SystemLine(error formatter text)`.
  - `get_schema` → unchanged single `SystemLine` (no SQL prefix).
  - Optional: pure function mirroring `toolName != 'execute_sql'` guard for call marker (or inline session test if extracted).
- **Regression:** Existing result-table mapping tests still pass; formatter tests untouched.
- **Manual (QA smoke #4):** NL SELECT; confirm SQL line precedes table; failed SQL still shows attempted statement before error YAML.

## Risks

- **Raw vs limited SQL:** Success shows `QueryResult.sql` (with `LIMIT`)—correct for audit vs displayed rows; may differ from model’s tool arg—acceptable.
- **Long statements:** Full SQL in `SystemLine` can wrap; no truncation in v1 (same as direct `sql:` user line).
- **Sensitive data:** SQL visible in transcript RAM only (not persisted)—same as current in-memory transcript; no new logging.
- **Multi `execute_sql`:** Each round gets its own SQL + result pair—intended.

## Rollback

Revert PR. Agent path reverts to `tool → execute_sql` + table/error only; no migrations.

## Ready for dev

- [x] Single-PR scope confirmed (event field + orchestrator emit + session mapping + tests + QA doc line)
- [x] No new infra / deps
- [x] Matches existing patterns (`SystemLine` mono in `TranscriptView`, `ResultLine` from #14)
