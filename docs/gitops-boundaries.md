# GitOps Boundaries

This lab separates three concerns:

1. Desired state rendering
2. Local workload validation
3. GitOps reconciliation validation

Kustomize is the desired-state interface. App/domain roots under `k8s/apps/**`
own manifests, and `k8s/targets/<target>` directories are thin composition
indexes over those owned overlays. Garden deploy actions use the same raw
Kustomize-safe desired-state roots that future ArgoCD Applications should
source.

The default implementation focuses on local workload validation. The separate
`local-argocd-reconcile` workflow adds an opt-in disposable app-of-apps path
that reconciles the same Kustomize entrypoints from a remote Git source. See
`docs/targeted-kustomize-composition.md` for the current domain split and
target-index rules.
