# pr-governance

Reusable GitHub Actions workflows for PR-level change management controls,
shared across DeepFeat, Inc. repositories. Implements the
[Change Management Compensating Control Policy](docs/change-management-compensating-control-policy.md)
for `CC8.1` / `CC5.2` given a single-engineer team.

## What's here

| Workflow | Trigger (in the calling repo) | What it does |
|---|---|---|
| [`review.yml`](.github/workflows/review.yml) | `pull_request` | Claude reviews the diff and submits a **formal GitHub review** — `--approve` or `--request-changes` — not just a comment. This is what satisfies branch protection's required-approval count. |
| [`auto-label.yml`](.github/workflows/auto-label.yml) | `pull_request` | Applies a `security-relevant` label if the diff touches any path you configure as sensitive (auth, access control, infra, data handling). |
| [`monthly-retro.yml`](.github/workflows/monthly-retro.yml) | `schedule` (defined in the calling repo — GitHub only fires cron where the file lives) | Opens a GitHub Issue listing every `security-relevant` PR merged in the last ~30 days, assigned to a named human reviewer. Closing that issue is the sign-off; the closed issue is the audit record. |

## Using this from another repo

```yaml
# .github/workflows/pr-review.yml
name: PR Review
on:
  pull_request:
    types: [opened, synchronize, reopened]
jobs:
  review:
    uses: DeepFeat/pr-governance/.github/workflows/review.yml@main
    secrets: inherit
```

```yaml
# .github/workflows/pr-label.yml
name: Security-Relevant Label
on:
  pull_request:
    types: [opened, synchronize, reopened]
jobs:
  label:
    uses: DeepFeat/pr-governance/.github/workflows/auto-label.yml@main
    secrets: inherit
    with:
      sensitive_paths: |
        apps/api/core/middleware/**
        apps/api/core/services/cognito*.py
        platform/terraform/**
```

```yaml
# .github/workflows/monthly-retro.yml
name: Monthly Retrospective
on:
  schedule:
    - cron: "0 15 1 * *"   # 1st of each month, 15:00 UTC
  workflow_dispatch: {}     # lets you trigger it manually to test
jobs:
  retro:
    uses: DeepFeat/pr-governance/.github/workflows/monthly-retro.yml@main
    secrets: inherit
    with:
      reviewer: <github-username>
```

`secrets: inherit` passes the calling repo's own secrets through — `review.yml`
needs `ANTHROPIC_API_KEY` to exist as a secret in the *calling* repo, not here.

## Requirements in the calling repo

- `ANTHROPIC_API_KEY` secret (for `review.yml`)
- Branch protection / ruleset configured to require the `Review / Review`
  status and the `security-relevant` label workflow to run — see the
  org-level ruleset in `docs/compliance/` (deepfeat-soc2 worktree) for the
  actual configuration DeepFeat uses.
