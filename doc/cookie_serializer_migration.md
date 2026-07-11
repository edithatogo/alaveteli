# Cookie Serializer Migration Design

Status: design gate for fork issue #44 and upstream issue mysociety/alaveteli#9379.

## Current State

Alaveteli uses Rails cookie-store sessions with the key `_wdtk_cookie_session` and
configures `action_dispatch.cookies_serializer` as `:hybrid`. The session holds
authentication and administrative state, login tokens, remember-me and TTL
state, post-redirect state, OTP state, Turnstile state, and other workflow
state.

Separate direct cookie consumers include `locale`, `last_request_id`,
`last_body_id`, and `widget_vote`. These must not be assumed to have the same
serialization or migration behavior as the session cookie.

## Security Objective

Remove the legacy deserialization posture flagged by Brakeman's
`CookieSerialization` check without creating an authentication, CSRF, session,
or availability regression. No scanner suppression is acceptable.

## Proposed Migration Shape

The implementation PR must select and test a non-hybrid serializer, with JSON
as the initial candidate, and use an explicitly versioned session-cookie key.
The key version prevents new requests from attempting to deserialize legacy
hybrid session data.

The exact key and serializer are deployment decisions and must not be hard
coded in this design document. They must be supplied through the supported
configuration path and validated at boot.

## Required Stages

1. **Preflight:** inventory all session fields and confirm that every value is
   representable by the selected serializer. Reject unsupported object types in
   tests before deployment.
2. **Compatibility proof:** exercise anonymous, authenticated, admin,
   remember-me, OTP, Turnstile, CSRF, locale, and post-redirect flows with the
   new serializer and key.
3. **Controlled rollout:** deploy the versioned key and serializer together;
   monitor session-reset, authentication-failure, invalid-cookie, and CSRF
   metrics. Do not silently fall back to hybrid deserialization.
4. **Legacy handling:** document whether the old cookie is allowed to expire,
   explicitly expired, or rejected. The chosen behavior must be tested and
   must not permit unsafe legacy deserialization.
5. **Rollback:** restore the previous configuration only as an emergency
   availability action, with a dated expiry and a follow-up to remove the old
   path. Rollback must not be described as a security resolution.

## Required Sensors

- Configuration spec proving the serializer is non-hybrid and the session key
  is versioned.
- Integration specs for login, logout, admin login-as, OTP, CSRF, remember-me,
  TTL expiry, and post-redirect flows.
- Tests proving malformed, legacy, and cross-key session cookies do not
  authenticate a user or bypass CSRF protection.
- Tests proving direct locale, request/body, and widget cookies retain their
  documented behavior.
- Deployment smoke test and rollback smoke test in the supported CI
  environment.
- Brakeman reports zero `CookieSerialization` findings.

## Completion Gate

No implementation PR may be promoted until the serializer choice, key
rotation, legacy-cookie behavior, observability, rollback, and all required
sensors are reviewed. Issue #44 remains open until the production configuration
and full evidence are complete.
