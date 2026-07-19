# Specification

## Objective

Restore a trustworthy supported-Ruby CI baseline and eliminate known security
findings without retries, exclusions, or scanner suppression.

## Workstreams

- Supported Ruby matrix policy (#58).
- Strict batch request parameter normalization (#57).
- Rack::Attack and BotTrafficMetrics test-state isolation (#63/#64).
- Xapian uniqueness-state isolation and complete failure taxonomy (#62/#65).
- Brakeman and dependency-audit remediation (#59).

## Acceptance

- Ruby 3.4 core and gem suites pass from a clean hosted environment.
- Experimental Ruby jobs execute on an available runtime and remain explicitly
  non-production.
- Brakeman and dependency audit pass without suppressing known risk.
- Every formerly observed failure maps to a resolved issue and immutable run.
