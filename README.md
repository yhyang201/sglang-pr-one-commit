# SGLang PR to Patch Converter

This project fetches Pull Requests from [sgl-project/sglang](https://github.com/sgl-project/sglang), squashes them into a single commit, and exports them as patch files.

## Features

- Automate PR fetching
- Squash commits
- Export patch files
- Archive in `commit/[pr_number/100]00+/pr_number.patch` structure

## Usage

### GitHub Actions (Recommended)

This repository includes a scheduled workflow that scans for new PRs periodically.
You can also manually trigger the "Convert PR to Patch" workflow:

1. Go to the "Actions" tab.
2. Select "Convert PR to Patch".
3. Click "Run workflow".
4. Enter the PR ID (e.g., `14717`) or leave empty to scan recent PRs.

### Local Execution

```bash
chmod +x scripts/process_pr.sh
./scripts/process_pr.sh <PR_ID>
```

Example:

```bash
./scripts/process_pr.sh 14717
```

## Directory Structure

```
.
├── commit/             # Generated patch files
│   └── ...
├── scripts/
│   ├── process_pr.sh   # Core processing script
│   └── scan_prs.sh     # Scanner script
└── .github/
    └── workflows/      # GitHub Action definitions
```
