## Why

The current repo has separate `platform/` and `apps/` roots that work for the first local loop, but the later ArgoCD and hcloud lanes need stable raw-Kustomize paths that both Garden and ArgoCD can consume. `kagent-garden` provides a useful smaller pattern to adapt: app-owned overlays plus thin target indexes that compose those overlays without becoming resource owners.

## What Changes

- Introduce a small target-oriented Kustomize composition pattern for `homelab-garden`.
- Keep manifests owned by domain/app roots, with target indexes acting only as composition indexes.
- Add `local` and `hcloud-lab` target identities as Kustomize-safe desired-state paths.
- Preserve Garden as the harness while allowing ArgoCD to point at the same raw-Kustomize-safe target or overlay paths.
- Do not copy `kagent-garden` wholesale or add broad domain sprawl.

## Capabilities

### New Capabilities
- `targeted-kustomize-composition`: Defines app-owned overlays, thin target indexes, and raw-Kustomize-safe paths shared by Garden and ArgoCD.

### Modified Capabilities

## Impact

- Later implementation may introduce `k8s/apps/**` and `k8s/targets/<target>` paths.
- Existing `platform/` and `apps/` paths may be moved or bridged during implementation.
- Affects validation render paths, Garden deploy action paths, and ArgoCD Application source paths.
- Does not add controllers, cloud resources, or production homelab integration.
