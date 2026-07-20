# Rate-Limit Status Reconstruction Evidence

## Provenance

- Fork issue: https://github.com/edithatogo/alaveteli/issues/39
- Fork pull request to replace: https://github.com/edithatogo/alaveteli/pull/40
- Reconstruction base: `8295e2a9b693b6e32553abe02fc7f365d4692e26`
- Base scope: the clean PR #33 bulk-export validator implementation

## Contract

`GET /api/v1/rate_limit` accepts no query parameters. It reads the current
request's `rack.attack.throttle_data`, which is the middleware snapshot produced
by the enforced `req/anonymous` or `req/verified_bot` Rack::Attack throttle. It
does not read, increment, write, fetch, or delete limiter cache entries.

Successful responses emit a versioned JSON body and matching
`RateLimit-Limit`, `RateLimit-Remaining`, and `RateLimit-Reset` headers. The
response is `no-store`, and `tier` plus `advisory_status` remain explicit.
Missing, malformed, or unrecognized middleware evidence produces a sanitized
degraded `503`; unrelated exceptions are not caught. Numeric evidence is
accepted only when `limit` and `count` are non-negative, `period` is positive,
and `epoch_time` is non-negative, preventing invalid headers and reset-time
arithmetic.

## Local Verification

Passed on 2026-07-20:

- Ruby syntax checks for all touched Ruby files
- `metadata.json` parse validation
- `git diff --check`

Focused RSpec, RuboCop, Brakeman, Bearer, dependency audit, and the complete
Ruby 3.4/4.0 matrix cannot run in this worktree because the available local
runtime is Apple Ruby 2.6.10 and the repository lockfile requires Bundler 2.7.2
with a supported Ruby runtime. Those checks remain mandatory hosted gates before
merge.

The PR #40-only hosted test was corrected to assert that the status object never
accesses `Rack::Attack.cache`, while allowing the real endpoint metric and its
shared `Rails.cache` cleanup to run. Shared bulk-export failures on this stacked
base belong to PR #33 and are being corrected there; they are not evidence of a
rate-limit endpoint regression.
