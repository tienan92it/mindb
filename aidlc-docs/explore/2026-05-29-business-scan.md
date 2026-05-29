# Business scan — 2026-05-29

## Context

**Product:** mindb — mobile PostgreSQL client with natural-language queries over live schema context.

**Jobs in scope:** faster time-to-first-query, trustworthy AI answers, terminal clarity (core loop: connect → schema → ask → execute → transcript).

**Signals today:**
- Business model success bar: first successful query from install in under 3 minutes; schema fetch reliability; zero credential leaks.
- **Trust cluster complete on master:** DDL schema cache (#35), schema failure warning (#39), row-cap notice (#43), partial schema index (#47), NL LLM error mapping (#53), safety-block transcript (#57), live settings refresh (#61, feature PR [#63](https://github.com/tienan92it/mindb/pull/63) merged). Issue #61 may still await Deliver housekeeping.
- **Prior scan consumed:** [2026-05-28-business-scan.md](./2026-05-28-business-scan.md) (PR [#64](https://github.com/tienan92it/mindb/pull/64), tracker [#65](https://github.com/tienan92it/mindb/issues/65) closed). Product Planner digest [#66](https://github.com/tienan92it/mindb/pull/66) deferred all five opportunities (top score 6/10); no open `planned` issues.
- **Pipeline:** Zero open `planned`. One open `explore` label on shipped #61 (housekeeping only). Execute→transcript and connect-path copy are the only unscored backlog themes.
- **Code review (master):** `PostgresDatabaseClient.execute` uses `future.timeout(timeout)` — failures surface as `TimeoutException`, not handled in `SessionErrorMapper.mapExecuteFailure` (falls through to `_shorten`). `ConnectionFormScreen._testConnection` still sets `Connection failed: $e` while `_connect` uses `SessionErrorMapper.map`. `mapExecuteFailure` and `explain_sql` (`explain failed: $e` in `ai_agent_orchestrator.dart`) leave Postgres syntax/relation/permission errors as shortened driver text. `AgentErrorEvent('Agent reached maximum tool rounds')` routes through `mapNlFailure` as a raw string (`session_error_mapper_test` preserves it). `PostgresDatabaseClient.activeProfile` is not compared after connection-form saves — open sessions keep stale TCP credentials. Live settings refresh applies timeout/row-cap/read-only on next query but adds no system line when only those settings change (LLM changes still get `llm:` system line).
- **QA smoke:** 7b/7c/8/8b cover live settings; no case for query timeout failure copy, connection-form test mapping, or profile edit with open session.

**Pipeline note:** Do not re-brief shipped #35, #39, #43, #47, #53, #57, #61 or cluster #2, #8, #14, #21. Score and plan only opportunities below.

---

## Opportunities

| # | Theme | Job statement | Success metric | Why now |
|---|--------|---------------|----------------|---------|
| 1 | Trustworthy AI answers · Terminal clarity | When a direct `sql:` or agent `execute_sql` run hits the configured query timeout, the user sees that the run timed out and which limit applied — not a raw `TimeoutException` string. | With `queryTimeoutSeconds` = 1 in Settings, `sql: SELECT pg_sleep(5)` shows one transcript line naming the timeout and Settings path; 0% raw `TimeoutException` strings. | Live settings refresh (#61) now applies timeout on the next query without reconnect — the failure path is the last execute→transcript gap in the trust cluster. Deferred 6/10 on 2026-05-28; re-score first. |
| 2 | Trustworthy AI answers · Execute | When Postgres rejects SQL (syntax, missing relation, permission), the transcript shows a short, recognizable reason on both `sql:` and agent `execute_sql` paths. | QA: `sql: SELECT * FROM missing_table` and NL ask that runs invalid SQL show mapped messages (relation/syntax keywords), not truncated driver dumps; `explain_sql` errors match direct SQL copy. | Safety, LLM, and settings trust shipped; SQL failure clarity is the main remaining “why didn’t it run?” gap on execute. Deferred 6/10 — sequence after or bundled with opp 1 only if single-PR gate holds. |
| 3 | Time-to-first-query · Connect | When testing a connection from the connection form, the user gets the same actionable failure copy as session connect (host, SSL, auth, password) — not a raw exception dump. | QA with wrong host, wrong password, and SSL mismatch on **Test connection** shows mapped copy consistent with session connect; 0% `Connection failed: SocketException…` on the form. | Connect path still splits mapper usage between form test and session `_connect` — blocks the &lt;3 minute install metric before the user opens a session. Deferred 5/10; independent of execute mapper bundle. |
| 4 | Trustworthy AI answers · Ask | When the agent exhausts its tool-round budget, the user knows the answer is incomplete and how to recover (narrow the question or use `sql:`). | QA prompt that forces max tool rounds shows one actionable transcript line with recovery hint; user completes a narrower follow-up in one session without reconnect. | Orchestrator still emits a bare string consumed by `mapNlFailure` without recovery guidance; more likely as schema-grounded NL runs grow on large DBs. Deferred 4/10. |
| 5 | Connect · Execute | When the user saves an updated password or host on a connection profile that already has an open session, the app prompts reconnect or applies credentials before the next query — instead of failing mid-session with stale auth errors. | QA: open session, edit connection password in form, return without force-quit, run `sql: SELECT 1` — either succeeds with new creds or shows one “Connection profile changed — reconnect” line with reconnect action. | `PostgresDatabaseClient` holds one connection per app instance; profile edits only update secure storage until reconnect — connect→execute trust hole after onboarding (#8). Deferred 4/10 on scope risk; Technical Analysis must confirm single-PR scope. |

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
| System line on every non-LLM settings change (timeout/row cap only) | Polish unless tied to timeout failure copy (opp 1); defer standalone ack. |
| Re-brief live settings refresh | #61 shipped on master. |
| Re-brief trust cluster (#35, #39, #43, #47, #53, #57, #2, #8, #14, #21) | Shipped. |
| Re-score evidence-policy / no-evidence guardrail copy | Already actionable; not a transcript regression. |

---

## Handoff to Product Planner

**When:** Next Product Planner webhook run.

**Actions:**
1. Score opportunities 1–5 with the 0–2 rubric (max 10) and anti-slop gates from `product-workflow.md`.
2. Skip re-scoring shipped #35, #39, #43, #47, #53, #57, #61 and transcript cluster #2, #8, #14, #21.
3. Opportunity 1 was 6/10 on 2026-05-28 digest — re-score first; #61 shipped raises Settings weight but does not close timeout **failure** copy.
4. Opportunities 1 and 2 may share `SessionErrorMapper` / execute-path work if one PR passes scope gate; keep `explain_sql` in scope for opp 2 only if bundled with opp 2, not opp 1 alone.
5. Opportunity 3 is connect-only — can ship independently.
6. Opportunity 5 — confirm single-PR scope (profile fingerprint vs `activeProfile` + reconnect CTA); defer if multi-session wiring required.
7. Do not add `planned` label from this scan.

**Suggested sequencing if multiple pass gates:** (1) query timeout transcript → (2) Postgres SQL error mapping (+ explain_sql if bundled) → (3) connection test mapping → (4) max tool rounds recovery → (5) profile-change reconnect prompt.

**Inputs:** This file, `business-model.md`, `decisions.md`, prior scan [2026-05-28-business-scan.md](./2026-05-28-business-scan.md), digest [2026-05-28-daily-digest.md](./2026-05-28-daily-digest.md), `qa-smoke.md`.
