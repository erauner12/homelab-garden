## 1. OpenSpec Artifacts

- [x] 1.1 Create the `add-hcloud-progressive-delivery-validation` OpenSpec change.
- [x] 1.2 Document goals, non-goals, safety boundaries, and branch/targetRevision caveats.
- [x] 1.3 Add requirements for guarded hcloud Rollouts install, isolated rollout validation, health/smoke checks, and post-validation ArgoCD health.

## 2. Hcloud Rollouts Workflow

- [x] 2.1 Add a guarded hcloud Argo Rollouts install script that reuses `platform/addons/argocd/hcloud-common.sh`.
- [x] 2.2 Add minimal RBAC for the Rollout analysis job to inspect pods in its namespace.
- [x] 2.3 Add an isolated hcloud good-rollout scenario that avoids the ArgoCD-managed `demo` namespace.
- [x] 2.4 Add a guarded hcloud script to apply the isolated good rollout scenario.
- [x] 2.5 Add a guarded hcloud script to wait for Rollout health, run structured health validation, and smoke the service.
- [x] 2.6 Add hcloud-only Garden Run actions for install, apply, and status/smoke.
- [x] 2.7 Add `workflows/hcloud-rollout-demo.garden.yml` with post-validation ArgoCD health and smoke checks.

## 3. Documentation and Validation

- [x] 3.0 Add explicit hcloud API source CIDR variables discovered during live rollout validation for rotating egress/NAT environments.
- [x] 3.1 Document the new optional hcloud progressive delivery workflow and prerequisites.
- [x] 3.2 Run bash syntax checks for new scripts.
- [x] 3.3 Run Kustomize render checks for the new scenario.
- [x] 3.4 Run `garden validate --env hcloud-lab` where possible without applying infrastructure.
- [x] 3.5 Run `openspec validate add-hcloud-progressive-delivery-validation --strict`.
- [x] 3.6 Live validation reported: `garden workflow hcloud-rollout-demo --env hcloud-lab` passed after temporarily widening the hcloud API firewall to the runner NAT `/29`; PodSecurity warnings remain for smoke pods.
