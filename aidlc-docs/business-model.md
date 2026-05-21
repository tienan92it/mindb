# Business Model

## Problem

Developers and analysts need quick access to PostgreSQL databases from mobile. Writing SQL on a phone is painful; existing clients are form-heavy and not AI-native. Natural language queries with automatic schema awareness reduce friction for ad-hoc exploration.

## Users

Primary: engineers and data analysts who already manage Postgres instances and want a minimal mobile client for inspection and light queries.

Job-to-be-done: connect to a database, ask questions in plain language, get correct SQL executed and results displayed.

## Value

Inputs: DB connection + natural language request + user LLM API key.

Logic: introspect schema → LLM generates SQL via tools → safety gate → execute → render terminal-style output.

Outputs: query results, explanations, schema summaries.

## Success metrics

- Time to first successful query from install < 3 minutes
- Schema fetch success > 99% on standard layouts
- Zero credential leaks in logs

## Constraints

- iOS-first v1; direct TCP only (no SSH tunnel)
- User supplies LLM API keys; no developer-hosted inference
- PostgreSQL only in v1

## Non-goals

- SSH tunneling, multi-DB engines, hosted AI proxy, cloud sync of connections
