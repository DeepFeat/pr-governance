# Compensating control: change management with one engineer

**Control:** SOC 2 `CC8.1` (Change Management) and `CC5.2` (General Controls
Over Technology) expect that changes to production systems are reviewed by
someone other than the person who made them, before they merge.

**The constraint:** DeepFeat, Inc. has one engineer (Ryan). Matt (co-founder)
is non-technical and cannot meaningfully review code for correctness. A
literal "every PR needs a human approval from someone else" requirement is
not achievable without either hiring, or a bottleneck that gets worked
around — which would be worse than not having the control at all.

**Why this matters more than it might seem:** a SOC 2 Type II audit samples
change records across the observation window and checks each one for an
approver who isn't the author. A single self-merged PR with zero approver in
that sample is a real exception on a critical control, regardless of
intent or overall practice quality.

## The two-part control this repo implements

1. **Every PR gets a real review, by something other than the author** — an
   AI reviewer (Claude, via `review.yml`) reads the diff against the repo's
   stated conventions, checks for bugs/security issues/missing tests, and
   submits a **formal GitHub review** (`--approve` or `--request-changes`).
   This is what satisfies "required approving review count" in branch
   protection without a human bottleneck on every routine change.

   **This is being explicit about what it is:** an AI system is the thing
   clicking "Approve" on most pull requests. That's a deliberate, documented
   choice, not something happening quietly. It closes the *sampling* risk
   (every change has *an* approver on record) — it does not replace human
   judgment on business risk, which is what part 2 is for.

2. **A human (Matt) reviews the changes that actually matter, on a real
   cadence** — PRs touching auth, access control, data handling, or infra
   get auto-labeled `security-relevant` (`auto-label.yml`), and once a month
   a summary issue is opened (`monthly-retro.yml`) for Matt to read through
   at a business-risk level — not "is this code correct," but "do I
   understand what changed and why, does this match what we're allowed to
   do." He closes the issue to sign off; the closed issue is the audit
   record, dated and attributed.

## Why not just require Matt's review on every PR?

A monthly batch review satisfies "someone independent looked at the
security-relevant changes on a real cadence," but it does **not** put an
approver on each individual change record — most PRs in an auditor's sample
would still show zero human approval if that were the only control. The two
parts above are deliberately different tools for different jobs: the AI
review closes the per-change sampling gap; the monthly retrospective is
where genuine independent human judgment happens, scoped to what a
non-technical reviewer can actually evaluate.

## When this should change

Once DeepFeat has a second engineer, `review.yml`'s AI approval should be
downgraded to "required check, not a substitute for human approval" —
i.e. move to Option A (gate on a status check) rather than Option B
(AI submits the approving review), and require a real second engineer's
approval instead. This document should be updated when that happens.
