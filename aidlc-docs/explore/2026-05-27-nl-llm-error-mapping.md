# NL LLM error mapping (actionable transcript copy)

## Job

When a natural-language ask fails because the LLM or API call errors, the user sees actionable recovery guidance in the transcript instead of a raw exception string.

## Success metric

QA with empty or invalid provider key shows mapped copy and a Settings recovery path — not `e.toString()` — in 100% of NL failure runs on `submitPrompt`.

## Scope

**In:** Extend `SessionErrorMapper` (or sibling helpers) for common NL/API failures (missing key, auth, rate limit, network); route `SessionController.submitPrompt` catch and `AgentErrorEvent` paths through mapper; preserve existing connect-time mapping.

**Out:** Query timeout copy, safety-block copy, live settings refresh, max tool rounds message (separate briefs); new infra or provider-specific dashboards; streaming tokens.

## Core path impact

**ask** → **transcript** (execute path unchanged this PR)

## Score (0–2 each, max 10)

| Area | Score |
|------|-------|
| Connection reliability | 0 |
| Schema / AI accuracy | 2 |
| Terminal UX | 2 |
| Safety | 0 |
| Settings ergonomics | 1 |
| **Total** | **7** |

## Anti-slop check

- [x] Job gate — Improves trust in AI answers on the ask path (largest remaining post-setup trust gap after 2026-05-26 trust cluster).
- [x] Core path — `submitPrompt` / orchestrator errors → transcript `ErrorLine`.
- [x] Single-PR scope — Mapper extension + call-site wiring; no new services.

## Decision

**Ship** — Score 7; trust cluster shipped (#35, #39, #43, #47); connect path already mapped; NL path still uses `ErrorLine(e.toString())` at lines ~357–361 in `session_providers.dart`.

## Notes

- Business scan: [2026-05-27-business-scan.md](./2026-05-27-business-scan.md) (PR [#50](https://github.com/tienan92it/mindb/pull/50)).
- Prior digest deferred this at 5/10 (2026-05-26); Terminal UX and Schema/AI raised after trust-cluster completion.
- Bundling with safety-block or timeout copy is out of scope unless mapper stays single-PR — sequence separately if needed.
