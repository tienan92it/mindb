# Visible notice when schema context is partial (large DB)

## Job

On a large database, the user knows when the session’s schema context is truncated (compact table index capped) before trusting a broad natural-language answer.

## Success metric

QA on a DB with more tables than the system index cap shows a visible transcript or session notice; follow-up `get_schema` for a named table succeeds without restart.

## Scope

**In:** Surface when the compact schema index is truncated vs full catalog; one-line transcript or session banner; recovery copy aligned with `get_schema` filtering on master.

**Out:** Raising index caps, new introspection sources, persisted schema sync, multi-DB, Kimi endpoint selection.

## Core path impact

schema | ask | transcript

## Score (0–2 each, max 10)

| Area | Score |
|------|-------|
| Connection reliability | 0 |
| Schema / AI accuracy | 2 |
| Terminal UX | 2 |
| Safety | 2 |
| Settings ergonomics | 1 |
| **Total** | **7** |

## Anti-slop check

- [x] Job gate — Silent index truncation makes NL answers look complete when unseen tables exist; last major schema→ask trust gap after transcript cluster, DDL cache, schema-failure warning, and row-cap notice shipped.
- [x] Core path — Strengthens schema → ask → transcript honesty when context budget trims the catalog.
- [x] Single-PR scope — Orchestrator/session notice when compact index build truncates; reuses `SchemaSummaryFormatter` signals; no new infra.

## Decision

**Ship** — Score 7 (re-score 2026-05-26, post–#35/#39/#43). With executed SQL ([#21](https://github.com/tienan92it/mindb/issues/21)), DDL invalidation ([#35](https://github.com/tienan92it/mindb/issues/35)), schema-failure warnings ([#39](https://github.com/tienan92it/mindb/issues/39)), and row-cap notices ([#43](https://github.com/tienan92it/mindb/issues/43)) shipped, silent compact-index truncation is the dominant remaining schema→ask trust gap.

## Notes

- Business scan opportunity #5: [2026-05-26-business-scan.md](./2026-05-26-business-scan.md) (PR [#32](https://github.com/tienan92it/mindb/pull/32)).
- Prior score 6 (2026-05-24–26); Safety 0→2 and Settings 1 — partial catalog increases risk of approving destructive SQL on wrong assumptions; recovery copy should point users to targeted `get_schema`.
- `SchemaSummaryFormatter` truncates with model-only suffix today; no user-visible session/transcript signal.
