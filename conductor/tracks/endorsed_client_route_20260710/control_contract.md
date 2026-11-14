# Endorsed Route Control Contract

This document defines the controls required before any implementation. It is
not a production configuration and does not enable the route.

## Disabled default and configuration

The route is disabled unless an operator explicitly sets a complete,
validated configuration. Missing, partial, malformed, or contradictory values
must fail closed. Configuration must include an explicit enabled flag, contract
version, allowlisted client identities, finite client and instance budgets,
revocation, emergency disablement, operator contact, and maintenance window.
There is no default client, default token, anonymous privileged mode, or
client-controlled limit. An invalid reload retains the disabled state.

## Authentication and identity

Authentication uses the deployment-controlled token boundary defined in
`fyi_cli_interoperability_20260710/identity_operations.md`. The server maps a
token to an allowlisted identity, applies revocation before privileged work,
and treats User-Agent/contact metadata as traceability only. Rotation and
revocation must be atomic; an overlap window requires a separately reviewed
contract.

## Budgets and back-pressure

Every request consumes the smallest applicable client and instance budget.
Budgets are finite server-side limits for requests, bytes, runtime,
concurrency, retries, and exports; request parameters cannot raise them.
Exceeding a limit returns a bounded response with the documented `RateLimit-*`,
`Retry-After`, and advisory signals. Output stops at every item, byte, runtime,
or concurrency ceiling and responses close on all failure paths.

## Audit and telemetry

Audit events may record contract version, client identity, endpoint, outcome,
budget class, and correlation identifier. They must not record tokens, full
headers, response bodies, private identifiers, or unbounded User-Agent values.
Metrics use bounded labels for enabled state, authorization outcome, status
class, budget class, and advisory state. Logs and traces apply the same
redaction policy.

## Export, authorization, and privacy

The route creates no new authorization capability. Existing visibility,
embargo, export, and privacy checks remain mandatory. Bulk export remains
verified and bounded; the route cannot select arbitrary fields, bypass
visibility, disable audit, or fall back to unbounded pagination. Capability
documents contain no record data.

## Operator controls

- **Enable:** validate the complete configuration and start with one allowlisted client.
- **Pause:** reject new endorsed-route requests while ordinary service remains available.
- **Revoke:** invalidate one identity and confirm an immediate bounded failure.
- **Emergency disable:** remove the enabled flag or secret and verify the route is unavailable.
- **Rollback:** return clients to conditional requests and bounded ordinary API access.

The offline fixture matrix and security gates in the Conductor plan are required
before implementation. Until they pass, this contract is design-only and no
upstream engagement is authorized.
