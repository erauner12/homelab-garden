## 1. Composition Design

- [x] 1.1 Document the adapted `kagent-garden` pattern: app-owned overlays plus thin target indexes. See `docs/targeted-kustomize-composition.md`.
- [x] 1.2 Define the minimal `homelab-garden` domain split without copying `kagent-garden` wholesale. Current split is `k8s/apps/platform/foundation`, `k8s/apps/workloads/demo-api`, and `k8s/targets/local`.
- [x] 1.3 Decide whether to move existing `platform/` and `apps/demo-api/` immediately or bridge them during the first implementation slice; prefer bridge-first if a move would delay local ArgoCD correctness. Chose a small immediate move for the two active roots and updated Garden/validation atomically.

## 2. Kustomize Layout

- [x] 2.1 Add or migrate to `k8s/apps/platform/.../base` and `overlays/local` for platform/namespace state. Implemented `k8s/apps/platform/foundation/{base,overlays/local}`.
- [x] 2.2 Add or migrate to `k8s/apps/workloads/demo-api/base` and `overlays/local` for the demo API.
- [x] 2.3 Add `k8s/targets/local` as a thin composition index over the selected local overlays.
- [x] 2.4 Add `k8s/targets/hcloud-lab` only when the hcloud lane needs a target composition. Deferred intentionally; no hcloud lane exists in this change, documented in `docs/targeted-kustomize-composition.md`.

## 3. Garden and Validation Wiring

- [x] 3.1 Update Garden deploy actions to point at the selected raw-Kustomize-safe overlays or target indexes. `platform` and `demo-api` deploy actions now point at `k8s/apps/**/overlays/local`.
- [x] 3.2 Update static/schema/contract validation render paths to match the new desired-state roots. Static/schema also render `k8s/targets/local`.
- [x] 3.3 If paths move, update Garden deploy actions, validation scripts, and Go contract render paths atomically so no half-migration breaks the default loop.
- [x] 3.4 Verify `make check` and `garden workflow local-validate --env local` still run without ArgoCD, Rollouts, Prometheus, Terraform, or hcloud credentials. Verified both; one immediate `make check` rerun hit a transient smoke pod deletion race, then passed after waiting.

## 4. ArgoCD Safety

- [x] 4.1 Verify every ArgoCD Application source path renders with raw Kustomize alone. No ArgoCD Applications exist yet; verified raw Kustomize render for sourceable paths `k8s/apps/platform/foundation/overlays/local`, `k8s/apps/workloads/demo-api/overlays/local`, and `k8s/targets/local`.
- [x] 4.2 Keep Garden-only `patchResources`, variables, and shell-derived values out of ArgoCD source paths. No Garden-only templates, `patchResources`, or shell-derived values were added under `k8s/apps/**` or `k8s/targets/**`.
- [x] 4.3 Document target indexes as composition-only and non-owning. See `docs/targeted-kustomize-composition.md`.
