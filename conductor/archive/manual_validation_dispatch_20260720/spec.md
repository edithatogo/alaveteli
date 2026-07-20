# Specification

## Objective

Allow fork maintainers to run the existing CI, RuboCop, security, and changelog
workflows manually against a selected branch without weakening pull-request or
push validation.

## Requirements

- Existing workflow triggers and commands remain unchanged.
- Manual dispatch is explicit and fork-controlled.
- Changelog dispatch accepts a base ref and PR-body equivalent as data.
- The base ref is quoted before use in shell commands.
- A manual run never represents approval, review, or a merge authorization.

## Acceptance

- Workflow syntax and static analysis pass.
- Current Ruby 3.4 and Ruby 4.0 hosted matrices pass.
- Brakeman, dependency audit/review, Bearer, RuboCop, and changelog checks pass.
- Issue #73 and PR #41 retain the immutable merge/check evidence at closeout.
