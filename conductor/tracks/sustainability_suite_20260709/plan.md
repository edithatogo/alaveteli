# Implementation Plan - Sustainability Suite for Scraper Traffic

## Phase 1: Rack::Attack Middleware [checkpoint: c744ef9]

- [x] Task: Rack::Attack Initializer Configuration [5116ea3]
    - [x] Write tests verifying verified bot header bypass and anonymous IP rate limiting
    - [x] Create `config/initializers/rack_attack.rb` and configure Redis store
    - [x] Implement rate-limit thresholds (10rpm for anonymous, 100rpm for verified bots)
- [x] Task: Fail2Ban Setup [5116ea3]
    - [x] Write tests for blocking IPs triggering multiple 429 status codes
    - [x] Configure Fail2Ban in Rack::Attack to block IPs for 10 minutes after 5 limit violations in 60 seconds
- [x] Task: Resiliency and Dynamic Limits [5116ea3]
    - [x] Implement Redis circuit-breaker fallback to local memory in the initializer
    - [x] Implement dynamic load monitoring to decrease limits to 2rpm under high server load
- [x] Task: Conductor - User Manual Verification 'Phase 1: Rack::Attack Middleware' (Protocol in workflow.md) [c744ef9]

## Phase 2: Traffic Control Concern [checkpoint: 18e0f55]

- [x] Task: Traffic Control Controller Concern [2200cf5]
    - [x] Write controller specs verifying injection of RFC rate limit headers
    - [x] Implement `app/controllers/concerns/traffic_control.rb` with header injection and advisory degradation headers
    - [x] Include concern in ApplicationController
- [x] Task: HTTP Caching Headers [2200cf5]
    - [x] Write specs verifying ETag and Last-Modified header responses
    - [x] Implement ETag caching for public requests/directories returning 304 Not Modified
- [x] Task: Conductor - User Manual Verification 'Phase 2: Traffic Control Concern' (Protocol in workflow.md) [18e0f55]

## Phase 3: Rate Limit & Bulk Export API [checkpoint: 90842d9]

- [x] Task: Rate Limit API Endpoint [36ea5af]
    - [x] Write routing and API controller tests verifying rate limit JSON output
    - [x] Implement `/api/v1/rate_limit` endpoint and configure its routes
- [x] Task: Bulk Export API Endpoint [36ea5af]
    - [x] Write specs verifying NDJSON formatted output for bulk extraction
    - [x] Implement `/api/v1/bulk_export` endpoint to support bulk extraction
- [x] Task: Conductor - User Manual Verification 'Phase 3: Rate Limit & Bulk Export API' (Protocol in workflow.md) [90842d9]

## Phase 4: Sidekiq Traffic Prioritization [checkpoint: ef15f49]

- [x] Task: Route Expensive Requests to Bulk Queue [e6c8d46]
    - [x] Write worker/request tests verifying queue redirection for unverified bot requests
    - [x] Implement Sidekiq queue routing logic redirecting expensive operations to the `bulk_processor` queue
- [x] Task: Conductor - User Manual Verification 'Phase 4: Sidekiq Traffic Prioritization' (Protocol in workflow.md) [ef15f49]

## Phase 5: fyi-cli Integration (Client-Side Updates)

> Historical note: the client-side tasks below were recorded against commit `e35c682`, which is not present in this repository. Their independent implementation and verification now belong to the paired fyi-cli track `fyi_cli_interoperability_20260710` and GitHub parent issue [#23](https://github.com/edithatogo/alaveteli/issues/23), paired with fyi-cli issue [#140](https://github.com/edithatogo/fyi-cli/issues/140). This track remains the server-side implementation record; the cross-repo track must close the evidence gap before client interoperability is claimed.

- [x] Task: Client-Side Rate-Limit Awareness [e35c682]
    - [x] Add rate-limit header parsing and dynamic back-off in the `fyi-cli` request client
    - [x] Add support for honoring `Retry-After` and `X-Advisory-Status`
- [x] Task: Client-Side Caching (ETag Support) [e35c682]
    - [x] Implement local database cache in `fyi-cli` to store resource ETags
    - [x] Send `If-None-Match` headers on subsequent runs and handle 304 responses
- [x] Task: Client-Side Bulk Mode [e35c682]
    - [x] Update `fyi-cli` synchronization logic to use the new `/api/v1/bulk_export` endpoint
- [x] Task: Conductor - User Manual Verification 'Phase 5: fyi-cli Integration (Client-Side Updates)' (Protocol in workflow.md) [e35c682]

## Phase 6: Orchestration Updates [checkpoint: b97b9f3]

- [x] Task: Conductor Scripts and Task Simulation [62e0ba5]
    - [x] Add Redis service health-check script in Docker Compose startup sequence
    - [x] Add `simulate-attack` script task to `conductor.json`
- [x] Task: Conductor - User Manual Verification 'Phase 6: Orchestration Updates' (Protocol in workflow.md) [b97b9f3]

## Phase 7: Upstream endpoint reconciliation

- [~] Task: Establish the upstream read-only sustainability endpoint foundation
    - Fork issue: https://github.com/edithatogo/alaveteli/issues/39
    - Upstream issue: https://github.com/mysociety/alaveteli/issues/9377
    - Fork PR: https://github.com/edithatogo/alaveteli/pull/40
    - Upstream draft PR: https://github.com/mysociety/alaveteli/pull/9378
    - The implementation is based directly on upstream `develop` and is
      limited to the route, controller, focused specs, and existing
      `AlaveteliRateLimiter` integration. Bulk export, client integration, and
      dependency migration remain separate child work.
- [x] Task: Address endpoint review edge cases [e79cd7b2d]
    - [x] Validate malformed and spoofed client addresses before limiter access.
    - [x] Verify non-cacheable `400`/`503` responses and over-limit reset math.
- [ ] Task: Obtain upstream workflow approval and complete CI, RuboCop, and
  Changelog checks with no action-required state.
    - Current blocker: fork-origin workflow runs require upstream repository
      administrator approval; the current token cannot approve them.
- [ ] Task: Run the focused RSpec locally after the native
  `xapian-full-alaveteli` dependency is available in the user-local bundle.
    - Ruby 3.4.9 syntax checks and `git diff --check` pass.
- [~] Task: Establish fork-owned manual GitHub validation dispatch
    - Harness PR: https://github.com/edithatogo/alaveteli/pull/41
    - The existing CI, RuboCop, Security & DevSecOps, and Changelog workflows
      now support manual dispatch without changing their validation commands.
    - Fork evidence: Ruby 3.4 gem specs pass; Ruby 3.4 core specs remain in
      progress. The full Ruby 3.4 core run completed with 41 baseline failures;
      Ruby 4 preview jobs also fail, while Brakeman and dependency audit expose
      pre-existing findings. Dependency Review is unavailable because
      dependency graph is disabled in the fork.
    - Baseline remediation is tracked separately in fork issues #18
      (dependency audit), #19 (Brakeman), #30 (Rack/WEBrick), and #31
      (Sprockets/Rack asset migration).
    - Brakeman child issue #42 and draft PR #43 remove the profiler parser
      error without changing the ignore file; the parent warning backlog still
      prevents a green security gate.
    - The next high-severity Brakeman finding is decomposed into fork issue
      #44 and upstream issue #9379 for a compatibility-first cookie serializer
      migration. No one-line `:hybrid` replacement is permitted without
      session, authentication, CSRF, migration, and rollback evidence.
    - Draft design PR: https://github.com/edithatogo/alaveteli/pull/45.
      Runtime serializer changes remain blocked until this design gate is
      reviewed.
    - Brakeman child issue #47 and draft PR #48 remediate the
      `TrafficControl#public_cache_control` HEAD verb-confusion finding with
      one focused behavior spec. Focused run
      https://github.com/edithatogo/alaveteli/actions/runs/29148478445 passes
      (14 examples, 0 failures); full Brakeman run
      https://github.com/edithatogo/alaveteli/actions/runs/29148478030 drops
      from 31 to 30 warnings and reports no remaining warning for
      `traffic_control.rb`. The parent security gate remains open.
    - Brakeman child issue #49 and draft PR #50 isolate request ZIP cache
      filenames from URL titles and use a fixed response filename. Focused
      run https://github.com/edithatogo/alaveteli/actions/runs/29148912185
      passes; full Brakeman still reports the model-derived cache path through
      `send_file`. Follow-up issue #51 owns that remaining path-flow warning;
      no suppression is permitted.
    - Child issue #51 and stacked draft PR #52 move cache paths behind a
      bounded SHA-256 route key and a primitive path builder. Focused run
      https://github.com/edithatogo/alaveteli/actions/runs/29150162888 passes;
      a pure path service, hashed version key, suffix allowlist, and Rails
      boundary normalization were also exercised. Full Brakeman run
      https://github.com/edithatogo/alaveteli/actions/runs/29150267630 still
      traces the model through `send_file` and `FileUtils.mkdir_p`, so the two
      request-controller warnings remain open. Further work requires a larger
      delivery redesign or explicitly reviewed proof; no scanner suppression
      or false-positive reclassification was made.
    - [ ] Child issue #53 is the next delivery-boundary gate, linked to #51
      and stacked PR #52. It must move filesystem ownership out of the
      model-derived controller flow or provide an explicitly reviewed proof
      that the scanner's dataflow is bounded. The gate stays open until
      Brakeman reports zero request-controller FileAccess and SendFile
      warnings without ignores, while focused authorization, visibility,
      cache-invalidation, and path-boundary tests remain green. No upstream
      submission or closure of #51/#52 is permitted before this evidence is
      complete. Design invariants and rejected shortcuts are recorded in
      `zip_delivery_boundary.md`.
    - [~] Implementation slice in stacked PR #52 (`66c25de49` through
      `85b4c2168`) moves cache creation, locking, permissions, and atomic
      publication into `RequestZipDelivery`, adds a focused service sensor,
      and initializes the disposable rate-limiter store in the focused
      workflow. Hosted contract run
      https://github.com/edithatogo/alaveteli/actions/runs/29152282061
      passes with 78 examples and 0 failures, including exclusive-lock,
      partial-artifact cleanup, and request-update cache-invalidation
      integration coverage. Latest Brakeman run
      https://github.com/edithatogo/alaveteli/actions/runs/29152283800
      reports 29 baseline warnings and no request-controller or
      `request_zip_delivery.rb` FileAccess/SendFile finding. Full repository
      security and dependency gates remain red; Ruby 3.4 core CI is still in
      progress in the hosted run. That core job ran for roughly ten hours
      without completing, was cancelled as a stale sensor, and GitHub has not
      yet released the workflow for rerun. Ruby 4 preview fails at toolchain
      installation. Keep #52 draft and do not close #53 until a fresh core run
      and the repository-wide gates are evidenced.
    - [ ] Baseline full-suite blockers are decomposed into fork issues #56
      (Alaveteli Pro batch parameter TypeError), #57 (rate-control/Xapian test
      isolation), and #59 (Brakeman and dependency audit remediation). These
      remain separate from PR #52 and must not be waived as baseline risk.
    - [~] Issue #56 is implemented in draft fork PR #61. The controller now
      normalizes exactly one array value before the permit boundary and rejects
      ambiguous multi-value input. Hosted focused run
      https://github.com/edithatogo/alaveteli/actions/runs/29190840378 passes
      with 47 examples and 0 failures. Full CI and security gates remain
      separate blockers.
    - [~] Fork issue #58 tracks the unsupported Ruby 4.0.0-preview1 matrix
      entry. Draft fork PR #60 changes only the experimental matrix entries to
      supported Ruby 4.0.0-preview3 and requires hosted proof of installation
      without masking Ruby 3.4 failures.
    - Initial inventory identifies `_wdtk_cookie_session` as the cookie-store
      session and direct unsigned consumers for locale, request/body IDs, and
      widget votes. No direct signed/encrypted cookie call sites were found;
      key rotation and legacy-cookie behavior remain design gates.
    - Do not suppress or reclassify these baseline findings in the endpoint PR.
- [x] Task: Run the focused sustainability controller suite in a hosted Linux
  environment [3e63d8506]
    - Focused harness run: https://github.com/edithatogo/alaveteli/actions/runs/29146357879
    - Ruby 3.4 / PostgreSQL 13.5: 6 examples, 0 failures.
    - The disposable harness initializes the existing `commonlib` submodule;
      this setup correction is not part of the endpoint PR.
