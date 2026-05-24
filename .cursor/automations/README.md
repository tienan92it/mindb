# Cursor Automations — product team roles

Six role-based automations + release webhook. **Open pull request tool: OFF** for all — use `git push` + `gh pr create`.

## Pipeline (ICT)

| Time | Role | Automation | Output |
|------|------|------------|--------|
| 09:00 | **Business Explorer** | `business-explorer.workflow.json` | Business scan PR + `[business]` issue |
| 09:30 | **Product Planner** | `product-planner.workflow.json` | Scored brief PR + `planned` issue if ≥7 |
| 10:00 | **Technical Analysis** | `technical-analysis.workflow.json` | Tech plan PR + `tech-reviewed` on issue |
| 11:00 | **Dev** | `dev-implement.workflow.json` | Code PR (`building`) |
| 11:45, 14:00 | **Code Reviewer** | `code-reviewer.workflow.json` | Fix loop → `ready-ship` on PR |
| 15:00, 15:30 | **Deliver Ship** | `deliver-ship.workflow.json` | Merge feature PR + **linked docs PRs** |
| On tag `v*.*.*` | **Deliver Announce** | `release-announce.workflow.json` | Landing changelog PR (webhook) |

Adjust cron in Cursor UI if needed (you set Dev to 11:00 = `0 4 * * *` UTC).

## Label flow

```
explore → planned → tech-reviewed → building → ready-ship (PR) → shipped (issue closed)
```

| Label | Set by |
|-------|--------|
| `explore` | Business Explorer / Product Planner |
| `planned` | Product Planner (score ≥7) |
| `tech-reviewed` | Technical Analysis |
| `building` | Dev (PR + issue) |
| `ready-ship` | Code Reviewer (PR label) |
| `in-review` | Code Reviewer (issue, optional) |
| `shipped` | Deliver / auto-ship.yml |
| `docs` | Docs PR (business/brief/plan); merged when ship issue closes |

Create labels:

```bash
gh label create docs --repo tienan92it/mindb --description "Docs PR; merged on ship" --color "C5DEF5" 2>/dev/null || true
gh label create tech-reviewed --repo tienan92it/mindb --description "Tech plan approved for dev" --color "006B75" 2>/dev/null || true
gh label create in-review --repo tienan92it/mindb --description "In code review" --color "D4C5F9" 2>/dev/null || true
gh label create ready-ship --repo tienan92it/mindb --description "Approved; merge when CI green" --color "5319E7" 2>/dev/null || true
```

## Prerequisites

1. GitHub integration: `tienan92it/mindb` — Issues, PRs, Contents write.
2. Cloud secret **`GH_TOKEN`** (PAT with `repo` scope).
3. `.github/workflows/auto-ship.yml` merges `ready-ship` PRs on CI success, then runs `.github/scripts/merge-docs-for-issue.sh` to merge linked explore/plan docs PRs.

## Docs PR merge (on ship)

Business scan, product brief, and tech plan PRs stay **open** until the feature ships:

1. Explore/plan automations label PRs `docs` and link `Ship issue: #N` (Product Planner adds doc URLs to the ship issue).
2. When Deliver merges a feature PR (`Fixes #N`), it runs `merge-docs-for-issue.sh` to squash-merge open `explore/*` and `plan/*` PRs for that issue.

Re-paste updated prompts from `business-explorer`, `product-planner`, `technical-analysis`, and `deliver-ship` workflow JSON after pulling.

## Setup each automation

1. [cursor.com/automations/new](https://cursor.com/automations/new)
2. Name + schedule from table above
3. Repo `tienan92it/mindb`, branch `master`
4. **Agent Instructions:** copy `prompt` field from matching `.workflow.json`
5. Tools: Open pull request **OFF**, Memories ON for explore/plan/dev/review roles

## Deliver (two automations)

### Ship — `deliver-ship.workflow.json`

Scheduled merge of Code Reviewer–approved PRs.

### Announce — `release-announce.workflow.json`

1. Trigger: **Webhook** (from `.github/workflows/release.yml` on tag push)
2. Secrets on GitHub repo: `CURSOR_ANNOUNCE_WEBHOOK_URL`, `CURSOR_ANNOUNCE_WEBHOOK_KEY`

## Legacy

`daily-explore.workflow.json` and `daily-build.workflow.json` are superseded by the role pipeline — disable and delete those automations in Cursor UI.

## Files

| File | Role |
|------|------|
| `business-explorer.workflow.json` | Business Explorer |
| `product-planner.workflow.json` | Product Planner |
| `technical-analysis.workflow.json` | Technical Analysis |
| `dev-implement.workflow.json` | Dev |
| `code-reviewer.workflow.json` | Code Reviewer |
| `deliver-ship.workflow.json` | Deliver Ship |
| `release-announce.workflow.json` | Deliver Announce |

Docs: `aidlc-docs/product-workflow.md`, plans in `aidlc-docs/plan/`.
