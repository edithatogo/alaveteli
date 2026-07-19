# Specification: Request-State Taxonomy Retrospective

## Overview

Record the already-completed fork-local delivery of issue
[#68](https://github.com/edithatogo/alaveteli/issues/68) through merged pull
request [#69](https://github.com/edithatogo/alaveteli/pull/69). This is a
retrospective governance track. It does not change application behavior.

## Authoritative Inputs

- Fork issue #68, closed by PR #69.
- PR #69, merged to `develop` as commit
  `f593584b1166841f78ab2bcd7d2226fc36f1cdd5`.
- Exact pre-merge base commit
  `fac3f622ab4672da10fc438cadb14f3141f7b394`.
- Hosted CI runs `29070480896` and `29070480890` for the exact base.
- Hosted CI runs `29666792936` and `29666792949` for PR #69.

## Requirements

1. Preserve the distinction between Alaveteli process/platform/admin/calculated
   states and jurisdiction-specific legal outcomes.
2. Record that optional theme-owned process-clock metadata is omitted when
   empty and exposed only when supplied.
3. Pin implementation provenance to issue #68, PR #69, the exact base, and the
   merge commit.
4. State the exact-base non-regression result without claiming a green baseline.
5. Keep upstream `mysociety/alaveteli` references as provenance only and make no
   upstream change or acceptance claim.

## Acceptance Criteria

- The completed issue and merged PR are linked from a canonical archived track.
- The plan, metadata, evidence report, ledger, and registry agree that the track
  is completed.
- Evidence records 41 Ruby 3.4 core failures on both the exact base and PR head.
- Evidence records the inherited failing security baseline, including 31
  Brakeman warnings on both revisions.
- Validation must not describe the repository baseline as green.

## Non-Functional Constraints

- Governance-only repository changes.
- No production code, tests, dependencies, workflows, or upstream refs changed.
- No claim that inherited failures are resolved, accepted, or newly introduced.

## External Gates

The original implementation was merged before this retrospective track. Hosted
checks for this governance-only PR determine whether this track can be merged;
inherited application/security failures are baseline evidence, not green checks.

## Out of Scope

- Fixing the 41 inherited Ruby 3.4 failures.
- Triaging or remediating the inherited security baseline.
- Changing request-state semantics or process-clock behavior.
- Opening or modifying anything in `mysociety/alaveteli`.
