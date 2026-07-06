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

### Requirement: Health gate v2 has a final decision enum
The v2 health gate output SHALL include a final decision enum for automation consumers.

#### Scenario: V2 health gate passes
- **WHEN** all required automation-grade checks pass for the evaluated target
- **THEN** the v2 output SHALL emit `decision: pass` and SHALL include the evidence that justified the pass.

#### Scenario: V2 health gate cannot prove health
- **WHEN** required checks fail, are degraded, or cannot be evaluated
- **THEN** the v2 output SHALL emit `decision: fail`, `decision: degraded`, or `decision: unknown` rather than silently passing.

### Requirement: Health gate v2 includes reason codes
The v2 health gate output SHALL include stable reason codes for every non-pass decision.

#### Scenario: V2 health gate emits a non-pass decision
- **WHEN** the v2 decision is `fail`, `degraded`, or `unknown`
- **THEN** the output SHALL include at least one reason code that explains the decision in a machine-readable form.

### Requirement: Health gate v2 includes evidence records
The v2 health gate output SHALL include structured evidence records for evaluated automation inputs.

#### Scenario: Evidence is recorded
- **WHEN** the v2 health gate evaluates Kubernetes readiness, rollout status, demo API health/readiness, or target guard state
- **THEN** the output SHALL record the signal name, source, observed value or summary, classification, and whether it contributed to the final decision.

### Requirement: Health gate v2 records environment and target guard outcome
The v2 health gate output SHALL include environment identity and target-guard outcome.

#### Scenario: V2 health gate runs for hcloud lab
- **WHEN** the v2 health gate runs against the `hcloud-lab` environment
- **THEN** it SHALL record the hcloud target-guard outcome and SHALL emit a non-pass decision if the disposable hcloud lab target cannot be verified.

### Requirement: Health gate v2 consumes demo API observability inputs
The v2 health gate SHALL consume demo API health and readiness inputs when the demo API observability surface is available.

#### Scenario: Demo API reports degraded or failing behavior
- **WHEN** demo API health or readiness reports degraded or failing behavior
- **THEN** the v2 health gate SHALL include that evidence and SHALL NOT emit `decision: pass` for the target.
