## ADDED Requirements

### Requirement: Public-safe delivery lab scope
The system SHALL remain a small public-safe delivery/CD lab harness rather than the real homelab configuration.

#### Scenario: Private homelab material is excluded
- **WHEN** foundation documentation describes repo scope
- **THEN** it SHALL exclude private homelab state, provider credentials, real domain configuration, Terraform state, SOPS secrets, and production-only assumptions.

### Requirement: Prior art stays external
The system SHALL treat `homelab-k8s` as prior art only, not as a source of copied production complexity.

#### Scenario: Prior art is referenced
- **WHEN** the foundation docs reference `homelab-k8s`
- **THEN** they SHALL describe it as a reference for patterns rather than a dependency or required source of manifests.

### Requirement: Garden remains pre-CD validation harness
Garden SHALL be used for local and CI-style validation, testing, and disposable exercise workflows, not as the owner of production GitOps deployment.

#### Scenario: Real homelab deployment is described
- **WHEN** documentation describes the real homelab deployment boundary
- **THEN** it SHALL state that the real homelab ArgoCD installation owns homelab reconciliation after changes are pushed to Git.

#### Scenario: Local ArgoCD is described
- **WHEN** documentation describes running ArgoCD from Garden
- **THEN** it SHALL frame that workflow as a disposable local reconciliation exercise for studying ArgoCD behavior, not as the canonical production deployment path.
