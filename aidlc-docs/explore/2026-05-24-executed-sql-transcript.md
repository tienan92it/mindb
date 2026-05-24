# Show executed SQL in agent transcript

## Job

Before accepting a natural-language answer, the user can see which SQL the agent ran so they can audit results against intent.

## Success metric

Every agent `execute_sql` step in QA smoke shows the statement in the transcript before any result block or assistant reply.

## Scope

**In:** Emit a transcript line with the SQL text (or formatted statement) when the orchestrator completes `execute_sql`; keep existing tool-name system lines optional or replace with statement-first copy.

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

**Defer** — Score 7; ship agent result tables first (#1); bundle with table parity or follow immediately after in transcript-trust sequence.

## Notes

- Business scan opportunity #3: [2026-05-24-business-scan.md](./2026-05-24-business-scan.md) (PR [#11](https://github.com/tienan92it/mindb/pull/11)).
- Today NL path shows `tool → execute_sql` only; no statement body in transcript.
