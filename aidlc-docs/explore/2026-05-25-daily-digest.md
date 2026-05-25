# Daily explore digest — 2026-05-25

Business scan: [2026-05-25-business-scan.md](./2026-05-25-business-scan.md) (PR [#26](https://github.com/tienan92it/mindb/pull/26), issue [#27](https://github.com/tienan92it/mindb/issues/27)).

**Pipeline (not re-scored):** shipped #2 Anthropic tool-use, #8 onboarding, #14 agent result tables; in-flight #21 executed SQL (`planned`, `tech-reviewed`).

---

## Scores — net-new top 3 briefed

| Opportunity | Conn | Schema/AI | Terminal UX | Safety | Settings | **Total** | Decision |
|-------------|------|-----------|-------------|--------|----------|-----------|----------|
| DDL schema cache invalidation | 0 | 2 | 1 | 1 | 0 | **6** | Defer |
| Schema failure transcript warning | 0 | 2 | 2 | 0 | 0 | **6** | Defer |
| Row-cap notice on truncated tables | 0 | 1 | 2 | 2 | 1 | **6** | Defer |

**No ship candidates ≥ 7** from this pass.

## Scores — not briefed (score < 7 or lower priority)

| Opportunity | Conn | Schema/AI | Terminal UX | Safety | Settings | **Total** | Decision |
|-------------|------|-----------|-------------|--------|----------|-----------|----------|
| NL LLM error mapping (actionable copy) | 0 | 1 | 2 | 0 | 0 | **5** | Defer |
| Read-only session indicator | 0 | 0 | 2 | 2 | 1 | **5** | Defer |

## Suggested sequencing (if build capacity opens)

1. DDL cache invalidation — unblocks correct NL after schema changes.
2. Schema failure visibility — reduces bad first answers on degraded introspection.
3. Row-cap notice — may bundle with executed-SQL (#21) if single-PR scope allows.
4. LLM error mapping — independent ask-path trust win.
5. Read-only indicator — small terminal/safety clarity.

## Rejected / skipped

Per scan non-goals and `business-model.md`; re-brief blocked for #8, #14, #2, #21.
