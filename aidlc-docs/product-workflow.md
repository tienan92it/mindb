# Product workflow

Professional loop for mindb: explore → plan → build → QA → review → release → announce.

## Cadence

| When | What | Owner |
|------|------|-------|
| **Daily 09:00 ICT** | Explore (≤3 ideas, score, 0–1 ship candidate) | Cursor **Daily Explore** |
| **Daily 10:30 ICT** | Build oldest `planned` issue → code PR | Cursor **Daily Build** |
| **Every PR** | CI + review checklist | GitHub Actions |
| **CI green + `auto-ship`** | Squash merge implementation PR | GitHub Actions `auto-ship.yml` |
| **On release tag** | GitHub Release + announce webhook | GitHub Actions + Cursor |
| **After tag** | Landing changelog PR | Cursor **Release Announce** |

## Core value filter (anti-slop)

Every idea must pass **all three** before implementation:

1. **Job** — Shortens time-to-first-query or improves trust in answers.
2. **Core path** — Strengthens connect → schema → ask → execute → transcript.
3. **Scope** — Ships in one PR without new infra.

Reject: accounts, sync, dashboards, multi-DB, hosted AI, plugin ecosystems. See `business-model.md` non-goals.

## Stages

### 1. Explore

- **Cursor:** [mindb Daily Explore](../.cursor/automations/daily-explore.workflow.json) — brief PR + GitHub issue (`planned` if score ≥ 7). **No product code.**
- **Manual:** Issue template **Explore** or file in `aidlc-docs/explore/`.

### 2. Plan

- Trivial: skip docs (explore issue + brief is enough).
- Multi-component: update `design.md`.
- Material choice: append `decisions.md`.

### 3. Build

- **Cursor:** [mindb Daily Build](../.cursor/automations/daily-build.workflow.json) — picks oldest open `planned` issue, implements on `fix/*` or `feat/*`, runs analyze/test, opens PR with `Fixes #N`.
- **Labels:** `planned` → `building` when PR opens; `shipped` + close when merged (auto-ship workflow or manual merge).
- **Auto-ship:** low-risk PRs get label `auto-ship`; `.github/workflows/auto-ship.yml` merges when CI green. Otherwise human merges.
- Branch from `master`. Smallest diff. Tests for behavior changes.

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
| `planned` | Approved to build (Daily Build picks these) |
| `building` | Implementation PR open |
| `shipped` | Merged to master |
| `auto-ship` | PR: merge when CI green |
| `bug` | Defect |
| `release` | Release tracking |

## Automations setup

1. Enable **Daily Explore**, **Daily Build**, and **Release Announce** — see `.cursor/automations/README.md`.
2. Connect GitHub for `tienan92it/mindb` (Issues + Pull requests + Contents write).
3. Cloud secret **`GH_TOKEN`** for all `gh` / git push operations.
4. Labels: `explore`, `planned`, `building`, `shipped`, `auto-ship`, `bug`, `release`.
5. Release webhook secrets after **Release Announce** automation.
