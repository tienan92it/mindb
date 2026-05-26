#!/usr/bin/env bash
# Close orphaned explore tracking issues when linked docs PRs are no longer open.
set -euo pipefail

REPO="${1:-${GITHUB_REPOSITORY:-tienan92it/mindb}}"
SHIP_ISSUE="${2:-}"

close_if_open() {
  local issue="$1"
  local comment="$2"
  local state
  state=$(gh issue view "$issue" --repo "$REPO" --json state --jq .state 2>/dev/null || echo "")
  if [ "$state" = "OPEN" ]; then
    echo "Closing issue #$issue"
    gh issue close "$issue" --repo "$REPO" --comment "$comment"
  fi
}

pr_urls_closed() {
  local body="$1"
  local pr url num state
  while IFS= read -r url; do
    [ -z "$url" ] && continue
    num=$(echo "$url" | grep -oE '[0-9]+$')
    state=$(gh pr view "$num" --repo "$REPO" --json state --jq .state 2>/dev/null || echo "")
    if [ "$state" = "OPEN" ]; then
      return 1
    fi
  done < <(echo "$body" | grep -oE 'https://github.com/[^/]+/[^/]+/pull/[0-9]+' || true)
  return 0
}

# [business] Scan trackers — close when linked scan PR is merged/closed.
while IFS= read -r line; do
  [ -z "$line" ] && continue
  num=$(echo "$line" | jq -r .number)
  body=$(echo "$line" | jq -r .body)
  title=$(echo "$line" | jq -r .title)
  if echo "$title" | grep -qE '\[business\].*Scan'; then
    if pr_urls_closed "$body"; then
      close_if_open "$num" "Housekeeping: linked scan PR merged or closed."
    fi
  fi
done < <(
  gh issue list --repo "$REPO" --state open --label explore --json number,title,body --limit 100 \
    | jq -c '.[] | select(.title | test("\\[business\\].*Scan"))'
)

# Digest issues — close when all linked docs PRs are merged/closed.
while IFS= read -r line; do
  [ -z "$line" ] && continue
  num=$(echo "$line" | jq -r .number)
  body=$(echo "$line" | jq -r .body)
  title=$(echo "$line" | jq -r .title)
  if echo "$title" | grep -q 'digest — no ship'; then
    if pr_urls_closed "$body"; then
      close_if_open "$num" "Housekeeping: digest docs PRs merged or closed."
    fi
  fi
done < <(
  gh issue list --repo "$REPO" --state open --label explore --json number,title,body --limit 100 \
    | jq -c '.[] | select(.title | test("digest — no ship"))'
)

# After ship — close scan trackers referenced on the ship issue thread.
if [ -n "$SHIP_ISSUE" ]; then
  TEXT=$(gh issue view "$SHIP_ISSUE" --repo "$REPO" --json body,comments \
    --jq '[.body] + [.comments[].body] | join("\n")')
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    title=$(gh issue view "$ref" --repo "$REPO" --json title --jq .title 2>/dev/null || echo "")
    if echo "$title" | grep -qE '\[business\].*Scan'; then
      close_if_open "$ref" "Housekeeping: ship issue #${SHIP_ISSUE} delivered."
    fi
  done < <(echo "$TEXT" | grep -oE 'https://github.com/[^/]+/[^/]+/issues/[0-9]+' | grep -oE '[0-9]+$' | sort -u)
fi
