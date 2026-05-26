# Row-cap notice on truncated result tables

## Job

When row limits cap what is shown, the user knows results are partial and how many rows were returned so NL answers are not mistaken for complete data.

## Success metric

Truncated or LIMIT-injected result sets display an explicit notice (rows shown vs configured cap) in 100% of capped QA runs.

## Scope

**In:** Surface row count vs `maxRows` / injected `LIMIT` on `TableResultBlock` (agent and direct `sql:` paths); copy tied to settings cap.

**Out:** Export, pagination, server-side `statement_timeout` UX, changing safety limits.

## Core path impact

execute | transcript

## Score (0–2 each, max 10)

| Area | Score |
|------|-------|
| Connection reliability | 0 |
| Schema / AI accuracy | 2 |
| Terminal UX | 2 |
| Safety | 2 |
| Settings ergonomics | 1 |
| **Total** | **7** |

## Anti-slop check

- [x] Job gate — Improves trust that capped tables are partial, not complete answers.
- [x] Core path — execute → transcript clarity after executed SQL and table rendering shipped.
- [x] Single-PR scope — `QueryResult` cap metadata + `TableResultBlock` footer + tests; no new infra.

## Decision

**Ship** — Score 7 (re-score 2026-05-26, post–#35/#39). With executed SQL ([#21](https://github.com/tienan92it/mindb/issues/21)), DDL cache ([#35](https://github.com/tienan92it/mindb/issues/35)), and schema-failure warnings ([#39](https://github.com/tienan92it/mindb/issues/39)) shipped, silent `maxRows` / `injectLimit` caps are the dominant remaining execute→transcript trust gap; users audit SQL and tables but still cannot tell when results are partial.

## Notes

- Business scan opportunity #2: [2026-05-26-business-scan.md](./2026-05-26-business-scan.md) (PR [#32](https://github.com/tienan92it/mindb/pull/32)).
- Prior score 6 (2026-05-24–26); Schema/AI 1→2 — partial result sets mislead NL conclusions once transcript audit cluster is complete.
- `SafetyPolicy.injectLimit` and `TableResultBlock` omit cap notice today; `QueryResult` has no truncation flag yet.
