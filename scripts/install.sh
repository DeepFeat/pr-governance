#!/usr/bin/env bash
# Install the pr-governance review workflow into a target repo.
#
# Usage:
#   ./scripts/install.sh <owner>/<repo> [--with-labeler]
#
# What it does:
#   1. Resolves pr-governance's current main commit SHA (always the latest,
#      not a hand-copied stale value).
#   2. Writes .github/workflows/pr-review.yml into the target repo on a new
#      branch, pinned to that SHA.
#   3. --with-labeler also adds pr-security-label.yml (only makes sense for
#      repos with actual application code, not docs-only repos).
#   4. Pushes the branch and opens a PR. If the target repo's default branch
#      currently has NO branch protection (e.g. mid-setup), you can merge
#      that PR immediately yourself with no approval needed. If protection
#      is on, this is the repo's first PR introducing the workflow, so it
#      needs a real human approval once (the bot can't approve the PR that
#      introduces its own review capability -- same reason deepfeat#403 and
#      pr-governance#1 needed manual approval).
#
# Requires: gh CLI authenticated with repo + workflow scopes.

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <owner>/<repo> [--with-labeler]" >&2
  exit 1
fi

TARGET="$1"
WITH_LABELER=false
if [ "${2:-}" = "--with-labeler" ]; then
  WITH_LABELER=true
fi

PR_GOV_SHA=$(gh api repos/DeepFeat/pr-governance/commits/main --jq '.sha')
echo "Using pr-governance @ $PR_GOV_SHA"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "Cloning $TARGET..."
gh repo clone "$TARGET" "$TMPDIR/repo" -- --quiet
cd "$TMPDIR/repo"

if [ -f ".github/workflows/pr-review.yml" ]; then
  echo "pr-review.yml already exists in $TARGET -- nothing to do."
  exit 0
fi

git checkout -b ci/install-pr-governance-review

mkdir -p .github/workflows
cat > .github/workflows/pr-review.yml <<EOF
name: PR Review

# Thin wrapper around DeepFeat/pr-governance's reusable review workflow.
# Installed via pr-governance/scripts/install.sh -- see that repo's
# docs/change-management-compensating-control-policy.md for the rationale.

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  review:
    if: github.event.pull_request.draft == false
    permissions:
      contents: read
      pull-requests: write
      issues: write
      id-token: write # required by anthropics/claude-code-action@v1's own OIDC auth
    uses: DeepFeat/pr-governance/.github/workflows/review.yml@${PR_GOV_SHA}
    secrets: inherit
EOF

if [ "$WITH_LABELER" = true ]; then
  cat > .github/workflows/pr-security-label.yml <<EOF
name: Security-Relevant Label

# Thin wrapper around DeepFeat/pr-governance's reusable auto-labeler.
# Installed via pr-governance/scripts/install.sh -- edit sensitive_paths
# below to match this repo's actual structure before relying on it.

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  label:
    if: github.event.pull_request.draft == false
    permissions:
      contents: read
      pull-requests: write
    uses: DeepFeat/pr-governance/.github/workflows/auto-label.yml@${PR_GOV_SHA}
    secrets: inherit
    with:
      sensitive_paths: |
        # TODO: fill in this repo's actual sensitive paths (auth, access
        # control, infra, data handling) before this label means anything.
        src/auth/**
EOF
fi

git add .github/workflows/
git commit -m "ci: install pr-governance review workflow" -q
git push -u origin ci/install-pr-governance-review -q

gh pr create \
  --title "ci: install pr-governance review workflow" \
  --body "Installed via pr-governance/scripts/install.sh, pinned to DeepFeat/pr-governance@${PR_GOV_SHA}." \
  2>&1

echo ""
echo "Done. If this repo's branch protection is currently off, you can merge"
echo "that PR immediately with no approval needed. If protection is on, it"
echo "needs one human approval -- the bot can't approve the PR that"
echo "introduces its own review capability."
