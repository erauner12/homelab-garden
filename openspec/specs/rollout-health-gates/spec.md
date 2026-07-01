# rollout-health-gates Specification

## Purpose

Define the first rollout health gate for the local progressive delivery demo. This capability keeps health evaluation Kubernetes-native and structured before introducing metrics or Prometheus-backed analysis.

## Requirements

### Requirement: Minimal health gate
The first rollout health gate SHALL use Kubernetes readiness and rollout status rather than Prometheus.

#### Scenario: Health gate runs during failure demo
- **WHEN** the failure demo evaluates rollout health
- **THEN** it SHALL inspect Kubernetes readiness and rollout status without requiring Prometheus.

### Requirement: Structured health output
The health gate SHALL produce structured output suitable for later automation.

#### Scenario: Health check completes
- **WHEN** `validation/health.sh` completes
- **THEN** it SHALL emit a structured pass/fail result with the evaluated signals.

### Requirement: Signal classes are documented
The health gate SHALL distinguish automation-grade signals from diagnostic-only signals.

#### Scenario: Documentation describes health gates
- **WHEN** health gate documentation is written
- **THEN** it SHALL identify which signals are safe for automated rollout decisions and which are diagnostic only.

### Requirement: Metrics come before Prometheus
Demo API metrics SHALL be added before introducing a lightweight Prometheus dependency.

#### Scenario: Health gates are expanded later
- **WHEN** a later change expands beyond readiness and rollout status
- **THEN** it SHALL prefer demo API metrics before adding Prometheus-backed queries.
