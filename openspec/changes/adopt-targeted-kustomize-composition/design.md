## Context

`kagent-garden` separates resource ownership from target composition: manifests stay under owning `k8s/apps/**/base|overlays/<target>` roots, while `k8s/targets/<target>` is a thin composition/documentation index. Garden actions deploy Kustomize roots with `spec.kustomize.path`, and target overlays add target labels consistently. The important part for `homelab-garden` is not the size of that repo, but the boundary: Garden and ArgoCD can consume the same raw Kustomize desired-state paths if Garden-only templating and patching stay outside ArgoCD-owned paths.

## Goals / Non-Goals

**Goals:**
- Define a small `k8s/apps` and `k8s/targets` composition model suitable for local kind and hcloud-lab.
- Keep the first implementation bridge-oriented if that preserves the fast validation loop.
- Keep target indexes thin and non-owning.
- Ensure paths intended for ArgoCD are raw-Kustomize-safe.
- Give Garden and ArgoCD a shared desired-state interface.

**Non-Goals:**
- Do not copy the full `kagent-garden` domain tree.
- Do not perform a broad directory migration before it is needed for ArgoCD or hcloud correctness.
- Do not add mesh, ingress, observability, service mesh, or test-support domains unless another change requires them.
- Do not add Garden-template syntax to paths ArgoCD will reconcile.
- Do not make target indexes responsible for owning manifests.

## Decisions

- Start with the smallest useful domain split:
  - `k8s/apps/platform/**` for namespaces/platform substrate needed by the demo.
  - `k8s/apps/policy/**` for Kyverno policy desired state when admission is later enabled.
  - `k8s/apps/workloads/demo-api/**` for the demo workload.
  - `k8s/apps/gitops/argocd/**` only for local/hcloud ArgoCD exercise resources if they need checked-in manifests.
- Add `k8s/targets/local` and later `k8s/targets/hcloud-lab` as thin Kustomize indexes over selected app-owned overlays.
- The first implementation may bridge the existing `platform/` and `apps/demo-api/` roots if moving them immediately would risk the default validation loop.
- Garden may deploy individual overlays or target indexes, but ArgoCD must point only at raw-Kustomize-safe paths.
- If Garden needs `patchResources` or Garden variables for local-only behavior, keep that behavior in Garden action config or local-only overlays that are not used as ArgoCD source paths.

## Risks / Trade-offs

- Moving too much structure early can bloat the lab → introduce only the directories needed by active changes.
- Dual source paths can drift → prefer one Kustomize path per target when ArgoCD and Garden are proving the same desired state.
- Garden-only patches can make ArgoCD reproduction false → require raw-Kustomize-safe paths for every ArgoCD Application source.
