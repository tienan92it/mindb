# Business scan — 2026-05-24

## Context

**Product:** mindb — mobile PostgreSQL client with natural-language queries over live schema context.

**Jobs in scope:** faster time-to-first-query, trustworthy AI answers, terminal clarity (core loop: connect → schema → ask → execute → transcript).

**Signals today:**
- Business model success bar: first successful query from install in under 3 minutes; schema fetch reliability; zero credential leaks.
- Open `explore` issues: [#6 [business] Daily scan 2026-05-23](https://github.com/tienan92it/mindb/issues/6), [#8 [explore] Time-to-first-query onboarding](https://github.com/tienan92it/mindb/issues/8) (feature merged via [#15](https://github.com/tienan92it/mindb/pull/15); Deliver pending), [#21 [explore] Show executed SQL in agent transcript](https://github.com/tienan92it/mindb/issues/21) (`planned`, `tech-reviewed` — tech plan PR [#22](https://github.com/tienan92it/mindb/pull/22) open).
- **Shipped since morning scan (PR #11):** [#14 Agent transcript tables](https://github.com/tienan92it/mindb/issues/14); [#15 Onboarding checklist](https://github.com/tienan92it/mindb/pull/15); Kimi/large-DB context budget on master (compact schema index, filtered `get_schema`, payload trimming) — model-side only, no transcript signal when schema context is partial.
- **Gaps still unaddressed:** `SchemaService.clearCache()` never called after DDL; `TableResultBlock` omits row-cap footer; schema fetch failures hidden in model prompt; NL `submitPrompt` / `executeSqlDirect` `catch` still use `ErrorLine(e.toString())` while connect uses `SessionErrorMapper`.
- Product Planner: executed-SQL brief scored 7 (defer behind tables — tables now shipped); DDL invalidation brief scored 6 (defer).

**Pipeline note:** Do not re-brief agent result tables (#14 shipped), onboarding (#15 merged / #8), executed SQL in transcript (#21 `planned` + `tech-reviewed`), or Anthropic tool-use (#2 shipped). Score and plan only net-new opportunities below.

---

## Opportunities

| # | Theme | Job statement | Success metric | Why now |
|---|--------|---------------|----------------|---------|
| 1 | Trustworthy AI answers · Terminal clarity | On a large database, the user knows when the session’s schema context is partial (table index truncated) before trusting a broad natural-language answer. | QA on a DB with more tables than the system index cap shows a visible transcript or session notice; follow-up `get_schema` for a named table succeeds without restart. | Kimi 4MB and compact schema index shipped today; truncation is silent in the UI while answers can omit unseen tables. |
| 2 | Trustworthy AI answers | After the agent or user changes database structure, the next plain-language question reflects current tables and columns. | Post-DDL prompt (“what columns does X have?”) matches live schema without app restart in QA smoke. | Stale in-memory schema cache still drives wrong SQL; DDL drift is the top schema→ask accuracy gap after table parity and provider fixes. |
| 3 | Terminal clarity · Trustworthy AI answers | When row limits cap what is shown, the user knows results are partial and how many rows were returned. | Truncated or LIMIT-injected result sets display an explicit notice (rows shown vs configured cap) in 100% of capped QA runs. | `SafetyPolicy.injectLimit` and settings `maxRows` cap rows silently; `TableResultBlock` renders the limited set with no footer — partial tables look complete. |
| 4 | Trustworthy AI answers · Time-to-first-query | When schema introspection fails, the user sees that the session lacks reliable schema context before relying on an NL answer. | QA scenario with blocked `information_schema` access shows a visible transcript warning; user is not left with a confident answer built on hidden “Schema unavailable” system text. | Orchestrator degrades schema in the model prompt only; failures surface late as wrong SQL, wasting retry time even with onboarding shipped. |
| 5 | Trustworthy AI answers · Terminal clarity | When an LLM call fails during a natural-language ask (missing/invalid API key, auth, rate limit), the user gets actionable recovery guidance in the transcript. | QA with empty or invalid provider key shows mapped copy and a Settings recovery path — not a raw exception string — in 100% of NL failure runs. | Connect-time errors already use `SessionErrorMapper`; `submitPrompt` and direct-SQL paths still append `ErrorLine(e.toString())`, undermining trust after onboarding lowers setup friction. |

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
| Re-brief agent result tables | Issue #14 shipped 2026-05-24. |
| Re-brief time-to-first-query onboarding | PR #15 merged; issue #8 in Deliver pipeline. |
| Re-brief executed SQL in agent transcript | Issue #21 already `planned` + `tech-reviewed`. |
| Re-brief Anthropic multi-round tool-use | Issue #2 shipped. |
| Re-implement Kimi 4MB / context budget plumbing | Shipped on master; user-facing gap is notice/trust, not transport. |

---

## Handoff to Product Planner

**When:** Next Product Planner run (09:30 ICT).

**Actions:**
1. Score opportunities 1–5 with the 0–2 rubric (max 10) and anti-slop gates from `product-workflow.md`.
2. Skip re-scoring shipped #14, merged onboarding (#15 / #8), in-flight executed SQL (#21), and shipped Anthropic tool-use (#2).
3. Produce explore brief from `TEMPLATE.md` only for items ≥ 7/10; add `planned` label on qualifying GitHub issues (do not add `planned` from this scan).
4. Suggested sequencing if multiple pass gates: let #21 (executed SQL) build first; (3) row-cap notice may bundle with executed SQL if single-PR scope allows; (2) DDL cache invalidation; (1) large-DB schema partial notice; (4) schema failure visibility; (5) NL LLM error mapping — may extend `SessionErrorMapper`.

**Inputs:** This file, `business-model.md`, `decisions.md`, open `explore` issues, `2026-05-24-executed-sql-transcript.md`, `2026-05-24-schema-cache-ddl-invalidation.md`, morning scan PR [#11](https://github.com/tienan92it/mindb/pull/11).
