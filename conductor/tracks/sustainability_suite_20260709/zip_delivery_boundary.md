# Request ZIP Delivery Boundary

Status: design gate for fork issue #53 and stacked PR #52.

## Objective

Remove model-derived filesystem paths from the request controller's ZIP
creation and delivery flow without weakening authorization, visibility
variants, cache invalidation, or overload protection.

## Non-negotiable invariants

- Every generated artifact is private to the authorized request and visibility
  variant that produced it.
- A route value, model attribute, filename, or visibility value cannot escape
  the configured ZIP root or select an arbitrary filesystem object.
- Request changes cannot return stale correspondence.
- Hidden and requester-only correspondence cannot cross a visibility boundary.
- Concurrent requests must not expose a partial ZIP or corrupt a cached ZIP.
- The design must preserve bounded resource use under repeated or concurrent
  downloads; moving the same work into `send_data` without a measured bound is
  not an acceptable fix.
- Brakeman must report zero request-controller FileAccess and SendFile warnings
  without ignores, suppressions, or false-positive reclassification.

## Candidate designs

### A. Dedicated delivery service with an opaque artifact

The service owns authorization-aware cache-key construction, path validation,
locking, generation, and artifact lifecycle. The controller receives only a
validated delivery object. This is the preferred direction if the scanner
accepts the opaque boundary and focused tests prove the invariants.

Required sensors: service unit tests, controller authorization tests, path
property tests, concurrent-generation test, cache-invalidation integration
test, Brakeman, and hosted Ruby 3.4 verification.

### B. Rails-managed private blob delivery

Store generated ZIPs as private application-managed blobs with a versioned,
visibility-scoped key and authorize every download before issuing a short-lived
download response. This can remove controller filesystem handling, but requires
an explicit storage, retention, cleanup, and authorization design before any
implementation.

Required sensors: storage isolation test, authorization test, expiry/cleanup
test, cache invalidation test, resource-limit test, Brakeman, and hosted
end-to-end verification.

## Rejected shortcuts

- Do not suppress or reclassify the current Brakeman findings.
- Do not use `send_data` for unbounded ZIP contents merely to avoid a path
  warning; this can convert a path-flow risk into an availability risk.
- Do not regenerate every ZIP on every request as a substitute for safe cache
  ownership; that would increase bot-overload pressure.
- Do not use a fixed shared filename without a lock and visibility/version
  isolation.
- Do not close #51 or submit #52 upstream until every invariant and required
  sensor has passing evidence.

## Exit criteria

Issue #53 may close only when one candidate is implemented in a small PR,
rollback is documented, focused and integration behavior is green, and all
repository security and dependency gates are green.
