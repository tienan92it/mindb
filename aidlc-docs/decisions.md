# Decisions

## 2026-05-21 — Flutter over native Swift

**Context**: Mobile DB client with terminal UI and AI tools.

**Choice**: Flutter (iOS-first).

**Trade-offs**: Less native keyboard integration; faster cross-platform path.

**Alternatives**: SwiftUI + PostgresNIO.

## 2026-05-21 — Project location and name

**Context**: User specified workspace layout.

**Choice**: `~/Workspace/mindb`, bundle org `app.mindb`.

**Alternatives**: `~/Projects/db-terminal`.

## 2026-05-21 — Drift version pin for Dart 3.6

**Context**: Flutter 3.27 ships Dart 3.6; latest drift_dev requires SDK 3.7+.

**Choice**: Pin `drift` / `drift_dev` to ^2.22.1, `build_runner` ^2.4.13.

**Trade-offs**: Older drift; upgrade when Flutter SDK bumps.

**Follow-ups**: Revisit when Dart >= 3.10 available.

## 2026-05-21 — User API keys only

**Context**: No hosted backend in v1.

**Choice**: OpenAI + Anthropic via direct HTTPS; keys in `flutter_secure_storage`.

**Alternatives**: Hosted proxy with billing.

## 2026-05-21 — Kimi LLM provider

**Context**: User requested Kimi as an AI provider option.

**Choice**: `KimiProvider` using Moonshot OpenAI-compatible API (`https://api.moonshot.ai/v1`).

**Trade-offs**: Same tool-call loop as OpenAI; China endpoint (`api.moonshot.cn`) not exposed in UI yet.

**Alternatives**: Single configurable OpenAI-compatible provider with custom base URL.
