# Cursor Automations

Workflow drafts for the mindb product loop. Confirm in Cursor UI before enabling.

Cursor Automations has **Open pull request** for GitHub PRs. There is no separate “GitHub issues” tool — issues are created via **`gh issue create`** in the agent prompt (terminal).

## Prerequisites (both automations)

1. [cursor.com/settings](https://cursor.com/settings) → **GitHub** → connect **tienan92it** with access to **`tienan92it/mindb`** (Issues + Pull requests: read/write).
2. [cursor.com/dashboard/cloud-agents](https://cursor.com/dashboard/cloud-agents) → **Secrets** → add **`GH_TOKEN`** (PAT with `issues` + `pull_requests` on this repo). The cloud agent’s default GitHub token often cannot create issues; `GH_TOKEN` makes `gh` use your PAT.

## 1. Daily Explore (09:00 ICT)

**Schedule:** `0 2 * * *` UTC (= 09:00 Asia/Ho_Chi_Minh)  
**Does:** Scores ≤3 ideas, writes brief PR, creates GitHub issue via `gh`. No product code.

**Enable:**

1. Go to [cursor.com/automations/new](https://cursor.com/automations/new).
2. Import settings from `daily-explore.workflow.json` (schedule, repo, prompt).
3. Paste the **Agent Instructions** from the `prompt` field in that JSON (or use the prefill URL from `build_automation_prefill_url`).
4. Enable tools:
   - **Open pull request** — OFF for Daily Explore (use `gh pr create` in the prompt instead; the Open PR tool expects a `cursor/*` session branch and fails on `explore/*`)
   - **Memories** — optional (on by default in JSON)
5. Repository: `tienan92it/mindb`, branch `master`.
6. Save and enable.

**Dry run:** Trigger manually once. Expect a PR on `explore/YYYY-MM-DD`, one new brief under `aidlc-docs/explore/`, and a GitHub issue labeled `explore` (plus `planned` if score ≥ 7). Requires **`GH_TOKEN`** for `git push`, `gh pr create`, and `gh issue create`. If issue creation fails, look for `## Manual issue fallback` in the PR body.

**Troubleshooting:** Error *“This branch is not pushed to the remote… Expected remote branch: cursor/…”* means the agent used the Open pull request tool instead of `gh pr create`. Turn that tool off and re-paste the prompt from `daily-explore.workflow.json`.

## 2. Release Announce (webhook)

**Trigger:** Webhook — fired by `.github/workflows/release.yml` on tag `v*.*.*`  
**Does:** PR updating `docs/index.html` changelog.

**Enable:**

1. Create from `release-announce.workflow.json` at [cursor.com/automations/new](https://cursor.com/automations/new).
2. Trigger type: **Webhook**.
3. Enable **Open pull request**.
4. After save, copy webhook URL + API key.
5. Add GitHub repo secrets:
   - `CURSOR_ANNOUNCE_WEBHOOK_URL`
   - `CURSOR_ANNOUNCE_WEBHOOK_KEY`

## Files

| File | Purpose |
|------|---------|
| `daily-explore.workflow.json` | Daily explore agent prompt + schedule |
| `release-announce.workflow.json` | Landing changelog PR after release |

Full operating model: `aidlc-docs/product-workflow.md`
