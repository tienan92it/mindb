# Daily explore digest — 2026-05-26

Business scan: [2026-05-26-business-scan.md](./2026-05-26-business-scan.md) (PR [#32](https://github.com/tienan92it/mindb/pull/32), issue [#33](https://github.com/tienan92it/mindb/issues/33)).

**Pipeline (not re-scored):** shipped #2 Anthropic tool-use, #8 onboarding, #14 agent result tables, #21 executed SQL in transcript.

---

## Scores — all opportunities

| Opportunity | Conn | Schema/AI | Terminal UX | Safety | Settings | **Total** | Decision |
|-------------|------|-----------|-------------|--------|----------|-----------|----------|
| DDL schema cache invalidation | 0 | 2 | 2 | 1 | 0 | **7** | **Ship** |
| Row-cap notice on truncated tables | 0 | 1 | 2 | 2 | 1 | **6** | Defer |
| Schema failure transcript warning | 0 | 2 | 2 | 0 | 0 | **6** | Defer |
| NL LLM error mapping (actionable copy) | 0 | 1 | 2 | 0 | 0 | **5** | Defer |
| Large-DB schema partial notice | 0 | 2 | 2 | 0 | 0 | **6** | Defer |

## Re-score note (DDL → 7)

Terminal UX raised 1→2 after transcript cluster shipped: executed SQL makes stale-schema mismatches visible in audit, increasing urgency to invalidate cache on DDL without restart.

## Ship candidate

Brief: [schema-cache-ddl-invalidation](./2026-05-26-schema-cache-ddl-invalidation.md) — tracking issue linked from Product brief PR.

## Suggested sequencing (remaining deferrals)

1. Schema failure visibility — reduces bad first answers on degraded introspection.
2. Row-cap notice — partial tables still look complete after #21.
3. Large-DB schema partial notice — silent index truncation.
4. NL LLM error mapping — extend `SessionErrorMapper` to ask path.

## Rejected / skipped

Per scan non-goals and `business-model.md`; re-brief blocked for #2, #8, #14, #21 (shipped). PR [#29](https://github.com/tienan92it/mindb/pull/29) prior briefs remain valid for defer items at score 6.
