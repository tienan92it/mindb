# Daily explore digest — 2026-05-31

Business scan: [2026-05-31-business-scan.md](./2026-05-31-business-scan.md) (PR [#78](https://github.com/tienan92it/mindb/pull/78), tracker [#79](https://github.com/tienan92it/mindb/issues/79)).

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

## Re-score note (2026-05-31)

No feature merges since [2026-05-30-daily-digest.md](./2026-05-30-daily-digest.md); master code and QA gaps unchanged. Query timeout (#71) remains the last shipped execute→transcript trust item — Postgres SQL clarity is still the **next** execute priority but rubric weights unchanged: Terminal UX 2 (primary “why didn’t it run?” gap after timeout), Schema/AI 2 (`execute_sql` + `explain_sql` parity), Safety 1 (permission/syntax copy is trust messaging, not an enforced limit like timeout/row-cap/read-only). Connection test (5) and profile reconnect (4) unchanged; opp 4 still needs Technical Analysis scope confirmation before `planned`. **Below ship bar (7).**

## Defer reasons (opps 1–4)

- **Postgres SQL errors (6):** Highest-priority execute gap; `mapExecuteFailure` lacks Postgres syntax/relation/permission branches; `explain_sql` still uses raw `explain failed: $e`. Sequence as first ship candidate when a rubric path reaches 7 (e.g. after mapper ships and connection test becomes top).
- **Connection test (5):** `ConnectionFormScreen._testConnection` bypasses `SessionErrorMapper.map`; connect-only PR improves &lt;3 min install metric; independent of opp 1.
- **Max tool rounds (4):** Bare `AgentErrorEvent` string via `mapNlFailure`; low frequency; after execute mapper work.
- **Profile reconnect (4):** `PostgresDatabaseClient.activeProfile` drift after form save; job gate passes; single-PR uncertain — defer until Technical Analysis confirms fingerprint + reconnect CTA.

## Suggested sequencing

1. Postgres SQL / `explain_sql` error mapping (opp 1).
2. Connection test uses `SessionErrorMapper.map` (opp 2).
3. Max tool rounds actionable copy (opp 3).
4. Profile-change reconnect prompt (opp 4) — confirm scope in Technical Analysis.

## Decision

**Digest — no ship candidates ≥ 7.** Top score 6/10; anti-slop pass on opps 1–3; opp 4 deferred on scope gate.
