# Safety-block transcript copy (read-only & cancelled SQL)

## Job

When read-only mode or the safety gate blocks SQL, the transcript explains why the query did not run and what to change — not a raw `StateError` string.

## Success metric

QA with read-only on: `sql: INSERT INTO …` shows a clear blocked message; toggling read-only off in Settings then retrying succeeds without guessing. Cancelled confirmation shows an explicit cancelled line.

## Scope

**In:** Extend `SessionErrorMapper` with execute-path mapping for read-only block, user-cancelled confirmation, and related `StateError` cases from `QueryExecutor`; add `transcriptErrorLineForExecuteFailure` and wire `executeSqlDirect` and the `sql:` branch in `submitPrompt` (not NL/agent paths already mapped).

**Out:** Query timeout copy, live settings refresh, max tool rounds message (separate briefs); new safety rules or confirmation UI changes.

## Core path impact

**execute** → **transcript** (settings read-only mode informs policy at connect)

## Score (0–2 each, max 10)

| Area | Score |
|------|-------|
| Connection reliability | 0 |
| Schema / AI accuracy | 1 |
| Terminal UX | 2 |
| Safety | 2 |
| Settings ergonomics | 1 |
| **Total** | **7** |

## Anti-slop check

- [x] Job gate — Improves trust when auditing blocked writes; completes execute-path parity after NL error mapping (#53) shipped.
- [x] Core path — `QueryExecutor` throws → transcript `ErrorLine` on direct `sql:` and agent `execute_sql` results.
- [x] Single-PR scope — Mapper extension + execute call-site wiring; no policy or settings-store changes.

## Decision

**Ship** — Score 7; `executeSqlDirect` still uses `ErrorLine(e.toString())` while NL path uses `transcriptErrorLineForNlFailure`; read-only/cancelled strings are the highest-safety execute gaps per scan sequencing.

## Notes

- Business scan: [2026-05-27-business-scan.md](./2026-05-27-business-scan.md) (PR [#50](https://github.com/tienan92it/mindb/pull/50), tracker [#51](https://github.com/tienan92it/mindb/issues/51)).
- Prior ship from same scan: [#53 NL LLM error mapping](https://github.com/tienan92it/mindb/issues/53) (PR [#55](https://github.com/tienan92it/mindb/pull/55)).
- Sequence after this: query timeout copy → max tool rounds → live settings refresh.
