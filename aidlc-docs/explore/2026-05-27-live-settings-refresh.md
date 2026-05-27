# Live settings refresh on active session

## Job

After changing read-only mode, row cap, query timeout, or LLM provider in Settings, the open session applies the new policy on the next query without a silent stale policy or forced reconnect.

## Success metric

QA: enable read-only in Settings, return to an open session, run `sql: DELETE FROM …` — blocked immediately with mapped read-only copy. Switch provider/model, save, run NL ask without reconnect — transcript header `llm:` line matches saved provider/model.

## Scope

**In:** On `appSettingsProvider` refresh while connected, rebuild `SafetyPolicy`, `QueryExecutor` (maxRows, queryTimeout), `AiAgentOrchestrator` + `LlmProvider`, and update session header `llmProvider` / `llmModel` in state. Trigger from settings save (`invalidate`) via `SessionController` listener or explicit refresh hook.

**Out:** Query timeout transcript mapping, max tool rounds copy, new settings UI, credential migration, multi-session sync.

## Core path impact

**settings** → **execute** | **ask** | **transcript** (header system line)

## Score (0–2 each, max 10)

| Area | Score |
|------|-------|
| Connection reliability | 0 |
| Schema / AI accuracy | 1 |
| Terminal UX | 2 |
| Safety | 2 |
| Settings ergonomics | 2 |
| **Total** | **7** |

## Anti-slop check

- [x] Job gate — Stale read-only/timeout/row-cap/LLM after Settings save breaks answer trust; QA smoke #8 currently requires reconnect.
- [x] Core path — `SessionController` snapshots policy only in `_connect()`; wiring refresh closes settings→session gap on execute and ask paths.
- [x] Single-PR scope — Rebuild executor/orchestrator from current `AppSettings` in one controller method; no new persistence or infra.

## Decision

**Ship** — Score 7; highest remaining gap from scan 2026-05-27 after #53 (NL errors) and #57 (safety-block) shipped. Safety-critical before timeout/max-rounds copy work.

## Notes

- Business scan: [2026-05-27-business-scan.md](./2026-05-27-business-scan.md) (PR [#50](https://github.com/tienan92it/mindb/pull/50)).
- Prior ships from same scan: [#53](https://github.com/tienan92it/mindb/issues/53), [#57](https://github.com/tienan92it/mindb/issues/57).
- Sequence after: query timeout transcript → max tool rounds copy.
