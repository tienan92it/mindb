# Cursor Automations — product team roles

Six role-based automations (webhook, ~4×/day) + release webhook on tag. **Open pull request tool: OFF** for all — use `git push` + `gh pr create`.

## Pipeline (webhook cadence)

External jobs hit each automation webhook **~4 times per day** (e.g. every 6 hours). Roles do **not** assume run order — each prompt checks state and exits idempotently when there is nothing to do.

| Role | Automation | Typical output per cycle |
|------|------------|--------------------------|
| **Business Explorer** | `business-explorer.workflow.json` | One business scan / day (first successful run) |
| **Product Planner** | `product-planner.workflow.json` | One brief / day when scan is ready |
| **Technical Analysis** | `technical-analysis.workflow.json` | One tech plan / run (oldest unplanned issue) |
| **Dev** | `dev-implement.workflow.json` | One implementation PR / run |
| **Code Reviewer** | `code-reviewer.workflow.json` | One building PR reviewed; fix loops across runs |
| **Deliver Ship** | `deliver-ship.workflow.json` | Merge ready-ship when CI green |
| On tag `v*.*.*` | **Deliver Announce** | `release-announce.workflow.json` — **not** in the 4×/day batch |

**Parallel runs:** Business Explorer and Product Planner may overlap on the same webhook tick. Product Planner reads the scan from master **or** an open business-scan PR; if neither exists, it skips until the next tick.

**CI auto-ship:** `.github/workflows/auto-ship.yml` merges `ready-ship` PRs when checks pass — Deliver webhook is a backup, not the only path.

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
3. Webhook URLs from Cursor for each role automation; wire your scheduler (GitHub Actions, cron job, etc.) to POST 4×/day.
4. `.github/workflows/auto-ship.yml` merges `ready-ship` PRs on CI success, then runs `.github/scripts/merge-docs-for-issue.sh`.

## Idempotency rules (built into prompts)

| Role | Skip when |
|------|-----------|
| Business Explorer | Today's scan file or open PR already exists |
| Product Planner | Brief PR for today exists, or no scan ready |
| Technical Analysis | No planned issue without tech-reviewed / plan PR |
| Dev | No planned+tech-reviewed issue, or building PR in flight |
| Code Reviewer | No open `building` PRs |
| Deliver Ship | No open `ready-ship` PRs |

## Docs PR merge (on ship)

Business scan, product brief, and tech plan PRs stay **open** until the feature ships:

1. Explore/plan automations label PRs `docs` and link `Ship issue: #N` (Product Planner adds doc URLs to the ship issue).
2. When Deliver merges a feature PR (`Fixes #N`), it runs `merge-docs-for-issue.sh` to squash-merge open `explore/*` and `plan/*` PRs for that issue.

Re-paste updated prompts from workflow JSON after pulling.

## Setup each automation

1. [cursor.com/automations/new](https://cursor.com/automations/new)
2. Name from table above
3. Trigger: **Webhook** (copy URL for your 4×/day scheduler)
4. Repo `tienan92it/mindb`, branch `master`
5. **Agent Instructions:** copy `prompt` field from matching `.workflow.json`
6. Tools: Open pull request **OFF**, Memories ON for explore/plan/dev/review roles

## Deliver (two automations)

### Ship — `deliver-ship.workflow.json`

Webhook merge of Code Reviewer–approved PRs (~4×/day).

### Announce — `release-announce.workflow.json`

1. Trigger: **Webhook** (from `.github/workflows/release.yml` on tag push only)
2. Secrets on GitHub repo: `CURSOR_ANNOUNCE_WEBHOOK_URL`, `CURSOR_ANNOUNCE_WEBHOOK_KEY`

## Legacy

`daily-explore.workflow.json` and `daily-build.workflow.json` are superseded — disable in Cursor UI.

## Files

| File | Role |
|------|------|
| `business-explorer.workflow.json` | Business Explorer |
| `product-planner.workflow.json` | Product Planner |
| `technical-analysis.workflow.json` | Technical Analysis |
| `dev-implement.workflow.json` | Dev |
| `code-reviewer.workflow.json` | Code Reviewer |
| `deliver-ship.workflow.json` | Deliver Ship |
| `release-announce.workflow.json` | Deliver Announce (tag only) |

Docs: `aidlc-docs/product-workflow.md`, plans in `aidlc-docs/plan/`.
