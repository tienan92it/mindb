# Cursor Automations — product team roles

Six role-based automations (webhook, on-demand) + release webhook on tag. **Open pull request tool: OFF** for all — use `git push` + `gh pr create`.

## Pipeline (continuous delivery)

Webhooks trigger roles **whenever your scheduler fires** — no fixed daily cadence. Each run **advances one unit of work** when the pipeline has actionable state: plan → build → review → ship. Roles check queue state first and exit cleanly when idle.

| Role | Automation | Responsibility per run |
|------|------------|------------------------|
| **Business Explorer** | `business-explorer.workflow.json` | Feed opportunity backlog when discovery is needed |
| **Product Planner** | `product-planner.workflow.json` | Score scan → brief → `planned` ship issue if ≥7 |
| **Technical Analysis** | `technical-analysis.workflow.json` | Tech plan for oldest unplanned `planned` issue |
| **Dev** | `dev-implement.workflow.json` | One implementation PR for oldest build-ready issue |
| **Code Reviewer** | `code-reviewer.workflow.json` | One `building` PR → `ready-ship` (fix loops OK) |
| **Deliver Ship** | `deliver-ship.workflow.json` | Merge all `ready-ship` PRs with green CI |
| On tag `v*.*.*` | **Deliver Announce** | `release-announce.workflow.json` — tag webhook only |

**Parallel runs:** Roles may overlap. State checks prevent duplicate PRs/issues; downstream roles skip until upstream artifacts exist.

**CI auto-ship:** `.github/workflows/auto-ship.yml` merges `ready-ship` when checks pass — Deliver webhook is parallel path, not exclusive.

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
3. Webhook URLs from Cursor for each role; wire your scheduler to POST on whatever cadence you want (hourly, on push, etc.).
4. `.github/workflows/auto-ship.yml` merges `ready-ship` PRs on CI success, then runs `.github/scripts/merge-docs-for-issue.sh`.

## State checks (built into prompts)

Each role exits cleanly when its queue is empty or work is already in flight — no duplicate PRs/issues.

| Role | Skip when |
|------|-----------|
| Business Explorer | Backlog fed; scan in PR and consumed |
| Product Planner | Brief/ship issue exists for scan; no scan ready |
| Technical Analysis | No `planned` issue without tech-reviewed / plan PR |
| Dev | No build-ready issue; building PR in flight |
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
3. Trigger: **Webhook** (copy URL for your scheduler)
4. Repo `tienan92it/mindb`, branch `master`
5. **Agent Instructions:** copy `prompt` field from matching `.workflow.json`
6. Tools: Open pull request **OFF**, Memories ON for explore/plan/dev/review roles

## Deliver (two automations)

### Ship — `deliver-ship.workflow.json`

Webhook merge of Code Reviewer–approved PRs whenever triggered.

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
