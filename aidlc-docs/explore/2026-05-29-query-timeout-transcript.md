# Query timeout transcript copy

## Job

When a direct `sql:` or agent `execute_sql` run hits the configured query timeout, the user sees that the run timed out and which limit applied — not a raw `TimeoutException` string.

## Success metric

With `queryTimeoutSeconds` = 1 in Settings, `sql: SELECT pg_sleep(5)` shows one transcript line naming the timeout and Settings path; 0% raw `TimeoutException` strings on execute paths.

## Scope

**In:** Map `TimeoutException` (and related timeout signals from `PostgresDatabaseClient.execute` / `Future.timeout`) in `SessionErrorMapper.mapExecuteFailure`; wire existing execute transcript helpers for direct `sql:` and agent `execute_sql`; unit tests in `session_error_mapper_test.dart`; QA smoke note for timeout failure copy.

**Out:** Postgres syntax/relation/permission mapping (separate brief); connection-form test mapping; max tool rounds recovery; profile-change reconnect; system line on non-LLM settings-only changes.

## Core path impact

**execute** → **transcript** (Settings `queryTimeoutSeconds` applied on next query after #61 live refresh)

## Score (0–2 each, max 10)

| Area | Score |
|------|-------|
| Connection reliability | 0 |
| Schema / AI accuracy | 0 |
| Terminal UX | 2 |
| Safety | 2 |
| Settings ergonomics | 2 |
| **Total** | **7** |

## Anti-slop check

- [x] Job gate — Improves trust when a safety limit stops a query; user knows the limit fired, not that the DB is broken.
- [x] Core path — `execute` failure → `ErrorLine` on `sql:` and agent `execute_sql` via `mapExecuteFailure`.
- [x] Single-PR scope — Mapper branch + tests only; no timeout policy, settings store, or reconnect changes.

## Decision

**Ship** — Score 7; last execute→transcript gap in the trust cluster after live settings refresh (#61) shipped. Re-score vs 2026-05-28 (6/10): Safety 2 reflects timeout as an enforced query limit alongside row-cap and read-only copy.

## Notes

- Business scan: [2026-05-29-business-scan.md](./2026-05-29-business-scan.md) (PR [#68](https://github.com/tienan92it/mindb/pull/68), tracker [#69](https://github.com/tienan92it/mindb/issues/69)).
- Prior digest deferred at 6/10: [2026-05-28-daily-digest.md](./2026-05-28-daily-digest.md).
- Sequence next: Postgres SQL error mapping → connection test mapping → max tool rounds → profile reconnect.
