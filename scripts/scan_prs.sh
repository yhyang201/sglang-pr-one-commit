#!/bin/bash

# Configuration
LIMIT=8000
MIN_PR_ID=10000
REPO="sgl-project/sglang"

echo "Scanning last $LIMIT PRs from $REPO (Targeting PRs >= $MIN_PR_ID)..."

if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed."
    exit 1
fi

# Fetch PRs with necessary metadata: number, headRefOid (SHA), author, updatedAt
# Output format: number|headRefOid|authorLogin|updatedAt
echo "Fetching PR list..."
PR_DATA=$(gh pr list --repo "$REPO" --state all --limit "$LIMIT" \
    --json number,headRefOid,author,updatedAt \
    --template '{{range .}}{{printf "%v|%v|%v|%v\n" .number .headRefOid .author.login .updatedAt}}{{end}}')

# Loop through each line
echo "$PR_DATA" | while IFS='|' read -r PR_ID HEAD_SHA AUTHOR UPDATED_AT; do
    # Skip empty lines
    [ -z "$PR_ID" ] && continue

    # Check minimum PR ID
    if [ "$PR_ID" -lt "$MIN_PR_ID" ]; then
        continue
    fi

    DIR_INDEX=$((PR_ID / 100))
    PATCH_FILE="commit/${DIR_INDEX}00+/${PR_ID}.patch"
    
    NEEDS_UPDATE=false
    
    if [ ! -f "$PATCH_FILE" ]; then
        echo "[NEW] PR #${PR_ID} (Author: $AUTHOR)"
        NEEDS_UPDATE=true
    else
        # Check if the local patch records the same commit hash
        # We look for "Original-Commit-Hash: <SHA>" in the patch file
        LOCAL_SHA=$(grep "Original-Commit-Hash:" "$PATCH_FILE" | awk '{print $2}')
        
        if [ "$LOCAL_SHA" != "$HEAD_SHA" ]; then
            echo "[UPDATE] PR #${PR_ID} changed ($LOCAL_SHA -> $HEAD_SHA)"
            NEEDS_UPDATE=true
        else
            # echo "[SKIP] PR #${PR_ID} is up to date"
            :
        fi
    fi

    if [ "$NEEDS_UPDATE" = true ]; then
        # Export variables for process_pr.sh
        export PR_AUTHOR="$AUTHOR"
        export PR_UPDATED_AT="$UPDATED_AT"
        export PR_HEAD_SHA="$HEAD_SHA"
        
        # Allow failure for individual PRs
        ./scripts/process_pr.sh "$PR_ID" || echo "Failed to process PR #${PR_ID}"
    fi
done
