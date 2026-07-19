# Implementation Plan

## Phase 1: Rebuild Existing Fixes on Current Develop

- [x] Add issues #56-#65 to Project 19.
- [x] Replace the unavailable Ruby preview matrix entry (#58).
- [x] Normalize and validate batch public-body IDs (#57).
- [x] Isolate BotTrafficMetrics cache state (#64).
- [x] Restore Rack::Attack global state after each example (#63).
- [ ] Obtain hosted evidence and merge the rebuilt slice.

## Phase 2: Remaining Full-Suite Failures

- [ ] Isolate Xapian job uniqueness state (#62).
- [ ] Inventory and resolve all remaining Ruby 3.4 failures (#56/#65).

## Phase 3: Security Baseline

- [x] Classify every Brakeman and dependency-audit finding (#59).
- [x] Upgrade or repair confirmed findings without default suppression.
- [ ] Obtain green security and supported-Ruby hosted evidence.

## Phase 4: Closeout

- [ ] Review the complete evidence packet.
- [ ] Mark all linked issues complete and archive this track.
