# Product workflow

Professional loop for mindb: **Business Explorer → Product Planner → Technical Analysis → Dev → Code Reviewer → Deliver**.

## Cadence (continuous delivery)

Webhooks trigger roles on your schedule — **no fixed times**. Each run advances the pipeline when work exists: discovery → plan → build → review → ship. Release Announce is a **separate tag webhook** only.

| Role | Output per successful run |
|------|---------------------------|
| **Business Explorer** | Business scan when backlog needs feeding |
| **Product Planner** | Scored brief + `planned` if ≥7 |
| **Technical Analysis** | Tech plan + `tech-reviewed` |
| **Dev** | Implementation PR (`building`) |
| **Code Reviewer** | `ready-ship` when quality bar met |
| **Deliver Ship** | Feature merged + docs + issue closed |
| **On tag** | Deliver Announce — landing changelog |

Every PR: GitHub Actions CI (analyze + test). `auto-ship.yml` merges `ready-ship` feature PRs, merges linked docs PRs via `merge-docs-for-issue.sh`, then runs `close-explore-housekeeping.sh`.

## Docs PRs

Explore/plan PRs for **ship candidates** stay open until the feature ships. **Digest** runs (score < 7) merge docs immediately in Product Planner — no stale PRs.

## Core value filter (anti-slop)

Every idea must pass **all three** before `planned`:

1. **Job** — Shortens time-to-first-query or improves trust in answers.
2. **Core path** — Strengthens connect → schema → ask → execute → transcript.
3. **Scope** — Ships in one PR without new infra.

Reject: accounts, sync, dashboards, multi-DB, hosted AI, plugin ecosystems. See `business-model.md` non-goals.

## Stages

### 1. Business Explorer

- **Cursor:** [business-explorer.workflow.json](../.cursor/automations/business-explorer.workflow.json)
- Output: `aidlc-docs/explore/YYYY-MM-DD-business-scan.md`, issue `[business]`

### 2. Product Planner

- **Cursor:** [product-planner.workflow.json](../.cursor/automations/product-planner.workflow.json)
- Output: explore brief ([TEMPLATE.md](../aidlc-docs/explore/TEMPLATE.md)), `planned` if score ≥7

### 3. Technical Analysis

- **Cursor:** [technical-analysis.workflow.json](../.cursor/automations/technical-analysis.workflow.json)
- Output: [plan/TEMPLATE.md](../aidlc-docs/plan/TEMPLATE.md), label `tech-reviewed`

### 4. Dev

- **Cursor:** [dev-implement.workflow.json](../.cursor/automations/dev-implement.workflow.json)
- Requires: `planned` + `tech-reviewed`. Opens implementation PR.

### 5. Code Reviewer

- **Cursor:** [code-reviewer.workflow.json](../.cursor/automations/code-reviewer.workflow.json)
- Loop: analyze, test, conventions → PR label `ready-ship`

### 6. Deliver

- **Ship:** [deliver-ship.workflow.json](../.cursor/automations/deliver-ship.workflow.json) + `auto-ship.yml` + [merge-docs-for-issue.sh](../.github/scripts/merge-docs-for-issue.sh)
- **Announce:** [release-announce.workflow.json](../.cursor/automations/release-announce.workflow.json)

```bash
# manual release cut
git tag v1.0.1 && git push origin v1.0.1
```

## GitHub labels

| Label | Use |
|-------|-----|
| `explore` | Discovery / briefs |
| `planned` | Approved to plan + build |
| `tech-reviewed` | Tech plan ready |
| `building` | Dev PR in progress |
| `in-review` | Code review |
| `ready-ship` | PR approved to merge |
| `shipped` | Merged |
| `bug` | Defect |
| `release` | Release tracking |

## Automations setup

See [.cursor/automations/README.md](../.cursor/automations/README.md).
