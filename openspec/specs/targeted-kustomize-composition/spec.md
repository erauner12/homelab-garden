# targeted-kustomize-composition Specification

## Purpose

Define the Kustomize desired-state layout used by the delivery lab: Kubernetes manifests live in app/domain-owned overlays under `k8s/apps/**`, while `k8s/targets/<target>` directories provide thin raw-Kustomize-safe composition indexes that Garden and future ArgoCD workflows can share.

## Requirements
### Requirement: App-owned overlays
Kubernetes manifests SHALL be owned by domain/app roots under `k8s/apps/**`, with base manifests and target-specific overlays kept near the owning app or domain.

#### Scenario: New Kubernetes desired state is added
- **WHEN** implementation adds new Kubernetes manifests
- **THEN** they SHALL be placed under the owning `k8s/apps/<domain>/<app-or-capability>/base` and `overlays/<target>` structure rather than directly under `k8s/targets/<target>`.

### Requirement: Target indexes are composition only
`k8s/targets/<target>` SHALL be a thin Kustomize composition index over app-owned target overlays and SHALL NOT own copied resources.

#### Scenario: Target composition is added
- **WHEN** implementation adds `k8s/targets/local` or `k8s/targets/hcloud-lab`
- **THEN** the target kustomization SHALL reference app-owned overlays and SHALL NOT define copied Kubernetes resources directly.

### Requirement: Raw-Kustomize-safe ArgoCD paths
Any Kustomize path used as an ArgoCD Application source SHALL be renderable by raw Kustomize without Garden-only template syntax, Garden variables, or Garden-only patch behavior.

#### Scenario: ArgoCD source path is configured
- **WHEN** an ArgoCD Application points at a repo path
- **THEN** that path SHALL render with Kustomize alone and SHALL NOT depend on Garden `patchResources`, Garden template expansion, or local shell state.

### Requirement: Garden and ArgoCD share desired-state paths
When Garden and ArgoCD are proving the same desired state for a target, they SHALL consume the same Kustomize overlay or target-index path.

#### Scenario: Local reconciliation exercise is implemented
- **WHEN** Garden runs the local ArgoCD reconciliation exercise
- **THEN** the Garden validation path and ArgoCD Application source paths SHALL be aligned to the same raw-Kustomize-safe desired-state roots, except for explicitly documented Garden-only preflight or harness actions.

### Requirement: First implementation stays minimal
The first implementation of targeted composition SHALL preserve the existing default validation loop and SHALL NOT require a broad directory migration before local ArgoCD or hcloud correctness needs it.

#### Scenario: Implementation chooses bridge-first composition
- **WHEN** moving existing `platform/` and `apps/demo-api/` paths would risk breaking `make check` or `local-validate`
- **THEN** implementation MAY bridge those roots into the targeted composition model while still exposing raw-Kustomize-safe paths for Garden and ArgoCD.

### Requirement: Target identity stays separate from cluster mechanism
Target names SHALL represent desired-state identity, not the mechanism used to run a cluster.

#### Scenario: Hcloud target is added
- **WHEN** implementation adds `hcloud-lab`
- **THEN** `hcloud-lab` SHALL identify the desired-state target composition, while Terraform/Garden configuration SHALL own how the ephemeral cluster is created and accessed.

