# Security Scanner Baseline

Issue: [#59](https://github.com/edithatogo/alaveteli/issues/59)

## Policy

Brakeman remains fail-closed with `-z`. The ignore file contains exact
fingerprints only: new findings, changed code shapes, parser errors, and stale
fingerprints are not accepted automatically.

CI pins Brakeman 8.0.5 and verifies the approved ledger against the scanner's
machine-readable report. Fingerprints and security-relevant warning metadata
must match exactly. The report is retained as a workflow artifact. Bearer is an
advisory scanner because its current signal has not been qualified as a release
gate; its SARIF output is retained for review even when the scan reports issues.

## Confirmed Findings Fixed

- Unsafe hybrid cookie deserialization was replaced by JSON serialization.
- User statistics raw SQL was replaced by bound Active Record relations.
- Administrative public-body locale SQL now uses a bind parameter.
- The generated incoming-subject regular expression is escaped.
- HEAD requests now follow the same public-cache policy as GET requests.
- The profile runner parser error was removed.
- Public-body change-request source URLs now require an absolute HTTP or HTTPS URL.
- External request URLs now require an absolute HTTP or HTTPS URL; unsafe
  legacy values render as text rather than administrator-facing links.

## Reviewed Residual Findings

| Class | Count | Provenance | Disposition |
|---|---:|---|---|
| SQL construction | 11 | Model-owned table/field names, configured locales, database metadata, sanitized tag helpers | Fingerprint baseline; no request value is concatenated without an existing sanitizer or allowlist. |
| Persisted/generated URLs | 9 | Public-body, citation, blog, Stripe and application action URLs | Fingerprint baseline; retain existing model/admin trust boundary and require separate URL-policy work if that boundary changes. |
| ZIP file paths | 2 | `InfoRequest#make_zip_cache_path` under the configured download root | Fingerprint baseline; path remains model-derived and authorization-gated. |
| Analytics rendering | 1 | Public-body homepage used as an escaped analytics label | Fingerprint baseline; not emitted as raw HTML. |

The 23 current fingerprints are enumerated in `config/brakeman.ignore`. This
classification does not authorize adding wildcard ignores or disabling a
Brakeman check.

The session compatibility impact, monitoring requirements, key-rotation
boundary, and emergency rollback procedure are documented in
`doc/cookie_serializer_migration.md`.
