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

## 2026-05-21 — Product team workflow

**Context**: MVP stable; need continuous explore → ship loop without slop.

**Choice**: GitHub Actions (CI + release) + Cursor Automations (daily explore, release announce) + `aidlc-docs/product-workflow.md` + `.cursor/rules/product-team.mdc`.

**Trade-offs**: Daily explore consumes cloud agent credits; explore PRs require human merge review.

**Alternatives**: Manual weekly planning only; Linear/Jira without repo-linked briefs.

## 2026-05-22 — Daily Build + auto-ship

**Context**: Explore-only loop left implementation manual; user wants full product + dev team automation.

**Choice**: Second Cursor automation **Daily Build** (10:30 ICT) implements oldest `planned` issue; optional PR label `auto-ship` + `.github/workflows/auto-ship.yml` merges when CI green. Open pull request tool disabled — use `gh pr create` + push.

**Trade-offs**: Auto-ship skips human review for low-risk fixes; one issue per build run; build may fail on large scope despite explore gates.

**Alternatives**: Single combined explore+build prompt; always require human merge; GitHub issue webhook trigger (not available in Cursor Automations).

## 2026-05-21 — User API keys only

**Context**: No hosted backend in v1.

**Choice**: OpenAI + Anthropic via direct HTTPS; keys in `flutter_secure_storage`.

**Alternatives**: Hosted proxy with billing.

## 2026-05-21 — Kimi LLM provider

**Context**: User requested Kimi as an AI provider option.

**Choice**: `KimiProvider` using Moonshot OpenAI-compatible API (`https://api.moonshot.ai/v1`).

**Trade-offs**: Same tool-call loop as OpenAI; China endpoint (`api.moonshot.cn`) not exposed in UI yet.

**Alternatives**: Single configurable OpenAI-compatible provider with custom base URL.
