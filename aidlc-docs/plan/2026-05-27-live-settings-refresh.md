# Live settings refresh on active session

**Issue:** #61  
**Explore brief:** `aidlc-docs/explore/2026-05-27-live-settings-refresh.md` (brief PR https://github.com/tienan92it/mindb/pull/60)

## Summary

`SessionController` snapshots `SafetyPolicy`, `QueryExecutor` (row cap, timeout), and `AiAgentOrchestrator` + `LlmProvider` only inside `_connect()`. After Settings save, `ref.invalidate(appSettingsProvider)` reloads prefs but the open session keeps stale runtime objects until reconnect. Extract settings wiring into `_applySettings(AppSettings)` (shared with `_connect`), subscribe to `appSettingsProvider` while connected, and rebuild executor/orchestrator on change. Update `SessionState.llmProvider` / `llmModel` (and `LlmStatusBar`) without reconnect; append a transcript `SystemLine` when provider/model change so QA can verify copy in the transcript. No new persistence, UI, or timeout/max-rounds copy work.

## Files to touch

| File | Change |
|------|--------|
| `lib/features/session/session_providers.dart` | Extract `_applySettings(AppSettings)` from `_connect()` body; call from `_connect` after DB connect; `ref.listen` on `appSettingsProvider` to refresh when connected; guard `isBusy` / connect-in-progress; update state header fields; optional transcript system line on LLM change. |
| `aidlc-docs/qa-smoke.md` | Steps 7b and 8: remove mandatory reconnect; add live-refresh steps (read-only without reconnect; provider/model without reconnect). |
| `test/session_live_settings_test.dart` | **New** — unit tests for executor wiring + read-only refresh behavior (see Tests). |

**Out of scope:** Query timeout transcript mapping; max tool rounds copy; Settings UI changes; API-key-only refresh without `AppSettings` change; multi-session broadcast; changing `QueryExecutor` throw strings or `SessionErrorMapper`; reconnecting Postgres; invalidating `postgresClientProvider`.

## Approach

### 1. Extract `_applySettings` — `session_providers.dart`

Move lines ~197–214 (settings load → policy → executor → orchestrator) into a private method:

```dart
Future<void> _applySettings(AppSettings settings) async {
  final safetyPolicy = SafetyPolicy(readOnlyMode: settings.readOnlyMode);
  _schemaService ??= SchemaService(_client);
  _queryExecutor = QueryExecutor(
    client: _client,
    safetyPolicy: safetyPolicy,
    schemaService: _schemaService,
    maxRows: settings.maxRows,
    queryTimeout: Duration(seconds: settings.queryTimeoutSeconds),
    confirmationHandler: _handleConfirmation,
  );
  final llm = await _buildLlmProvider(settings);
  _orchestrator = AiAgentOrchestrator(
    llmProvider: llm,
    schemaService: _schemaService!,
    queryExecutor: _queryExecutor!,
  );
}
```

`_connect()` after successful `_client.connect(...)`: `await _applySettings(settings)` then set initial state (unchanged connect/system lines except use `settings` for `llmProvider` / `llmModel`).

Keep `_schemaService` instance across refresh (same `PostgresDatabaseClient`; cache invalidation unchanged).

### 2. Subscribe to settings changes

In `SessionController` constructor, after `_connect()` kickoff:

```dart
_ref.listen<AsyncValue<AppSettings>>(
  appSettingsProvider,
  (previous, next) {
    final settings = next.valueOrNull;
    if (settings == null) return;
    if (!state.isConnected) return;
    if (state.isBusy) return; // apply on next settings event after idle, or see note below
  unawaited(_refreshFromSettings(settings));
  },
);
```

Implement `_refreshFromSettings(AppSettings settings)`:

1. `await _applySettings(settings)` inside `try/catch`.
2. On success: `state = state.copyWith(llmProvider: settings.llmProvider, llmModel: settings.llmModel)` (and optionally append `SystemLine('Settings applied — ${_llmSystemLine(settings)}')` to `lines` **only** when provider or model changed vs previous state).
3. On `_buildLlmProvider` failure (missing API key): append `ErrorLine` with mapped copy via `SessionErrorMapper.mapNlFailure` or `map()` — do **not** disconnect Postgres; next NL ask will also fail until user fixes Settings.

**Busy guard:** If `isBusy`, skip refresh in listener (settings already saved; user’s in-flight query uses old executor). Next `appSettingsProvider` emission after save is single-shot — if user saves during busy, add `_pendingSettingsRefresh` flag set in listener when skipped, cleared and applied at end of `submitPrompt` / `executeSqlDirect` `finally` paths when `!isBusy`. Smallest fix: **defer one refresh** at busy end rather than missing refresh entirely.

**Initial connect:** Ignore first listener fire if `previous == null` or `previous?.valueOrNull == next.valueOrNull` to avoid double-apply during `_connect` (or only listen after `isConnected` becomes true).

### 3. Settings save path (no change required)

`settings_screen.dart` already calls `ref.invalidate(appSettingsProvider)` on save (~113). That reload triggers the listener for any open `SessionController` (autoDispose family stays alive while session route is mounted).

Do **not** add a manual `sessionControllerProvider.notifier.refresh()` from Settings unless listener proves unreliable in QA.

### 4. UI surfaces

| Surface | Behavior after refresh |
|---------|-------------------------|
| `LlmStatusBar` (`session_screen.dart`) | Reads `state.llmProvider` / `llmModel` — updates automatically via `copyWith`. |
| Transcript connect line | Unchanged (historical). |
| New system line | Append on provider/model change so transcript shows current `llm: …` per issue QA. |

### 5. Acceptance mapping (issue success metric)

| QA step | Expected |
|---------|----------|
| Connected session → Settings → read-only **on** → save → back to session (no reconnect) → `sql: DELETE FROM …` | Blocked with mapped read-only copy (`transcriptErrorLineForExecuteFailure` from #57); **no** reconnect |
| Connected → switch provider/model → save → NL ask (no reconnect) | `LlmStatusBar` shows new provider/model; new or latest transcript system line matches; NL uses new provider (verify via model label or provider-specific behavior) |
| Row cap | Save lower `maxRows` → `sql: SELECT * FROM generate_series(1, 500)` respects new cap without reconnect |
| Timeout | Save lower timeout → long-running query respects new timeout (raw timeout until timeout-copy issue ships) |

### 6. `qa-smoke.md` edits

- **7b:** Replace “reconnect” with “return to open session (no reconnect)”.
- **8:** “Switch provider/model, save, return to session — LLM bar and transcript reflect choice without reconnect.”
- Add **8b:** “Read-only live refresh” cross-ref step 7b without reconnect.

## Tests

### Unit — `test/session_live_settings_test.dart`

Use existing `_RecordingDatabaseClient` pattern from `test/query_executor_row_cap_test.dart`.

1. **`createQueryExecutorForSettings` parity (inline helper in test file):** Build `QueryExecutor` with `SafetyPolicy(readOnlyMode: false)` then `true` with same client — second blocks `DELETE FROM t` with `StateError` containing `Read-only mode`.
2. **Row cap refresh:** Executor with `maxRows: 5` injects `LIMIT 5`; rebuild with `maxRows: 10` injects `LIMIT 10` on next `execute` (same client, new executor instance).
3. **Regression:** Existing `safety_policy_test.dart`, `query_executor_row_cap_test.dart`, `session_error_mapper_test.dart` unchanged.

No `ProviderContainer` integration test required for this PR (defer if listener deferral is hard to test).

### Manual — `aidlc-docs/qa-smoke.md`

As in Acceptance above.

### CI gate

`flutter analyze` + `flutter test` green.

## Risks

- **Missed refresh while busy:** Without `_pendingSettingsRefresh`, saving settings during an active ask leaves stale policy until reconnect; implement defer-at-busy-end.
- **Listener during `_connect`:** Double-apply or race with partial connect — gate on `isConnected` and skip when `previous` is loading.
- **API key only:** Changing keys without changing `AppSettings` fields does not re-fire `appSettingsProvider`; user must toggle a tracked field or reconnect — document in PR, do not expand scope.
- **In-flight query uses old executor:** Acceptable; refresh applies before next `submitPrompt` / `executeSqlDirect` when not busy.
- **LLM refresh failure:** Missing key for new provider surfaces error line but DB stays connected — user fixes Settings and saves again.
- **#57 copy dependency:** Read-only QA expects mapped transcript; ensure #57 shipped on `master` before QA (already shipped per brief).

## Rollback

Revert PR: remove `_applySettings`, listener, and `_refreshFromSettings`; restore inline wiring in `_connect()` only; revert qa-smoke and test file.

## Ready for dev

- [x] Single-PR scope confirmed (`SessionController` wiring + qa-smoke + focused tests)
- [x] No new infra / deps
- [x] Matches existing patterns (`ref.listen` in feature layer, `appSettingsProvider` invalidate on save, rebuild domain objects in controller)
