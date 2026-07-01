## 1. Local ArgoCD Exercise Setup

- [ ] 1.1 Choose and document the disposable local ArgoCD install/apply mechanism.
- [ ] 1.2 Add `platform/addons/argocd/` resources or installer wrapper scoped to the local kind exercise.
- [ ] 1.3 Add readiness wait behavior for ArgoCD components.

## 2. GitOps Applications

- [ ] 2.1 Add `gitops/projects/` with a minimal lab AppProject.
- [ ] 2.2 Add `gitops/applications/platform-local.yaml`.
- [ ] 2.3 Add `gitops/applications/demo-api-local.yaml`.
- [ ] 2.4 Add `gitops/app-of-apps.yaml` with platform before app ordering.
- [ ] 2.5 Configure demo app automated sync and self-heal with prune disabled.

## 3. Workflow and Verification

- [ ] 3.1 Add `workflows/local-argocd-reconcile.garden.yml`.
- [ ] 3.2 Document the remote HTTPS Git source and branch/revision behavior, including that uncommitted local changes are invisible.
- [ ] 3.3 Add a documented drift exercise for manual scale and self-heal.
- [ ] 3.4 Document that this workflow does not deploy to, configure, or manage the real homelab ArgoCD installation.
- [ ] 3.5 Verify `make check` and `local-validate` remain unchanged and ArgoCD-free.
