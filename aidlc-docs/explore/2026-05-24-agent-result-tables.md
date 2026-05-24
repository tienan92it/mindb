# Render agent execute_sql results as transcript tables

## Job

Natural-language asks show query results in the same readable table form as direct `sql:` commands so users can verify database output.

## Success metric

100% of agent-driven `SELECT` outcomes in QA smoke show a table block in the transcript, not only a YAML-like `SystemLine` tool dump.

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
| **Total** | **8** |

## Anti-slop check

- [x] Job gate — Improves trust in NL answers (core JTBD).
- [x] Core path — Closes execute → transcript gap vs direct SQL.
- [x] Single-PR scope — Orchestrator events + session transcript only.

## Decision

**Ship** — Score 8; Anthropic multi-round tool-use (#2) shipped 2026-05-23; execute → transcript is now the highest-impact trust gap on the ask path.

## Notes

- Business scan opportunity #1: [2026-05-24-business-scan.md](./2026-05-24-business-scan.md) (PR [#11](https://github.com/tienan92it/mindb/pull/11)).
- Agent path appends `SystemLine(result)` only; direct `sql:` already uses `ResultLine` in `session_providers.dart`.
- Pairs with executed-SQL visibility brief; row-cap notice may bundle if single-PR scope allows.
