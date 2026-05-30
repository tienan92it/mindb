# Business scan — 2026-05-30

## Context

**Product:** mindb — mobile PostgreSQL client with natural-language queries over live schema context.

**Jobs in scope:** faster time-to-first-query, trustworthy AI answers, terminal clarity (core loop: connect → schema → ask → execute → transcript).

**Signals today:**
- Business model success bar: first successful query from install in under 3 minutes; schema fetch reliability; zero credential leaks.
- **Query timeout transcript shipped:** [#71](https://github.com/tienan92it/mindb/issues/71) closed via feature PR [#73](https://github.com/tienan92it/mindb/pull/73). `SessionErrorMapper.mapExecuteFailure` maps `TimeoutException` with limit + Settings CTA; QA smoke **6c** covers timeout failure copy.
- **Trust cluster on master:** DDL schema cache (#35), schema failure warning (#39), row-cap notice (#43), partial schema index (#47), NL LLM error mapping (#53), safety-block transcript (#57), live settings refresh (#61), query timeout (#71).
- **Prior scan consumed:** [2026-05-29-business-scan.md](./2026-05-29-business-scan.md) (PR [#68](https://github.com/tienan92it/mindb/pull/68), tracker [#69](https://github.com/tienan92it/mindb/issues/69) closed). Product Planner digest [#66](https://github.com/tienan92it/mindb/pull/66) equivalent [2026-05-29-daily-digest.md](./2026-05-29-daily-digest.md) shipped opp 1 (7/10); deferred opps 2–5 at 6/5/4/4.
- **Pipeline:** Zero open `planned`, `building`, `tech-reviewed`, or open PRs. No open `explore` issues except closed scan trackers.
- **Code review (master):** `mapExecuteFailure` still falls through to `_shorten(error.toString())` for Postgres syntax/relation/permission failures (`session_error_mapper_test.dart` asserts unknown errors shorten only). `explain_sql` in `ai_agent_orchestrator.dart` uses raw `explain failed: $e` instead of `mapExecuteFailure`. `ConnectionFormScreen._testConnection` sets `Connection failed: $e` while session `_connect` uses `SessionErrorMapper.map`. `AgentErrorEvent('Agent reached maximum tool rounds')` routes through `mapNlFailure` as a bare string. `PostgresDatabaseClient.activeProfile` is not compared after connection-form saves — open sessions keep stale TCP credentials until manual reconnect.
- **QA smoke:** 6c covers timeout; no cases for Postgres SQL error mapping, connection-form test mapping, max tool rounds, or profile edit with open session.

**Pipeline note:** Do not re-brief shipped #35, #39, #43, #47, #53, #57, #61, #71 or cluster #2, #8, #14, #21. Score and plan only opportunities below.

---

## Opportunities

| # | Theme | Job statement | Success metric | Why now |
|---|--------|---------------|----------------|---------|
| 1 | Trustworthy AI answers · Execute | When Postgres rejects SQL (syntax, missing relation, permission), the transcript shows a short, recognizable reason on both `sql:` and agent `execute_sql` paths. | QA: `sql: SELECT * FROM missing_table` and NL ask that runs invalid SQL show mapped messages (relation/syntax keywords), not truncated driver dumps; `explain_sql` errors use the same copy as direct SQL. | Timeout copy (#71) closed the last execute→transcript gap in the safety/settings cluster; SQL failure clarity is the main remaining “why didn’t it run?” gap on execute. Scored 6/10 on 2026-05-29 — re-score first for ship bar. |
| 2 | Time-to-first-query · Connect | When testing a connection from the connection form, the user gets the same actionable failure copy as session connect (host, SSL, auth, password) — not a raw exception dump. | QA with wrong host, wrong password, and SSL mismatch on **Test connection** shows mapped copy consistent with session connect; 0% `Connection failed: SocketException…` on the form. | `ConnectionFormScreen._testConnection` still bypasses `SessionErrorMapper.map` — blocks the &lt;3 minute install metric before the user opens a session. Deferred 5/10; independent connect-only PR. |
| 3 | Trustworthy AI answers · Ask | When the agent exhausts its tool-round budget, the user knows the answer is incomplete and how to recover (narrow the question or use `sql:`). | QA prompt that forces max tool rounds shows one actionable transcript line with recovery hint; user completes a narrower follow-up in one session without reconnect. | Orchestrator still emits a bare string consumed by `mapNlFailure` without recovery guidance; more likely as schema-grounded NL runs grow on large DBs. Deferred 4/10. |
| 4 | Connect · Execute | When the user saves an updated password or host on a connection profile that already has an open session, the app prompts reconnect or applies credentials before the next query — instead of failing mid-session with stale auth errors. | QA: open session, edit connection password in form, return without force-quit, run `sql: SELECT 1` — either succeeds with new creds or shows one “Connection profile changed — reconnect” line with reconnect action. | `PostgresDatabaseClient` holds one connection per app instance; profile edits only update secure storage until reconnect — connect→execute trust hole after onboarding (#8). Deferred 4/10 on scope risk; Technical Analysis must confirm single-PR scope. |

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
| Re-brief query timeout transcript | #71 shipped on master (PR #73). |
| Re-brief trust cluster (#35, #39, #43, #47, #53, #57, #61, #2, #8, #14, #21) | Shipped. |
| System line on every non-LLM settings change (timeout/row cap only) | Polish unless tied to a scored opportunity; no standalone job gate. |
| Re-score evidence-policy / no-evidence guardrail copy | Already actionable; not a transcript regression. |

---

## Handoff to Product Planner

**When:** Next Product Planner webhook run.

**Actions:**
1. Score opportunities 1–4 with the 0–2 rubric (max 10) and anti-slop gates from `product-workflow.md`.
2. Skip re-scoring shipped #35, #39, #43, #47, #53, #57, #61, #71 and transcript cluster #2, #8, #14, #21.
3. Opportunity 1 was 6/10 on 2026-05-29 digest — re-score first now that timeout (#71) shipped; do not bundle timeout work.
4. Opportunity 1 scope: `mapExecuteFailure` Postgres error branches + `explain_sql` path in orchestrator if single PR passes gate; defer FK/catalog parsing.
5. Opportunity 2 is connect-only — can ship independently of opp 1.
6. Opportunity 4 — confirm single-PR scope (profile fingerprint vs `activeProfile` + reconnect CTA); defer if multi-session wiring required.
7. Do not add `planned` label from this scan.

**Suggested sequencing if multiple pass gates:** (1) Postgres SQL error mapping (+ explain_sql if bundled) → (2) connection test mapping → (3) max tool rounds recovery → (4) profile-change reconnect prompt.

**Inputs:** This file, `business-model.md`, `decisions.md`, prior scan [2026-05-29-business-scan.md](./2026-05-29-business-scan.md), digest [2026-05-29-daily-digest.md](./2026-05-29-daily-digest.md), shipped brief [2026-05-29-query-timeout-transcript.md](./2026-05-29-query-timeout-transcript.md), `qa-smoke.md`.
