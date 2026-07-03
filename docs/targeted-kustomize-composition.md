# Targeted Kustomize Composition

`homelab-garden` adapts the small useful part of the `kagent-garden` pattern:
Kubernetes desired state is owned by app/domain roots, while target directories
are thin Kustomize indexes over those owned overlays.

## Domain-owned desired state

The first slice keeps the domain split intentionally small:

```text
k8s/apps/platform/foundation/base
k8s/apps/platform/foundation/overlays/local
k8s/apps/workloads/demo-api/base
k8s/apps/workloads/demo-api/overlays/local
k8s/targets/local
```

- `k8s/apps/platform/foundation` owns the platform namespaces and local platform
  smoke workload needed by the demo.
- `k8s/apps/workloads/demo-api` owns the demo workload.
- Policy fixtures remain under `policy/kyverno` until a later change needs
  admission-controller desired state under `k8s/apps/policy/**`.
- GitOps controller resources stay outside the app-owned Kustomize roots; the
  opt-in local reconciliation exercise keeps ArgoCD `Application` manifests
  under `gitops/`.

This is an immediate minimal move for the active local roots, not a wholesale
copy of the larger `kagent-garden` domain tree.

## Target indexes

`k8s/targets/<target>` is composition-only. A target kustomization may reference
selected app-owned overlays, but it must not define copied Kubernetes resources
itself.

Today `k8s/targets/local` and `k8s/targets/hcloud-lab` compose:

```text
../../apps/platform/foundation/overlays/local
../../apps/workloads/demo-api/overlays/local
```

`hcloud-lab` is an explicit desired-state target identity for direct workload
validation against the ephemeral Hetzner/Talos lab. It currently reuses the same
app-owned overlays as `local`; future hcloud-specific behavior should move into
app-owned hcloud overlays and keep the target as a thin composition index.

Garden deploy actions still deploy the platform and demo overlays separately so
the local smoke-test ordering stays explicit, while validation also renders the
`local` and `hcloud-lab` target indexes to prove the composed desired state is
raw-Kustomize-safe.

## Raw Kustomize and ArgoCD safety

Paths intended for future ArgoCD sources must render with `kustomize build`
alone. Do not put Garden template syntax, Garden `patchResources`, shell-derived
state, or other harness-only behavior inside `k8s/apps/**` or `k8s/targets/**`.
Keep that behavior in Garden action/workflow configuration if it is needed.

The local ArgoCD `Application` resources under `gitops/applications/` source
these same app-owned overlays directly, so their configured source paths can be
verified with raw `kustomize build` before ArgoCD is involved.

## hcloud-lab target identity

`hcloud-lab` is a desired-state target identity, not the mechanism that creates
or accesses a cluster. `k8s/targets/hcloud-lab` is a durable composition-only
Kustomize target for hcloud direct workload validation. Terraform/Garden remain
responsible for cluster lifecycle and access; the target only selects the
app-owned desired-state overlays to render or apply.
