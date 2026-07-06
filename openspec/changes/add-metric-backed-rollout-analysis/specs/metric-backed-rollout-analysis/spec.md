## ADDED Requirements

### Requirement: Rollouts analysis uses demo API metrics
Metric-backed Rollouts analysis SHALL use metrics emitted by the demo API observability surface.

#### Scenario: AnalysisRun evaluates a healthy rollout
- **WHEN** a metric-backed rollout analysis runs against a healthy demo API version
- **THEN** it SHALL query demo API metrics and allow rollout progression according to the documented success criteria.

#### Scenario: AnalysisRun evaluates a failing rollout
- **WHEN** demo API metrics indicate the controlled failure threshold has been exceeded
- **THEN** the analysis SHALL fail and the Rollout SHALL stop, pause, abort, or roll back according to the documented Rollouts behavior.

### Requirement: Prometheus is optional and scoped
Prometheus SHALL be installed or used only for workflows that explicitly require metric queries.

#### Scenario: Developer runs default validation
- **WHEN** a developer runs `make check` or the default local validation workflow
- **THEN** Prometheus SHALL NOT be required or installed for metric-backed rollout analysis.

#### Scenario: Developer runs metric analysis workflow
- **WHEN** a developer runs the optional metric-backed analysis workflow
- **THEN** any Prometheus dependency SHALL be documented, lab-scoped, and removable without affecting the default validation loop.

### Requirement: Metric analysis depends on app metrics
The metric-backed analysis path SHALL NOT be implemented before the demo API exposes the required metrics.

#### Scenario: Required metrics are absent
- **WHEN** a metric-backed analysis workflow starts and required demo API metrics are absent
- **THEN** the workflow SHALL fail with an actionable prerequisite error rather than installing unrelated substitutes or passing without analysis.

### Requirement: Hcloud metric analysis is guarded
Metric-backed analysis against hcloud SHALL target only the disposable `hcloud-lab` cluster.

#### Scenario: Hcloud analysis starts
- **WHEN** metric-backed analysis runs with `--env hcloud-lab`
- **THEN** it SHALL verify the hcloud target guard before installing, querying, or mutating any Kubernetes resources.
