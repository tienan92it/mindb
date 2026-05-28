# Business scan — 2026-05-28

## Context

**Product:** mindb — mobile PostgreSQL client with natural-language queries over live schema context.

**Jobs in scope:** faster time-to-first-query, trustworthy AI answers, terminal clarity (core loop: connect → schema → ask → execute → transcript).

**Signals today:**
- Business model success bar: first successful query from install in under 3 minutes; schema fetch reliability; zero credential leaks.
- **Trust cluster (2026-05-26–27) shipped on master:** [#35 DDL schema cache](https://github.com/tienan92it/mindb/issues/35), [#39 schema failure warning](https://github.com/tienan92it/mindb/issues/39), [#43 row-cap notice](https://github.com/tienan92it/mindb/issues/43), [#47 partial schema index](https://github.com/tienan92it/mindb/issues/47), [#53 NL LLM error mapping](https://github.com/tienan92it/mindb/issues/53), [#57 safety-block transcript](https://github.com/tienan92it/mindb/issues/57), [#61 live settings refresh](https://github.com/tienan92it/mindb/issues/61) (feature PR [#63](https://github.com/tienan92it/mindb/pull/63) merged; Deliver may still close #61).
- **Pipeline:** No open `planned` issues. One open `explore` ship candidate (#61) awaiting Deliver housekeeping. Prior digest [2026-05-27-trust-path-remainder.md](./2026-05-27-trust-path-remainder.md) deferred query timeout (5/10), live settings (6→shipped), max tool rounds (4/10).
- **Code review (master):** `SessionErrorMapper.mapExecuteFailure` handles read-only, cancel, and network cases but not `TimeoutException` from `PostgresDatabaseClient.execute` (`future.timeout`). `AiAgentOrchestrator` still emits `AgentErrorEvent('Agent reached maximum tool rounds')` with no recovery guidance; `session_error_mapper_test` explicitly preserves the raw string. `ConnectionFormScreen._testConnection` surfaces `Connection failed: $e` while session connect uses `SessionErrorMapper.map`. Unknown Postgres/SQL failures on `sql:` and agent `execute_sql` still pass through `_shorten(error.toString())`. `explain_sql` tool path uses raw `explain failed: $e` in `ai_agent_orchestrator.dart`.
- **QA smoke:** Items 5b, 7b, 7c, 8, 8b assume mapped transcript copy; timeout and connection-test paths are not covered.

**Pipeline note:** Do not re-brief shipped #35, #39, #43, #47, #53, #57, #61 or prior cluster #2, #8, #14, #21. Score and plan only opportunities below.

---

## Opportunities

| # | Theme | Job statement | Success metric | Why now |
|---|--------|---------------|----------------|---------|
| 1 | Trustworthy AI answers · Terminal clarity | When a direct `sql:` or agent `execute_sql` run hits the configured query timeout, the user sees that the run timed out and which limit applied — not a generic `TimeoutException` string. | QA with `queryTimeoutSeconds` = 1 and `sql: SELECT pg_sleep(5)` shows a transcript line naming the timeout and Settings path; 0% raw timeout stack strings. | Live settings refresh (#61) now applies timeout on the next query, but timeout failures are still unmapped in `mapExecuteFailure` — the largest remaining execute→transcript trust gap after NL/safety/settings cluster shipped. |
| 2 | Trustworthy AI answers · Terminal clarity | When the agent exhausts its tool-round budget, the user knows the answer is incomplete and how to recover (narrow the question or use `sql:`). | QA prompt that forces >8 tool rounds shows one actionable transcript line with recovery hint; user completes a narrower follow-up in one session without reconnect. | Orchestrator still emits a bare `AgentErrorEvent`; post–schema-trust workloads on large DBs will hit this edge more often. Deferred at 4/10 on 2026-05-27 — re-score after timeout copy ships. |
| 3 | Time-to-first-query · Connect | When testing a connection from the connection form, the user gets the same actionable failure copy as session connect (host, SSL, auth, password) — not a raw exception dump. | QA with wrong host, wrong password, and SSL mismatch on **Test connection** shows mapped copy consistent with session connect failures; 0% `Connection failed: SocketException…` style strings on form. | `ConnectionFormScreen._testConnection` uses `Connection failed: $e` while `_connect` uses `SessionErrorMapper` — connect-path inconsistency blocks the &lt;3 minute success metric before the user opens a session. |
| 4 | Trustworthy AI answers · Execute | When Postgres rejects SQL (syntax, missing relation, permission), the transcript shows a short, recognizable reason — on both `sql:` and agent `execute_sql` paths. | QA: `sql: SELECT * FROM missing_table` and NL ask that runs invalid SQL show mapped messages (relation/syntax keywords), not truncated driver dumps; agent tool errors match direct SQL copy. | `mapExecuteFailure` falls through to `_shorten(text)` for most DB errors; `explain_sql` still uses raw `explain failed: $e`. With execute/safety/LLM trust shipped, SQL failure clarity is the main remaining “why didn’t it run?” gap on execute. |
| 5 | Connect · Execute | When the user saves an updated password or host on a connection profile that already has an open session, the app prompts reconnect or applies credentials before the next query — instead of failing mid-session with stale auth errors. | QA: open session, edit connection password in form, return without force-quit, run `sql: SELECT 1` — either succeeds with new creds or shows a single “Connection profile changed — reconnect” line with reconnect action. | `PostgresDatabaseClient` stays connected across profile edits; edited credentials live only in secure storage until reconnect — a connect→execute trust hole after onboarding improvements (#8). |

---

## Non-goals rejected

Per `aidlc-docs/business-model.md` — do not brief or plan:

| Rejected idea | Reason |
|---------------|--------|
| SSH tunneling | Explicit non-goal; direct TCP only in v1. |
| Multi-database engines (MySQL, SQLite, etc.) | PostgreSQL-only v1. |
| Hosted AI proxy / developer-hosted inference | User API keys + direct HTTPS only. |
| Cloud sync of connections or credentials | No backend sync in v1. |
| Dashboards, analytics home, or BI-style views | Outside terminal JTBD. |
| Streaming assistant tokens in transcript | Multi-PR UX scope; does not pass single-PR gate without infra. |
| FK/index catalog or deep schema graph | Multi-PR schema scope; not required for ad-hoc NL queries. |
| Accounts, billing, org workspaces | No identity layer in v1. |
| Persisted full agent transcript (tools + tables) across sessions | Sync/persistence expansion; text-only turn history is current scope. |
| Kimi China endpoint (`api.moonshot.cn`) exposure | Regional endpoint choice, not core-path job gate. |
| Re-brief NL LLM error mapping | Issue #53 shipped. |
| Re-brief safety-block transcript | Issue #57 shipped. |
| Re-brief live settings refresh | Issue #61 shipped (PR #63). |
| Re-brief trust cluster (#35, #39, #43, #47, #2, #8, #14, #21) | Shipped. |
| Streaming “session health” dashboard | Settings/session polish outside job gate. |
| Re-score / re-ship evidence-policy guardrail copy | `EvidencePolicy.noEvidenceReply` already actionable; not a transcript-trust regression. |

---

## Handoff to Product Planner

**When:** Next Product Planner webhook run.

**Actions:**
1. Score opportunities 1–5 with the 0–2 rubric (max 10) and anti-slop gates from `product-workflow.md`.
2. Skip re-scoring shipped #35, #39, #43, #47, #53, #57, #61 and transcript cluster #2, #8, #14, #21.
3. Opportunity 1 was deferred at 5/10 on 2026-05-27 — re-score first; live settings (#61) may raise Settings score but does not close the timeout copy gap.
4. Opportunities 1 and 4 may share `SessionErrorMapper` / execute-path work if a single PR passes scope gate; keep `explain_sql` in scope for opp 4 only if one PR.
5. Opportunity 3 is connect-only — can ship independently of execute mapper bundle.
6. Opportunity 5 — confirm single-PR scope (profile change detection + reconnect CTA vs auto-reconnect); defer if multi-session wiring required.
7. Do not add `planned` label from this scan.

**Suggested sequencing if multiple pass gates:** (1) query timeout transcript → (4) Postgres SQL error mapping (+ explain_sql if bundled) → (3) connection test mapping → (2) max tool rounds recovery → (5) profile-change reconnect prompt.

**Inputs:** This file, `business-model.md`, `decisions.md`, prior scan [2026-05-27-business-scan.md](./2026-05-27-business-scan.md), remainder scores [2026-05-27-trust-path-remainder.md](./2026-05-27-trust-path-remainder.md), `qa-smoke.md`.
