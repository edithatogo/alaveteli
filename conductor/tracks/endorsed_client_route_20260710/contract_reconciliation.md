# Contract Reconciliation

This proposal is downstream of the completed fork-local FYI contract slices;
it does not replace or broaden them.

| Existing evidence | Route implication | Status |
| --- | --- | --- |
| #24 / PR #46: versioned server/client contract | Discovery must advertise a version and reject unsupported negotiation | Complete prerequisite |
| #25 / PR #79: offline server fixtures for headers, 304, and bounded NDJSON | Any endorsed route reuses back-pressure, conditional requests, and export bounds | Complete prerequisite |
| #26 / PR #81: token identity, rotation, rollout, and disablement contract | Route authentication must remain deployment-controlled and fail closed | Complete prerequisite |
| #27 / PR #83: reciprocal offline verification | New route controls need paired fixtures and evidence before upstream discussion | Complete prerequisite |
| fyi-cli #148 / PR #153 | Client capability evaluator is fork-local and does not authorize server enablement | Paired proposal only |

## Scope boundary

The endorsed route remains a future, opt-in server feature. The current
repository has not enabled a route, exposed MCP remotely, changed production
authorization, or opened an upstream issue/PR. The next implementation slices
must each have a focused issue, a disabled-default test, and a rollback path.
