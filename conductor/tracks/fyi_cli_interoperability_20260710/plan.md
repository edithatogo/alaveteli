# Implementation Plan: fyi-cli Interoperability

## Phase 1: Contract evidence

- [x] Issue #24: Audit and publish the exact server/client contract in PR #46.
- [x] Record the paired fyi-cli issue #142 and contract version 0.1 in this plan.
- [x] Add focused streamed-response sensors for the private, ETag-only bulk
  export contract.
- [x] Verify no live network is required by the contract suite.

> CHECKPOINT (2026-07-24): The server contract suite uses controller/request
> doubles, factories, and the offline `spec/fixtures/fyi_cli_contract_cases.yml`
> manifest; it contains no HTTP client, VCR cassette, or live endpoint call.
> Hosted CI run `29832274405` passed the controller, request, and full Ruby
> matrices on `develop` at `6b516f5a`. Local replay was attempted with the
> pinned `commonlib` submodule initialized, but this checkout lacks generated
> `config/database.yml`; hosted setup remains the authoritative runtime evidence.

> Provenance (2026-07-20): PR #46 was reconstructed from the clean PR #33 head
> `8295e2a9b693b6e32553abe02fc7f365d4692e26`. The stale branch was not replayed;
> runtime code, `scripts/profile_runner.rb`, and workflows are outside this
> task. Issue #47 concerns HEAD cache-control semantics and is not provenance
> for this contract publication.

## Phase 2: Server conformance fixtures

- [ ] Issue #25: Add focused fixtures/specs for back-pressure, 304, and bulk export.
- Paired fyi-cli issue: https://github.com/edithatogo/fyi-cli/issues/142
- Paired fyi-cli draft PR: https://github.com/edithatogo/fyi-cli/pull/150
- [ ] Test absent, malformed, degraded, throttled, conditional, and bounded cases.
- Paired fyi-cli cache/bulk issue: https://github.com/edithatogo/fyi-cli/issues/143
- Paired fyi-cli bounded bulk draft PR: https://github.com/edithatogo/fyi-cli/pull/152
- [ ] Run RuboCop, Brakeman, dependency audit, and focused tests with zero untriaged findings.

## Phase 3: Identity and operations

- [ ] Issue #26: Define token, User-Agent, rotation, and staged rollout behavior.
- [ ] Prove no secret appears in logs, traces, fixtures, or errors.
- [ ] Add rollback and disablement runbook steps.

## Phase 4: Cross-repo verification

- [ ] Issue #27: Reconcile the paired fyi-cli implementation evidence.
- [ ] Run the shared offline contract suite and only an explicitly enabled bounded smoke test.
- [ ] Close this track only when every known risk is fixed, verified false positive, or blocked by a dated disabled follow-up.

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
