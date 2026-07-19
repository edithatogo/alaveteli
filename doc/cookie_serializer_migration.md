# Cookie Serializer Migration Runbook

Status: implementation and deployment guidance for fork issue #44, PR #45,
and upstream issue `mysociety/alaveteli#9379`.

## Implemented State

Alaveteli uses Rails cookie-store sessions with the key
`_wdtk_cookie_session`. The application now configures
`action_dispatch.cookies_serializer` as `:json` instead of `:hybrid` so it no
longer deserializes legacy Marshal payloads.

This is an intentionally breaking security migration. Existing sessions that
were encoded with Marshal are not migrated and become unreadable. Users with
those sessions must authenticate again. Authentication and administrative
state, login tokens, remember-me and TTL state, post-redirect state, OTP state,
Turnstile state, and other session-backed workflow state can therefore be
reset at deployment.

Separate direct cookies include `locale`, `last_request_id`, `last_body_id`,
and `widget_vote`. They are not Rails session payloads and must not be assumed
to have the same serialization or migration behaviour.

## Deployment Gate

Before deploying the serializer change:

1. Confirm session values used by anonymous, authenticated, administrator,
   remember-me, OTP, Turnstile, CSRF, locale, and post-redirect flows are JSON
   representable.
2. Run the session, authentication, CSRF, direct-cookie, and malformed-cookie
   test coverage on the supported Ruby and Rails environment.
3. Notify operators that existing sessions will be invalidated and that users
   may lose in-progress session-backed workflow state.
4. Record the deployment time and current session key version so telemetry can
   be correlated with the migration.
5. Confirm the deployment owner has access to authentication, CSRF, invalid
   cookie, and application-error telemetry before rollout.

Do not add a fallback to `:hybrid` to preserve old sessions. That would restore
the unsafe deserialization path the change removes.

## Observability

Compare a normal pre-deployment window with the deployment window and monitor:

- login success and failure rates;
- administrator login and login-as failures;
- CSRF verification failures;
- invalid, undecodable, or reset session-cookie events;
- OTP, remember-me, Turnstile, and post-redirect flow failures;
- unexpected increases in anonymous sessions and support reports; and
- request error rate and latency around session middleware.

Record the deployment identifier and observation window with the release
evidence. Avoid logging cookie values, session contents, secrets, or tokens.

## Legacy Sessions And Key Rotation

The JSON-only serializer rejects legacy Marshal session data rather than
converting it. Let the old browser cookie be replaced by the next valid session
response or explicitly expire it if repeated decode failures affect service
availability. Neither path may deserialize the old payload.

For a future planned session-key rotation, introduce an explicitly versioned
key through the supported configuration path, test that cookies under the old
key cannot authenticate under the new key, and deploy the new key and JSON
serializer together. Retire the old signing and encryption secrets after the
documented overlap period. Never copy an old cookie value into the new key or
log either value during diagnosis.

Emergency secret rotation takes precedence over session continuity. It should
invalidate all sessions, be recorded as an incident action, and require users
to authenticate again.

## Rollback

Application rollback must preserve `:json` where possible. If the prior
application version requires `:hybrid`, restoring it is an emergency
availability action, not a security resolution. Such a rollback requires:

- an incident owner and recorded reason;
- a short, dated expiry for the restored legacy path;
- monitoring for authentication, CSRF, and cookie-decoding failures; and
- a follow-up deployment that restores JSON-only serialization.

Do not rotate the session key or secrets during an ordinary code rollback
unless invalidating all sessions is an explicit incident decision. After any
rollback, smoke-test anonymous, authenticated, administrator, logout, OTP,
remember-me, CSRF, and post-redirect flows.

## Completion Evidence

Release evidence must include supported-environment tests for the flows above,
proof that malformed and legacy cookies cannot authenticate or bypass CSRF,
direct-cookie regression coverage, deployment and rollback smoke-test results,
and a Brakeman report with no unapproved `CookieSerialization` finding.

