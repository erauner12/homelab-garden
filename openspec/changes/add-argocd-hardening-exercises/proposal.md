## Why

Existing local and hcloud ArgoCD specs already cover baseline sync and self-heal evidence. The next hardening slice should focus only on safety behavior not yet exercised: bounded prune, AppProject denial, sync option safety, and blast-radius reporting.

## What Changes

- Add optional ArgoCD hardening exercises for bounded prune, AppProject denial behavior, sync option safety, and blast-radius reporting.
- Treat existing local/hcloud sync and self-heal workflows as prerequisites and evidence sources, not as the main new exercise.
- Cover local and disposable hcloud lab targets with environment guards.
- Keep destructive or prune scenarios bounded to lab-owned resources and namespaces.

## Capabilities

### New Capabilities
- `argocd-hardening-exercises`: Defines optional ArgoCD safety exercises for bounded prune, project denial, sync option safety, and blast-radius reporting.

### Modified Capabilities

## Impact

- Future implementation may add lab-only ArgoCD Applications, AppProject denial fixtures, prune test resources, sync-option fixtures, reports, workflows, and docs.
- Depends on existing local and hcloud ArgoCD reconciliation/self-heal evidence.
- Does not target the real homelab ArgoCD installation.
