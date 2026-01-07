#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <PR_ID>"
    exit 1
fi

PR_ID="$1"
REPO_URL="https://github.com/sgl-project/sglang.git"
WORK_DIR="sglang_temp_${PR_ID}"
BASE_BRANCH="main"

DIR_INDEX=$((PR_ID / 100))
OUTPUT_DIR="commit/${DIR_INDEX}00+"
OUTPUT_FILENAME="${PR_ID}.patch"
OUTPUT_PATH="${OUTPUT_DIR}/${OUTPUT_FILENAME}"

echo "=== Processing PR #${PR_ID} ==="

if [ -d "$WORK_DIR" ]; then
    rm -rf "$WORK_DIR"
fi

# Clone with filter to save time/space
git clone --filter=blob:none "$REPO_URL" "$WORK_DIR"

CURRENT_DIR=$(pwd)
ABS_OUTPUT_PATH="${CURRENT_DIR}/${OUTPUT_PATH}"

cd "$WORK_DIR"

git config user.email "action@github.com"
git config user.name "GitHub Action"

# Fetch PR
git fetch origin pull/${PR_ID}/head:pr-${PR_ID}-temp

git checkout pr-${PR_ID}-temp

# Fetch base for merge-base calculation
git fetch origin $BASE_BRANCH

MERGE_BASE=$(git merge-base HEAD origin/$BASE_BRANCH)

if [ -z "$MERGE_BASE" ]; then
    echo "Error: Could not find merge base."
    exit 1
fi

# Soft reset to squash
git reset --soft $MERGE_BASE

# Prepare commit message with metadata
COMMIT_MSG="feat: Squash PR #${PR_ID} changes"

if [ -n "$PR_AUTHOR" ]; then
    COMMIT_MSG="${COMMIT_MSG}

PR Author: ${PR_AUTHOR}"
fi

if [ -n "$PR_UPDATED_AT" ]; then
    COMMIT_MSG="${COMMIT_MSG}
PR Last Updated: ${PR_UPDATED_AT}"
fi

if [ -n "$PR_HEAD_SHA" ]; then
    COMMIT_MSG="${COMMIT_MSG}
Original-Commit-Hash: ${PR_HEAD_SHA}"
fi

git commit -m "$COMMIT_MSG"

mkdir -p "${CURRENT_DIR}/${OUTPUT_DIR}"

git format-patch -1 HEAD --stdout > "$ABS_OUTPUT_PATH"

cd "$CURRENT_DIR"
rm -rf "$WORK_DIR"

echo "=== Done! Patch created at $OUTPUT_PATH ==="
