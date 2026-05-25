# Business scan — 2026-05-25

## Context

**Product:** mindb — mobile PostgreSQL client with natural-language queries over live schema context.

**Jobs in scope:** faster time-to-first-query, trustworthy AI answers, terminal clarity (core loop: connect → schema → ask → execute → transcript).

**Signals today:**
- Business model success bar: first successful query from install in under 3 minutes; schema fetch reliability; zero credential leaks.
- **Shipped since 2026-05-24 scan:** [#8 time-to-first-query onboarding](https://github.com/tienan92it/mindb/issues/8), [#14 agent `execute_sql` → transcript tables](https://github.com/tienan92it/mindb/issues/14), [#2 Anthropic multi-round tool-use](https://github.com/tienan92it/mindb/issues/2), [#21 show executed SQL in agent transcript](https://github.com/tienan92it/mindb/issues/21) (merged 2026-05-25).
- **Product Planner pass (same day):** [#30 daily digest — no ship candidates](https://github.com/tienan92it/mindb/issues/30); top net-new scores 6/10 (DDL cache, schema failure warning, row-cap notice) — brief PR [#29](https://github.com/tienan92it/mindb/pull/29).
- Open `explore` issues: duplicate `[business] Daily scan 2026-05-24` trackers (#12, #19, #23, #25), [#24 daily digest](https://github.com/tienan92it/mindb/issues/24), [#27 business scan 2026-05-25](https://github.com/tienan92it/mindb/issues/27).
- Code review: transcript trust cluster largely closed (tables + executed SQL shipped); `SchemaService.clearCache()` still unused after DDL; `SafetyPolicy.injectLimit` caps rows without transcript notice; schema fetch failures only in model system prompt (`Schema unavailable: …`); connect system lines omit read-only mode; NL/agent catch paths still use raw `e.toString()` in `ErrorLine`.

**Pipeline note:** Do not re-brief shipped #2, #8, #14, #21. Do not re-score opportunities already briefed in PR #29 unless signals change. Score and plan only net-new opportunities below.

---

## Opportunities

| # | Theme | Job statement | Success metric | Why now |
|---|--------|---------------|----------------|---------|
| 1 | Trustworthy AI answers | After the agent or user changes database structure, the next plain-language question reflects current tables and columns. | Post-DDL prompt (“what columns does X have?”) matches live schema without app restart in QA smoke. | NL path now shows tables and executed SQL; stale in-memory schema is the dominant remaining cause of wrong follow-up SQL. |
| 2 | Terminal clarity · Trustworthy AI answers | When row limits cap what is shown, the user knows results are partial and how many rows were returned. | Truncated or LIMIT-injected result sets display an explicit notice (rows shown vs configured cap) in 100% of capped QA runs. | Agent `ResultLine` tables render, but silent `injectLimit` caps still make partial data look complete. |
| 3 | Trustworthy AI answers · Time-to-first-query | When schema introspection fails, the user sees that the session lacks reliable schema context before relying on an NL answer. | QA scenario with blocked `information_schema` access shows a visible transcript warning; user is not left with a confident answer built on hidden degraded schema text. | Onboarding shortened cold start; hidden schema failure still wastes retries on first session. |
| 4 | Trustworthy AI answers · Time-to-first-query | When an LLM or API call fails, the user gets a short, actionable error in the transcript instead of a raw provider dump. | QA smoke item 4 with invalid/revoked API key shows mapped copy (e.g. key missing, rate limit, auth) in under 160 characters; no stack trace or JSON blob in the transcript. | Transcript audit trail for NL is in place; opaque provider failures are the next trust cliff after connect + prompt. |
| 5 | Terminal clarity · Trustworthy AI answers | While read-only mode is on, the user can see that write/destructive SQL is blocked before sending a prompt. | With read-only enabled in Settings, session header or connect system line includes a persistent read-only indicator; QA confirms blocked writes are expected, not surprising errors. | Read-only lives only in Settings; blocked writes surface as late `ErrorLine`s and read as bugs rather than policy. |

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

---

## Handoff to Product Planner

**When:** Next 09:30 ICT run (or manual re-score if build capacity opens).

**Actions:**
1. Score opportunities 1–5 with the 0–2 rubric (max 10) and anti-slop gates from `product-workflow.md`.
2. Skip re-scoring shipped issues #2, #8, #14, #21.
3. Produce explore brief from `TEMPLATE.md` only for items ≥ 7/10; add `planned` label on qualifying GitHub issues (do not add `planned` from this scan).
4. **2026-05-25 planner note:** Opportunities 1–3 scored 6 in [#30](https://github.com/tienan92it/mindb/issues/30); no new ≥7 candidates. Revisit after next ship if transcript/schema gaps shrink further.
5. Suggested sequencing if multiple pass gates: (1) DDL cache invalidation; (3) schema failure visibility; (2) row-cap notice; (4) LLM error mapping; (5) read-only session indicator.

**Inputs:** This file, `business-model.md`, `decisions.md`, open `explore` issues, `2026-05-24-business-scan.md`, `2026-05-25-daily-digest.md` (PR #29).
