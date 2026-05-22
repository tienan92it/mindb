# Daily explore — 2026-05-22

Three candidates for the core loop **connect → schema → ask → execute → transcript**. No existing `explore`-labeled issues in the repo at scan time.

---

## 1. Fix Anthropic multi-round tool-use encoding

### Job

Anthropic users can complete multi-step agent runs (schema fetch → SQL → follow-up) without the API rejecting or mis-associating tool results.

### Success metric

QA smoke item 4 (AI query) passes with **Anthropic** provider on a prompt that requires ≥2 tool rounds (e.g. "list tables then count rows in the largest").

### Scope

**In:** Encode assistant `tool_use` blocks in outbound messages; pass real `tool_use_id` on `tool_result` content blocks; extend `ChatMessage` / history builder if needed; regression test with mocked Anthropic payloads.

**Out:** Streaming, new providers, hosted proxy, prompt rewrites.

### Core path impact

ask | execute

### Score (0–2 each, max 10)

| Area | Score |
|------|-------|
| Connection reliability | 0 |
| Schema / AI accuracy | 2 |
| Terminal UX | 1 |
| Safety | 0 |
| Settings ergonomics | 1 |
| **Total** | **7** |

### Anti-slop check

- [x] Job gate — Restores trustworthy multi-step answers for a configured provider.
- [x] Core path — Fixes LLM ↔ tool loop on the ask/execute bridge.
- [x] Single-PR scope — `anthropic_provider.dart`, message model, tests only.

### Decision

**Ship** — Highest score; known defect (`tool_use_id: 'tool_result'` hardcoded; assistant tool blocks omitted). Blocks a full provider path in v1.

### Notes

- `lib/data/llm/anthropic_provider.dart` lines 30–48: tool results use fixed id; assistant messages are text-only.
- OpenAI/Kimi paths use OpenAI-compatible tool IDs and are unaffected.

---

## 2. Render agent `execute_sql` results as transcript tables

### Job

Natural-language asks show the same tabular result blocks as `sql:` direct queries so users can verify what the database returned.

### Success metric

After an AI-driven `SELECT`, transcript contains a `ResultLine` / `TableResultBlock` (not only a YAML-like `SystemLine` tool dump).

### Scope

**In:** Propagate `QueryResult` from tool execution through orchestrator events; map `execute_sql` success to `ResultLine` in `SessionController.submitPrompt`.

**Out:** Persisting tables in session history, charting, export.

### Core path impact

execute | transcript

### Score (0–2 each, max 10)

| Area | Score |
|------|-------|
| Connection reliability | 0 |
| Schema / AI accuracy | 2 |
| Terminal UX | 2 |
| Safety | 0 |
| Settings ergonomics | 0 |
| **Total** | **6** |

### Anti-slop check

- [x] Job gate — Improves trust in NL answers (core JTBD).
- [x] Core path — Closes execute → transcript gap vs direct `sql:` path.
- [x] Single-PR scope — Orchestrator events + session transcript wiring.

### Decision

**Defer** — Score 6; strong UX win but Anthropic fix unblocks reliable multi-step runs first.

### Notes

- Direct path already adds `ResultLine` in `session_providers.dart` (~247–248); agent path only appends `SystemLine(result)` (~271–272).

---

## 3. Invalidate schema cache after DDL-classified writes

### Job

After the agent or user runs schema-changing SQL, the next `get_schema` / system prompt reflects current tables and columns.

### Success metric

Run `CREATE TABLE explore_tmp (id int)` then ask "what columns does explore_tmp have?" — answer matches live schema without app restart.

### Scope

**In:** Call `SchemaService.clearCache()` (or `fetchSchema(forceRefresh: true)`) when `SafetyPolicy` classifies executed SQL as write/destructive and statement matches DDL patterns (`CREATE`, `ALTER`, `DROP`, …).

**Out:** FK/index introspection, persisted schema cache, polling.

### Core path impact

schema | ask

### Score (0–2 each, max 10)

| Area | Score |
|------|-------|
| Connection reliability | 0 |
| Schema / AI accuracy | 2 |
| Terminal UX | 1 |
| Safety | 1 |
| Settings ergonomics | 0 |
| **Total** | **6** |

### Anti-slop check

- [x] Job gate — Reduces wrong SQL from stale schema context.
- [x] Core path — schema → ask accuracy.
- [x] Single-PR scope — Hook in `QueryExecutor` or orchestrator post-execute; unit tests.

### Decision

**Defer** — Score 6; `clearCache()` exists but is never called from production code.

### Notes

- In-memory cache only; no migration to JSON persistence (non-goal).

---

## Summary

| Idea | Total | Decision |
|------|-------|----------|
| Anthropic tool-use encoding | 7 | **Ship** |
| Agent SQL → ResultLine tables | 6 | Defer |
| Schema cache invalidation on DDL | 6 | Defer |

**Rejected (non-goals / anti-slop):** SSH tunnel, multi-DB, hosted AI, sync, dashboards, connection cloud backup, streaming assistant tokens, FK/index catalog expansion (multi-PR schema scope).
