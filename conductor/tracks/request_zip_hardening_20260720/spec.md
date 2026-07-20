# Request ZIP hardening specification

## Objective

Remove route slugs and other user-controlled values from request ZIP filesystem
paths and download filenames while preserving authorization, cache invalidation,
and public/requester/admin visibility variants.

## Path contract

- The cache root is `InfoRequest.download_zip_dir`.
- Cache identity is derived from the persisted numeric `InfoRequest#id`.
- The cache version is a 64-character SHA-256 digest over narrowly projected
  output and visibility revision data for the request, authority and its
  translations, requester, events, messages, comments and comment users,
  attachments, raw emails, applicable censor rules, masks, locale, and domain.
- Large message bodies and cached extracted text are never loaded or hashed to
  decide a cache hit. Their persisted records use microsecond-capable
  `updated_at` revisions; stored attachment and raw-email content additionally
  uses existing Active Storage and model checksums.
- Small output and redaction values are included directly. Every projected
  collection is sorted by record type and numeric primary key or stable
  identity before canonical serialization, independently of query order.
- Snapshot construction uses a fixed number of projected queries rather than
  association traversal proportional to message or attachment count.
- The only filename variants are the existing trusted visibility suffixes.
- The response filename is the fixed `request-correspondence.zip`.
- New ZIP artifacts are created with owner-only mode `0600`.
- Writers coordinate on a mode-`0600` lock scoped to the final cache path.
- ZIPs are generated in mode-`0600` same-directory staging files, flushed,
  fsynced, closed, and atomically renamed before the final path is visible.
- Waiting callers reuse only the complete artifact observed after acquiring the
  lock; they never treat an in-progress staging file as a cache hit.
- Cross-process tests signal at the instruction immediately before the
  competing blocking `flock`, avoiding scheduler-delay inference.
- Every cache directory component is created separately and checked with
  `lstat`; symlinks and non-directories are rejected before lock, cleanup,
  staging, rename, and delivery operations.
- `url_title`, request titles, authority names, and route text must not reach the
  filesystem path or response filename.

## Delivery boundaries

`RequestZipCachePath` accepts a persisted `InfoRequest` and the authenticated
user context, derives bounded components internally, and rejects malformed
versions. Callers do not supply path fragments.

## Non-scope

- Changing ZIP contents or visibility policy.
- Replaying stale PR #50 or #52 branch history.
- Altering the external URL, SQL, cookie, traffic-control, or dependency
  protections merged in PR #71.

This track consolidates the path and atomic-delivery requirements into one
merge-safe successor change.

## Residual filesystem assumption

The configured cache root and its parent are operator-controlled and not
writable by an untrusted local user. Ruby does not expose a portable complete
`openat`/`O_BENEATH` directory traversal API, so component checks cannot prevent
a same-user process from replacing a checked parent in the interval before the
next filesystem syscall. Mode-`0700` cache directories, repeated `lstat`
validation, `O_NOFOLLOW` where available, and mode-`0600` files form the
strongest practical portable boundary under that trusted-root assumption.
