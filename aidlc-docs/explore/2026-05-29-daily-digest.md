# Daily explore digest — 2026-05-29

Business scan: [2026-05-29-business-scan.md](./2026-05-29-business-scan.md) (PR [#68](https://github.com/tienan92it/mindb/pull/68), tracker [#69](https://github.com/tienan92it/mindb/issues/69)).

**Pipeline (not re-scored):** shipped #35, #39, #43, #47, #53, #57, #61 and cluster #2, #8, #14, #21.

---

## Scores — opportunities 1–5

| Opportunity | Conn | Schema/AI | Terminal UX | Safety | Settings | **Total** | Anti-slop | Decision |
|-------------|------|-----------|-------------|--------|----------|-----------|-----------|----------|
| 1. Query timeout transcript copy | 0 | 0 | 2 | 2 | 2 | **7** | Pass | **Ship** |
| 2. Postgres SQL error mapping (+ explain_sql) | 0 | 2 | 2 | 1 | 0 | **6** | Pass* | Defer |
| 3. Connection test failure mapping | 2 | 0 | 2 | 1 | 0 | **5** | Pass | Defer |
| 4. Max tool rounds recovery copy | 0 | 1 | 2 | 0 | 0 | **4** | Pass | Defer |
| 5. Profile-change reconnect prompt | 2 | 0 | 1 | 1 | 0 | **4** | Scope risk | Defer |

\*Opportunity 2 passes gates if limited to `mapExecuteFailure` + `explain_sql` in one mapper PR; keep separate from opp 1 to preserve single-PR scope.

## Re-score note (timeout 6→7)

2026-05-28 digest scored opp 1 at 6/10 (Safety 1). With live settings refresh (#61) on master, timeout limits apply on the next query without reconnect — failure copy is the remaining limits→transcript gap. Safety raised to 2 (enforced query limit, same cluster as row-cap and read-only transcript work). Meets ship bar.

## Defer reasons (opps 2–5)

- **Postgres SQL errors (6):** Main execute “why didn’t it run?” gap after timeout; sequence immediately after opp 1 ships; do not bundle with timeout PR.
- **Connection test (5):** Connect-path only; independent PR after execute mapper work.
- **Max tool rounds (4):** Low frequency; orchestrator string only.
- **Profile reconnect (4):** Job gate passes; single-PR uncertain — Technical Analysis must confirm profile fingerprint vs reconnect CTA scope.

## Ship candidate

See [2026-05-29-query-timeout-transcript.md](./2026-05-29-query-timeout-transcript.md).
