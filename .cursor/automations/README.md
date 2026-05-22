# Cursor Automations

Workflow drafts for the mindb product loop. Confirm in Cursor UI before enabling.

## 1. Daily Explore (09:00 ICT)

**Schedule:** `0 2 * * *` UTC (= 09:00 Asia/Ho_Chi_Minh)  
**Does:** Scores ≤3 ideas, writes brief PR, opens GitHub issue. No product code.

**Enable:**

1. Go to [cursor.com/automations/new](https://cursor.com/automations/new).
2. Import settings from `daily-explore.workflow.json` (schedule, repo, prompt).
3. Enable tools: **Open pull request**, GitHub issues.
4. Repository: `tienan92it/mindb`, branch `master`.
5. Save and enable.

Or run locally:

```bash
# Opens prefill in browser (requires Cursor MCP or manual copy from workflow JSON)
open "https://cursor.com/automations/new"
```

## 2. Release Announce (webhook)

**Trigger:** Webhook — fired by `.github/workflows/release.yml` on tag `v*.*.*`  
**Does:** PR updating `docs/index.html` changelog.

**Enable:**

1. Create from `release-announce.workflow.json` at [cursor.com/automations/new](https://cursor.com/automations/new).
2. Trigger type: **Webhook**.
3. After save, copy webhook URL + API key.
4. Add GitHub repo secrets:
   - `CURSOR_ANNOUNCE_WEBHOOK_URL`
   - `CURSOR_ANNOUNCE_WEBHOOK_KEY`

## Files

| File | Purpose |
|------|---------|
| `daily-explore.workflow.json` | Daily explore agent prompt + schedule |
| `release-announce.workflow.json` | Landing changelog PR after release |

Full operating model: `aidlc-docs/product-workflow.md`
