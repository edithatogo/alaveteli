# Implementation Plan

## Phase 1: Rebuild Existing Fixes on Current Develop

- [x] Add issues #56-#65 to Project 19.
- [x] Replace the unavailable Ruby preview matrix entry (#58).
- [x] Normalize and validate batch public-body IDs (#57).
- [x] Isolate BotTrafficMetrics cache state (#64).
- [x] Restore Rack::Attack global state after each example (#63).
- [x] Obtain hosted evidence and merge the rebuilt slice.

## Phase 2: Remaining Full-Suite Failures

- [x] Isolate Xapian job uniqueness state (#62).
- [x] Inventory and resolve all remaining Ruby 3.4 failures (#56/#65).

## Phase 3: Security Baseline

- [x] Classify every Brakeman and dependency-audit finding (#59).
- [x] Upgrade or repair confirmed findings without default suppression.
- [x] Obtain green security and supported-Ruby hosted evidence.

## Phase 4: Closeout

- [x] Review the complete evidence packet.
- [x] Mark all linked issues complete and archive this track.

## Completion Evidence

Merged PR #71 at `7aeb011e9f2bb7a93e217b5851972c052509e574` after hosted
run `29686377247` passed all 9,550 core examples on Ruby 3.4 and Ruby 4.0,
both gem-spec matrices, and Coveralls. Security run `29686377246` passed
Brakeman, Bearer, dependency review, and dependency vulnerability audit.
Issues #56-#65 linked by this track are closed and their Project 19 items are
Done. See `evidence.md` for the immutable gate inventory.
