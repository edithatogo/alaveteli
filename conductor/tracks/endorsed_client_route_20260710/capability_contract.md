# Endorsed Route Capability Contract

This is a proposal for a future, disabled-by-default route. It is not a
public endpoint and does not authorize an implementation or upstream request.

## Discovery document

An enabled instance may expose a versioned, read-only capability document only
after operator configuration and authentication have succeeded. A candidate
response shape is:

```json
{
  "contract": "fyi-endorsed-route",
  "version": "0.1",
  "enabled": true,
  "capabilities": {
    "rate_limit": true,
    "conditional_get": true,
    "bounded_bulk_export": true
  },
  "limits": {
    "max_items": 1000,
    "max_response_bytes": 10485760,
    "max_concurrent_requests": 1
  },
  "signals": ["RateLimit-*", "Retry-After", "X-Advisory-Status"],
  "revocation": {"supported": true},
  "mcp": {"remote": false}
}
```

The example is illustrative only. Limits must be instance configuration, not
client-selected values, and the discovery response must never disclose a
secret, internal path, or unbounded capability.

## Negotiation

- The client sends an explicit supported contract version during an
  authenticated request.
- The server selects one exact version or returns an unsupported-version error;
  it must not silently downgrade to an older or broader contract.
- Unknown capability names are ignored by clients but never enable behavior.
- A missing, malformed, unauthenticated, revoked, or disabled request fails
  closed and cannot obtain the discovery document.
- A capability response is advisory. Normal authorization, privacy, abuse,
  and export controls remain authoritative for every subsequent request.
- `mcp.remote` remains `false` unless a separately approved network boundary
  and control contract exists.

## Versioning and compatibility

The version is a major/minor decimal string. A major change requires a new
negotiation contract and migration evidence; a minor change may add optional
capabilities but cannot relax an existing limit or authorization rule. Clients
must reject a response with an unsupported major version and must treat missing
optional fields conservatively.

## Required sensors before implementation

- disabled, unauthenticated, revoked, malformed-version, unsupported-version,
  and successful negotiation fixtures;
- assertions that limits are finite positive integers and are not client
  supplied;
- assertions that secrets and internal configuration are absent from the
  document and error responses;
- a bounded offline client/server fixture exchange; and
- a rollback test proving the discovery document disappears when the route is
  disabled.
