# Trust-path remainder — scores for scan 2026-05-27 (opps 2, 4, 5)

Business scan: [2026-05-27-business-scan.md](./2026-05-27-business-scan.md) (PR [#50](https://github.com/tienan92it/mindb/pull/50)).

**Shipped from scan:** [#53 NL LLM error mapping](https://github.com/tienan92it/mindb/issues/53).

**Ship candidate this run:** [safety-block-transcript](./2026-05-27-safety-block-transcript.md) — issue linked from Product brief PR.

---

## Scores — deferred opportunities (not briefed as ship)

| Opportunity | Conn | Schema/AI | Terminal UX | Safety | Settings | **Total** | Decision |
|-------------|------|-----------|-------------|--------|----------|-----------|----------|
| Query timeout transcript copy | 0 | 0 | 2 | 1 | 1 | **5** | Defer — after safety-block; same mapper family |
| Live settings refresh on session | 0 | 1 | 1 | 2 | 2 | **6** | Defer — wiring change; safety-critical but multi-touch |
| Max tool rounds recovery copy | 0 | 1 | 2 | 0 | 0 | **4** | Defer — edge frequency; single string in orchestrator |

## Defer reasons

- **Timeout (5):** Job gate passes; execute-path mapper should follow safety-block PR to avoid scope creep.
- **Live settings (6):** Below 7; requires `SessionController` to re-apply `SafetyPolicy` / `QueryExecutor` / LLM provider without full reconnect — sequence after execute-error cluster.
- **Max tool rounds (4):** Terminal clarity only; does not unblock core jobs until higher-priority execute/settings gaps close.

## Suggested sequencing

1. Safety-block transcript (this run, score 7).
2. Query timeout transcript mapping.
3. Live settings refresh.
4. Max tool rounds actionable copy.
