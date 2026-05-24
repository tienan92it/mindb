# Show executed SQL in agent transcript

## Job

Before accepting a natural-language answer, the user can see which SQL the agent ran so they can audit results against intent.

## Success metric

Every agent `execute_sql` step in QA smoke shows the statement in the transcript before any result table or assistant reply.

## Scope

**In:** Emit a transcript line with the SQL text when the orchestrator completes `execute_sql` (from tool args or executor); place before `transcriptLineForAgentToolResult` output; keep or replace `tool → execute_sql` with statement-first copy.

**Out:** SQL editor, explain plans, query history persistence, diff vs suggested SQL.

## Core path impact

execute | transcript

## Score (0–2 each, max 10)

| Area | Score |
|------|-------|
| Connection reliability | 0 |
| Schema / AI accuracy | 1 |
| Terminal UX | 2 |
| Safety | 1 |
| Settings ergonomics | 0 |
| **Total** | **7** |

## Anti-slop check

- [x] Job gate — Improves trust in NL answers (audit “what ran”).
- [x] Core path — Strengthens execute → transcript clarity on the ask path.
- [x] Single-PR scope — Transcript line mapping in session/orchestrator wiring only.

## Decision

**Ship** — Score 7; agent result tables (#14) shipped; users can verify *what returned* but not *what ran*.

## Notes

- Business scan opportunity #1 (refresh): [2026-05-24-business-scan.md](./2026-05-24-business-scan.md) (PR [#18](https://github.com/tienan92it/mindb/pull/18)).
- `session_providers.dart` still adds `SystemLine('tool → execute_sql')` without statement body.
- Row-cap notice may bundle if single-PR scope allows.

## Tracking issue

_(filled when ship issue is created)_
