# Track Specification: Staged Rack and Asset-Pipeline Modernization

## Overview

Modernize Alaveteli's Sass, asset-pipeline, and Rack dependencies through
independently reversible stages. This track refreshes the assessment formerly
recorded in PR #32 against the hardened `develop` baseline and implements
[issue #74](https://github.com/edithatogo/alaveteli/issues/74).

This is a non-release-blocking roadmap track. The current dependency graph is
supported by passing Ruby 3.4 and experimental Ruby 4.0 suites and has no open
Dependabot finding that makes this migration an immediate security gate.
Discovery may identify a new primary advisory or scanner finding; if so, that
finding must be handled through the normal security process rather than
retroactively changing the evidence in this specification.

## Current Constraints

The authoritative starting point is `Gemfile` and `Gemfile.lock` at the
`origin/develop` revision from which this track was created. The current graph
includes:

- Rack 2.2.23, with Rack 2 constraints from `rack-session` 1.0.2, `rackup`
  1.0.1, Sidekiq 6.5.12, and Sprockets 3.7.5;
- Rails 8.0.5 and Rack::Attack 6.7.0;
- `sass-rails` 5.0.8, which depends on end-of-life Ruby Sass and requires
  Sprockets below 4;
- Sprockets 3.7.5 and `sprockets-rails` 3.4.2;
- WEBrick 1.9.2 through `rackup`, without a current open Dependabot alert; and
- existing Bootstrap Sass, theme, public/admin CSS, runtime asset-read, and
  JavaScript behavior compatibility obligations.

Rack 3 therefore cannot be treated as a Sprockets-only upgrade. The obsolete
Sass integration must be replaced before Sprockets 4 is attempted, and the
asset pipeline must be migrated and verified independently before changing
Rack.

## Requirements

### R1: Evidence-bound dependency discovery

- Produce a reproducible Bundler resolver matrix for Rails, Rack,
  `rack-session`, `rackup`, Rack::Attack, Sidekiq, `sidekiq-limit_fetch`,
  Sprockets, `sprockets-rails`, `sass-rails`, the selected maintained Sass
  implementation, and WEBrick.
- Record direct and transitive constraints, supported Ruby versions,
  operational consequences, primary release notes or advisories, and viable
  replacement versions.
- Do not claim a vulnerability without a current primary advisory or scanner
  finding tied to the resolved version.

### R2: Independent migration boundaries

- Replace Ruby Sass/`sass-rails` before attempting Sprockets 4.
- Upgrade the asset pipeline before attempting Rack 3.
- Upgrade Rack only after every Rack 2 constraint has a tested compatible
  replacement or an explicit blocking disposition.
- Deliver each boundary through a dedicated child issue and focused PR that
  can be reverted without reverting another stage.

### R3: Asset compatibility sensors

Before changing the asset toolchain, preserve or add deterministic coverage
for:

- production asset precompilation and manifest completeness;
- representative public, admin, responsive, and theme CSS compilation;
- Bootstrap compatibility relied upon by existing views;
- runtime asset reads and missing-asset behavior;
- JavaScript bundle registration and real headless-browser behavior; and
- deployment artifact creation without undeclared network access.

Visual behavior that cannot be proven through compilation must have a bounded,
repeatable browser verification procedure with retained evidence.

### R4: Rack middleware compatibility sensors

Before changing Rack, map and test sessions, cookies and serializers, uploads,
streaming responses, request parsing, host/proxy handling, Rack::Attack,
authentication boundaries, error handling, and server startup/shutdown. Tests
must cover representative success, malformed-input, and failure behavior and
must not depend on live external services.

### R5: Compatibility, performance, and rollback evidence

- Retain the full Ruby 3.4 suite and experimental Ruby 4.0 suite.
- Retain RuboCop, Brakeman, Bearer where configured, `bundle-audit`, dependency
  review, and exact baseline verification.
- Measure production asset build time and size, application boot, representative
  request latency, streaming behavior, and memory at a documented baseline and
  after each migration stage.
- Define configuration, dependency, cache, and deployment rollback steps for
  every stage, including the evidence that triggers rollback.
- Treat performance budgets as comparison evidence until a measured baseline
  justifies enforceable thresholds; do not invent thresholds.

### R6: WEBrick disposition

WEBrick's current transitive presence is not a failing gate. Add a lockfile
exclusion assertion only after the project intentionally removes WEBrick and
verifies that supported development, test, and deployment commands do not need
it. A future primary advisory is handled independently under R1.

## Acceptance Criteria

1. A committed resolver matrix accounts for every named dependency and every
   current Rack 2 constraint using reproducible commands and primary evidence.
2. Ruby Sass replacement, asset-pipeline migration, and Rack migration are
   separate child issues and focused PRs with independent rollback boundaries.
3. Asset and middleware sensor inventories are complete before their respective
   migrations and all required sensors pass afterward.
4. Ruby 3.4 and Ruby 4.0 suites, lint, security, dependency, asset, and
   middleware checks pass for each implementation stage.
5. Deployment compatibility and before/after performance evidence is retained
   for each stage, with no unexplained regression or unresolved known risk.
6. Documentation describes the resulting dependency boundaries and operator
   rollback procedure.
7. The track remains explicitly non-release-blocking unless a separate,
   evidence-backed security issue establishes a release gate.

## Non-Functional Constraints

- No user-visible FOI workflow, authorization, privacy, localization, or
  jurisdiction behavior may change as an incidental migration effect.
- No broad dependency update may be bundled into a migration stage.
- No stage may suppress, weaken, or bypass a current CI/security sensor to
  achieve a green result.
- Dependency resolution and tests must be deterministic and must not require
  runtime AI decisions or live third-party services.
- Generated asset and benchmark evidence must identify the command,
  environment, revision, and limitations needed for reproduction.

## External Gates

No publication, deployment, signing, or upstream submission is authorized by
this track. Merging each implementation PR and deploying a migrated stack
remain repository-owner actions under the normal review and deployment rules.
No external gate blocks planning or local implementation.

## Out of Scope

- Treating this work as a prerequisite for the current release or hardened
  baseline.
- Rewriting the frontend, replacing Rails, or changing Alaveteli's product
  behavior.
- Removing WEBrick solely to satisfy a historical security narrative.
- Combining the Sass, Sprockets, and Rack migrations into one PR.
- Accepting a known security, correctness, availability, compatibility, or
  performance regression as migration debt.

## Authoritative Inputs

- [Alaveteli issue #74](https://github.com/edithatogo/alaveteli/issues/74)
- `Gemfile` and `Gemfile.lock` on the track's pinned base revision
- `.github/workflows/ci.yml`, `.github/workflows/security.yml`, and
  `.github/workflows/rubocop.yml` on the pinned base revision
- Existing asset behavior specs under `spec/lib/` and middleware/integration
  specs under `spec/`
- Primary gem release notes, gemspec constraints, and security advisories
  captured with immutable URLs or revisions during Phase 1
