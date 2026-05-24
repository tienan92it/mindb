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
| Schema / AI accuracy | 1 |
| Terminal UX | 2 |
| Safety | 2 |
| Settings ergonomics | 1 |
| **Total** | **6** |

## Anti-slop check

- [x] Job gate — Improves trust that capped tables are partial, not complete answers.
- [x] Core path — execute → transcript clarity after #14 table parity.
- [x] Single-PR scope — `TableResultBlock` + executor metadata only; may bundle with executed-SQL brief if one PR.

## Decision

**Defer** — Score 6; ship executed-SQL visibility first; bundle here if Dev confirms single-PR fit.

## Notes

- Business scan opportunity #3 (refresh): [2026-05-24-business-scan.md](./2026-05-24-business-scan.md) (PR [#18](https://github.com/tienan92it/mindb/pull/18)).
- `SafetyPolicy.injectLimit` applies silently today.
