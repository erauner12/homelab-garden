## ADDED Requirements

### Requirement: Optional hcloud lab environment
The system SHALL provide an optional `hcloud-lab` environment for disposable cloud-cluster reconciliation testing.

#### Scenario: Developer runs default validation
- **WHEN** a developer runs `make check`, `garden workflow local-validate --env local`, `make policy-validate`, or `garden workflow local-argocd-reconcile --env local`
- **THEN** none of those commands SHALL require Hetzner Cloud credentials, Terraform state, Talos config, or cloud resources.

### Requirement: Explicit Terraform lifecycle
The `hcloud-lab` environment SHALL require explicit Terraform plan/apply before any cloud resources are created.

#### Scenario: Developer prepares cloud infrastructure
- **WHEN** a developer wants to create the hcloud lab cluster
- **THEN** the documented path SHALL require an explicit Terraform plan command followed by an explicit apply command.

### Requirement: Reconciliation does not apply infrastructure
The hcloud reconciliation workflow SHALL NOT run Terraform apply or destroy operations.

#### Scenario: Developer runs hcloud reconciliation
- **WHEN** a developer runs `garden workflow hcloud-argocd-reconcile --env hcloud-lab`
- **THEN** the workflow SHALL assume infrastructure already exists and SHALL NOT create, modify, or destroy Hetzner Cloud infrastructure.

### Requirement: Terraform auto-apply disabled
The `hcloud-lab` Terraform integration SHALL NOT automatically apply infrastructure changes during default Garden initialization or validation.

#### Scenario: Garden initializes hcloud environment
- **WHEN** Garden initializes the `hcloud-lab` environment
- **THEN** it SHALL NOT create or modify Hetzner Cloud resources unless the operator has invoked an explicit Terraform apply path.

### Requirement: Hcloud preflight fails before apply
The hcloud lab SHALL provide a preflight path that fails before Terraform apply when required tools or credentials are missing.

#### Scenario: Required tools or credentials are missing
- **WHEN** a developer runs the hcloud lab preflight without required tools or credentials
- **THEN** the preflight SHALL fail before Terraform apply and report the missing prerequisites.

### Requirement: Sensitive files stay out of Git
The hcloud lab SHALL keep provider credentials, Terraform state, tfvars, kubeconfig, talosconfig, and generated secret material out of Git.

#### Scenario: Hcloud lab files are added
- **WHEN** implementation adds `infra/hcloud-lab/` or related scripts
- **THEN** repository ignore rules and documentation SHALL prevent committing credentials, state, tfvars, kubeconfig, talosconfig, and generated secret material.

### Requirement: Garden consumes Terraform outputs
The hcloud lab SHALL expose or materialize Terraform outputs needed by Garden to target the ephemeral Kubernetes cluster.

#### Scenario: Terraform apply completes
- **WHEN** the hcloud Terraform stack has been applied successfully
- **THEN** Garden SHALL be able to use the resulting kubeconfig output or kubeconfig path to run validation and reconciliation workflows against the ephemeral cluster.

### Requirement: Hcloud reconciliation workflow
The system SHALL provide an optional hcloud reconciliation workflow that verifies the GitOps desired state on real disposable infrastructure.

#### Scenario: Developer runs hcloud reconciliation
- **WHEN** a developer runs the hcloud reconciliation workflow after provisioning the hcloud lab cluster
- **THEN** the workflow SHALL install or bootstrap ArgoCD only into the ephemeral Hetzner cluster, reconcile platform before demo app, and verify sync/health or drift/self-heal behavior.

### Requirement: Real homelab remains out of scope
The hcloud lab SHALL NOT deploy to, configure, sync, or manage the real homelab ArgoCD installation.

#### Scenario: Hcloud workflow runs
- **WHEN** the hcloud reconciliation workflow runs
- **THEN** all cluster, ArgoCD, and Application operations SHALL target only the ephemeral hcloud lab cluster.

### Requirement: Cost and lifetime are explicit
The hcloud lab SHALL document expected resource classes, rough hourly cost, and intended maximum lifetime for a disposable cluster.

#### Scenario: Developer provisions hcloud lab
- **WHEN** documentation describes provisioning the hcloud lab
- **THEN** it SHALL describe expected resource classes, rough hourly cost, intended maximum lifetime, and how to check active resources.

### Requirement: Explicit teardown path
The hcloud lab SHALL provide an explicit documented teardown path.

#### Scenario: Developer finishes the cloud lab
- **WHEN** a developer completes the hcloud reconciliation exercise
- **THEN** documentation SHALL provide the commands and any module-specific delete-protection steps required to destroy the ephemeral cluster and verify cloud resources are removed.

### Requirement: Teardown verification is observable
The hcloud lab teardown path SHALL include an observable verification step for remaining Hetzner resources.

#### Scenario: Developer destroys hcloud lab
- **WHEN** teardown completes
- **THEN** documentation SHALL describe how to verify no expected hcloud servers, load balancers, or networks remain for the lab.
