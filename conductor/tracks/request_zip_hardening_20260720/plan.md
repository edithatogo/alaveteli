# Request ZIP hardening implementation plan

## Phase 1: Bounded path and filename

- [x] **Task: Replace slug-derived ZIP paths with a typed boundary**
  - Add `RequestZipCachePath`, deriving cache identity from a persisted numeric
    request ID and the existing cache version and visibility policy.
  - Remove `url_title` from cache paths and use a fixed response filename.
  - Create new artifacts with mode `0600`.
  - Add traversal, alias, visibility, root-boundary, and permission tests.
  - Preserve all protections merged through PR #71.
  - Provenance: issues #49, #51, and #53; replaces stale PR #50 requirements.

## Phase 2: Atomic delivery

- [x] **Task: Add locking and atomic ZIP publication**
  - Generate into a mode-`0600` temporary file inside the bounded cache
    directory.
  - Coordinate concurrent writers and atomically rename a complete ZIP.
  - Clean failed temporary files and prove readers cannot observe partial ZIPs.
  - Consolidate stale PR #52 requirements into the same merge-safe successor
    change without replaying its branch history.

## Verification

- [x] **Task: Address independent pre-push review findings**
  - Replace second-granularity cache identity with a deterministic SHA-256
    representation digest covering visibility, redaction, attachment, message,
    event, comment, authority, requester, mask, locale, and blob inputs.
  - Reject symlink/non-directory components throughout the bounded hierarchy
    and document the residual operator-controlled-root assumption.
  - Replace thread scheduling coverage with fork/pipe publication and abnormal
    writer-exit recovery tests where `fork` is available.

- [ ] Run focused model, service, controller, and integration specs on the
  repository-supported Ruby toolchain.
- [ ] Run RuboCop, Brakeman without new suppressions, Bearer, dependency audit,
  and the full Ruby 3.4/4.0 hosted CI matrix.
- [ ] Record immutable hosted evidence before closing issues #49/#51/#53 and
  superseding PRs #50/#52.

> CHECKPOINT (2026-07-20): Phases 1 and 2 are implemented together from current
> `origin/develop`. The final cache pathname is published only by same-filesystem
> atomic rename after private staging-file flush, fsync, and close. Hosted RSpec
> verification remains required because PostgreSQL is unavailable locally.

> LOCAL EVIDENCE (2026-07-20): Ruby 4.0 syntax, focused RuboCop, metadata and
> ledger JSON parsing, `git diff --check`, paused-writer and ten-writer
> concurrency harnesses, failure cleanup, Brakeman 8.0.5, and the exact
> fingerprint verifier pass. The Rails-focused RSpec file cannot boot locally
> without PostgreSQL; hosted CI remains the authoritative RSpec gate.

> REVIEW CHECKPOINT (2026-07-20): Independent findings on same-second cache
> invalidation, parent symlink traversal, and thread-only concurrency evidence
> are implemented. Final local syntax, lint, Brakeman, deterministic digest,
> symlink, and cross-process harness evidence must be recorded in the follow-up
> commit note; hosted Rails RSpec remains required before merge.
