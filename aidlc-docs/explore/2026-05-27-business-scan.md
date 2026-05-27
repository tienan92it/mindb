# Business scan — 2026-05-27

## Context

**Product:** mindb — mobile PostgreSQL client with natural-language queries over live schema context.

**Jobs in scope:** faster time-to-first-query, trustworthy AI answers, terminal clarity (core loop: connect → schema → ask → execute → transcript).

**Signals today:**
- Business model success bar: first successful query from install in under 3 minutes; schema fetch reliability; zero credential leaks.
- **2026-05-26 trust cluster shipped:** [#35 DDL schema cache invalidation](https://github.com/tienan92it/mindb/issues/35) (PR [#37](https://github.com/tienan92it/mindb/pull/37)), [#39 schema failure transcript warning](https://github.com/tienan92it/mindb/issues/39) (PR [#41](https://github.com/tienan92it/mindb/pull/41)), [#43 row-cap notice](https://github.com/tienan92it/mindb/issues/43) (PR [#45](https://github.com/tienan92it/mindb/pull/45)), [#47 large-DB schema partial notice](https://github.com/tienan92it/mindb/issues/47) (PR [#49](https://github.com/tienan92it/mindb/pull/49)). QA smoke items 3b–3c, 4, 6b are covered on master.
- **Pipeline:** No open `explore` or `planned` issues; no in-flight ship candidates. Product Planner last digest ([2026-05-26-daily-digest.md](./2026-05-26-daily-digest.md)) deferred NL LLM error mapping at score 5 — now the largest remaining transcript-trust gap on the ask/execute paths.
- **Code review (master):** `SessionController.submitPrompt` and `executeSqlDirect` still `catch` with `ErrorLine(e.toString())` while `_connect` uses `SessionErrorMapper` (lines ~357–361, ~441–445 in `session_providers.dart`). `SafetyPolicy` / read-only / timeout values are snapshotted only in `_connect()` — Settings changes do not refresh `QueryExecutor` or LLM provider until session reconnect. `AgentErrorEvent('Agent reached maximum tool rounds')` surfaces raw copy. Postgres `execute` uses `future.timeout` with no mapped timeout message.
- **Cadence:** Webhook-driven roles (~4×/day per `decisions.md`); this scan feeds the next Product Planner run.

**Pipeline note:** Do not re-brief shipped #35, #39, #43, #47 or prior cluster #2, #8, #14, #21. Score and plan only opportunities below.

---

## Opportunities

| # | Theme | Job statement | Success metric | Why now |
|---|--------|---------------|----------------|---------|
| 1 | Trustworthy AI answers · Time-to-first-query | When an LLM or API call fails during a natural-language ask, the user gets actionable recovery guidance in the transcript. | QA with empty or invalid provider key shows mapped copy and a Settings recovery path — not a raw exception string — in 100% of NL failure runs. | Connect path already uses `SessionErrorMapper`; NL `submitPrompt` still surfaces `e.toString()`. With schema/row-cap/DDL trust shipped, post-setup API failures are the main trust regression on the ask path. |
| 2 | Trustworthy AI answers · Terminal clarity | When a direct `sql:` or agent `execute_sql` run hits the configured query timeout, the user sees that the run timed out and which limit applied — not a generic `TimeoutException` string. | QA with `queryTimeoutSeconds` set to 1s and `sql: SELECT pg_sleep(5)` shows a transcript line naming the timeout; 0% raw timeout stack strings. | Timeout is user-configurable in Settings and enforced in `PostgresDatabaseClient.execute`; errors bubble unmapped through the same `ErrorLine(e.toString())` paths as other execute failures. |
| 3 | Safety · Trustworthy AI answers | When read-only mode or the safety gate blocks SQL (write/destructive/cancelled), the transcript explains why the query did not run and what to change. | QA with read-only on: `sql: INSERT INTO …` shows a clear blocked message; toggling read-only off in Settings then retrying succeeds without guessing. | Read-only and confirmation flows exist, but blocked runs still throw `StateError` strings into `ErrorLine` on direct SQL; users auditing safety need the same clarity as connect-time mapping. |
| 4 | Trustworthy AI answers · Safety | After changing read-only mode, row cap, query timeout, or LLM provider in Settings, the active session applies the new policy on the next query without a silent stale policy. | QA: enable read-only in Settings, return to an open session, run `sql: DELETE FROM …` — blocked immediately; transcript header updates `llm:` line after provider switch without force-quit. | `QueryExecutor`, `SafetyPolicy`, and `_buildLlmProvider` are created once in `_connect()`; Settings-only changes leave execute/ask paths on old limits — a trust and safety gap now that row-cap and schema notices make partial results visible. |
| 5 | Trustworthy AI answers · Terminal clarity | When the agent exhausts its tool-round budget, the user knows the answer is incomplete and how to recover (simplify the question or use `sql:`). | QA prompt that forces >8 tool rounds shows a single actionable transcript line; user can complete the task with a narrower follow-up in one session. | `AiAgentOrchestrator` emits `AgentErrorEvent('Agent reached maximum tool rounds')` with no recovery guidance; complex schemas post-trust-cluster will surface this edge more often. |

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
| Re-brief DDL schema cache invalidation | Issue #35 shipped. |
| Re-brief schema failure transcript warning | Issue #39 shipped. |
| Re-brief row-cap notice | Issue #43 shipped. |
| Re-brief large-DB schema partial notice | Issue #47 shipped. |
| Re-brief transcript cluster (#2, #8, #14, #21) | Shipped. |
| Streaming “session health” dashboard | Settings/session polish outside job gate. |

---

## Handoff to Product Planner

**When:** Next Product Planner webhook run.

**Actions:**
1. Score opportunities 1–5 with the 0–2 rubric (max 10) and anti-slop gates from `product-workflow.md`.
2. Skip re-scoring shipped #35, #39, #43, #47 and transcript cluster #2, #8, #14, #21.
3. Opportunity 1 was deferred at 5/10 on 2026-05-26 — re-score first; trust-cluster completion may raise Terminal UX / Schema-AI scores.
4. Opportunities 2–3 may bundle with 1 if a single PR extending `SessionErrorMapper` + transcript mapping passes scope gate; otherwise sequence separately.
5. Opportunity 4 is a settings→session wiring change — confirm single-PR scope (refresh executor/policy on resume or settings save callback).
6. Do not add `planned` label from this scan.

**Suggested sequencing if multiple pass gates:** (1) NL LLM error mapping → (3) safety-block copy (may share mapper) → (2) query timeout copy → (5) max tool rounds message → (4) live settings refresh (safety-critical, may warrant higher score).

**Inputs:** This file, `business-model.md`, `decisions.md`, prior scan [2026-05-26-business-scan.md](./2026-05-26-business-scan.md), digest [2026-05-26-daily-digest.md](./2026-05-26-daily-digest.md), `qa-smoke.md`.
