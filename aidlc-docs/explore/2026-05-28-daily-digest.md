# Daily explore digest — 2026-05-28

Business scan: [2026-05-28-business-scan.md](./2026-05-28-business-scan.md) (PR [#64](https://github.com/tienan92it/mindb/pull/64), tracker [#65](https://github.com/tienan92it/mindb/issues/65)).

**Pipeline (not re-scored):** shipped #35, #39, #43, #47, #53, #57, #61 and cluster #2, #8, #14, #21. Open explore #61 may await Deliver housekeeping only.

---

## Scores — all opportunities

| Opportunity | Conn | Schema/AI | Terminal UX | Safety | Settings | **Total** | Anti-slop | Decision |
|-------------|------|-----------|-------------|--------|----------|-----------|-----------|----------|
| 1. Query timeout transcript copy | 0 | 0 | 2 | 1 | 2 | **6** | Pass | Defer |
| 2. Max tool rounds recovery copy | 0 | 1 | 2 | 0 | 0 | **4** | Pass | Defer |
| 3. Connection test failure mapping | 2 | 0 | 2 | 1 | 0 | **5** | Pass | Defer |
| 4. Postgres SQL error mapping (+ explain_sql) | 0 | 2 | 2 | 1 | 0 | **6** | Pass* | Defer |
| 5. Profile-change reconnect prompt | 2 | 0 | 1 | 1 | 0 | **4** | Scope risk | Defer |

\*Opportunity 4 passes gates if limited to `mapExecuteFailure` + `explain_sql` in one mapper PR; bundling with opp 1 risks single-PR creep — sequence separately.

## Re-score note (timeout 5→6)

Live settings refresh (#61) raised Settings 1→2: timeout limits now apply on the next query, so transcript copy must name the active limit and Settings path. Terminal UX remains 2; still below ship bar (7).

## Defer reasons

- **Timeout (6):** Highest-priority execute→transcript gap after trust cluster; ship after next planner run or when bundled score strategy clears 7 with SQL errors only if one PR.
- **Postgres SQL errors (6):** Main “why didn’t it run?” execute gap; defer until timeout mapping lands to keep mapper PRs focused.
- **Connection test (5):** Connect-path only; improves time-to-first-query but below bar; independent PR after execute cluster.
- **Max tool rounds (4):** Low frequency; one orchestrator string; sequence after execute copy.
- **Profile reconnect (4):** Job gate passes; single-PR uncertain (profile-change detection + reconnect CTA vs auto-reconnect across open sessions) — revisit when connect house is quiet.

## Suggested sequencing

1. Query timeout transcript mapping (opp 1).
2. Postgres SQL / `explain_sql` error mapping (opp 4).
3. Connection test uses `SessionErrorMapper.map` (opp 3).
4. Max tool rounds actionable copy (opp 2).
5. Profile-change reconnect prompt (opp 5) — confirm scope in Technical Analysis.

## Decision

**Digest — no ship candidates ≥ 7.** Top scores 6/6; explicit anti-slop pass on opps 1–4; opp 5 deferred on scope gate.
