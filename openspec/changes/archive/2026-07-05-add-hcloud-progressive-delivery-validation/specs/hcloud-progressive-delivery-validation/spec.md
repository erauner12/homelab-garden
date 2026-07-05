## ADDED Requirements

### Requirement: Hcloud progressive delivery validation workflow
The system SHALL provide a separate `hcloud-rollout-demo` Garden workflow for validating Argo Rollouts on the ephemeral hcloud lab cluster.

#### Scenario: Developer runs hcloud rollout validation
- **WHEN** a developer runs `garden workflow hcloud-rollout-demo --env hcloud-lab`
- **THEN** the workflow SHALL install Argo Rollouts, apply a good Rollout scenario, validate health, smoke-test the Rollout service, and verify the ArgoCD-managed demo remains healthy.

### Requirement: Hcloud progressive delivery validation is infrastructure-neutral
The hcloud progressive delivery workflow SHALL NOT run Terraform/OpenTofu apply/destroy operations or create/delete Hetzner Cloud resources.

#### Scenario: Workflow executes hcloud rollout validation
- **WHEN** the hcloud rollout workflow runs
- **THEN** it SHALL only use Kubernetes resources in the guarded `hcloud-lab` cluster and SHALL NOT perform cloud infrastructure lifecycle operations.

### Requirement: Hcloud guard prevents wrong target
The hcloud progressive delivery workflow SHALL reuse the hcloud kubeconfig/context guard before reading or mutating cluster state.

#### Scenario: User points the workflow at another cluster
- **WHEN** the configured kubeconfig or context does not match the ephemeral hcloud lab target
- **THEN** the workflow SHALL fail before installing Rollouts or applying workloads.

### Requirement: Rollout validation does not destabilize ArgoCD-managed demo
The hcloud Rollout scenario SHALL run outside the ArgoCD-managed `demo` namespace and SHALL NOT replace the `demo-api-hcloud-lab` desired Deployment in this slice.

#### Scenario: Hcloud Rollout scenario is applied
- **WHEN** the workflow applies the good Rollout scenario
- **THEN** it SHALL target an isolated namespace and SHALL leave the ArgoCD-managed `demo/demo-api` workload available for post-validation health and smoke checks.

### Requirement: Hcloud Rollout health and smoke are validated
The hcloud progressive delivery workflow SHALL validate Kubernetes-native Rollout health and smoke-test service reachability without requiring Prometheus, a service mesh, or Rollouts CLI plugins.

#### Scenario: Rollout completes successfully
- **WHEN** the hcloud Rollout reaches a healthy phase
- **THEN** the workflow SHALL run the structured health gate and verify the service returns the expected demo API response from inside the cluster.

### Requirement: Hcloud ArgoCD baseline is healthy after Rollout validation
The hcloud progressive delivery workflow SHALL check the hcloud ArgoCD Applications and demo API smoke path after Rollout validation.

#### Scenario: Rollout validation finishes
- **WHEN** the isolated hcloud Rollout validation succeeds
- **THEN** the workflow SHALL verify `app-of-apps-hcloud-lab`, `platform-hcloud-lab`, and `demo-api-hcloud-lab` are Synced/Healthy and SHALL run the existing hcloud demo API smoke action.

### Requirement: Hcloud Rollout validation remains opt-in
The hcloud progressive delivery workflow SHALL NOT be part of default local validation or check paths.

#### Scenario: Developer runs default validation
- **WHEN** a developer runs `make check` or local validation workflows
- **THEN** hcloud Rollouts installation and validation SHALL NOT run.
