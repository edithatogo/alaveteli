# Plan: Optimize Bulk Export API

## Phase 1: Baseline and Harness Setup [checkpoint: 5a69b07]

- [x] Task: Register issue-led delivery and benchmark harness [1f7a04a]
    - [x] Create or update the fork-local parent issue and small subissue map
    - [x] Add a benchmark command for bulk export allocations, query count, and latency
    - [x] Document the baseline command, expected inputs, and CI/local execution limits
- [x] Task: Conductor - User Manual Verification 'Phase 1' [680171b]
    - [x] Baseline and Harness Setup protocol in `workflow.md`

## Phase 2: Streaming Export Implementation [checkpoint: 9fc4ac3]

- [x] Task: Add contract-preserving streaming export query [0e3cb94]
    - [x] Refactor `SustainabilityController#bulk_export` to stream selected columns
      in deterministic pages
    - [x] Resolve public body fields with a join instead of per-row association access
    - [x] Preserve verified bot enforcement, `limit`, `since`, NDJSON shape, and response headers
    - [x] Add controller or service specs for authorization, validation, filtering,
      ordering, and row shape
- [x] Task: Add performance and security sensors [aba1f38]
    - [x] Add a query-count or allocation guard where practical
    - [x] Add no-SQL-interpolation review evidence for user-controlled values
    - [x] Update metrics or runbooks if export telemetry changes
- [x] Task: Conductor - User Manual Verification 'Phase 2' [e674cb0]
    - [x] Streaming Export Implementation protocol in `workflow.md`

## Phase 3: Verification and Closeout

- [x] Task: Reconstruct private bulk-export HTTP validators
    - [x] Replace the superseded PR #33 validator proposal with a clean implementation
      from current `origin/develop`
    - [x] Bind the ETag to the exact bytes of one immutable, permission-restricted
      NDJSON snapshot covering request, deletion, translation, and status changes
    - [x] Keep authenticated exports private, stream the hashed snapshot bytes, and
      unlink snapshots after `304`, successful delivery, failure, or abandoned bodies
    - [x] Add focused validator and controller regression coverage
- [~] Task: Run regression and security gate
    - [~] Run scoped RSpec, RuboCop, Brakeman, and benchmark command where available
    - [~] Document unavailable local gates and CI follow-up without accepting risk
    - [ ] Confirm no known security, quality, correctness, availability, or operator risk remains
    - [ ] Blocking follow-up: remediate dependency audit advisories tracked in `#18`
    - [ ] Blocking follow-up: remediate Brakeman security findings tracked in `#19`
- [ ] Task: Archive track and synchronize docs
    - [ ] Update Conductor track status and issue map
    - [ ] Archive only after implementation commits, plan updates, and notes are complete
- [ ] Task: Conductor - User Manual Verification 'Phase 3'
    - [ ] Verification and Closeout protocol in `workflow.md` (deferred; hosted qualification is recorded)

## Completion Evidence

- [x] Current-base PR #33 hosted matrix passed on Ruby 3.4 and Ruby 4.0.
- [x] PR #33 merged; immutable evidence is recorded in `evidence.md`.
- [x] Track archived; baseline dependency/security follow-ups remain separately tracked.
