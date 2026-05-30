# Daily explore digest — 2026-05-30

Business scan: [2026-05-30-business-scan.md](./2026-05-30-business-scan.md) (PR [#74](https://github.com/tienan92it/mindb/pull/74), tracker [#75](https://github.com/tienan92it/mindb/issues/75)).

**Pipeline (not re-scored):** shipped #35, #39, #43, #47, #53, #57, #61, #71 and cluster #2, #8, #14, #21.

---

## Scores — opportunities 1–4

| Opportunity | Conn | Schema/AI | Terminal UX | Safety | Settings | **Total** | Anti-slop | Decision |
|-------------|------|-----------|-------------|--------|----------|-----------|-----------|----------|
| 1. Postgres SQL error mapping (+ explain_sql) | 0 | 2 | 2 | 1 | 0 | **6** | Pass* | Defer |
| 2. Connection test failure mapping | 2 | 0 | 2 | 1 | 0 | **5** | Pass | Defer |
| 3. Max tool rounds recovery copy | 0 | 1 | 2 | 0 | 0 | **4** | Pass | Defer |
| 4. Profile-change reconnect prompt | 2 | 0 | 1 | 1 | 0 | **4** | Scope risk | Defer |

\*Opportunity 1 passes gates if limited to `mapExecuteFailure` Postgres branches + `explain_sql` orchestrator path in one mapper PR; defer FK/catalog parsing.

## Re-score note (SQL errors 6→6, timeout shipped)

2026-05-29 digest scored Postgres SQL errors at 6/10 and shipped opp 1 (query timeout) at 7/10 ([#71](https://github.com/tienan92it/mindb/issues/71), PR [#73](https://github.com/tienan92it/mindb/pull/73)). With timeout failure copy on master, SQL error mapping is the **next** execute→transcript priority but rubric weights unchanged: Terminal UX 2 (primary “why didn’t it run?” gap), Schema/AI 2 (`execute_sql` + `explain_sql`), Safety 1 (permission clarity is trust copy, not an enforced limit like timeout/row-cap). Settings stays 0 — no settings knob. **Below ship bar (7).**

## Defer reasons (opps 1–4)

- **Postgres SQL errors (6):** Highest-priority execute gap after #71; sequence as next ship candidate when planner re-run or scope bundling clears 7; keep separate from connection-test PR.
- **Connection test (5):** `ConnectionFormScreen._testConnection` still bypasses `SessionErrorMapper.map`; connect-only, improves &lt;3 min install metric; independent PR.
- **Max tool rounds (4):** Bare orchestrator string via `mapNlFailure`; low frequency; sequence after execute mapper work.
- **Profile reconnect (4):** `activeProfile` vs secure-storage drift after form save; job gate passes; single-PR uncertain — Technical Analysis must confirm fingerprint + reconnect CTA scope.

## Suggested sequencing

1. Postgres SQL / `explain_sql` error mapping (opp 1).
2. Connection test uses `SessionErrorMapper.map` (opp 2).
3. Max tool rounds actionable copy (opp 3).
4. Profile-change reconnect prompt (opp 4) — confirm scope in Technical Analysis.

## Decision

**Digest — no ship candidates ≥ 7.** Top score 6/10; anti-slop pass on opps 1–3; opp 4 deferred on scope gate.
