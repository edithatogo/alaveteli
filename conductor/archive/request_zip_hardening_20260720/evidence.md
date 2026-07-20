# Request ZIP Hardening Closeout Evidence

## Provenance

- Issues: [#49](https://github.com/edithatogo/alaveteli/issues/49), [#51](https://github.com/edithatogo/alaveteli/issues/51), and [#53](https://github.com/edithatogo/alaveteli/issues/53).
- Pull request: [#50](https://github.com/edithatogo/alaveteli/pull/50).
- Merge commit: `9ec601be195d1261f0907d51d485ee630f5aba1d`.
- Final validated head: `16a122cb654de030d65b25ad1204e9efaa3c4b9c`.

## Hosted Qualification

- Ruby 3.4 core: [job 88279503049](https://github.com/edithatogo/alaveteli/actions/runs/29719549272/job/88279503049)
- Ruby 4.0 core: [job 88279503044](https://github.com/edithatogo/alaveteli/actions/runs/29719549272/job/88279503044)
- Ruby 3.4 gems: [job 88279503061](https://github.com/edithatogo/alaveteli/actions/runs/29719549272/job/88279503061)
- Ruby 4.0 gems: [job 88279503054](https://github.com/edithatogo/alaveteli/actions/runs/29719549272/job/88279503054)
- Security and dependency checks: [security run 29719549274](https://github.com/edithatogo/alaveteli/actions/runs/29719549274)

## Scope

Numeric request-ID paths, component-by-component symlink rejection, atomic publication, locking, cache-version invalidation, crash recovery, and hosted regression coverage are merged. Stale PR #52 was superseded by this implementation.
