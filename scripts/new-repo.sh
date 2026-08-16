#!/usr/bin/env bash
# Create a new DeepFeat repo, fully set up in one command:
#   1. Created from repo-template (pr-review.yml pre-installed, no
#      separate "install PR" needed).
#   2. Classic branch protection (enforce_admins) applied immediately --
#      this is the field Vanta's "branch protection enforced for
#      administrators" test actually reads. Not copied by "create from
#      template" -- repo settings never are, only files are -- so this
#      script applies it as a separate API call right after creation.
#
# The org-level ruleset (modern Rulesets, targets ~ALL repos) needs nothing
# here -- it's already live on any new repo automatically.
#
# Usage:
#   ./scripts/new-repo.sh <name> [--public]
#
# Requires: gh CLI authenticated with repo + workflow scopes.

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <name> [--public]" >&2
  exit 1
fi

NAME="$1"
VISIBILITY="--private"
if [ "${2:-}" = "--public" ]; then
  VISIBILITY="--public"
  echo "NOTE: public repo -- PR_REVIEW_ANTHROPIC_API_KEY won't be reachable" >&2
  echo "here (org secret visibility is 'private repos only', by design)." >&2
  echo "The review workflow will be installed but will fail until that's" >&2
  echo "addressed deliberately, not automatically." >&2
fi

echo "Creating DeepFeat/$NAME from repo-template..."
gh repo create "DeepFeat/$NAME" --template DeepFeat/repo-template $VISIBILITY 2>&1

echo "Applying classic branch protection..."
cat > /tmp/new-repo-protection-$$.json <<'EOF'
{
  "required_status_checks": null,
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_last_push_approval": true
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
EOF
gh api -X PUT "repos/DeepFeat/$NAME/branches/main/protection" --input /tmp/new-repo-protection-$$.json --jq '.enforce_admins.enabled' 2>&1
rm -f /tmp/new-repo-protection-$$.json

echo ""
echo "Done. DeepFeat/$NAME is ready:"
echo "  - pr-review.yml pre-installed, no install PR needed"
echo "  - classic branch protection (enforce_admins) applied"
echo "  - org-level ruleset already covers it automatically"
echo ""
echo "Still manual: edit README.md to drop the template boilerplate, and if"
echo "this repo has real app code, add pr-security-label.yml with this"
echo "repo's actual sensitive_paths (see scripts/install.sh's template)."
