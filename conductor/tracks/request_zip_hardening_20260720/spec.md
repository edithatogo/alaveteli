# Request ZIP hardening specification

## Objective

Remove route slugs and other user-controlled values from request ZIP filesystem
paths and download filenames while preserving authorization, cache invalidation,
and public/requester/admin visibility variants.

## Path contract

- The cache root is `InfoRequest.download_zip_dir`.
- Cache identity is derived from the persisted numeric `InfoRequest#id`.
- The cache version is the existing 40-character hexadecimal
  `last_update_hash`.
- The only filename variants are the existing trusted visibility suffixes.
- The response filename is the fixed `request-correspondence.zip`.
- New ZIP artifacts are created with owner-only mode `0600`.
- `url_title`, request titles, authority names, and route text must not reach the
  filesystem path or response filename.

## Delivery boundaries

`RequestZipCachePath` accepts a persisted `InfoRequest` and the authenticated
user context, derives bounded components internally, and rejects malformed
versions. Callers do not supply path fragments.

## Non-scope for the first PR

- Inter-process locking.
- Temporary-file generation and atomic rename.
- Changing ZIP contents or visibility policy.
- Replaying stale PR #50 or #52 branch history.
- Altering the external URL, SQL, cookie, traffic-control, or dependency
  protections merged in PR #71.

Those delivery concerns remain a second reviewable PR after this path boundary
is green.
