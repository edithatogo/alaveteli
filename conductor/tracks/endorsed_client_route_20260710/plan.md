# Implementation Plan: Endorsed Client Route

## Phase 0: Paired proposal

- [x] Create fork issue #28 and cross-reference fyi-cli #148.
- [x] Record the shared no-known-risk and upstream-disabled evidence gate.
- [x] Reconcile this proposal with the existing contract issues #23-#27.
- [x] Produce a server-side threat model and abuse-case matrix.

> CHECKPOINT (2026-07-26): Phase 0 reconciliation is recorded in
> `contract_reconciliation.md`; the threat and abuse-case matrix is in
> `threat_model.md`. The proposal remains disabled by default and upstream
> submission remains disabled. No production route or MCP exposure was added.

## Phase 1: Server contract and controls

- [x] Define versioned capability discovery and negotiation in
  `capability_contract.md`.
- [ ] Define disabled-default configuration, allowlists, quotas, maintenance
  windows, revocation, and emergency disablement.
- [ ] Define authentication, identity, token rotation, audit, metrics, and
  secret-redaction requirements.
- [ ] Define bounded export authorization and privacy constraints.
- [ ] Add offline fixtures/specs for enabled, disabled, unauthorized,
  throttled, degraded, revoked, and over-budget behavior.

> CHECKPOINT (2026-07-26): The capability contract is a planning artifact only.
> It defines exact-version negotiation, finite instance-controlled limits,
> fail-closed disabled/unauthorized/revoked behavior, and remote MCP disabled
> by default. Implementation remains gated on the listed offline sensors.

## Phase 2: Fork implementation slices

- [ ] Create one focused issue/PR per server control concern.
- [ ] Add harness tests and security/quality gates with no default live network.
- [ ] Document operator rollout, status, rollback, and kill-switch procedures.
- [ ] Reconcile evidence with the paired fyi-cli track after each slice.

## Phase 3: Upstream handoff

- [ ] Prepare a maintainer-readable problem/solution and limitations package.
- [ ] Obtain shared evidence-gate sign-off in both repositories.
- [ ] Open one upstream Alaveteli discussion issue only after maintainer package
  completion.
- [ ] Submit small upstream PRs only after maintainer direction.

## Closure gate

Do not close while any known security, privacy, availability, correctness, or
quality risk lacks a fix, deterministic sensor, or explicit disabled follow-up.
