# Product workflow

Professional loop for mindb: explore → plan → build → QA → review → release → announce.

## Cadence

| When | What | Owner |
|------|------|-------|
| **Daily 09:00 ICT** | Explore (≤3 ideas, score, 0–1 ship candidate) | Cursor Automation |
| **Per ship candidate** | Plan → branch → PR | Agent / you |
| **Every PR** | CI + review checklist | GitHub Actions |
| **On release tag** | GitHub Release + announce | GitHub Actions + Cursor |
| **After tag** | Landing changelog PR | Agent / you |

## Core value filter (anti-slop)

Every idea must pass **all three** before implementation:

1. **Job** — Shortens time-to-first-query or improves trust in answers.
2. **Core path** — Strengthens connect → schema → ask → execute → transcript.
3. **Scope** — Ships in one PR without new infra.

Reject: accounts, sync, dashboards, multi-DB, hosted AI, plugin ecosystems. See `business-model.md` non-goals.

## Stages

### 1. Explore

- **Cursor:** [mindb Daily Explore](../.cursor/automations/daily-explore.workflow.json) — opens PR with brief + GitHub issue.
- **Manual:** Issue template **Explore** or file in `aidlc-docs/explore/`.

### 2. Plan

- Trivial: skip docs.
- Multi-component: update `design.md`.
- Material choice: append `decisions.md`.

### 3. Build

- Branch from `master`.
- Smallest diff; match existing patterns.
- Tests for behavior changes.

### 4. QA

- CI green (`.github/workflows/ci.yml`).
- Manual smoke (`qa-smoke.md`) for user-facing changes.

### 5. Review

- PR template checklist complete.
- One approval (you or agent summary).

### 6. Release

```bash
# bump pubspec.yaml version
git tag v1.0.1
git push origin v1.0.1
```

`.github/workflows/release.yml` runs tests and creates GitHub Release.

Optional secrets for announce automation:

- `CURSOR_ANNOUNCE_WEBHOOK_URL`
- `CURSOR_ANNOUNCE_WEBHOOK_KEY`

### 7. Announce

- **Cursor:** [mindb Release Announce](../.cursor/automations/release-announce.workflow.json) — PR updating `docs/index.html` changelog.
- Only user-facing bullets; no roadmap slop.

## GitHub labels (recommended)

Create in repo settings:

| Label | Use |
|-------|-----|
| `explore` | Daily exploration |
| `planned` | Approved to build |
| `bug` | Defect |
| `release` | Release tracking |

## Automations setup

1. Open prefill URLs in `.cursor/automations/README.md` and confirm in Cursor UI.
2. Enable GitHub integration for `tienan92it/mindb`.
3. Add release webhook secrets after creating **Release Announce** automation.
