# Query timeout transcript copy

**Issue:** #71  
**Explore brief:** `aidlc-docs/explore/2026-05-29-query-timeout-transcript.md` (brief PR https://github.com/tienan92it/mindb/pull/70)

## Summary

`PostgresDatabaseClient.execute` enforces `queryTimeout` via `Future.timeout`, which throws `TimeoutException`. Execute paths already route failures through `SessionErrorMapper.mapExecuteFailure` (`transcriptErrorLineForExecuteFailure` on `sql:` / `executeSqlDirect`; `AiAgentOrchestrator` `execute_sql` catch uses the same mapper for tool error text). Today `mapExecuteFailure` falls through to `_shorten(error.toString())`, so users see raw `TimeoutException` copy. Smallest fix: add a `TimeoutException` branch in `mapExecuteFailure` with seconds-aware message and `SessionRecoveryAction.settings`. No wiring, timeout policy, settings store, or client changes.

## Files to touch

| File | Change |
|------|--------|
| `lib/features/session/session_error_mapper.dart` | Import `dart:async`; in `mapExecuteFailure`, handle `TimeoutException` before network/default fallthrough. |
| `test/session_error_mapper_test.dart` | Unit tests for timeout mapping (with and without `duration`). |
| `test/execute_error_transcript_test.dart` | One test: `transcriptErrorLineForExecuteFailure(TimeoutException(...))` → `ErrorLine` + `settings` action. |
| `aidlc-docs/qa-smoke.md` | Manual step for query timeout transcript (see Acceptance). |

**Out of scope:** Postgres syntax/relation/permission mapping; `explain_sql` copy; connection-form test mapping; max tool rounds; profile reconnect; changing `PostgresDatabaseClient`, `QueryExecutor`, settings slider bounds, or live settings refresh; converting agent tool failures from `SystemLine` to `ErrorLine`; wrapping/rethrowing timeouts with custom exception types.

## Approach

### 1. Error source (unchanged)

```56:56:lib/data/postgres/postgres_database_client.dart
        timeout == null ? await future : await future.timeout(timeout);
```

`QueryExecutor` passes `_queryTimeout` from `AppSettings.queryTimeoutSeconds` at session refresh time (`session_providers.dart`). Do **not** change throw site.

### 2. `TimeoutException` branch — `mapExecuteFailure`

Insert **after** existing `StateError` handling and **before** `SocketException` / `_looksLikeNetworkFailure` (avoid misclassifying query timeouts).

```dart
if (error is TimeoutException) {
  final seconds = error.duration?.inSeconds;
  final limit = seconds != null && seconds > 0
      ? '$seconds second${seconds == 1 ? '' : 's'}'
      : 'the configured limit';
  return SessionErrorMapping(
    message:
        'Query timed out after $limit. '
        'Increase query timeout in Settings to run longer SQL.',
    action: SessionRecoveryAction.settings,
  );
}
```

**Rationale:** `Future.timeout` sets `TimeoutException.duration` to the limit passed from `QueryExecutor` — no need to thread settings into the mapper. If `duration` is null (edge case), copy still names Settings without a wrong second count.

**Do not** match generic `toString()` substrings like `timed out` on arbitrary errors — only `error is TimeoutException`.

Keep existing `StateError`, network, and `_shorten` default paths unchanged.

### 3. Transcript wiring (no code changes expected)

Already wired:

| Path | Mechanism |
|------|-----------|
| `sql:` in `submitPrompt` | `transcriptErrorLineForExecuteFailure(e)` |
| `executeSqlDirect` | same helper |
| Agent `execute_sql` | `SessionErrorMapper.mapExecuteFailure(e).message` in `ToolResultFormatter.sqlError` → `SystemLine` in transcript |

Dev should **not** add new catch blocks or change `session_providers.dart` / `ai_agent_orchestrator.dart` unless regression shows a path still using `e.toString()` for timeouts (none found on master).

### 4. Copy consistency

Match tone of read-only execute mapping (`Settings` CTA, `SessionRecoveryAction.settings`). Message must **not** include `TimeoutException`, `Bad state`, or stack traces.

## Tests

### Unit — `test/session_error_mapper_test.dart` (`mapExecuteFailure`)

| Case | Input | Expect |
|------|-------|--------|
| Timeout with duration | `TimeoutException('Future not completed', Duration(seconds: 30))` | Message contains `timed out`, `30 second`, `Settings`; `action == settings`; message does **not** contain `TimeoutException` |
| Timeout without duration | `TimeoutException('Future not completed')` | Message contains `timed out`, `configured limit` or `Settings`; `action == settings` |
| Regression — read-only | existing test | unchanged |
| Regression — unknown SQL | existing `Exception('syntax error…')` test | still `_shorten`, `none` action |

### Unit — `test/execute_error_transcript_test.dart`

- `transcriptErrorLineForExecuteFailure(TimeoutException(..., Duration(seconds: 5)))` → `isA<ErrorLine>()`, `action == SessionRecoveryAction.settings`, message contains `timed out`.

### Automated gate

```bash
flutter analyze
flutter test
```

## Acceptance criteria

| Scenario | Expected |
|----------|----------|
| Direct `sql:` exceeds timeout | One `ErrorLine` naming timeout + Settings path; Open Settings affordance when `action == settings` |
| Agent NL ask runs `execute_sql` that times out | Transcript shows same mapped copy in tool result text (via `sqlError`), not raw `TimeoutException` |
| Successful query under limit | No change |
| Read-only / cancel / network execute errors | Existing mapped copy unchanged |

### Manual QA (`aidlc-docs/qa-smoke.md`)

Add step **6c** (after 6b):

- Set **Query timeout** to minimum (**5** seconds on current slider), save, return to open session.
- Run `sql: SELECT pg_sleep(10)` (Postgres `pg_sleep` extension available in default Docker image).
- Transcript shows mapped timeout line with **5** seconds (or “configured limit”) and Settings guidance — not `TimeoutException` / `Future not completed` raw string.

**Note:** Explore brief mentions `queryTimeoutSeconds = 1`; Settings UI slider minimum is **5** today. Unit tests use `TimeoutException` with explicit `Duration`; do not change slider bounds in this PR.

## Risks

| Risk | Mitigation |
|------|------------|
| `TimeoutException.duration` null on some platforms | Fallback copy without numeric seconds |
| Sub-second timeouts display `0 seconds` | `seconds > 0` guard; use “configured limit” when 0 |
| Network “connection timed out” vs query timeout | Only branch on `is TimeoutException`, not string heuristics on generic errors |
| Scope creep into Postgres SQL mapping | Defer per issue #71 deferred table |

## Rollback

Revert PR: remove `TimeoutException` branch and tests; execute paths automatically restore `_shorten(TimeoutException…)` behavior.

## Ready for dev

- [x] Single-PR scope confirmed (mapper + tests + qa-smoke note only)
- [x] No new infra / deps
- [x] Matches existing patterns (`mapExecuteFailure`, `transcriptErrorLineForExecuteFailure`, Settings CTA)
