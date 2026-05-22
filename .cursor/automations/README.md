# Cursor Automations

Workflow drafts for the mindb product loop. Confirm in Cursor UI before enabling.

Cursor Automations has **Open pull request** for GitHub PRs. There is no separate “GitHub issues” tool — issues and PRs are created via **`gh`** in the agent prompt (terminal). **Turn Open pull request OFF** for explore and build automations.

## Full loop

| Time (ICT) | Automation | Output |
|------------|------------|--------|
| 09:00 | **Daily Explore** | Brief PR + GitHub issue (`planned` if score ≥ 7) |
| 10:30 | **Daily Build** | Code PR for oldest `planned` issue (+ optional auto-ship) |
| On tag | **Release Announce** (webhook) | Landing changelog PR |

Merge explore brief PRs when convenient (docs-only). Build reads the **issue** body; brief on `master` is nice-to-have.

## Prerequisites (all automations)

1. [cursor.com/settings](https://cursor.com/settings) → **GitHub** → connect **tienan92it** with access to **`tienan92it/mindb`** (Issues + Pull requests + Contents: read/write).
2. [cursor.com/dashboard/cloud-agents](https://cursor.com/dashboard/cloud-agents) → **Secrets** → **`GH_TOKEN`** (PAT with `repo` or issues + pull_requests + contents on this repo).
3. GitHub labels: `explore`, `planned`, `building`, `shipped`, `bug`, `release`, `auto-ship` (PR label for auto-merge when CI green).

Create missing labels:

```bash
gh label create building --repo tienan92it/mindb --description "Implementation in progress" --color "FBCA04" 2>/dev/null || true
gh label create shipped --repo tienan92it/mindb --description "Merged to master" --color "0E8A16" 2>/dev/null || true
gh label create auto-ship --repo tienan92it/mindb --description "Merge when CI green (.github/workflows/auto-ship.yml)" --color "5319E7" 2>/dev/null || true
```

## 1. Daily Explore (09:00 ICT)

**Schedule:** `0 2 * * *` UTC  
**Does:** Scores ≤3 ideas, brief PR, GitHub issue. **No product code.**

**Tools:** Open pull request **OFF**, Memories optional ON.

**Agent Instructions:** copy from `daily-explore.workflow.json` → `prompt` field.

## 2. Daily Build (10:30 ICT)

**Schedule:** `30 3 * * *` UTC (90 min after explore)  
**Does:** Implements **one** oldest open `planned` issue; opens code PR; optional `auto-ship` label.

**Tools:** Open pull request **OFF**, Memories optional ON.

**Agent Instructions:** copy from `daily-build.workflow.json` → `prompt` field.

**Manual trigger:** Run now to implement issue #2 (Anthropic tool-use fix) if still `planned`.

**Human review:** PRs without `auto-ship` wait for you to merge. PRs with `auto-ship` merge via `.github/workflows/auto-ship.yml` when CI passes.

## 3. Release Announce (webhook)

**Trigger:** Webhook from `.github/workflows/release.yml` on tag `v*.*.*`  
**Does:** PR updating `docs/index.html` changelog.

**Tools:** Open pull request **OFF** (use `gh pr create` in prompt, same as explore/build).

## Files

| File | Purpose |
|------|---------|
| `daily-explore.workflow.json` | Product explorer — brief + issue |
| `daily-build.workflow.json` | Dev team — implement planned issue |
| `release-announce.workflow.json` | Landing changelog after release |

Full operating model: `aidlc-docs/product-workflow.md`
