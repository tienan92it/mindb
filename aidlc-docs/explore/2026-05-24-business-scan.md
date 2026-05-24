# Business scan — 2026-05-24 (refresh)

## Context

**Product:** mindb — mobile PostgreSQL client with natural-language queries over live schema context.

**Jobs in scope:** faster time-to-first-query, trustworthy AI answers, terminal clarity (core loop: connect → schema → ask → execute → transcript).

**Signals today:**
- Business model success bar: first successful query from install in under 3 minutes; schema fetch reliability; zero credential leaks.
- Open `explore` issues: [#6 [business] Daily scan 2026-05-23](https://github.com/tienan92it/mindb/issues/6), [#8 [explore] Time-to-first-query onboarding](https://github.com/tienan92it/mindb/issues/8) (`tech-reviewed`, `in-review` — feature PR merged, awaiting Deliver), [#12 [business] Daily scan 2026-05-24](https://github.com/tienan92it/mindb/issues/12).
- **Shipped since morning scan:** [#14 Render agent execute_sql results as transcript tables](https://github.com/tienan92it/mindb/issues/14) — NL `SELECT` now maps to `ResultLine` / `TableResultBlock` on master; [#15 Time-to-first-query onboarding](https://github.com/tienan92it/mindb/pull/15) merged (checklist on connections home).
- **Still open on ask path:** `SystemLine('tool → execute_sql')` without statement body; `SchemaService.clearCache()` unused after DDL; `TableResultBlock` shows capped rows with no partial-data notice; schema introspection failures only in model prompt (`Schema unavailable: …`); NL `catch` surfaces raw `e.toString()` while connect uses `SessionErrorMapper`.
- Product Planner briefs exist for transcript-trust cluster and DDL invalidation (`2026-05-24-agent-result-tables.md` shipped; `executed-sql-transcript`, `schema-cache-ddl-invalidation` deferred).

**Pipeline note:** Do not re-brief agent result tables (#14 shipped), onboarding (#15 merged), or Anthropic tool-use (#2 shipped). Score and plan only net-new opportunities below.

---

## Opportunities

| # | Theme | Job statement | Success metric | Why now |
|---|--------|---------------|----------------|---------|
| 1 | Trustworthy AI answers | Before accepting a natural-language answer, the user can see which SQL the agent executed. | Every agent `execute_sql` step in QA smoke shows the statement in the transcript before any result table or assistant reply. | Agent tables (#14) shipped; users can verify *what returned* but not *what ran* — `tool → execute_sql` lines still omit the statement. |
| 2 | Trustworthy AI answers | After the agent or user changes database structure, the next plain-language question reflects current tables and columns. | Post-DDL prompt (“what columns does X have?”) matches live schema without app restart in QA smoke. | Stale in-memory schema cache still drives wrong SQL; DDL drift remains the top schema→ask accuracy gap after provider and table parity fixes. |
| 3 | Terminal clarity · Trustworthy AI answers | When row limits cap what is shown, the user knows results are partial and how many rows were returned. | Truncated or LIMIT-injected result sets display an explicit notice (rows shown vs configured cap) in 100% of capped QA runs. | `SafetyPolicy.injectLimit` and settings `maxRows` cap rows silently; `TableResultBlock` renders the limited set with no footer — partial tables look complete. |
| 4 | Trustworthy AI answers · Time-to-first-query | When schema introspection fails, the user sees that the session lacks reliable schema context before relying on an NL answer. | QA scenario with blocked `information_schema` access shows a visible transcript warning; user is not left with a confident answer built on hidden “Schema unavailable” system text. | Orchestrator degrades schema in the model prompt only; failures surface late as wrong SQL, wasting cold-start and retry time even with onboarding shipped. |
| 5 | Trustworthy AI answers · Terminal clarity | When an LLM call fails during a natural-language ask (missing/invalid API key, auth, rate limit), the user gets actionable recovery guidance in the transcript. | QA with empty or invalid provider key shows mapped copy and a Settings recovery path — not a raw exception string — in 100% of NL failure runs. | Connect-time errors already use `SessionErrorMapper`; `submitPrompt` `catch` still appends `ErrorLine(e.toString())`, undermining trust after first-query onboarding lowers setup friction. |

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
| Re-brief Anthropic multi-round tool-use | Issue #2 shipped. |
| Remove `tool →` lines without adding SQL visibility | UX-only dedupe; does not meet job gate without executed-SQL audit. |

---

## Handoff to Product Planner

**When:** Next Product Planner run (09:30 ICT).

**Actions:**
1. Score opportunities 1–5 with the 0–2 rubric (max 10) and anti-slop gates from `product-workflow.md`.
2. Skip re-scoring shipped #14, merged onboarding (#15 / #8), and shipped Anthropic tool-use (#2).
3. Produce explore brief from `TEMPLATE.md` only for items ≥ 7/10; add `planned` label on qualifying GitHub issues (do not add `planned` from this scan).
4. Suggested sequencing if multiple pass gates: (1) executed SQL — pairs with shipped tables; (3) row-cap notice — may bundle with (1) if single-PR scope allows; (2) DDL cache invalidation; (4) schema failure visibility; (5) NL LLM error mapping — may share `SessionErrorMapper` pattern.

**Inputs:** This file, `business-model.md`, `decisions.md`, open `explore` issues, `2026-05-24-agent-result-tables.md`, `2026-05-24-executed-sql-transcript.md`, `2026-05-24-schema-cache-ddl-invalidation.md`, morning scan PR #11.
