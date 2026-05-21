# Design

## Units of work

1. **Persistence** — Drift profiles + secure storage for passwords/API keys
2. **Postgres client** — connect, execute, disconnect via `postgres` package
3. **Schema service** — introspection + JSON cache for LLM context
4. **Safety + executor** — classify SQL, confirm destructive ops, row/timeout limits
5. **AI orchestrator** — tool loop with OpenAI / Anthropic providers
6. **Terminal UI** — connections home, session transcript, settings

## Components

| Component | Responsibility | Dependencies |
|-----------|----------------|--------------|
| `ConnectionRepository` | CRUD profiles, credential bridge | Drift, SecureCredentialStore |
| `PostgresDatabaseClient` | TCP connection, query execution | postgres |
| `SchemaService` | information_schema introspection | DatabaseClient |
| `QueryExecutor` | Safety + limits wrapper | SafetyPolicy, DatabaseClient |
| `AiAgentOrchestrator` | Tool-call loop | LlmProvider, SchemaService, QueryExecutor |
| Session UI | Transcript + SqlInputBar | Riverpod, orchestrator |

## Contracts

- `DatabaseClient`: `connect`, `execute`, `disconnect`, `isConnected`
- `LlmProvider`: `runAgentLoop(messages, tools)` → stream of events
- Tools: `get_schema`, `execute_sql`, `explain_sql`

## Data flow

```
User prompt → Orchestrator → LLM (with tools)
  → get_schema → SchemaService → PG
  → execute_sql → SafetyPolicy → QueryExecutor → PG → ResultLine in UI
  → final assistant text → AssistantLine in UI
```

## Trade-offs

- **Flutter over native Swift**: one codebase; custom SQL keyboard bar in v1
- **Drift 2.22 pinned**: compatible with Dart 3.6 on current Flutter stable
- **Client-side statement timeout**: `Future.timeout` rather than server `statement_timeout`
- **Non-streaming tool loop**: simpler reliability; assistant text streamed where supported
