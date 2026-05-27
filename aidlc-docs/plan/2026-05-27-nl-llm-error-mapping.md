# NL LLM error mapping (actionable transcript copy)

**Issue:** #53  
**Explore brief:** `aidlc-docs/explore/2026-05-27-nl-llm-error-mapping.md` (brief PR https://github.com/tienan92it/mindb/pull/52)

## Summary

Natural-language asks still append `ErrorLine(e.toString())` in `SessionController.submitPrompt` while connect-time failures already use `SessionErrorMapper`. Smallest fix: add `SessionErrorMapper.mapNlFailure` for LLM/API exception shapes (missing key, auth, rate limit, network, provider `formatLlmApiError` output), route `submitPrompt`’s outer `catch` and `AgentErrorEvent` through it, and surface `SessionRecoveryAction.settings` in the transcript via an optional action on `ErrorLine`. Leave `executeSqlDirect`, connect-time `map()`, schema degraded events, Anthropic provider HTTP formatting, and max-tool-rounds copy unchanged.

## Files to touch

| File | Change |
|------|--------|
| `lib/features/session/session_error_mapper.dart` | Add `mapNlFailure(Object error)` with NL/API heuristics; keep `map()` and `mapSchemaIntrospectionFailure()` unchanged for connect/schema paths. |
| `lib/domain/models/models.dart` | Extend `ErrorLine` with optional `SessionRecoveryAction? action` (default `null`). |
| `lib/features/session/session_providers.dart` | Add `transcriptErrorLineForNlFailure(Object error)` helper; use in `submitPrompt` `catch` and `AgentErrorEvent` branch; do **not** change `executeSqlDirect` or connect `catch`. |
| `lib/features/session/transcript_view.dart` | When `ErrorLine.action == settings`, show inline “Open Settings” `TextButton` (same route as `_ConnectErrorBanner`: `context.push('/settings')`). |
| `test/session_error_mapper_test.dart` | New `mapNlFailure` cases (see Tests). |
| `test/nl_error_transcript_test.dart` | **New** — `transcriptErrorLineForNlFailure` returns `ErrorLine` with expected message substring + action (no widget test). |
| `aidlc-docs/qa-smoke.md` | Manual step: invalid LLM key → NL ask shows mapped transcript error + Settings affordance. |

**Out of scope:** `executeSqlDirect` mapping; query timeout / safety-block copy; live settings refresh; improving `AnthropicProvider` to call `formatLlmApiError`; max tool rounds message rewrite; new transcript line types; provider dashboards; streaming.

## Approach

### 1. `SessionErrorMapper.mapNlFailure`

Add a dedicated mapper (do not overload connect `map()` with LLM heuristics that could mis-read Postgres errors).

**Detection order** (first match wins):

| Condition | Message (example) | `action` |
|-----------|-------------------|----------|
| Same as today’s `map()` for `StateError` containing `LLM API key not configured` | `LLM API key not configured. Add your key in Settings.` | `settings` |
| `SocketException` or `_looksLikeNetworkFailure(text)` | `Could not reach the LLM API. Check network and try again.` | `settings` |
| Text contains `401` or `invalid_api_key` or `incorrect api key` or `authentication` (case-insensitive) | `LLM API authentication failed. Check your API key in Settings.` | `settings` |
| Text contains `403` or `permission` + `api` | `LLM API access denied for this key. Check provider account tier in Settings.` | `settings` |
| Text contains `429` or `rate limit` | First line of error or `LLM rate limit reached. Wait and retry, or choose a lighter model in Settings.` | `settings` |
| `StateError` whose message starts with `<Provider> request failed` / `rate limit (429)` / `context too large (400)` / `model error (404)` from `formatLlmApiError` | Use **full** `StateError.message` (preserve provider guidance newlines); do not `_shorten` below 400 chars for these | `settings` when message mentions Settings or key; else `none` |
| `AgentErrorEvent` passthrough (`message` is `String` passed as `Object`) | Return message unchanged | `none` |
| Default | `_shorten(error.toString())` | `none` |

Implementation notes:

- Normalize with `final text = error is String ? error : error.toString();`
- For `StateError`, prefer `error.message` over `toString()` to avoid `Bad state: …` prefix.
- Reuse private `_looksLikeNetworkFailure` and `_shorten` from the same library.
- Do **not** map `Agent reached maximum tool rounds` to new copy (deferred issue).

### 2. Transcript helper — `session_providers.dart`

Export for tests (parity with `transcriptLineForSchemaDegraded`):

```dart
ErrorLine transcriptErrorLineForNlFailure(Object error) {
  final mapped = SessionErrorMapper.mapNlFailure(error);
  return ErrorLine(mapped.message, action: mapped.action);
}
```

### 3. Wire `submitPrompt`

**Outer catch** (~357–361):

```dart
} catch (e) {
  state = state.copyWith(
    lines: [...state.lines, transcriptErrorLineForNlFailure(e)],
    isBusy: false,
  );
}
```

**`AgentErrorEvent` case** (~337–338):

```dart
case AgentErrorEvent(:final message):
  newLines.add(transcriptErrorLineForNlFailure(message));
```

Leave `sql:` branch, schema events, tool lines, and `const ErrorLine('Not connected')` unchanged.

### 4. `ErrorLine` + `TranscriptView`

```dart
class ErrorLine extends TranscriptLine {
  const ErrorLine(this.message, {this.action});
  final String message;
  final SessionRecoveryAction? action;
}
```

In `transcript_view.dart`, for `ErrorLine` with `action == SessionRecoveryAction.settings`, render message plus a compact `TextButton` → `/settings`. Other actions stay message-only for this PR (no edit-connection CTA on NL path).

Update `const ErrorLine('Not connected')` call sites — still valid (action defaults null).

### 5. Provider errors (no provider edits)

OpenAI/Kimi already `throw StateError(formatLlmApiError(...))` — `mapNlFailure` must recognize those strings. Anthropic currently throws `StateError('Anthropic request failed: $statusCode')` — covered by 401/403 table rows; optional follow-up to unify formatting is out of scope.

### 6. Acceptance mapping (issue success metric)

| QA step | Expected |
|---------|----------|
| Valid connection + **invalid** provider API key in Settings | NL ask → transcript `!` line contains “API key” or “authentication”, not `StateError:` / `Bad state:` / raw JSON body |
| Same run | Transcript shows **Open Settings** button (or message explicitly says Settings with `action: settings`) |
| Rate-limit / network simulation (optional) | Mapped copy; no stack trace dump |

Empty key at **connect** remains connect-banner behavior (existing `map()`); this PR targets failures during `orchestrator.run` after connected.

## Tests

### Unit — `test/session_error_mapper_test.dart` (`mapNlFailure`)

- `StateError('LLM API key not configured. Open Settings.')` → message contains `API key`, `action == settings`.
- `StateError(formatLlmApiError(..., statusCode: 401, ...))` (import helper) → `settings`, message lacks `Bad state`.
- `StateError('OpenAI rate limit (429): …')` → `settings`, message contains `rate` or `429`.
- `SocketException` / failed host lookup string → network-style message, `settings`.
- `Exception('Anthropic request failed: 401')` → auth message, `settings`.
- `'Agent reached maximum tool rounds'` → message unchanged, `action == none`.
- Long unknown exception → length ≤ 160, `action == none`.

### Unit — `test/nl_error_transcript_test.dart`

- `transcriptErrorLineForNlFailure(StateError(...))` is `ErrorLine` with `action == SessionRecoveryAction.settings` for 401 fixture.

### Regression

- Existing `map()` and `mapSchemaIntrospectionFailure` tests unchanged and passing.
- `flutter analyze` + `flutter test` green.

### Manual — `aidlc-docs/qa-smoke.md`

Add after step 5:

`5b. **NL LLM error** — Set wrong API key in Settings, reconnect, natural-language ask. Transcript shows mapped error (not raw exception) and Open Settings affordance.`

## Risks

- **Heuristic false positives:** Generic “permission” strings could map to settings; keep patterns narrow (`permission` + `api` or status codes).
- **Long provider messages:** Full `formatLlmApiError` text may wrap in transcript; acceptable vs truncating recovery steps.
- **ErrorLine API change:** Any exhaustive switches on `ErrorLine` must accept new field (grep before merge).
- **Connected vs banner:** Settings CTA only on transcript for NL; connect failures keep existing banner — two surfaces, same enum.

## Rollback

Revert PR: remove `mapNlFailure`, restore `ErrorLine(e.toString())` in `submitPrompt`, drop optional `action` on `ErrorLine` if no other callers need it.

## Ready for dev

- [x] Single-PR scope confirmed (mapper + `submitPrompt` / `AgentErrorEvent` + optional `ErrorLine` action UI)
- [x] No new infra / deps
- [x] Matches existing patterns (`SessionErrorMapper`, exported transcript helpers, connect banner navigation)
