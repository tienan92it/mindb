# Daily explore — 2026-05-24

Planner pass on business scan PR [#18](https://github.com/tienan92it/mindb/pull/18) / issue [#25](https://github.com/tienan92it/mindb/issues/25). Skipped pipeline items: agent tables ([#14](https://github.com/tienan92it/mindb/issues/14) shipped), onboarding ([#8](https://github.com/tienan92it/mindb/issues/8) shipped), executed SQL ([#21](https://github.com/tienan92it/mindb/issues/21) `planned` + `tech-reviewed`).

## Top 3 scored (net-new)

| Opportunity | Conn | Schema/AI | Terminal | Safety | Settings | **Total** | Decision |
|-------------|------|-----------|----------|--------|----------|-----------|----------|
| Schema partial notice (large DB) | 0 | 2 | 2 | 0 | 0 | **6** | Defer |
| DDL schema cache invalidation | 0 | 2 | 1 | 1 | 0 | **6** | Defer |
| Row-cap notice on tables | 0 | 1 | 2 | 2 | 1 | **6** | Defer |

## Not briefed (score &lt; 7)

| Opportunity | Total | Notes |
|-------------|-------|-------|
| Schema introspection failure visibility | 6 | Defer after DDL + transcript trust |
| NL LLM error mapping (`SessionErrorMapper`) | 5 | Conn path already mapped; extend after #21 |

## Summary

No **new** ship candidates ≥ 7 from this scan pass. Highest net-new scores are **6** (trust notices and schema→ask accuracy). Active ship remains **[#21 Show executed SQL in agent transcript](https://github.com/tienan92it/mindb/issues/21)** (score 7, prior brief).

Briefs: [schema-partial-notice](./2026-05-24-schema-partial-notice.md), [schema-cache-ddl-invalidation](./2026-05-24-schema-cache-ddl-invalidation.md), [row-cap-notice](./2026-05-24-row-cap-notice.md).
