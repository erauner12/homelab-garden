## 1. Composition Design

- [ ] 1.1 Document the adapted `kagent-garden` pattern: app-owned overlays plus thin target indexes.
- [ ] 1.2 Define the minimal `homelab-garden` domain split without copying `kagent-garden` wholesale.
- [ ] 1.3 Decide whether to move existing `platform/` and `apps/demo-api/` immediately or bridge them during the first implementation slice; prefer bridge-first if a move would delay local ArgoCD correctness.

## 2. Kustomize Layout

- [ ] 2.1 Add or migrate to `k8s/apps/platform/.../base` and `overlays/local` for platform/namespace state.
- [ ] 2.2 Add or migrate to `k8s/apps/workloads/demo-api/base` and `overlays/local` for the demo API.
- [ ] 2.3 Add `k8s/targets/local` as a thin composition index over the selected local overlays.
- [ ] 2.4 Add `k8s/targets/hcloud-lab` only when the hcloud lane needs a target composition.

## 3. Garden and Validation Wiring

- [ ] 3.1 Update Garden deploy actions to point at the selected raw-Kustomize-safe overlays or target indexes.
- [ ] 3.2 Update static/schema/contract validation render paths to match the new desired-state roots.
- [ ] 3.3 If paths move, update Garden deploy actions, validation scripts, and Go contract render paths atomically so no half-migration breaks the default loop.
- [ ] 3.4 Verify `make check` and `garden workflow local-validate --env local` still run without ArgoCD, Rollouts, Prometheus, Terraform, or hcloud credentials.

## 4. ArgoCD Safety

- [ ] 4.1 Verify every ArgoCD Application source path renders with raw Kustomize alone.
- [ ] 4.2 Keep Garden-only `patchResources`, variables, and shell-derived values out of ArgoCD source paths.
- [ ] 4.3 Document target indexes as composition-only and non-owning.
