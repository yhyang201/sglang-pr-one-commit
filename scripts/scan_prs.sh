#!/bin/bash

# Limit scan to recent PRs
LIMIT=50
REPO="sgl-project/sglang"

echo "Scanning last $LIMIT PRs from $REPO..."

if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed."
    exit 1
fi

# Get recent PR numbers
PR_LIST=$(gh pr list --repo "$REPO" --state all --limit "$LIMIT" --json number --jq '.[].number')

for PR_ID in $PR_LIST; do
    DIR_INDEX=$((PR_ID / 100))
    PATCH_FILE="commit/${DIR_INDEX}00+/${PR_ID}.patch"
    
    if [ ! -f "$PATCH_FILE" ]; then
        echo "Processing new PR #${PR_ID}..."
        # Allow failure for individual PRs
        ./scripts/process_pr.sh "$PR_ID" || echo "Failed to process PR #${PR_ID}"
    fi
done
