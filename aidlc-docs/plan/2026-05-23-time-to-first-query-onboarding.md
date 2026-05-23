# Time-to-first-query onboarding

**Issue:** #8  
**Explore brief:** [2026-05-23-time-to-first-query-onboarding.md](../explore/2026-05-23-time-to-first-query-onboarding.md) (PR #7)

## Summary

Replace the minimal connections empty state with a three-step checklist (connection → LLM API key → open session) and add actionable recovery on the session screen when connect or key setup fails. No new persistence keys, routes, or dependencies—only UI and small readiness/error-mapping helpers wired to existing `connectionsListProvider`, `appSettingsProvider`, and `SecureCredentialStore`.

## Files to touch

| File | Change |
|------|--------|
| `lib/features/connections/onboarding_status.dart` | **New** — immutable readiness model + pure `computeOnboardingStatus` for tests |
| `lib/features/connections/connections_providers.dart` | Add `onboardingReadinessProvider` (FutureProvider: list connections + read active-provider API key) |
| `lib/features/connections/connections_screen.dart` | Rich empty state checklist; optional top banner when connections exist but key missing |
| `lib/features/connections/onboarding_checklist.dart` | **New** — checklist UI (steps, CTAs, `go_router` pushes to `/connections/new`, `/settings`, first connection session) |
| `lib/features/session/session_error_mapper.dart` | **New** — map `StateError`/socket errors to short user copy + action kind (`settings` \| `editConnection` \| `none`) |
| `lib/features/session/session_providers.dart` | Use mapper in `_connect` catch so `ErrorLine` and `state.error` carry actionable text |
| `lib/features/session/session_screen.dart` | When `!isConnected` and `error != null`, show banner with primary action (Settings / Edit connection) above transcript |
| `test/onboarding_status_test.dart` | **New** — unit tests for readiness computation |
| `test/session_error_mapper_test.dart` | **New** — unit tests for error classification strings |

## Approach

### 1. Readiness model (testable, no UI)

```dart
class OnboardingStatus {
  final bool hasConnection;
  final bool hasLlmKey;
  bool get canOpenSession => hasConnection && hasLlmKey;
}
```

`computeOnboardingStatus({required int connectionCount, required bool hasLlmKey})` — keeps logic out of widgets.

### 2. `onboardingReadinessProvider`

- `await ref.watch(connectionsListProvider.future)` → `hasConnection = list.isNotEmpty`
- `await ref.watch(appSettingsProvider.future)` → active `llmProvider`
- `await ref.read(credentialStoreProvider).readLlmApiKey(provider)` → non-empty trim
- Return `OnboardingStatus`

Invalidate when connections save/delete and when settings save (existing `ref.invalidate(connectionsListProvider)` / `appSettingsProvider` already run from form/settings flows).

### 3. Connections home — empty state

When `connections.isEmpty`, replace centered “Tap +” text with `OnboardingChecklist`:

| Step | Done when | CTA |
|------|-----------|-----|
| 1. Add connection | `hasConnection` | **Add connection** → `/connections/new` |
| 2. LLM API key | `hasLlmKey` | **Open Settings** → `/settings` |
| 3. Ask a question | `canOpenSession` | **Open session** → `/session/{first.id}` (disabled until step 2) |

Visual: JetBrains Mono, `ConnectionsScreen` colors; step rows use `Icons.check_circle` (done) / `Icons.radio_button_unchecked` (pending). Short subtitle under title: “~3 min to first query: connection, API key, then ask.”

### 4. Connections home — non-empty, missing key

If `connections.isNotEmpty && !hasLlmKey`, show a slim `MaterialBanner` or padded row above the list (not only empty state): “Add your LLM API key in Settings to use natural language.” → `/settings`. Prevents users who added a profile from tapping through to a dead session.

### 5. Session connect errors

Current behavior: `_connect` catch sets `error: e.toString()` and `ErrorLine('Connection failed: $e')` — raw exceptions, no navigation.

- Add `SessionErrorMapper.map(Object error)` returning `{message, action}`.
- Map known cases:
  - `StateError` containing `LLM API key not configured` → message + `action: settings`
  - `StateError` `Password not stored` / `Connection not found` → `editConnection`
  - Postgres/socket failures → shorten to “Could not reach host:port. Check host, port, and network.” + `editConnection`
- `session_screen.dart`: if `!state.isConnected && state.error != null`, render a top `Banner` or `Container` with message + `TextButton` (“Open Settings” / “Edit connection”) using `context.push('/settings')` or `context.push('/connections/$id/edit')`.

Keep `SqlInputBar` disabled when `!isConnected` (unchanged).

### 6. Out of scope (per explore brief)

- Hosted onboarding, tutorials, SSH, multi-provider comparison UI, cloud sync
- Auto-opening Settings on first launch (explicit CTA only)
- Changing LLM tool loop or schema fetch

## Tests

- **Unit:** `computeOnboardingStatus` — all combinations of connection count × key present; `canOpenSession` only when both true.
- **Unit:** `SessionErrorMapper` — API key `StateError`, password missing, generic socket string → expected message substring and action enum.
- **Regression:** None in repo for connections UI today; mapper tests lock copy so future exception refactors do not regress onboarding CTAs.
- **Manual (QA smoke extension):** Cold install → checklist → add connection → settings key → open session → one NL prompt succeeds (document in PR if smoke checklist updated—optional, not required for this PR).

Run `flutter analyze` + `flutter test` before merge.

## Risks

- **Secure storage latency:** Readiness provider must not block UI thread; keep async in `FutureProvider`, show loading on empty state same as connections list spinner.
- **First connection ordering:** “Open session” uses `connections.first` from `listAll()` order—document that order is repository sort; if unstable, use most recently `touchLastUsed` once user saves (optional polish, not blocking).
- **Error mapper drift:** New throw sites in `_connect` must go through mapper or CTAs silently disappear.

## Rollback

Revert the implementation PR. No migrations or feature flags. Connections empty state reverts to prior copy; session errors revert to raw exception strings.

## Ready for dev

- [x] Single-PR scope confirmed (connections + session UI + small helpers + tests only)
- [x] No new infra / deps
- [x] Matches existing patterns (Riverpod FutureProvider, `ConnectionsScreen` theme, `go_router` pushes)
