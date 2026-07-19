# Evidence Report

## Provenance

- Issue: [edithatogo/alaveteli#68](https://github.com/edithatogo/alaveteli/issues/68), closed.
- Pull request: [edithatogo/alaveteli#69](https://github.com/edithatogo/alaveteli/pull/69), merged 2026-07-19 02:35:39 UTC.
- Exact base: `fac3f622ab4672da10fc438cadb14f3141f7b394`.
- PR head: `2e5221dff86fe86aa4177fc2ac6f97a7099bbfb4`.
- Merge commit: `f593584b1166841f78ab2bcd7d2226fc36f1cdd5`.
- Merged scope: 7 files, 293 insertions, no deletions.

## Hosted Exact-Base Comparison

| Sensor | Exact base | PR #69 | Result |
| --- | --- | --- | --- |
| Ruby 3.4 core specs | [run 29070480896](https://github.com/edithatogo/alaveteli/actions/runs/29070480896): 9464 examples, 41 failures, 6 pending | [run 29666792936](https://github.com/edithatogo/alaveteli/actions/runs/29666792936): 9471 examples, 41 failures, 6 pending | Failure count unchanged; non-regression only |
| Ruby 3.4 nested gem specs | Passed | Passed | Passed |
| RuboCop | Not part of the cited base run | Passed on PR #69 | Passed for PR scope |
| Brakeman | [run 29070480890](https://github.com/edithatogo/alaveteli/actions/runs/29070480890): 31 warnings | [run 29666792949](https://github.com/edithatogo/alaveteli/actions/runs/29666792949): 31 warnings | Inherited failing baseline; count unchanged |
| Dependency audit | Failed with inherited advisories | Failed with inherited advisories | Inherited failing baseline; not green |
| Bearer | Passed | Passed | Passed |

## Limitation

PR #69 did not establish a green repository baseline. The supported Ruby 3.4
core job retained 41 failures, and the security workflow retained failing
Brakeman and dependency-audit jobs. The exact-base comparison supports only the
bounded claim that the request-state change did not increase the Ruby 3.4 core
failure count or Brakeman warning count. It does not resolve, waive, or accept
the inherited failures.

## Scope Review

The merged diff documents state roles, adds deterministic role classification,
and exposes theme-owned process-clock metadata only when non-empty. It does not
encode jurisdiction-specific legal outcomes. This retrospective governance PR
changes only `conductor/` documentation and registry files.

## Upstream Boundary

No change was made to `mysociety/alaveteli`. Upstream issues referenced by the
implementation are provenance only and are not acceptance or merge gates for
this fork-local track.
