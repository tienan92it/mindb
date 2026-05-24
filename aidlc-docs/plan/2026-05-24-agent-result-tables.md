# Render agent execute_sql results as transcript tables

**Issue:** #14  
**Explore brief:** `aidlc-docs/explore/2026-05-24-agent-result-tables.md` (PR https://github.com/tienan92it/mindb/pull/13; supersedes defer note in `aidlc-docs/explore/2026-05-23-agent-result-tables.md`)

## Summary

Agent NL prompts already run `execute_sql` and format results for the model via `ToolResultFormatter`, but `SessionController.submitPrompt` maps every `AgentToolResultEvent` to `SystemLine(result)` — a YAML-like text dump. Direct `sql:` and `executeSqlDirect` already append `ResultLine` → `TableResultBlock`. Smallest fix: carry the in-memory `QueryResult` from orchestrator tool execution into `AgentToolResultEvent`, then render `ResultLine` for successful `execute_sql` while keeping the formatted string on the event for LLM history (unchanged). No persistence, schema, or provider changes.

## Files to touch

| File | Change |
|------|--------|
| `lib/domain/models/models.dart` | Add optional `QueryResult? queryResult` on `AgentToolResultEvent`. |
| `lib/domain/ai/ai_agent_orchestrator.dart` | After `QueryExecutor.execute` for `execute_sql`, emit event with both `ToolResultFormatter.sqlResult(result)` and `queryResult: result`; errors/schema/explain unchanged (`queryResult` null). |
| `lib/features/session/session_providers.dart` | In `submitPrompt` event loop: `execute_sql` + non-null `queryResult` → `ResultLine`; else keep `SystemLine(result)`. Keep `SystemLine('tool → $toolName')` for tool calls. |
| `test/agent_tool_result_transcript_test.dart` | **New.** Pure Dart test mapping event → transcript line choice (no Flutter widget test). |

**Out of scope:** `ToolResultFormatter` (LLM evidence format stays), `TranscriptView` / `TableResultBlock` (already handle `ResultLine`), session persistence (`SessionContextBuilder` still stores assistant text only), showing executed SQL in transcript (issue follow-up), truncation banner (optional follow-up; executor `maxRows` already caps rows).

## Approach

### 1. Extend `AgentToolResultEvent`

```dart
class AgentToolResultEvent extends AgentEvent {
  const AgentToolResultEvent({
    required this.toolName,
    required this.result,
    this.queryResult,
  });
  final String toolName;
  final String result;
  final QueryResult? queryResult;
}
```

`result` remains the authoritative string pushed into `ChatMessage(role: 'tool', …)` for the model.

### 2. Orchestrator: attach `QueryResult` only for successful `execute_sql`

In `_executeTool` / tool loop (today returns `String` only):

- `execute_sql` success path: `final qr = await _queryExecutor.execute(sql);` then emit  
  `AgentToolResultEvent(toolName: 'execute_sql', result: ToolResultFormatter.sqlResult(qr), queryResult: qr)`.
- `execute_sql` error path: `queryResult: null`, `result: ToolResultFormatter.sqlError(...)`.
- `get_schema`, `explain_sql`, unknown tools: `queryResult: null` (existing formatted strings).

Refactor `_executeTool` to return `({String formatted, QueryResult? queryResult})` or inline in the `for (final toolCall …)` loop — avoid duplicating execute calls.

### 3. Session transcript wiring (parity with `sql:` path)

Current agent branch (~lines 274–287 in `session_providers.dart`):

```dart
case AgentToolResultEvent(:final result):
  newLines.add(SystemLine(result));
```

Replace with:

```dart
case AgentToolResultEvent(:final toolName, :final result, :final queryResult):
  if (toolName == 'execute_sql' && queryResult != null) {
    newLines.add(ResultLine(queryResult));
  } else {
    newLines.add(SystemLine(result));
  }
```

Behavior matrix:

| Tool | Outcome | Transcript line |
|------|---------|-----------------|
| `execute_sql` | SELECT / DML success | `ResultLine` → `TableResultBlock` |
| `execute_sql` | Error (formatter `status: error`) | `SystemLine(result)` |
| `get_schema` / `explain_sql` | any | `SystemLine(result)` |

`_persistTurns` unchanged — still stores assistant reply text only (brief explicitly out of scope).

### 4. QA alignment

Update manual check for issue #14 in QA smoke step 4: after NL question that triggers `execute_sql`, transcript shows bordered table (same as step 5 `sql: SELECT 1`), not only muted system YAML.

## Tests

- **Unit:** `test/agent_tool_result_transcript_test.dart`
  - Fixture `AgentToolResultEvent` with `toolName: 'execute_sql'`, sample `QueryResult`, and a small pure function or test helper mirroring session mapping → expect `ResultLine`.
  - Error `execute_sql` event (`queryResult: null`, `status: error` in `result`) → expect `SystemLine`.
  - `get_schema` event → `SystemLine`.
- **Regression:** Existing `test/evidence_policy_test.dart` / `ToolResultFormatter` tests unchanged (formatter not modified).
- **Manual (QA smoke #4 + #5):** Connected DB; NL prompt requiring SELECT; verify table block; compare with `sql: SELECT 1` styling.

## Risks

- **Double display:** Tool call line (`tool → execute_sql`) plus table — acceptable; matches trust goal. Executed-SQL brief may refine later.
- **Row volume:** UI table shows full `QueryResult` from executor (already `SafetyPolicy.injectLimit`); LLM still sees max 20 rows in formatter — intentional split, not a regression.
- **Non-SELECT agent runs:** `ResultLine` with `rowsAffected` uses existing `TableResultBlock` non-select branch — same as direct SQL.
- **Multi `execute_sql` in one turn:** Each success emits its own `ResultLine` — correct for verification.

## Rollback

Revert PR. Agent path reverts to `SystemLine` tool dumps; direct `sql:` path unaffected. No migrations.

## Ready for dev

- [x] Single-PR scope confirmed (models event field + orchestrator emit + session mapping + unit test)
- [x] No new infra / deps
- [x] Matches existing patterns (`ResultLine` / `TableResultBlock` on direct SQL path)
