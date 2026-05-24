# Invalidate schema cache after DDL-classified writes

## Job

After the agent or user changes database structure, the next plain-language question reflects the current tables and columns.

## Success metric

Post-DDL prompt (“what columns does X have?”) matches live schema without app restart in QA smoke.

## Scope

**In:** Call `SchemaService.clearCache()` (or `fetchSchema(forceRefresh: true)`) when executed SQL is classified as write/destructive and matches DDL patterns (`CREATE`, `ALTER`, `DROP`, …).

**Out:** FK/index catalog, persisted schema cache, polling, multi-DB introspection.

## Core path impact

schema | ask

## Score (0–2 each, max 10)

| Area | Score |
|------|-------|
| Connection reliability | 0 |
| Schema / AI accuracy | 2 |
| Terminal UX | 1 |
| Safety | 1 |
| Settings ergonomics | 0 |
| **Total** | **6** |

## Anti-slop check

- [x] Job gate — Reduces wrong SQL from stale schema context.
- [x] Core path — Strengthens schema → ask accuracy.
- [x] Single-PR scope — Hook in `QueryExecutor` or post-execute path + unit tests.

## Decision

**Defer** — Score 6; `clearCache()` exists but is unused in production; sequence after transcript table parity (#1) and executed-SQL visibility.

## Notes

- Business scan opportunity #2: [2026-05-24-business-scan.md](./2026-05-24-business-scan.md) (PR [#11](https://github.com/tienan92it/mindb/pull/11)).
- Same theme deferred 2026-05-22 and 2026-05-23; gap unchanged per scan.
