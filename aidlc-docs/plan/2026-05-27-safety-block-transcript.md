# Safety-block transcript copy (read-only & cancelled SQL)

**Issue:** #57  
**Explore brief:** `aidlc-docs/explore/2026-05-27-safety-block-transcript.md` (brief PR https://github.com/tienan92it/mindb/pull/56)

## Summary

Direct SQL (`sql:` prefix and `executeSqlDirect`) still append `ErrorLine(e.toString())`, so read-only blocks and confirmation cancellations surface as `Bad state: Read-only mode: …` instead of actionable copy. NL asks already use `transcriptErrorLineForNlFailure`; the `sql:` branch has no inner `catch`, so safety failures incorrectly fall through to that NL mapper today. Smallest fix: add `SessionErrorMapper.mapExecuteFailure` for `QueryExecutor` / `SafetyPolicy` `StateError` shapes, export `transcriptErrorLineForExecuteFailure`, and wire **only** `executeSqlDirect` and the `sql:` branch in `submitPrompt` with a dedicated `catch` (leave NL orchestrator path, connect `map()`, schema events, timeout copy, and confirmation UI unchanged). Optionally pass mapped text into `ToolResultFormatter.sqlError` in the orchestrator `execute_sql` catch so agent tool failures show readable `error:` lines without changing transcript line types.

## Files to touch

| File | Change |
|------|--------|
| `lib/features/session/session_error_mapper.dart` | Add `mapExecuteFailure(Object error)` with execute/safety heuristics; keep `map()`, `mapNlFailure()`, and `mapSchemaIntrospectionFailure()` unchanged. |
| `lib/features/session/session_providers.dart` | Add `transcriptErrorLineForExecuteFailure`; use in `executeSqlDirect` `catch` and `sql:` branch `catch`; do **not** change NL `catch`, connect `catch`, or schema/tool helpers. |
| `lib/domain/ai/ai_agent_orchestrator.dart` | **Optional (same PR if diff stays small):** In `execute_sql` / `explain_sql` `catch`, call `ToolResultFormatter.sqlError(SessionErrorMapper.mapExecuteFailure(e).message)` instead of `e.toString()`. |
| `test/session_error_mapper_test.dart` | New `mapExecuteFailure` cases (see Tests). |
| `test/execute_error_transcript_test.dart` | **New** — `transcriptErrorLineForExecuteFailure` returns `ErrorLine` with expected message + action. |
| `aidlc-docs/qa-smoke.md` | Manual steps for read-only block and cancelled confirmation on direct `sql:` (see Acceptance). |

**Out of scope:** Query timeout mapping; live settings refresh (`SafetyPolicy` still snapshotted at connect); max tool rounds copy; new safety rules or confirmation sheet UI; converting agent `execute_sql` failures from `SystemLine` to `ErrorLine`; Postgres / network errors beyond `_shorten` default; changing `QueryExecutor` throw strings.

## Approach

### 1. Stable error sources (`QueryExecutor`)

Match these **exact** `StateError.message` values (today in `lib/domain/query/query_executor.dart`):

| Thrown message | Mapped user message (example) | `action` |
|----------------|------------------------------|----------|
| `Read-only mode: write/destructive SQL is blocked` | `Read-only mode is on. Turn off read-only in Settings to run write or DDL SQL.` | `settings` |
| `Query cancelled by user` | `Query cancelled. No changes were made.` | `none` |
| `Not connected to database` | `Not connected to the database.` | `none` |
| `Confirmation required but no handler configured` | `Could not confirm this query. Reconnect and try again.` | `none` |

**Detection order:** `StateError` → exact / `contains` match on `error.message` (not `toString()`, to avoid `Bad state:` prefix). Then reuse `_looksLikeNetworkFailure` + `SocketException` with connect-style host message and `editConnection` (parity with `map()` for execute-time network failures). Default: `_shorten(error.toString())`, `action: none`.

Do **not** map `ArgumentError('SQL cannot be empty')` to custom copy unless it appears in QA; default shorten is fine.

### 2. `SessionErrorMapper.mapExecuteFailure`

Add a dedicated mapper (do not overload `mapNlFailure` — LLM heuristics must not swallow read-only strings; do not overload connect `map()`).

```dart
static SessionErrorMapping mapExecuteFailure(Object error) {
  if (error is StateError) {
    final msg = error.message;
    if (msg.contains('Read-only mode')) { ... settings ... }
    if (msg.contains('Query cancelled by user')) { ... none ... }
    if (msg.contains('Not connected')) { ... none ... }
    if (msg.contains('Confirmation required')) { ... none ... }
  }
  // SocketException / network → same as map() host message, editConnection
  return SessionErrorMapping(message: _shorten(...), action: none);
}
```

Keep throw strings in `QueryExecutor` unchanged so tests stay stable.

### 3. Transcript helper — `session_providers.dart`

Export for tests (parity with `transcriptErrorLineForNlFailure`):

```dart
ErrorLine transcriptErrorLineForExecuteFailure(Object error) {
  final mapped = SessionErrorMapper.mapExecuteFailure(error);
  return ErrorLine(mapped.message, action: mapped.action);
}
```

### 4. Wire `executeSqlDirect` (~447–451)

```dart
} catch (e) {
  state = state.copyWith(
    lines: [...state.lines, transcriptErrorLineForExecuteFailure(e)],
    isBusy: false,
  );
}
```

### 5. Wire `sql:` branch in `submitPrompt` (~295–307)

Wrap the `sql:` execute block in its own `try/catch` so safety failures do **not** reach the outer NL mapper:

```dart
if (trimmed.toLowerCase().startsWith('sql:')) {
  final sql = trimmed.substring(4).trim();
  try {
    final result = await executor.execute(sql);
    ...
    return;
  } catch (e) {
    state = state.copyWith(
      lines: [...state.lines, transcriptErrorLineForExecuteFailure(e)],
      isBusy: false,
    );
    return;
  }
}
```

Leave outer `catch (e)` as `transcriptErrorLineForNlFailure(e)` for orchestrator failures only.

### 6. `ErrorLine` + `TranscriptView`

No model changes required (`ErrorLine` already has optional `action`). Read-only mapping uses `SessionRecoveryAction.settings` → existing **Open Settings** button in `transcript_view.dart`.

### 7. Agent `execute_sql` (optional, same PR)

In `ai_agent_orchestrator.dart` `execute_sql` / `explain_sql` catch blocks, replace:

```dart
formatted: ToolResultFormatter.sqlError(e.toString()),
```

with:

```dart
formatted: ToolResultFormatter.sqlError(
  SessionErrorMapper.mapExecuteFailure(e).message,
),
```

Transcript still renders `SystemLine` tool output (`agent_tool_result_transcript_test.dart` contract unchanged); only the embedded `error:` field becomes user-readable. Skip if scope review prefers strict two call-site wiring only.

### 8. Acceptance mapping (issue success metric)

| QA step | Expected |
|---------|----------|
| Settings → read-only **on**, reconnect, `sql: INSERT INTO …` | Transcript `!` line explains read-only block; message mentions Settings; **Open Settings** visible; no `Bad state:` / `StateError:` prefix |
| Turn read-only **off**, reconnect, retry same INSERT | Query runs or shows confirmation sheet (destructive/write path unchanged) |
| Write/destructive SQL with confirmation sheet → **Cancel** | Transcript `!` line says query was cancelled; no raw `Query cancelled by user` |
| `executeSqlDirect` path (if exposed in UI) | Same mapped copy as `sql:` prefix |

## Tests

### Unit — `test/session_error_mapper_test.dart` (`mapExecuteFailure`)

- `StateError('Read-only mode: write/destructive SQL is blocked')` → message contains `read-only` (case-insensitive), `action == settings`, message does not contain `Bad state`.
- `StateError('Query cancelled by user')` → message contains `cancelled`, `action == none`.
- `StateError('Not connected to database')` → message contains `Not connected`, `action == none`.
- `SocketException('Connection refused')` → message contains `Could not reach`, `action == editConnection`.
- Unknown `Exception('syntax error at or near')` → `_shorten` length ≤ 160, `action == none`.

### Unit — `test/execute_error_transcript_test.dart`

- `transcriptErrorLineForExecuteFailure(StateError('Read-only mode: write/destructive SQL is blocked'))` → `ErrorLine` with `action == SessionRecoveryAction.settings`.

### Regression

- Existing `map()`, `mapNlFailure`, and `mapSchemaIntrospectionFailure` tests unchanged and passing.
- `agent_tool_result_transcript_test.dart` unchanged unless orchestrator optional step is included (formatter text changes only; still `SystemLine`).
- `flutter analyze` + `flutter test` green.

### Manual — `aidlc-docs/qa-smoke.md`

Add after step 7 (Safety):

- `7b. **Read-only transcript** — Enable read-only in Settings, reconnect, run `sql: INSERT INTO …`. Transcript shows mapped read-only message and Open Settings (not raw StateError).`
- `7c. **Cancelled SQL** — With read-only off, run destructive/write SQL, cancel confirmation sheet. Transcript shows mapped cancelled message.`

## Risks

- **`sql:` outer catch regression:** Without inner `catch`, read-only errors hit `mapNlFailure` and may get wrong copy; inner `catch` is required, not optional.
- **Settings CTA vs reconnect:** Read-only requires reconnect today; message should say “turn off read-only in Settings” and CTA opens Settings — user must reconnect manually (live refresh is deferred issue).
- **Agent path UX:** Optional orchestrator change improves embedded error text but not `ErrorLine` visibility; full agent `ErrorLine` parity is a follow-up if QA requires it.
- **String drift:** Mapper keys off `QueryExecutor` messages; any change to throw text must update mapper + tests together.

## Rollback

Revert PR: remove `mapExecuteFailure` and `transcriptErrorLineForExecuteFailure`, restore `ErrorLine(e.toString())` in `executeSqlDirect` and remove `sql:` inner `catch`; revert orchestrator `sqlError` argument if optional step shipped.

## Ready for dev

- [x] Single-PR scope confirmed (mapper + two direct-SQL call sites + tests + qa-smoke; optional one-line orchestrator mapping)
- [x] No new infra / deps
- [x] Matches existing patterns (`SessionErrorMapper`, exported transcript helpers, `ErrorLine` + Settings CTA)
