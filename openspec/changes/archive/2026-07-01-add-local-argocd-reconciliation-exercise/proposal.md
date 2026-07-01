## Why

The repo has a placeholder GitOps plan but no executable reconciliation exercise. A disposable local ArgoCD workflow should prove app-of-apps, ordering, sync, health, drift, and self-heal behavior without making Garden the owner of production GitOps deployment.

## What Changes

- Add a separate `local-argocd-reconcile` workflow for a disposable local ArgoCD reconciliation exercise.
- Install/apply ArgoCD only in the local kind cluster for the exercise.
- Add app-of-apps with platform reconciliation before demo app reconciliation.
- Use raw-Kustomize-safe source paths from the targeted Kustomize composition change.
- Demonstrate live drift self-heal for the demo app.
- Keep `make check` and `local-validate` unchanged.
- Do not deploy to, configure, or manage the real homelab ArgoCD installation.

## Capabilities

### New Capabilities
- `gitops-reconciliation`: Defines the disposable local ArgoCD exercise, app ordering, Git source assumptions, and drift self-heal behavior.

### Modified Capabilities

## Impact

- Adds ArgoCD addon manifests or install workflow.
- Adds `gitops/projects/`, `gitops/applications/`, and `gitops/app-of-apps.yaml`.
- Adds a new Garden workflow for the local ArgoCD reconciliation exercise.
- Requires a reachable Git source for ArgoCD.
