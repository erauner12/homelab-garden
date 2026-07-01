## ADDED Requirements

### Requirement: Separate policy validation workflow
The system SHALL provide a separate policy validation workflow for local Kyverno CLI checks.

#### Scenario: Developer runs policy validation
- **WHEN** a developer runs `make policy-validate`
- **THEN** the command SHALL invoke `garden workflow policy-validate --env local`, which SHALL run a Garden exec test named `policy-validation`, which SHALL invoke `validation/policy.sh` against local Kyverno fixtures without requiring the Kyverno admission controller.

### Requirement: Default check remains independent
The `policy-validate` workflow SHALL NOT be required by `make check` unless explicitly promoted by a later change.

#### Scenario: Developer runs make check
- **WHEN** a developer runs `make check`
- **THEN** the command SHALL NOT require Kyverno CLI or Kyverno admission controller installation.

### Requirement: Contract and policy ownership is explicit
The system SHALL distinguish repo-specific Go contract checks from cluster-enforceable Kyverno policy checks.

#### Scenario: A safety rule is added
- **WHEN** a new safety rule is introduced
- **THEN** implementation SHALL place repo-layout invariants in Go contracts and admission-style guardrails in Kyverno policy tests.

### Requirement: Missing Kyverno is actionable
The policy validation entrypoint SHALL report a clear actionable error when the Kyverno CLI is missing.

#### Scenario: Kyverno CLI is absent
- **WHEN** a developer runs policy validation without `kyverno` installed
- **THEN** the command SHALL fail with an error that names the missing tool and how to install or skip the optional workflow.
