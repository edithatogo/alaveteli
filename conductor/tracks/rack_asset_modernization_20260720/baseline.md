# Modernization Baseline

Recorded against `origin/develop` revision
`1da7ad55e81d9671b3c7a3455eed78c3d2430c30` on 2026-07-26. The machine-readable
dependency inventory is `dependency_inventory.json`; the authoritative lockfile
is `Gemfile.lock`.

## Current graph

Rails 8.0.5 currently resolves with Rack 2.2.23, rack-session 1.0.2, rackup
1.0.1, Rack::Attack 6.7.0, Sidekiq 6.5.12, sidekiq-limit_fetch 4.4.1,
Sprockets 3.7.5, sprockets-rails 3.4.2, sass-rails 5.0.8, and WEBrick 1.9.2.
The dependency ordering means Ruby Sass replacement must precede Sprockets 4,
and the asset pipeline must be migrated and qualified before Rack 3.

## Existing qualification sensors

- Hosted CI runs Ruby 3.4 and experimental Ruby 4.0 core and gem suites.
- Hosted security workflow runs Brakeman, dependency vulnerability audit, and
  dependency review.
- The repository retains asset, middleware, Rack::Attack, streaming, and
  deployment-related specs; missing sensors must be added before migration.

## Phase 0 disposition

The current evidence supports decomposition, not a migration decision. No
production lockfile was changed, no current primary advisory was asserted, and
WEBrick remains a non-failing transitive dependency until an intentional removal
is qualified. The next task is a reproducible resolver matrix for candidate
combinations, followed by primary release/advisory verification.
