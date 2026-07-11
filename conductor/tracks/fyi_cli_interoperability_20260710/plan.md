# Implementation Plan: fyi-cli Interoperability

## Phase 1: Contract evidence [checkpoint: 13ec754f0]

- [x] Issue #24: Audit and publish the exact server/client contract [13ec754f0].
  - Fork-only draft PR: https://github.com/edithatogo/alaveteli/pull/46
- [x] Record the paired fyi-cli issue and contract version in this plan.
  - Paired issue: https://github.com/edithatogo/fyi-cli/issues/142 (closed)
  - Paired PR: https://github.com/edithatogo/fyi-cli/pull/150 (merged)
  - Contract version: `doc/fyi_cli_contract.md` version `0.1`
- [x] Add a drift sensor for every documented header and endpoint behavior.
  - The fork-owned workflow runs the rate-limit, back-pressure, cache,
    bulk-export, and parameter-contract specs.
- [x] Verify no live network is required by the contract suite.
  - Hosted run: https://github.com/edithatogo/alaveteli/actions/runs/29148244853
  - Result: Ruby 3.4/PostgreSQL 13.5, 19 examples, 0 failures.

## Phase 2: Server conformance fixtures

- [ ] Issue #25: Add focused fixtures/specs for back-pressure, 304, and bulk export.
- Paired fyi-cli issue: https://github.com/edithatogo/fyi-cli/issues/142
- Paired fyi-cli draft PR: https://github.com/edithatogo/fyi-cli/pull/150
- [ ] Test absent, malformed, degraded, throttled, conditional, and bounded cases.
- Paired fyi-cli cache/bulk issue: https://github.com/edithatogo/fyi-cli/issues/143
- Paired fyi-cli bounded bulk draft PR: https://github.com/edithatogo/fyi-cli/pull/152
- Paired Alaveteli validator draft PR: https://github.com/edithatogo/alaveteli/pull/29
- Validator PR syntax checks pass; focused Rails/RuboCop/Brakeman gates remain
  blocked by the locked native `xapian-full-alaveteli` dependency on this
  Windows workstation.
- Dependency audit also has a blocking child issue, Alaveteli #30, for the
  `rackup`/Rack migration needed to remove the vulnerable transitive `webrick`
  path. The isolated resolver failure is decomposed into Alaveteli #31 for the
  Sprockets/Rack asset-pipeline migration; no scanner suppression is permitted.
- Migration assessment: `conductor/tracks/export_optimization_20260710/rack_sprockets_migration_assessment.md`.
- [ ] Run RuboCop, Brakeman, dependency audit, and focused tests with zero untriaged findings.

## Phase 3: Identity and operations

- [ ] Issue #26: Define token, User-Agent, rotation, and staged rollout behavior.
- [ ] Prove no secret appears in logs, traces, fixtures, or errors.
- [ ] Add rollback and disablement runbook steps.

## Phase 4: Cross-repo verification

- [ ] Issue #27: Reconcile the paired fyi-cli implementation evidence.
- [ ] Run the shared offline contract suite and only an explicitly enabled bounded smoke test.
- [ ] Close this track only when every known risk is fixed, verified false positive, or blocked by a dated disabled follow-up.

## Current blockers

- PR #46 remains draft until the repository-wide Brakeman, dependency-audit,
  Dependency Review, and preview-Ruby baseline findings are resolved or have
  explicit dated child issues. No finding is suppressed.
- Issue #25 remains open for the server-side conformance fixture slice; this
  Phase 1 contract artifact does not close production behavior gaps.

## Paired endorsed-route proposal

- Fork-local Alaveteli planning issue: https://github.com/edithatogo/alaveteli/issues/28
- Paired fyi-cli planning issue: https://github.com/edithatogo/fyi-cli/issues/148
- Paired Conductor track: `conductor/tracks/endorsed_client_route_20260710/`
- Upstream Alaveteli issue/PR creation remains disabled until the shared
  evidence gate passes.

## PR standard

One child issue maps to one PR. Each PR must state scope, non-scope, test-first
evidence, security/quality sensors, rollback, and harness changes. Parent and
paired issue links are mandatory. No child issue is closed by a documentation
claim alone when production behavior remains unverified.
