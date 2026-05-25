# QA smoke test

Run before every release and after user-facing PRs (~5 minutes).

## Prerequisites

- Postgres (Docker): `docker run --name mindb-pg -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:16`
- LLM API key in Settings (any provider)

## Checklist

1. **Connections** — Add profile (localhost:5432, postgres/postgres). Opens session.
2. **Session header** — Transcript shows connect line + `llm: <provider> · <model>`.
3. **Schema** — Ask "test connection" or "list tables". No schema SQL errors.
4. **AI query** — Natural language question returns answer grounded in tool results. If `execute_sql` runs, the executed statement appears in the transcript immediately above the result table (or error block), not only `tool → execute_sql`.
5. **Direct SQL** — `sql: SELECT 1` shows result table.
6. **Safety** — Read-only mode blocks INSERT; destructive SQL prompts confirmation.
7. **Settings** — Switch provider/model, save, reconnect; LLM bar reflects choice.
8. **Persistence** — Kill app, reopen session; history restores and scrolls to bottom.

## Platform notes

- **iOS 26+ device:** use `flutter run --profile` or `--release` for debug JIT limitation.
- **Enums:** status columns show readable strings, not `UndecodedBytes`.

## Automated gate

CI runs `flutter analyze` + `flutter test` on every PR and push to `master`.
