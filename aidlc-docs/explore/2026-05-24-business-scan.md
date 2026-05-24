# Business scan — 2026-05-24

## Context

**Product:** mindb — mobile PostgreSQL client with natural-language queries over live schema context.

**Jobs in scope:** faster time-to-first-query, trustworthy AI answers, terminal clarity (core loop: connect → schema → ask → execute → transcript).

**Signals today:**
- Business model success bar: first successful query from install in under 3 minutes; schema fetch reliability; zero credential leaks.
- Open `explore` issues: [#6 [business] Daily scan 2026-05-23](https://github.com/tienan92it/mindb/issues/6), [#8 [explore] Time-to-first-query onboarding](https://github.com/tienan92it/mindb/issues/8) (`planned`, `tech-reviewed` — implementation pipeline).
- [#2 Anthropic multi-round tool-use encoding](https://github.com/tienan92it/mindb/issues/2) **shipped** (merged 2026-05-23); multi-step agent runs unblocked for Anthropic users.
- 2026-05-23 scan identified transcript trust cluster (tables, executed SQL, truncation) and DDL schema freshness; code review confirms gaps unchanged: NL path still emits `SystemLine` tool dumps only; `SchemaService.clearCache()` never called from production; row caps applied via `injectLimit` without UI notice.
- QA smoke items 4–5 still differentiate direct `sql:` (tabular) vs natural-language (text-only tool output).

**Pipeline note:** Do not re-brief time-to-first-query onboarding (#8) or Anthropic tool-use (#2 shipped). Score and plan only net-new opportunities below.

---

## Opportunities

| # | Theme | Job statement | Success metric | Why now |
|---|--------|---------------|----------------|---------|
| 1 | Trustworthy AI answers · Terminal clarity | After a natural-language ask that runs `SELECT`, the user sees the same tabular result block as for direct `sql:` commands. | 100% of agent-driven `SELECT` outcomes in QA smoke show a table block in the transcript, not only a YAML-like `SystemLine` tool dump. | Anthropic multi-round encoding shipped; execute → transcript is now the highest-impact trust gap on the ask path. |
| 2 | Trustworthy AI answers | After the agent or user changes database structure, the next plain-language question reflects current tables and columns. | Post-DDL prompt (“what columns does X have?”) matches live schema without app restart in QA smoke. | Stale in-memory schema cache still drives wrong SQL; DDL + follow-up is reliable now that provider tool loops work end-to-end. |
| 3 | Trustworthy AI answers · Terminal clarity | Before accepting an answer, the user can see which SQL the agent executed. | Every agent `execute_sql` step in QA shows the statement in the transcript before any result or assistant reply. | Tool lines show `tool → execute_sql` only; users cannot audit “what ran” on the NL path despite direct SQL already exposing statements. |
| 4 | Terminal clarity · Trustworthy AI answers | When row limits cap what is shown, the user knows results are partial and how many rows were returned. | Truncated or LIMIT-injected result sets display an explicit notice (rows shown vs configured cap) in 100% of capped QA runs. | `SafetyPolicy.injectLimit` and settings `maxRows` apply silently; partial tables look complete and undermine answer trust. |
| 5 | Trustworthy AI answers · Time-to-first-query | When schema introspection fails, the user sees that the session lacks reliable schema context before relying on an NL answer. | QA scenario with blocked `information_schema` access shows a visible transcript warning; user is not left with a confident answer built on hidden “Schema unavailable” system text. | Orchestrator continues with degraded schema in the model prompt only; failures surface late as wrong SQL, wasting cold-start and retry time. |

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
| Re-brief time-to-first-query onboarding | Issue #8 already `planned` + `tech-reviewed`. |
| Re-brief Anthropic multi-round tool-use | Issue #2 shipped. |

---

## Handoff to Product Planner

**When:** 09:30 ICT (Product Planner automation).

**Actions:**
1. Score opportunities 1–5 with the 0–2 rubric (max 10) and anti-slop gates from `product-workflow.md`.
2. Skip re-scoring [#8 time-to-first-query onboarding](https://github.com/tienan92it/mindb/issues/8) and shipped Anthropic tool-use (#2).
3. Produce explore brief from `TEMPLATE.md` only for items ≥ 7/10; add `planned` label on qualifying GitHub issues (do not add `planned` from this scan).
4. Suggested sequencing if multiple pass gates: (1) agent tables — unblocks NL verification; (3) executed SQL — pairs with (1); (2) DDL cache invalidation; (4) row-cap notice — may bundle with (1) if single-PR scope allows; (5) schema failure visibility.

**Inputs:** This file, `business-model.md`, `decisions.md`, open `explore` issues, `2026-05-22-daily-digest.md`, `2026-05-23-business-scan.md` (PR #5).
