# Daily explore digest — 2026-06-02

Business scan: [2026-06-02-business-scan.md](./2026-06-02-business-scan.md) (PR [#86](https://github.com/tienan92it/mindb/pull/86), tracker [#87](https://github.com/tienan92it/mindb/issues/87)).

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

## Re-score note (2026-06-02)

No feature merges since [2026-06-01-daily-digest.md](./2026-06-01-daily-digest.md); master at `cd25f16`. `SessionErrorMapper.mapExecuteFailure` still falls through to `_shorten` for Postgres syntax/relation/permission failures; `explain_sql` still uses raw `explain failed: $e` in `ai_agent_orchestrator.dart`; connection form `_testConnection` still bypasses `SessionErrorMapper.map`; max tool rounds and `activeProfile` drift unchanged. **Below ship bar (7).** No duplicate feature briefs — scores match prior digest.

## Defer reasons (opps 1–4)

- **Postgres SQL errors (6):** Highest-priority execute gap after query timeout (#71); mapper lacks Postgres branches; `explain_sql` bypasses mapper. First ship candidate when rubric reaches 7 or code delta changes scope.
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
