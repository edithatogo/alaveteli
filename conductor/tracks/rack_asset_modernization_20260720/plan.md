# Implementation Plan: Staged Rack and Asset-Pipeline Modernization

Track contract: [spec.md](./spec.md)
GitHub parent issue: [#74](https://github.com/edithatogo/alaveteli/issues/74)
Delivery posture: non-release-blocking; one child issue and focused PR per
independently reversible implementation slice.

## Phase 0: Refresh and Decomposition

- [ ] **Task 0.1: Pin the starting baseline and superseded assessment**
  - Record the exact `origin/develop` revision, relevant lockfile entries,
    current scanner status, Ruby 3.4/4.0 CI matrix, and the disposition of PR
    #32 and issues #30/#31.
  - Produce a machine-readable inventory of direct and transitive dependencies
    in scope.
  - Trace to R1 and acceptance criteria 1 and 7.
- [ ] **Task 0.2: Create child issues and migration ownership boundaries**
  - Create separate child issues for resolver discovery, Sass replacement,
    asset sensors, asset-pipeline migration, Rack middleware sensors, Rack
    migration, and deployment/performance evidence.
  - Cross-reference each child issue to #74 and this track; define one focused
    PR and rollback boundary per implementation unit.
  - Trace to R2 and acceptance criterion 2.
- [ ] **Task 0.3: Automated review and Phase 0 validation checkpoint**
  - Review track traceability, issue decomposition, baseline evidence, and
    non-release-blocking language.
  - Validate Markdown links, JSON/JSONL, clean diffs, and registry consistency.

## Phase 1: Resolver Matrix and Migration Decisions

- [ ] **Task 1.1: Build a reproducible dependency resolver matrix**
  - Add deterministic scripts or documented commands that evaluate supported
    combinations of Rails, Rack, `rack-session`, `rackup`, Rack::Attack,
    Sidekiq, `sidekiq-limit_fetch`, Sprockets, `sprockets-rails`, Sass tooling,
    and WEBrick.
  - Capture successful and failed resolutions without editing the production
    lockfile.
  - Trace to R1 and acceptance criterion 1.
- [ ] **Task 1.2: Verify primary compatibility and security evidence**
  - Pin gemspec constraints, release notes, support policies, and any current
    advisory/scanner finding.
  - Explicitly distinguish unsupported/obsolete software, operational risk,
    and an evidenced vulnerability.
  - Trace to R1 and R6.
- [ ] **Task 1.3: Select staged target versions and stop/go criteria**
  - Document the maintained Sass toolchain, asset-pipeline target, and Rack
    target supported by the resolver evidence.
  - Define blockers, rollback points, and prohibited combined changes.
  - Stop the affected migration phase if no supported combination exists.
  - Trace to R2, R6, and acceptance criteria 1, 2, and 7.
- [ ] **Task 1.4: Automated review and Phase 1 validation checkpoint**
  - Independently review the matrix for omitted constraints, stale evidence,
    hidden lockfile changes, and unsupported security claims.
  - Run resolver tests, JSON validation, lint for added tooling, and diff checks.

## Phase 2: Asset Harness Before Migration

- [ ] **Task 2.1: Inventory asset inputs and observable contracts**
  - Map manifests, Sass entrypoints, themes, Bootstrap dependencies, public and
    admin bundles, runtime asset reads, and deployment compilation commands.
  - Classify each contract as compile-time, structural, browser-observable, or
    operator-observable.
  - Trace to R3.
- [ ] **Task 2.2: Add missing deterministic asset sensors using TDD**
  - First add failing coverage for any absent production precompile, manifest,
    representative CSS, theme, runtime-read, or JavaScript contract.
  - Implement only the harness needed to make the sensors deterministic and
    retain failure artifacts in CI.
  - Trace to R3 and acceptance criterion 3.
- [ ] **Task 2.3: Record the pre-migration asset baseline**
  - Measure production compilation time, output size, manifest completeness,
    and representative browser behavior with revision and environment data.
  - Define comparison rules and rollback evidence without invented thresholds.
  - Trace to R5 and acceptance criterion 5.
- [ ] **Task 2.4: Automated review and Phase 2 validation checkpoint**
  - Review sensor coverage against the inventory and test false-positive and
    false-negative boundaries.
  - Run focused asset specs, production precompile, headless browser behavior,
    full required CI/security checks, and diff checks.

## Phase 3: Maintained Sass Toolchain

- [ ] **Task 3.1: Add failing compatibility tests for Sass replacement risks**
  - Cover imports, variables, mixins, Bootstrap integration, theme overrides,
    URL helpers, source ordering, and representative compiled selectors.
  - Trace to R2 and R3.
- [ ] **Task 3.2: Replace Ruby Sass and `sass-rails` in a focused PR**
  - Apply only the resolver-approved Sass toolchain and required source/config
    compatibility changes.
  - Preserve Sprockets 3 during this phase and avoid unrelated asset rewrites.
  - Trace to R2 and acceptance criterion 2.
- [ ] **Task 3.3: Verify compatibility, performance, and rollback**
  - Run all asset sensors and compare build time/output to Phase 2.
  - Document cache clearing, dependency/configuration rollback, and operator
    verification.
  - Trace to R5 and acceptance criteria 4-6.
- [ ] **Task 3.4: Automated review and Phase 3 validation checkpoint**
  - Review dependency scope, compiled output, browser evidence, known-risk
    disposition, and rollback reproducibility.
  - Run Ruby 3.4/4.0, asset, lint, security, and dependency gates.

## Phase 4: Asset-Pipeline Migration

- [ ] **Task 4.1: Add failing tests for the selected pipeline boundary**
  - Exercise production manifest behavior, digest URLs, runtime reads, themes,
    JavaScript registration, CSS rendering, and missing-asset failures under
    the target pipeline.
  - Trace to R3.
- [ ] **Task 4.2: Upgrade the asset pipeline in a focused PR**
  - Change only Sprockets, `sprockets-rails`, and directly required
    configuration/source compatibility approved in Phase 1.
  - Keep Rack unchanged during this phase.
  - Trace to R2 and acceptance criterion 2.
- [ ] **Task 4.3: Verify deployment artifacts and rollback**
  - Reproduce clean production precompile and deployment artifact creation,
    compare performance/output evidence, and test rollback/cache invalidation.
  - Trace to R5 and acceptance criteria 4-6.
- [ ] **Task 4.4: Automated review and Phase 4 validation checkpoint**
  - Review the migration for omitted assets, implicit network access, cache
    hazards, environment-specific behavior, and unexplained regressions.
  - Run all asset, Ruby, lint, security, dependency, and build gates.

## Phase 5: Rack Harness Before Migration

- [ ] **Task 5.1: Map the Rack dependency and middleware graph**
  - Map every Rack 2 constraint and the runtime order/contract for sessions,
    cookies, uploads, streaming, parsing, proxy/host handling, Rack::Attack,
    authentication, errors, and server lifecycle.
  - Trace to R1 and R4.
- [ ] **Task 5.2: Add missing middleware contract tests using TDD**
  - First demonstrate failures for untested success, malformed-input, and
    backend-failure paths; then add the minimum deterministic harness.
  - Include streaming/no-buffering behavior and security-sensitive request
    boundaries without live services.
  - Trace to R4 and acceptance criterion 3.
- [ ] **Task 5.3: Record the pre-migration runtime baseline**
  - Measure boot, representative request latency, streaming, and memory in a
    reproducible deployment-like environment.
  - Define comparison and rollback evidence.
  - Trace to R5.
- [ ] **Task 5.4: Automated review and Phase 5 validation checkpoint**
  - Review middleware inventory completeness and sensor quality.
  - Run focused middleware/integration specs, Ruby 3.4/4.0 suites, lint,
    security, dependency, boot, and deployment checks.

## Phase 6: Rack-Compatible Dependency Migration

- [ ] **Task 6.1: Upgrade non-Rack constraints in isolated slices**
  - Upgrade `rack-session`, `rackup`, Sidekiq and related adapters only in the
    focused child PRs required by the approved resolver path.
  - Preserve behavior and run the complete middleware harness after each PR.
  - Trace to R1, R2, and R4.
- [ ] **Task 6.2: Add failing Rack target compatibility tests**
  - Exercise changed Rack APIs and edge cases before changing the direct Rack
    dependency.
  - Trace to R4.
- [ ] **Task 6.3: Upgrade Rack in a focused PR**
  - Change Rack only after all Rack 2 constraints are removed or explicitly
    resolved and all preconditions are green.
  - Do not combine feature work or broad dependency updates.
  - Trace to R2 and acceptance criterion 2.
- [ ] **Task 6.4: Apply the evidence-based WEBrick disposition**
  - If WEBrick is intentionally absent and no supported command requires it,
    add a lockfile exclusion sensor. Otherwise document its justified presence
    without creating a false security gate.
  - Trace to R6.
- [ ] **Task 6.5: Automated review and Phase 6 validation checkpoint**
  - Review request semantics, security middleware, deployment behavior,
    dependency scope, performance comparison, and rollback evidence.
  - Run the full Ruby 3.4/4.0, middleware, asset, lint, security, dependency,
    boot, deployment, and performance gates.

## Phase 7: Operational Qualification and Closure

- [ ] **Task 7.1: Verify clean deployment and rollback rehearsal**
  - Build and boot from a clean environment, verify representative FOI and
    administrator flows, and rehearse each documented rollback boundary.
  - Retain commands, revision, environment, results, and limitations.
  - Trace to R5 and acceptance criteria 5 and 6.
- [ ] **Task 7.2: Reconcile documentation and dependency policy**
  - Update architecture, operator, dependency, and contributor guidance to
    match the final graph and sensors.
  - Confirm no historical vulnerability claim remains without current primary
    evidence.
  - Trace to R1, R5, and R6.
- [ ] **Task 7.3: Final automated review and acceptance audit**
  - Audit every acceptance criterion, child issue, focused PR, risk
    disposition, sensor, benchmark, rollback procedure, and external boundary.
  - Run the complete repository check matrix and validate Conductor evidence.
- [ ] **Task 7.4: Archive the completed track**
  - Record immutable merge/check evidence, close #74 only after all child
    issues are complete, update metadata/registry, and archive the track.

## Global Stop Conditions

- Stop a phase when its resolver path is unsupported, a required sensor is
  absent, a known risk lacks a verified control, a performance regression is
  unexplained, or rollback cannot be reproduced.
- Do not bypass or weaken CI/security checks to continue.
- Do not treat a stop condition as a current-release blocker unless a separate
  evidence-backed issue explicitly establishes that gate.
