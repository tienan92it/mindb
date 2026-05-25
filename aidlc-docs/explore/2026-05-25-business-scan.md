# Business scan — 2026-05-25

## Context

**Product:** mindb — mobile PostgreSQL client with natural-language queries over live schema context.

**Jobs in scope:** faster time-to-first-query, trustworthy AI answers, terminal clarity (core loop: connect → schema → ask → execute → transcript).

**Signals today:**
- Business model success bar: first successful query from install in under 3 minutes; schema fetch reliability; zero credential leaks.
- **Shipped (transcript trust cluster):** [#2 Anthropic multi-round tool-use](https://github.com/tienan92it/mindb/issues/2), [#8 time-to-first-query onboarding](https://github.com/tienan92it/mindb/issues/8), [#14 agent `execute_sql` → transcript tables](https://github.com/tienan92it/mindb/issues/14), [#21 show executed SQL in agent transcript](https://github.com/tienan92it/mindb/issues/21) (merged 2026-05-25).
- QA smoke item 4 now expects executed SQL above result tables; master implements `transcriptLinesForAgentToolResult` with statement + `ResultLine`.
- **Planner pass (09:30 ICT):** [#30 daily digest — no ship candidates](https://github.com/tienan92it/mindb/issues/30); top net-new scores 6/10 (DDL cache, schema failure warning, row-cap notice) — brief PR [#29](https://github.com/tienan92it/mindb/pull/29).
- Open `explore` issues: [#27 business scan 2026-05-25](https://github.com/tienan92it/mindb/issues/27), [#30 daily digest](https://github.com/tienan92it/mindb/issues/30), duplicate `[business] Daily scan 2026-05-24` trackers (#12, #19, #23, #25).
- **Remaining gaps (code review):** `SchemaService.clearCache()` unused after DDL; row caps via `injectLimit` with no transcript footer; schema fetch failures only in model prompt (`Schema unavailable: …`); compact schema index truncation silent in UI on large DBs; NL `submitPrompt` / direct SQL `catch` still append `ErrorLine(e.toString())` while connect uses `SessionErrorMapper`.

**Pipeline note:** Do not re-brief shipped #2, #8, #14, #21. Do not re-brief opportunities already covered in PR #29 briefs (DDL cache, schema failure warning, row-cap notice). Score and plan only net-new opportunities below.

---

## Opportunities

| # | Theme | Job statement | Success metric | Why now |
|---|--------|---------------|----------------|---------|
| 1 | Trustworthy AI answers | After the agent or user changes database structure, the next plain-language question reflects current tables and columns. | Post-DDL prompt (“what columns does X have?”) matches live schema without app restart in QA smoke. | Executed SQL and result tables now ship in transcript; stale in-memory schema is the dominant remaining schema→ask accuracy gap. |
| 2 | Terminal clarity · Trustworthy AI answers | When row limits cap what is shown, the user knows results are partial and how many rows were returned. | Truncated or LIMIT-injected result sets display an explicit notice (rows shown vs configured cap) in 100% of capped QA runs. | Users can audit SQL and tables, but silent `maxRows` / `injectLimit` caps still make partial answers look complete. |
| 3 | Trustworthy AI answers · Time-to-first-query | When schema introspection fails, the user sees that the session lacks reliable schema context before relying on an NL answer. | QA scenario with blocked `information_schema` access shows a visible transcript warning; user is not left with a confident answer built on hidden degraded schema text. | Onboarding shortened cold start; hidden schema failure still wastes retries on first session. |
| 4 | Trustworthy AI answers · Time-to-first-query | When an LLM or API call fails during a natural-language ask, the user gets actionable recovery guidance in the transcript. | QA with empty or invalid provider key shows mapped copy and a Settings recovery path — not a raw exception string — in 100% of NL failure runs. | Connect path uses `SessionErrorMapper`; NL/agent catch paths still surface `e.toString()`, undermining trust after setup friction is gone. |
| 5 | Trustworthy AI answers · Terminal clarity | On a large database, the user knows when the session’s schema context is partial (table index truncated) before trusting a broad natural-language answer. | QA on a DB with more tables than the system index cap shows a visible transcript or session notice; follow-up `get_schema` for a named table succeeds without restart. | Kimi 4MB and compact schema index shipped; truncation is model-side only while NL answers can omit unseen tables. |

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
| Re-brief time-to-first-query onboarding | Issue #8 shipped. |
| Re-brief agent result tables | Issue #14 shipped. |
| Re-brief Anthropic multi-round tool-use | Issue #2 shipped. |
| Re-brief executed SQL in agent transcript | Issue #21 shipped. |
| Read-only session header indicator | Settings-only policy; scored 5 in #30 — defer behind schema/truncation trust cluster. |
| Re-implement Kimi 4MB / context budget plumbing | Shipped on master; user-facing gap is notice/trust, not transport. |

---

## Handoff to Product Planner

**When:** Next 09:30 ICT run (or manual re-score if build capacity opens).

**Actions:**
1. Score opportunities 1–5 with the 0–2 rubric (max 10) and anti-slop gates from `product-workflow.md`.
2. Skip re-scoring shipped issues #2, #8, #14, #21.
3. Skip re-briefing DDL cache, schema failure warning, and row-cap notice if PR #29 briefs remain current.
4. Produce explore brief from `TEMPLATE.md` only for items ≥ 7/10; add `planned` label on qualifying GitHub issues (do not add `planned` from this scan).
5. **2026-05-25 planner note:** Opportunities 1–3 scored 6 in [#30](https://github.com/tienan92it/mindb/issues/30); no ≥7 candidates yet. Opportunity 5 (schema partial notice) was deferred at 6 on 2026-05-24 — re-score after #21 ship.
6. Suggested sequencing if multiple pass gates: (1) DDL cache invalidation; (3) schema failure visibility; (2) row-cap notice; (5) large-DB schema partial notice; (4) NL LLM error mapping.

**Inputs:** This file, `business-model.md`, `decisions.md`, open `explore` issues, `2026-05-24-business-scan.md`, `2026-05-25-daily-digest.md` (PR #29), shipped feature PR [#28](https://github.com/tienan92it/mindb/pull/28).
