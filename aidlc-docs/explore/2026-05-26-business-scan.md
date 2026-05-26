# Business scan — 2026-05-26

## Context

**Product:** mindb — mobile PostgreSQL client with natural-language queries over live schema context.

**Jobs in scope:** faster time-to-first-query, trustworthy AI answers, terminal clarity (core loop: connect → schema → ask → execute → transcript).

**Signals today:**
- Business model success bar: first successful query from install in under 3 minutes; schema fetch reliability; zero credential leaks.
- **Transcript trust cluster shipped:** [#2 Anthropic multi-round tool-use](https://github.com/tienan92it/mindb/issues/2), [#8 time-to-first-query onboarding](https://github.com/tienan92it/mindb/issues/8), [#14 agent result tables](https://github.com/tienan92it/mindb/issues/14), [#21 executed SQL in transcript](https://github.com/tienan92it/mindb/issues/21) (merged 2026-05-25 via [#28](https://github.com/tienan92it/mindb/pull/28)). Users can audit tool SQL and tabular results; remaining trust gaps are schema freshness, silent caps, and error/schema signals.
- **Planner / digest:** [#30 Daily digest — no ship candidates](https://github.com/tienan92it/mindb/issues/30) (2026-05-25); open brief refresh PR [#29](https://github.com/tienan92it/mindb/pull/29) defers DDL cache, schema-failure warning, and row-cap notice at score 6 each. No `planned` items in flight after #21 closed.
- Open `explore` issues: duplicate `[business] Daily scan` trackers (#6, #12, #19, #23, #25, #27); prior scan PR [#26](https://github.com/tienan92it/mindb/pull/26) (2026-05-25) still open.
- **Gaps still unaddressed (code review):** `SchemaService.clearCache()` unused after DDL; `TableResultBlock` has no row-cap footer; schema fetch failures only in model prompt (`Schema unavailable: …`); compact schema index truncation silent on large DBs; NL `submitPrompt` / `executeSqlDirect` `catch` still append `ErrorLine(e.toString())` while connect uses `SessionErrorMapper`.
- **Cadence:** Product automations moved to webhook ~4×/day (`decisions.md` 2026-05-26) — Planner can pick up this scan on next run without waiting for a single daily cron.

**Pipeline note:** Do not re-brief shipped #2, #8, #14, #21. Do not re-brief opportunities already covered in PR #29 briefs unless re-scored net-new. Score and plan only opportunities below.

---

## Opportunities

| # | Theme | Job statement | Success metric | Why now |
|---|--------|---------------|----------------|---------|
| 1 | Trustworthy AI answers | After the agent or user changes database structure, the next plain-language question reflects current tables and columns. | Post-DDL prompt (“what columns does X have?”) matches live schema without app restart in QA smoke. | Transcript can show what ran and what returned, but stale in-memory schema still drives wrong SQL — the dominant schema→ask accuracy gap once the trust cluster is shipped. |
| 2 | Terminal clarity · Trustworthy AI answers | When row limits cap what is shown, the user knows results are partial and how many rows were returned. | Truncated or LIMIT-injected result sets display an explicit notice (rows shown vs configured cap) in 100% of capped QA runs. | Executed SQL and tables are visible; silent `maxRows` / `injectLimit` caps still make partial answers look complete when users audit results. |
| 3 | Trustworthy AI answers · Time-to-first-query | When schema introspection fails, the user sees that the session lacks reliable schema context before relying on an NL answer. | QA with blocked `information_schema` access shows a visible transcript warning; user is not left with a confident answer built on hidden degraded schema text. | Onboarding shortened cold start; hidden schema failure still wastes retries on the first session and undermines the under-3-minute success bar. |
| 4 | Trustworthy AI answers · Time-to-first-query | When an LLM or API call fails during a natural-language ask, the user gets actionable recovery guidance in the transcript. | QA with empty or invalid provider key shows mapped copy and a Settings recovery path — not a raw exception string — in 100% of NL failure runs. | Connect path uses `SessionErrorMapper`; NL/agent paths still surface `e.toString()`, so post-setup failures erode trust after onboarding is no longer the bottleneck. |
| 5 | Trustworthy AI answers · Terminal clarity | On a large database, the user knows when the session’s schema context is partial (table index truncated) before trusting a broad natural-language answer. | QA on a DB with more tables than the system index cap shows a visible transcript or session notice; follow-up `get_schema` for a named table succeeds without restart. | Kimi 4MB and compact schema index are on master; truncation is model-side only while NL answers can omit unseen tables — the last major silent trust gap after executed SQL shipped. |

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
| Re-brief executed SQL in agent transcript | Issue #21 shipped. |
| Re-brief Anthropic multi-round tool-use | Issue #2 shipped. |
| Re-implement Kimi 4MB / context budget plumbing | Shipped on master; user-facing gap is notice/trust, not transport. |
| Read-only session header / connection health indicator | Settings-only polish; scored 5 in #30 — defer behind schema/truncation trust cluster. |

---

## Handoff to Product Planner

**When:** Next Product Planner webhook run (~4×/day).

**Actions:**
1. Score opportunities 1–5 with the 0–2 rubric (max 10) and anti-slop gates from `product-workflow.md`.
2. Skip re-scoring shipped #2, #8, #14, #21.
3. If PR [#29](https://github.com/tienan92it/mindb/pull/29) briefs remain current for items 1–3, update scores only; produce new explore brief from `TEMPLATE.md` only for items ≥ 7/10 not already briefed.
4. Do not add `planned` label from this scan.
5. **2026-05-26 note:** With no in-flight `planned` builds, re-evaluate whether any deferred-6 item crosses 7 after transcript cluster completion. Suggested sequencing if multiple pass: (1) DDL cache invalidation; (3) schema failure visibility; (2) row-cap notice; (5) large-DB schema partial notice; (4) NL LLM error mapping.

**Inputs:** This file, `business-model.md`, `decisions.md`, open `explore` issues, [#30 digest](https://github.com/tienan92it/mindb/issues/30), PR [#29](https://github.com/tienan92it/mindb/pull/29), prior scans `2026-05-24-business-scan.md` / `2026-05-25-business-scan.md` (remote PR [#26](https://github.com/tienan92it/mindb/pull/26)).
