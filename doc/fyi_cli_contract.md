# fyi-cli HTTP Contract

Version: `0.1`

This document describes the fork-local Alaveteli surface consumed by
`fyi-cli`. It is an advisory, read-only contract for bounded clients. The
server remains authoritative for authentication, throttling, and response
validity.

## Back-pressure headers

Responses which pass through the traffic-control concern may include:

| Header | Meaning |
| --- | --- |
| `RateLimit-Limit` | The request limit for the selected tier. |
| `RateLimit-Remaining` | Non-negative requests remaining in the current window. |
| `RateLimit-Reset` | Seconds until the current window resets. |
| `X-Advisory-Status: degraded` | The server is under elevated load. |
| `Retry-After` | Seconds to wait when the server is degraded or returns `429`. |

Missing advisory headers are not an authorization signal. Clients must treat
`429` as authoritative back-pressure, honor `Retry-After` when valid, and use a
bounded local fallback when it is absent or malformed. Clients must never log
the `X-FYI-Bot-Token` value.

## Rate-limit discovery

`GET /api/v1/rate_limit` returns JSON containing `tier`, `limit`, `remaining`,
`reset_in_seconds`, and `advisory_status`. The server derives these values from
its active request-throttling data when available. Clients must treat this
endpoint as advisory: the status and headers on each protected request remain
authoritative.

## Bounded bulk export

`GET /api/v1/bulk_export` requires the configured `X-FYI-Bot-Token` and returns
`401` when the token is absent or invalid. Authentication occurs before the
server exposes representation validators.

Successful requests return newline-delimited JSON as
`application/x-ndjson`, with an attachment filename of
`requests_export.ndjson`. The body is a streamed Rack response backed by one
immutable snapshot. Clients must consume or close the response body so the
server can release that snapshot.

The response includes:

| Header | Contract |
| --- | --- |
| `ETag` | A quoted SHA-256 digest of the exact NDJSON response bytes. |
| `Cache-Control` | `private, no-cache`; shared caches must not store the authenticated export. |

The endpoint deliberately does not publish `Last-Modified`. A client with a
previous ETag may send `If-None-Match`; a match returns `304` with an empty
body. Clients must not infer conditional-export support from
`If-Modified-Since`.

Supported query parameters are:

- `limit`: a positive integer;
- `since`: an optional timestamp accepted by the server contract.

Invalid parameters return `422`. The export is bounded and does not grant
general-purpose database access.

Each NDJSON object contains exactly these public request fields:

- `id`
- `title`
- `url_title`
- `created_at`
- `updated_at`
- `status`
- `public_body_name`
- `public_body_url_name`

## Verification boundary

The focused controller and snapshot specs are deterministic, offline sensors
for authentication ordering, private caching, exact-byte ETags, conditional
responses, body streaming, cleanup, and the public NDJSON field set. Changes to
this contract require updating those sensors in the same pull request.

This document does not define token issuance, rotation, allowlisting, a
production enablement policy, or a client implementation. Those remain
separate design and operator-gate work under the fyi-cli interoperability and
endorsed-route tracks.
