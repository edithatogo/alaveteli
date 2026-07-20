# Notification Preferences Upstream Readiness

## Fork-Local Delivery

- Parent issue: `#20` Prepare notification preferences for upstream review.
- Focused subissue: `#21` Build and verify isolated notification-preferences
  candidate.
- Original draft PR: `#22` Add user notification preferences.
- Reconstruction baseline: fork `origin/develop` at `c76820871`.
- Reconstruction branch: `codex/pr22-notification-corrections`.
- The original PR branch must not be merged wholesale because its first four
  commits are already patch-equivalent to changes on `develop`.
- No upstream issue or PR has been created.

## Candidate Scope

The reconstructed candidate contains only the remaining controller ownership
and partial-update corrections, profile navigation, mailer eager loading, and
focused tests. It does not replay the existing migration, model, route, form,
or original mail-suppression behavior, and it excludes unrelated changes.

## Findings Resolved

- Added profile navigation so authenticated users can discover the settings.
- Replaced manual Boolean casting with strong-parameter model updates, which
  preserves omitted values during partial updates.
- Made authenticated-user ownership explicit in the controller.
- Eager-loaded notification users to prevent a newly introduced N+1 query.
- Added the upstream-required changelog entry and conformed new lines to the
  upstream RuboCop policy.

## Verification Evidence

- `git diff --check`: pass for the reconstructed candidate.
- Ruby syntax checks: pass for touched Ruby files.
- Dependency manifest delta: none; `Gemfile` and `Gemfile.lock` are unchanged.
- Focused specs, RuboCop, security checks, and the supported Ruby 3.4/4.0 full
  suites remain pending in hosted CI.
- Local execution is unavailable because the workstation Ruby 2.6 environment
  does not provide the lockfile-required Bundler 2.7.2.

The track remains in progress until supported CI is green and the final risk
review confirms that no known risk remains.
