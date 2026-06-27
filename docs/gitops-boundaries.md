# GitOps Boundaries

This lab separates three concerns:

1. Desired state rendering
2. Local workload validation
3. GitOps reconciliation validation

Kustomize is the desired-state interface. Garden deploy actions use Kustomize so
the local path stays close to the manifests ArgoCD would reconcile.

The first implementation focuses on local workload validation. A later ArgoCD
workflow can add an app-of-apps path that reconciles the same Kustomize
entrypoints from a Git source.
