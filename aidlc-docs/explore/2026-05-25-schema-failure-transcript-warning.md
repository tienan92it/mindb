# Visible transcript warning when schema introspection fails

## Job

When schema introspection fails, the user sees that the session lacks reliable schema context before relying on a natural-language answer.

## Success metric

QA scenario with blocked `information_schema` access shows a visible transcript warning; the user is not left with a confident answer built on hidden degraded schema text.

## Scope

**In:** Surface schema fetch failure as a user-visible transcript line (e.g. `SystemLine` or dedicated warning) when `SchemaService` cannot load context; keep degraded model prompt behavior optional but never silent-only.

**Out:** Auto-retry across networks, persisted schema snapshots, multi-DB introspection, permission-grant wizards.

## Core path impact

schema | ask | transcript

## Score (0–2 each, max 10)

| Area | Score |
|------|-------|
| Connection reliability | 0 |
| Schema / AI accuracy | 2 |
| Terminal UX | 2 |
| Safety | 0 |
| Settings ergonomics | 0 |
| **Total** | **6** |

## Anti-slop check

- [x] Job gate — Improves trust in first-session NL answers when introspection fails.
- [x] Core path — schema → ask with explicit transcript feedback.
- [x] Single-PR scope — Orchestrator/session wiring + QA smoke scenario; no new infra.

## Decision

**Defer** — Score 6; onboarding (#8) shortened cold start but hidden `Schema unavailable: …` system text still wastes retries. Pick up after DDL cache invalidation if only one build slot.

## Notes

- Business scan opportunity #3: [2026-05-25-business-scan.md](./2026-05-25-business-scan.md) (PR [#26](https://github.com/tienan92it/mindb/pull/26)).
- Today failures appear only inside the model system prompt, not in the transcript UI.
