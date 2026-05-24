#!/usr/bin/env bash
# Merge open explore/* and plan/* docs PRs linked to a shipped issue.
set -euo pipefail

ISSUE="${1:?Usage: merge-docs-for-issue.sh ISSUE [REPO]}"
REPO="${2:-${GITHUB_REPOSITORY:-tienan92it/mindb}}"

merge_pr() {
  local pr="$1"
  local state head
  state=$(gh pr view "$pr" --repo "$REPO" --json state --jq .state 2>/dev/null || echo "")
  [ "$state" != "OPEN" ] && return 0
  head=$(gh pr view "$pr" --repo "$REPO" --json headRefName --jq .headRefName)
  if [[ "$head" == explore/* ]] || [[ "$head" == plan/* ]]; then
    echo "Merging docs PR #$pr ($head) for issue #$ISSUE"
    gh pr merge "$pr" --repo "$REPO" --squash --delete-branch
  fi
}

# 1) Open PRs labeled docs that reference this ship issue
while IFS= read -r pr; do
  [ -n "$pr" ] && merge_pr "$pr"
done < <(
  gh pr list --repo "$REPO" --state open --label docs --json number,body \
    --jq ".[] | select(.body | test(\"Ship issue: #${ISSUE}([^0-9]|$)\")) | .number"
)

# 2) PR URLs in issue body and comments
TEXT=$(gh issue view "$ISSUE" --repo "$REPO" --json body,comments \
  --jq '[.body] + [.comments[].body] | join("\n")')

while IFS= read -r pr; do
  [ -n "$pr" ] && merge_pr "$pr"
done < <(echo "$TEXT" | grep -oE 'https://github.com/[^/]+/[^/]+/pull/[0-9]+' | grep -oE '[0-9]+$' | sort -u)
