# Time-to-first-query onboarding

## Job

A new installer can connect to Postgres and run a first natural-language question without leaving the app for undocumented setup steps.

## Success metric

Median cold-install → first successful NL query under 3 minutes in a scripted QA path (save connection + API key + one prompt).

## Scope

**In:** First-run empty state on connections home; inline checklist (connection profile, LLM API key, open session); deep-link or prominent entry to Settings for API key before first session; actionable errors when connect fails at session open.

**Out:** Hosted onboarding backend, video tutorials, SSH tunnel setup, multi-provider comparison UI, cloud sync of profiles.

## Core path impact

connect | settings ergonomics (enables ask)

## Score (0–2 each, max 10)

| Area | Score |
|------|-------|
| Connection reliability | 2 |
| Schema / AI accuracy | 1 |
| Terminal UX | 2 |
| Safety | 0 |
| Settings ergonomics | 2 |
| **Total** | **7** |

## Anti-slop check

- [x] Job gate — Directly targets business-model time-to-first-query metric.
- [x] Core path — Unblocks connect and settings before schema → ask.
- [x] Single-PR scope — Connections empty state + settings entry + copy only; no new infra.

## Decision

**Ship** — Highest net-new score; Anthropic encoding (#2) already in flight; onboarding can parallel without blocking transcript fixes.

## Notes

- Business scan: [2026-05-23-business-scan.md](./2026-05-23-business-scan.md) opportunity #1.
- Issue #2 (`planned` + `tech-reviewed`) remains implementation priority for multi-step ask.
