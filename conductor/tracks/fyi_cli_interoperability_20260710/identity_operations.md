# FYI Bot Identity and Rollout Contract

## Credential boundary

- The server reads the expected credential only from the deployment secret
  `FYI_BOT_TOKEN`.
- Clients send the credential in `X-FYI-Bot-Token` over the configured TLS
  endpoint. The token is not a query parameter, fixture value, User-Agent, or
  response field.
- Missing, malformed, stale, or rotated credentials are anonymous requests and
  receive the same `401` bulk-export response. They do not receive a retry hint
  or a diagnostic that distinguishes token states.
- The API must not include the supplied or configured token in response bodies,
  headers, logs, traces, or test fixtures.

## Traceable client identity

The token authenticates the deployment-controlled client identity; it does not
make arbitrary clients trusted. The client should send a stable, descriptive
User-Agent containing the client name and version plus an operator contact
route. User-Agent text is telemetry and troubleshooting context, not an
authentication factor and not a substitute for the token.

## Rotation

1. Prepare the replacement secret in the deployment secret store.
2. Coordinate a client deployment using the replacement token.
3. Replace `FYI_BOT_TOKEN` during a controlled maintenance window.
4. Verify a bounded authenticated request and an old-token `401` response.
5. Revoke the old secret and record the change without recording either value.

The current single-secret interface has no overlap window. A rotation that
requires overlap must be implemented as a separately reviewed server/client
contract; do not weaken the equality check or add a second implicit credential.

## Staged rollout and disablement

- Start with the endpoint disabled by leaving `FYI_BOT_TOKEN` unset.
- Enable only after the offline contract suite and bounded smoke check pass.
- Observe authorization failures, rate-limit status, advisory state, and bulk
  volume during a small client rollout.
- Disable immediately by removing or rotating `FYI_BOT_TOKEN`; do not broaden
  rate limits to compensate for rejected traffic.
- Roll back the client to conditional requests and bounded pagination if bulk
  export or server load sensors regress.

## Threat model

| Threat | Control | Residual boundary |
| --- | --- | --- |
| Spoofed User-Agent | User-Agent is non-authoritative; token remains required | A leaked token can still impersonate the client |
| Missing or stale token | Uniform `401`, no diagnostic detail | Operator must deploy the current secret |
| Accidental anonymous overload | Unverified traffic remains subject to normal controls | Monitor rate-limit and advisory metrics |
| Token disclosure | No token in fixtures, responses, or error text | Deployment/logging systems must redact environment values |

## Evidence and rollback

The focused controller specs cover missing, invalid, valid, rotated, and
non-leaking credential behavior. If any identity assertion fails, disable the
client token, preserve bounded requests, and do not submit upstream until the
failure has a dated remediation record.
