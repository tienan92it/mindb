# Row-cap notice on truncated or LIMIT-injected results

## Job

When row limits cap what is shown, the user knows results are partial and how many rows were returned.

## Success metric

Truncated or LIMIT-injected result sets display an explicit notice (rows shown vs configured cap) in 100% of capped QA runs.

## Scope

**In:** After `SafetyPolicy.injectLimit` or row-cap enforcement, append transcript copy or metadata on `ResultLine` indicating partial results (rows returned vs `maxRows` / cap).

**Out:** Server-side `statement_timeout` changes, export of full result sets, charting.

## Core path impact

execute | transcript

## Score (0–2 each, max 10)

| Area | Score |
|------|-------|
| Connection reliability | 0 |
| Schema / AI accuracy | 1 |
| Terminal UX | 2 |
| Safety | 2 |
| Settings ergonomics | 1 |
| **Total** | **6** |

## Anti-slop check

- [x] Job gate — Prevents mistaking partial tables for complete answers.
- [x] Core path — execute → transcript clarity for agent and direct `sql:` paths.
- [x] Single-PR scope — `ResultLine` / session UI + executor metadata; standalone PR.

## Decision

**Defer** — Score 6; agent `SELECT` tables and executed SQL in transcript ([#21](https://github.com/tienan92it/mindb/issues/21) shipped) but silent row caps still make partial results look complete.

## Notes

- Business scan opportunity #2: [2026-05-25-business-scan.md](./2026-05-25-business-scan.md) (PR [#26](https://github.com/tienan92it/mindb/pull/26)).
- `SafetyPolicy.injectLimit` applies without transcript notice today.
