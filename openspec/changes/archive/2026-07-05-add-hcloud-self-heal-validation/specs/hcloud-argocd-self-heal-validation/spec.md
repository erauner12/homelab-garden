## ADDED Requirements

### Requirement: Hcloud self-heal validation workflow
The system SHALL provide a separate `hcloud-argocd-self-heal` Garden workflow for validating ArgoCD self-heal behavior on the ephemeral hcloud lab cluster.

#### Scenario: Developer runs hcloud self-heal validation
- **WHEN** a developer runs `garden workflow hcloud-argocd-self-heal --env hcloud-lab`
- **THEN** the workflow SHALL validate an already-reconciled hcloud ArgoCD installation, induce safe demo workload drift, wait for self-heal, and run the demo API smoke test.

### Requirement: Hcloud self-heal validation is infrastructure-neutral
The hcloud self-heal validation workflow SHALL NOT run Terraform apply/destroy operations or create/delete Hetzner Cloud resources.

#### Scenario: Workflow executes self-heal validation
- **WHEN** the hcloud self-heal workflow runs
- **THEN** it SHALL only use Kubernetes and ArgoCD resources in the guarded `hcloud-lab` cluster and SHALL NOT perform cloud infrastructure lifecycle operations.

### Requirement: Hcloud guard prevents wrong target
The hcloud self-heal validation workflow SHALL reuse the hcloud kubeconfig/context guard before reading or mutating cluster state.

#### Scenario: User points the workflow at another cluster
- **WHEN** the configured kubeconfig or context does not match the ephemeral hcloud lab target
- **THEN** the workflow SHALL fail before mutating any workload.

### Requirement: Baseline ArgoCD health is required before drift
The hcloud self-heal validation workflow SHALL verify hcloud Applications exist and are Synced and Healthy before inducing drift.

#### Scenario: Hcloud applications are not healthy
- **WHEN** `app-of-apps-hcloud-lab`, `platform-hcloud-lab`, or `demo-api-hcloud-lab` is missing, not Synced, or not Healthy
- **THEN** the workflow SHALL stop and report current Application and workload status without creating drift.

### Requirement: Demo deployment drift is safe and self-healed
The hcloud self-heal validation workflow SHALL create bounded live drift on `deployment/demo-api` in namespace `demo` and wait for ArgoCD to restore the reconciled replica count.

#### Scenario: Demo deployment is scaled away from desired state
- **WHEN** the workflow scales the live `demo-api` Deployment away from the healthy baseline replica count
- **THEN** it SHALL wait until the Deployment returns to the baseline replica count and `demo-api-hcloud-lab` returns to Synced and Healthy.

### Requirement: Smoke test runs after self-heal
The hcloud self-heal validation workflow SHALL run the existing demo API smoke test after self-heal succeeds.

#### Scenario: Self-heal completes
- **WHEN** ArgoCD has restored the demo Deployment and Application health
- **THEN** the workflow SHALL run the existing `validation/smoke-demo-api.sh` path through Garden with hcloud environment variables.

### Requirement: Self-heal failures include diagnostics
The hcloud self-heal validation workflow SHALL emit actionable diagnostics when baseline validation, drift, self-heal waiting, or smoke validation fails.

#### Scenario: Self-heal validation fails
- **WHEN** any self-heal validation step fails
- **THEN** output SHALL include current ArgoCD Application status, demo Deployment status, pods/events, and recent relevant logs when available.
