# Render agent execute_sql results as transcript tables

## Job

Natural-language asks show query results in the same readable table form as direct `sql:` commands so users can verify database output.

## Success metric

100% of agent-driven `SELECT` outcomes in QA show a table block in the transcript, not only a system/tool dump line.

## Scope

**In:** Propagate `QueryResult` from tool execution through orchestrator events; map `execute_sql` success to `ResultLine` / `TableResultBlock` in session transcript wiring (parity with direct `sql:` path).

**Out:** Persisting tables in session history, charting, export, streaming assistant tokens.

## Core path impact

execute | transcript

## Score (0–2 each, max 10)

| Area | Score |
|------|-------|
| Connection reliability | 0 |
| Schema / AI accuracy | 2 |
| Terminal UX | 2 |
| Safety | 0 |
| Settings ergonomics | 0 |
| **Total** | **6** |

## Anti-slop check

- [x] Job gate — Improves trust in NL answers (core JTBD).
- [x] Core path — Closes execute → transcript gap vs direct SQL.
- [x] Single-PR scope — Orchestrator events + session transcript only.

## Decision

**Defer** — Score 6; ship after or alongside Anthropic tool-use fix (#2); pairs with “show executed SQL” and truncation notice in a transcript-trust sequence.

## Notes

- Carried from 2026-05-22 digest; codebase gap unchanged per business scan.
- Business scan opportunity #3.
