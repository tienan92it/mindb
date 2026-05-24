# Business scan — 2026-05-23

## Context

**Product:** mindb — mobile PostgreSQL client with natural-language queries over live schema context.

**Jobs in scope:** faster time-to-first-query, trustworthy AI answers, terminal clarity (core loop: connect → schema → ask → execute → transcript).

**Signals today:**
- Business model success bar: first successful query from install in under 3 minutes; schema fetch reliability; zero credential leaks.
- Open `explore` issue: [#2 [explore] Fix Anthropic multi-round tool-use encoding](https://github.com/tienan92it/mindb/issues/2) — already `planned` + `tech-reviewed`; implementation in flight.
- 2026-05-22 Product Planner digest deferred agent table rendering and DDL schema invalidation (score 6 each) behind Anthropic encoding (score 7, ship).
- Codebase review: no first-run onboarding; NL agent path still omits tabular `ResultLine`; schema cache never invalidated after DDL; executed SQL and truncation not surfaced in transcript.

**Pipeline note:** Do not re-brief Anthropic tool-use encoding today — score and plan only net-new opportunities below.

---

## Opportunities

| # | Theme | Job statement | Success metric | Why now |
|---|--------|---------------|----------------|---------|
| 1 | Time-to-first-query | A new installer can connect to Postgres and run a first natural-language question without leaving the app for setup steps. | Median cold-install → first successful NL query under 3 minutes in a scripted QA path (connection + API key + one prompt). | Empty connections screen and API key only in Settings block the business-model time metric; failures surface late at session connect. |
| 2 | Trustworthy AI answers | After the agent changes database structure, the next plain-language question reflects the current tables and columns. | Post-DDL prompt (“what columns does X have?”) matches live schema without app restart in QA smoke. | Stale schema context causes wrong SQL and erodes trust; 2026-05-22 digest deferred this behind provider fixes — DDL drift remains a daily failure mode. |
| 3 | Terminal clarity | Natural-language asks show query results in the same readable table form as direct `sql:` commands. | 100% of agent-driven `SELECT` outcomes in QA show a table block in the transcript, not only a system/tool dump line. | Execute → transcript gap persists for NL path; users cannot verify DB output the way direct SQL already allows. |
| 4 | Trustworthy AI answers | Before accepting an answer, the user can see which SQL the agent executed. | Every agent `execute_sql` step in QA shows the statement in the transcript prior to any result block. | Tool lines show name only today; trust requires parity with “what ran” before “what returned.” |
| 5 | Terminal clarity | When row limits cap what is shown, the user sees that results are partial and how many rows were returned. | Truncated result sets display an explicit notice (rows shown vs applied cap) in 100% of capped QA runs. | Safety policy applies limits invisibly; partial data looks complete and undermines answer trust. |

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
| Persisted full agent transcript (tools + tables) across sessions | Sync/persistence expansion; text-only history is current scope. |
| Kimi China endpoint (`api.moonshot.cn`) exposure | Regional endpoint choice, not core-path job gate. |

---

## Handoff to Product Planner

**When:** 09:30 ICT (Product Planner automation).

**Actions:**
1. Score opportunities 1–5 with the 0–2 rubric (max 10) and anti-slop gates from `product-workflow.md`.
2. Skip re-scoring Anthropic multi-round tool-use — issue #2 already `planned` + `tech-reviewed`.
3. Produce explore brief from `TEMPLATE.md` only for items ≥ 7/10; add `planned` label on qualifying GitHub issues.
4. Prefer sequencing: (1) onboarding if it passes gates while Anthropic ships; (3)+(4) transcript trust cluster; (2) schema freshness; (5) truncation notice — may bundle with (3) if same PR scope allows.

**Inputs:** This file, `business-model.md`, `decisions.md`, open `explore` issues, yesterday’s `2026-05-22-daily-digest.md`.
