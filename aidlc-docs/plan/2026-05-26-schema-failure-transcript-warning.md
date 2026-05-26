# Schema failure transcript warning

**Issue:** #39  
**Explore brief:** `aidlc-docs/explore/2026-05-26-schema-failure-transcript-warning.md` (product brief PR https://github.com/tienan92it/mindb/pull/38)

## Summary

Today `AiAgentOrchestrator._loadSchemaIndex()` catches `SchemaService.fetchSchema()` failures and injects `Schema unavailable: $e` into the **model system prompt only** — the transcript stays silent while the assistant may still answer confidently. Smallest fix: emit a dedicated `AgentSchemaDegradedEvent` with user-facing copy (via `SessionErrorMapper`) when session index load fails and when the `get_schema` tool fails; map that event to a visible `SystemLine` in `SessionController.submitPrompt` **before** tool markers and assistant text. Keep introspection SQL unchanged; do not add retries or new transcript line types.

## Files to touch

| File | Change |
|------|--------|
| `lib/domain/models/models.dart` | Add `AgentSchemaDegradedEvent` with `message` field on the `AgentEvent` sealed hierarchy. |
| `lib/features/session/session_error_mapper.dart` | Add `mapSchemaIntrospectionFailure(Object error)` → short user copy (permission / connection / generic). |
| `lib/domain/ai/ai_agent_orchestrator.dart` | Track schema degradation in `run()`: emit warning event when `_loadSchemaIndex` fails; emit warning on `get_schema` catch (dedupe same message in one run). |
| `lib/domain/ai/tool_result_formatter.dart` | Add `schemaError(String error)` with `source: get_schema` (fix today’s misuse of `sqlError` for schema tool failures). |
| `lib/features/session/session_providers.dart` | Handle `AgentSchemaDegradedEvent` in the event loop; export `transcriptLineForSchemaDegraded(String message)` for tests. |
| `test/session_error_mapper_test.dart` | Cases for permission denied, not connected, long exception shortening. |
| `test/ai_agent_orchestrator_schema_warning_test.dart` | **New** — fake `SchemaService` + stub `LlmProvider`: index failure yields degraded event before LLM; `get_schema` failure yields degraded event + tool result. |
| `test/schema_degraded_transcript_test.dart` | **New** — `transcriptLineForSchemaDegraded` → `SystemLine` with expected prefix/copy. |
| `aidlc-docs/qa-smoke.md` | Manual step: role without `information_schema` SELECT shows transcript warning before NL answer. |

**Out of scope:** Background schema retry, connect-time prefetch, SSH/connect fixes, Kimi context caps, truncation notices (issue #40+), new `WarningLine` UI type, persisting warnings in `SessionContext`, changing `SchemaService` SQL, mapping NL `catch` to `SessionErrorMapper` (separate issue).

## Approach

### 1. User-facing copy — `SessionErrorMapper.mapSchemaIntrospectionFailure`

Add a focused mapper (name as implemented):

| Condition | Transcript message (example) |
|-----------|------------------------------|
| `StateError` / text contains `Not connected` | `Not connected to the database.` |
| Permission / denied / `42501` / `information_schema` in message | `Cannot read database schema (permission denied). Natural-language answers may not match your tables.` |
| Default | Shortened `error.toString()` (reuse `_shorten`, max 160) |

Do **not** dump full driver stack traces. Model prompt may still include technical detail via existing `Schema unavailable: $e` string.

### 2. New agent event

```dart
class AgentSchemaDegradedEvent extends AgentEvent {
  const AgentSchemaDegradedEvent(this.message);
  final String message;
}
```

Update any exhaustive `switch` on `AgentEvent` (orchestrator tests only today; session loop gains a case).

### 3. Orchestrator — session index path

Refactor `_loadSchemaIndex()` to return a record, e.g. `({String summary, Object? error})`:

- **Success:** `summary = SchemaSummaryFormatter.formatSystemIndex(schema)`, `error = null`.
- **Failure:** `summary = 'Schema unavailable: $e'` (unchanged model text), `error = e`.

At the **start** of `run()`, after building `schemaSummary`:

```dart
if (indexError != null) {
  events.add(AgentSchemaDegradedEvent(
    SessionErrorMapper.mapSchemaIntrospectionFailure(indexError).message,
  ));
}
```

Then continue the existing tool loop (model still sees degraded index in system prompt).

### 4. Orchestrator — `get_schema` tool path

In `_executeTool` `get_schema` catch:

1. Keep returning `ToolResultFormatter.schemaError(...)` to the model (new formatter; replaces `sqlError`).
2. In `run()`, after appending `AgentToolResultEvent`, if this tool outcome was a schema failure, append `AgentSchemaDegradedEvent` **unless** the same `message` was already emitted this run (simple `String? _lastSchemaWarning` or `Set<String>` on stack inside `run()`).

Order in `events` for a failing `get_schema` round: `AgentToolCallEvent` → `AgentToolResultEvent` → optional `AgentSchemaDegradedEvent` (session maps all three to transcript lines).

### 5. `ToolResultFormatter.schemaError`

Mirror `sqlError` shape but `source: get_schema` and instruction to not invent tables. Example:

```
source: get_schema
status: error
no_data: true
error: <message>
instruction: Do not invent schema. Report unavailable or Unknown.
```

### 6. Session transcript mapping

Export helper (parity with `transcriptLineForAgentToolResult`):

```dart
TranscriptLine transcriptLineForSchemaDegraded(String message) {
  return SystemLine('Schema unavailable — $message');
}
```

In `submitPrompt` event loop, insert **before** `AgentToolCallEvent` handling (or at loop order: process degraded first when seen):

```dart
case AgentSchemaDegradedEvent(:final message):
  newLines.add(transcriptLineForSchemaDegraded(message));
```

**Acceptance:** After `UserLine`, the next system line for a failed index is the schema warning, then `tool → …` / results, then `AssistantLine`.

No `TranscriptView` style change — warning uses `SystemLine` (muted) with explicit `Schema unavailable —` prefix so it is distinguishable from `tool → get_schema` blocks.

### 7. Deduping

Within a single `orchestrator.run()` call:

- Index failure always emits one warning.
- If the model later calls `get_schema` and it fails with the **same** mapped message, skip the second `AgentSchemaDegradedEvent`.
- Different messages (e.g. transient then permission) may emit twice — acceptable for v1.

## Tests

### Unit — `session_error_mapper_test.dart`

- Permission-style exception → permission copy, no raw `PostgresqlException` paragraph.
- `StateError('Not connected to database')` → not-connected copy.
- Long generic exception → truncated to ≤160 chars.

### Unit — `ai_agent_orchestrator_schema_warning_test.dart`

Use a test double for `SchemaService` that throws on `fetchSchema()`, and a stub `LlmProvider` that returns one assistant message with no tool calls (minimal `chat` implementation).

- **Index failure:** `run(userPrompt: 'list tables', …)` → first event is `AgentSchemaDegradedEvent`; system message in captured LLM request still contains `Schema unavailable`.
- **get_schema failure:** stub LLM returns one `get_schema` tool call; assert events include `AgentToolResultEvent` with `source: get_schema` / `status: error` and `AgentSchemaDegradedEvent`.
- **Dedup:** index failure + failing `get_schema` in same run → exactly one `AgentSchemaDegradedEvent`.

### Unit — `schema_degraded_transcript_test.dart`

- `transcriptLineForSchemaDegraded('permission denied')` is `SystemLine` containing `Schema unavailable —` and the message.

### Regression

- `flutter analyze` + `flutter test` green.
- Existing `agent_tool_result_transcript_test.dart` unchanged for successful `get_schema` (still single `SystemLine`).

## Acceptance criteria

1. NL prompt when `fetchSchema()` fails for session index: transcript shows `Schema unavailable — …` **before** assistant reply.
2. Agent invokes `get_schema` and introspection fails: transcript shows the same style warning (plus existing tool output); model receives `source: get_schema` error block.
3. Successful schema load: no new warning lines.
4. QA smoke (manual): Postgres role denied `SELECT` on `information_schema` → warning visible; user understands answers are not schema-grounded.

## Risks

| Risk | Mitigation |
|------|------------|
| Warning too subtle (muted `SystemLine`) | Fixed prefix `Schema unavailable —`; revisit styling only if QA rejects |
| Duplicate warnings noise | Per-run dedupe on identical mapped message |
| Breaking exhaustive switches on `AgentEvent` | Compiler will flag; grep `AgentEvent` when implementing |
| Model still answers without schema | Expected; this issue is visibility only, not blocking generation |

## Rollback

Revert PR: remove `AgentSchemaDegradedEvent`, mapper method, orchestrator emissions, and session case. Behavior returns to model-only `Schema unavailable` text with no transcript line.

## Ready for dev

- [x] Single-PR scope confirmed
- [x] No new infra / deps
- [x] Matches existing patterns (`AgentEvent` stream, `SessionErrorMapper`, exported transcript mappers for tests)
