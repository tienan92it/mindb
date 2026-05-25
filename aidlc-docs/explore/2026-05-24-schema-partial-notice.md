# Visible notice when schema context is partial (large DB)

## Job

On a large database, the user knows when the session’s schema context is truncated (compact table index capped) before trusting a broad natural-language answer.

## Success metric

QA on a DB with more tables than the system index cap shows a visible transcript or session notice; follow-up `get_schema` for a named table succeeds without restart.

## Scope

**In:** Surface when the compact schema index is truncated vs full catalog; optional one-line transcript or session banner; align copy with Kimi/large-DB context budget behavior on master.

**Out:** Raising index caps, new introspection sources, persisted schema sync, multi-DB.

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

- [x] Job gate — Improves trust in NL answers when model context omits unseen tables.
- [x] Core path — Strengthens schema → ask → transcript honesty after Kimi 4MB work.
- [x] Single-PR scope — Session/orchestrator notice when index build truncates; no new infra.

## Decision

**Defer** — Score 6; active ship [#21](https://github.com/tienan92it/mindb/issues/21) (executed SQL) and DDL/row-cap sequence per refresh scan handoff.

## Notes

- Business scan opportunity #1 (refresh): [2026-05-24-business-scan.md](./2026-05-24-business-scan.md) (PR [#18](https://github.com/tienan92it/mindb/pull/18)).
- Compact schema index and filtered `get_schema` shipped on master; truncation is silent in the UI today.
