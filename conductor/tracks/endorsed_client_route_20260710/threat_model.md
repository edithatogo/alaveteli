# Threat and Abuse-Case Matrix

The route is treated as privileged automation. A capability response is
advisory; existing authentication, authorization, privacy, and abuse controls
remain authoritative.

| Threat / abuse case | Impact | Required control | Evidence before enablement |
| --- | --- | --- | --- |
| Route enabled accidentally | Anonymous privileged access or load spike | Disabled-by-default configuration; fail closed on missing/ambiguous config | Config and startup/endpoint tests |
| Spoofed User-Agent or capability claim | Untrusted client appears endorsed | Scoped token plus server-side allowlist; User-Agent is telemetry only | Invalid-token and allowlist tests |
| Token theft or reuse | Unauthorized export and instance load | Secret-store token, rotation, revocation, no token in responses/logs | Redaction and rotation tests; operator runbook |
| Unbounded request rate | Service degradation | Per-client and instance-wide request quotas with `RateLimit-*` and `Retry-After` | Deterministic throttling fixtures |
| Oversized response or export | Memory, bandwidth, or privacy exposure | Item, byte, runtime, concurrency, and export ceilings | Boundary and failure-path tests |
| Retry storm after 429/degraded response | Multiplicative load | Client backoff contract and bounded retry budget | Shared offline retry fixtures |
| Capability negotiation downgrade | Client uses unsafe behavior | Explicit supported-version negotiation; reject unsupported versions | Version mismatch tests |
| Revoked client continues operating | Control-plane failure | Immediate revocation and emergency kill switch | Revocation/disablement tests |
| Cross-tenant or unauthorized records exposed | Privacy or legal harm | Existing authorization remains mandatory; route cannot bypass it | Fixture-level authorization tests |
| MCP exposure reaches public network | Uncontrolled remote execution | No remote MCP by default; sysadmin-controlled network boundary | Deployment/configuration review |
| Secret appears in traces or metrics | Credential compromise | Structured redaction and allowlisted telemetry fields | Log/trace fixture scan |
| Operator cannot recover | Prolonged incident | Document maintenance window, disablement, rollback, and status signals | Rehearsed runbook evidence |

## Residual risk rule

Any row without a deterministic sensor or an explicit disabled follow-up blocks
implementation and all upstream engagement. A low observed incident rate does
not reduce this gate.
