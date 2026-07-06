# Demo API Observability Surface Specification

## Purpose
Define the lab-safe demo API health, readiness, metrics, and simulation contract used by delivery validation exercises.

## Requirements

### Requirement: Demo API exposes health and readiness endpoints
The demo API SHALL expose stable health and readiness endpoints suitable for local and hcloud lab validation.

#### Scenario: Health endpoint is queried
- **WHEN** a validation workflow queries the demo API health endpoint
- **THEN** the response SHALL indicate whether the process is healthy using a deterministic status and machine-readable body or status code.

#### Scenario: Readiness endpoint is queried
- **WHEN** a validation workflow queries the demo API readiness endpoint
- **THEN** the response SHALL indicate whether the app is ready to receive traffic without requiring external cloud or homelab dependencies.

### Requirement: Demo API exposes rollout-relevant metrics
The demo API SHALL expose a small metrics surface that future rollout analysis can consume without requiring Prometheus to exist in this change.

#### Scenario: Metrics endpoint is queried
- **WHEN** a validation workflow queries the metrics endpoint
- **THEN** the response SHALL include rollout-relevant request, error, latency, and simulation-state signals in a documented machine-readable format.

### Requirement: Demo API supports bounded simulation modes
The demo API SHALL provide controlled simulation modes for healthy, degraded, failing, and latency-injected behavior.

#### Scenario: Failure simulation is enabled
- **WHEN** a future workflow enables a failing simulation mode for the demo API
- **THEN** the app SHALL produce deterministic failed health or request behavior and expose the active mode through health or metrics output.

#### Scenario: Simulation is reset
- **WHEN** a workflow resets simulation state
- **THEN** the demo API SHALL return to the documented healthy behavior without requiring cluster recreation.

### Requirement: Observability surface remains lab-safe
The demo API observability surface SHALL remain safe for a public disposable lab.

#### Scenario: Observability output is inspected
- **WHEN** health, readiness, or metrics output is viewed
- **THEN** it SHALL NOT expose secrets, real homelab identifiers, provider credentials, private domains, or Terraform state.
