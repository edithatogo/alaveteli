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

- [ ] **Task: Add locking and atomic ZIP publication**
  - Generate into a mode-`0600` temporary file inside the bounded cache
    directory.
  - Coordinate concurrent writers and atomically rename a complete ZIP.
  - Clean failed temporary files and prove readers cannot observe partial ZIPs.
  - Keep this work in a separate PR after Phase 1 has passed hosted CI.

## Verification

- [ ] Run focused model, service, controller, and integration specs on the
  repository-supported Ruby toolchain.
- [ ] Run RuboCop, Brakeman without new suppressions, Bearer, dependency audit,
  and the full Ruby 3.4/4.0 hosted CI matrix.
- [ ] Record immutable hosted evidence before closing issues #49/#51/#53.

> CHECKPOINT (2026-07-20): Phase 1 is implemented from current `origin/develop`.
> Local syntax and structural checks are required before commit; hosted Ruby
> verification remains required because the workstation Ruby cannot install the
> lockfile-required Bundler version.
