## ADDED Requirements

### Requirement: Tenant wave simulation uses a small fixed sample
The tenant wave simulation SHALL start with a small public-safe sample of three tenants.

#### Scenario: Tenant sample is loaded
- **WHEN** the simulation loads tenant data
- **THEN** it SHALL include exactly three sample tenants with public-safe names and no real customer, private homelab, or provider data.

### Requirement: Simulation references release intent
The tenant wave simulation SHALL use release intent and artifact identity to describe what each tenant would receive.

#### Scenario: Simulation runs with release intent
- **WHEN** a release intent document is provided
- **THEN** the simulation output SHALL reference the intended app, environment, Git revision, manifest path, and image identity from that release intent.

### Requirement: Wave ordering and stop conditions are explicit
The tenant wave simulation SHALL model ordered waves, per-tenant gate status, and stop-on-blocker behavior.

#### Scenario: Earlier wave has blocker
- **WHEN** a tenant in an earlier wave has a blocker or failed gate
- **THEN** the simulation SHALL mark later waves as blocked or not ready according to the documented stop condition.

#### Scenario: All gates pass
- **WHEN** every tenant gate in the current wave passes
- **THEN** the simulation SHALL mark the next wave as eligible in the rendered output without mutating Git or cluster state.

### Requirement: Simulation is non-mutating
The tenant wave simulation SHALL NOT generate PRs, apply manifests, patch clusters, sync ArgoCD, promote Rollouts, or reconcile resources.

#### Scenario: Simulation completes
- **WHEN** the tenant wave simulation renders its output
- **THEN** it SHALL have changed no cluster, Git remote, ArgoCD, Rollouts, Terraform, or hcloud resources.

### Requirement: No custom delivery controller is introduced
The tenant wave simulation SHALL NOT require a custom DeliveryPlan CRD, controller, or reconciler.

#### Scenario: Simulation model is defined
- **WHEN** the tenant wave model is documented or validated
- **THEN** it SHALL be represented as files or report inputs rather than a Kubernetes custom resource requiring a controller.
