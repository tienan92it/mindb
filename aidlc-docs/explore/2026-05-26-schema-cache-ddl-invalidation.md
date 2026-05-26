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
| Terminal UX | 2 |
| Safety | 1 |
| Settings ergonomics | 0 |
| **Total** | **7** |

## Anti-slop check

- [x] Job gate — Reduces wrong SQL from stale schema context after DDL.
- [x] Core path — Strengthens schema → ask accuracy.
- [x] Single-PR scope — Hook in `QueryExecutor` or post-execute path + unit tests; `clearCache()` already exists.

## Decision

**Ship** — Score 7 (re-score 2026-05-26). With executed SQL in transcript ([#21](https://github.com/tienan92it/mindb/issues/21) shipped), stale schema is the dominant remaining schema→ask trust gap; users can audit tool SQL but still get wrong columns until cache invalidates.

## Notes

- Business scan opportunity #1: [2026-05-26-business-scan.md](./2026-05-26-business-scan.md) (PR [#32](https://github.com/tienan92it/mindb/pull/32)).
- Prior deferrals at score 6 (2026-05-22–25); Terminal UX raised from 1→2 post-transcript cluster.
- `SchemaService.clearCache()` is unused in production paths today.
