# Schema failure transcript warning

## Job

When schema introspection fails, the user sees that the session lacks reliable schema context before relying on a natural-language answer.

## Success metric

QA with blocked `information_schema` access shows a visible transcript warning; the user is not left with a confident answer built on hidden degraded schema text.

## Scope

**In:** Surface a transcript-visible warning when `SchemaService.fetchSchema()` fails for the session system index or `get_schema` tool path; reuse or extend `SessionErrorMapper` copy where appropriate; do not change introspection queries.

**Out:** Retrying schema fetch in background, SSH/connect fixes, raising Kimi context caps, FK/index catalog.

## Core path impact

schema | ask | transcript

## Score (0–2 each, max 10)

| Area | Score |
|------|-------|
| Connection reliability | 0 |
| Schema / AI accuracy | 2 |
| Terminal UX | 2 |
| Safety | 1 |
| Settings ergonomics | 0 |
| **Total** | **7** |

## Anti-slop check

- [x] Job gate — Hidden schema failure wastes first-session retries and undermines the under-3-minute success bar.
- [x] Core path — Makes schema → ask → transcript honest when introspection degrades.
- [x] Single-PR scope — Orchestrator/session transcript line on existing catch paths; tests only; no new infra.

## Decision

**Ship** — Score 7 (re-score 2026-05-26 refresh). After [#35](https://github.com/tienan92it/mindb/issues/35) DDL cache invalidation shipped, model-only `Schema unavailable: …` text is the dominant remaining schema→ask trust gap; users cannot see that NL answers lack reliable schema context.

## Notes

- Business scan opportunity #3: [2026-05-26-business-scan.md](./2026-05-26-business-scan.md) (PR [#32](https://github.com/tienan92it/mindb/pull/32)).
- Prior score 6 (2026-05-24–25); Safety 0→1 — degraded schema without a visible warning can mislead users into trusting generated SQL.
- Code today: `AiAgentOrchestrator._loadSchemaIndex()` returns `Schema unavailable: $e` to the model only.
