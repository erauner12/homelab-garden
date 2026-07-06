## ADDED Requirements

### Requirement: Separate Kyverno admission exercise
The system SHALL provide a separate optional exercise for live Kyverno admission behavior.

#### Scenario: Developer runs local admission exercise
- **WHEN** a developer runs the local Kyverno admission exercise
- **THEN** the exercise SHALL install or enable Kyverno only in the disposable local cluster, apply lab-scoped policies, and run allow and deny fixtures.

### Requirement: Admission exercise is outside default validation
The Kyverno admission exercise SHALL NOT be invoked by `make check`, `local-validate`, or the existing `policy-validate` CLI path.

#### Scenario: Developer runs default checks
- **WHEN** a developer runs `make check`, `garden workflow local-validate --env local`, or `make policy-validate`
- **THEN** those commands SHALL NOT require a Kyverno admission controller to be installed.

### Requirement: Admission exercise covers allow and deny outcomes
The Kyverno admission exercise SHALL prove both successful admission and rejected admission for public-safe fixtures.

#### Scenario: Allowed fixture is applied
- **WHEN** the exercise applies a compliant fixture
- **THEN** the Kubernetes API SHALL admit the resource and the exercise SHALL report the allowed result.

#### Scenario: Denied fixture is applied
- **WHEN** the exercise applies a non-compliant fixture
- **THEN** Kyverno admission SHALL reject the resource and the exercise SHALL report the policy and reason for denial.

### Requirement: Hcloud admission exercise is guarded
The hcloud Kyverno admission exercise SHALL target only the disposable `hcloud-lab` cluster.

#### Scenario: Developer runs hcloud admission exercise
- **WHEN** a developer runs the admission exercise with `--env hcloud-lab`
- **THEN** it SHALL verify the hcloud target guard before installing Kyverno or applying policy fixtures.

### Requirement: Admission exercise cleanup is explicit
The Kyverno admission exercise SHALL document cleanup for policies, fixtures, and Kyverno components it installs.

#### Scenario: Exercise completes
- **WHEN** the admission exercise finishes or fails
- **THEN** documentation SHALL describe how to remove lab-scoped policies, fixtures, and optional Kyverno components without affecting other workflows.
