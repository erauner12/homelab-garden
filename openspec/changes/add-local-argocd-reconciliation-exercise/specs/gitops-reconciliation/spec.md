## ADDED Requirements

### Requirement: Separate local ArgoCD reconciliation exercise
The system SHALL provide a separate `local-argocd-reconcile` workflow for disposable local ArgoCD reconciliation validation.

#### Scenario: Developer runs local ArgoCD reconciliation
- **WHEN** a developer runs `garden workflow local-argocd-reconcile --env local`
- **THEN** the workflow SHALL install or apply ArgoCD only in the local kind cluster, wait for ArgoCD readiness, apply the parent Application, and verify child Application sync or health status.

### Requirement: Local ArgoCD exercise is outside default validation
The `local-argocd-reconcile` workflow SHALL NOT be invoked by `make check` or `local-validate`.

#### Scenario: Developer runs default validation
- **WHEN** a developer runs `make check` or `garden workflow local-validate --env local`
- **THEN** neither command SHALL install ArgoCD or require ArgoCD resources.

### Requirement: Platform reconciles before demo app
The GitOps application graph SHALL reconcile the local platform desired state before the demo API desired state.

#### Scenario: App-of-apps reconciles children
- **WHEN** ArgoCD reconciles child Applications
- **THEN** `platform-local` SHALL reconcile before `demo-api-local` so namespace and platform dependencies are explicit.

### Requirement: Demo app self-heals live drift
The demo app Application SHALL use automated sync with self-heal enabled and prune disabled for the first drift exercise.

#### Scenario: Demo deployment is manually scaled
- **WHEN** a user manually changes the live `demo-api` Deployment replica count
- **THEN** ArgoCD SHALL detect drift and self-heal the resource back to the Git-declared desired state.

### Requirement: Remote Git source is documented
The first local ArgoCD reconciliation exercise SHALL use a remote HTTPS Git source and documented branch or revision.

#### Scenario: User expects local uncommitted changes to sync
- **WHEN** documentation describes the local ArgoCD reconciliation workflow
- **THEN** it SHALL state that uncommitted local changes are invisible to ArgoCD until pushed to the tracked Git source.

### Requirement: Real homelab ArgoCD is not managed
The local ArgoCD reconciliation exercise SHALL NOT deploy to, configure, sync, or manage the real homelab ArgoCD installation.

#### Scenario: User runs the local exercise
- **WHEN** a developer runs the local ArgoCD reconciliation workflow
- **THEN** all ArgoCD installation and Application changes SHALL be scoped to the disposable local kind cluster.
