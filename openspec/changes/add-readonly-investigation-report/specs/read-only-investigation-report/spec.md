## ADDED Requirements

### Requirement: Read-only investigation workflow
The system SHALL provide an `investigate-demo` Garden workflow that renders a Markdown investigation report for `demo-api` without mutating the cluster.

#### Scenario: Developer runs investigation
- **WHEN** a developer runs `garden workflow investigate-demo --env local`
- **THEN** the workflow SHALL collect context and render a Markdown report for `demo-api`.
- **AND** the workflow SHALL NOT apply, delete, patch, scale, sync, promote, rollback, or remediate resources.

### Requirement: Report includes required sections
The investigation report SHALL include Summary, Environment, GitOps Status, Rollout Status, Workload Status, Health Signals, Recent Events, Recent Logs, Safe Next Actions, and Approval-Required Actions sections.

#### Scenario: Report is rendered
- **WHEN** the investigation script completes
- **THEN** the generated Markdown SHALL contain each required section heading.

### Requirement: Optional ArgoCD tolerance
The investigation SHALL tolerate ArgoCD being absent.

#### Scenario: ArgoCD is absent
- **WHEN** ArgoCD Application CRDs are not installed
- **THEN** the report SHALL include `argocd: not_installed` and continue rendering other sections.

### Requirement: Optional Argo Rollouts tolerance
The investigation SHALL tolerate Argo Rollouts being absent.

#### Scenario: Argo Rollouts is absent
- **WHEN** Argo Rollouts CRDs are not installed
- **THEN** the report SHALL include `rollouts: not_installed` and continue rendering other sections.

### Requirement: Context collection
The investigation SHALL collect current kube context, relevant namespaces, recent events, demo deployment or rollout status, pods, services, recent logs, optional ArgoCD application sync and health, optional Argo Rollouts phase/message, ReplicaSets, AnalysisRuns, and `validation/health.sh` output when available.

#### Scenario: Context command fails
- **WHEN** a read-only context command fails because a resource is absent
- **THEN** the report SHALL include the command output or absence note and continue where possible.
