## 1. Local ArgoCD Exercise Setup

- [x] 1.1 Choose and document the disposable local ArgoCD install/apply mechanism.
- [x] 1.2 Add `platform/addons/argocd/` resources or installer wrapper scoped to the local kind exercise.
- [x] 1.3 Add readiness wait behavior for ArgoCD components.

## 2. GitOps Applications

- [x] 2.1 Confirm `adopt-targeted-kustomize-composition` provides raw-Kustomize-safe source paths for platform and demo app desired state.
- [x] 2.2 Add `gitops/projects/` with a minimal lab AppProject.
- [x] 2.3 Add `gitops/applications/platform-local.yaml` pointing at a raw-Kustomize-safe platform overlay or target path.
- [x] 2.4 Add `gitops/applications/demo-api-local.yaml` pointing at a raw-Kustomize-safe demo app overlay or target path.
- [x] 2.5 Add `gitops/app-of-apps.yaml` with platform before app ordering.
- [x] 2.6 Configure demo app automated sync and self-heal with prune disabled.
- [x] 2.7 Verify each Application source path renders with Kustomize alone.

## 3. Workflow and Verification

- [x] 3.1 Add `workflows/local-argocd-reconcile.garden.yml`.
- [x] 3.2 Document the remote HTTPS Git source and branch/revision behavior, including that uncommitted local changes are invisible.
- [x] 3.3 Add a documented drift exercise for manual scale and self-heal.
- [x] 3.4 Document that this workflow does not deploy to, configure, or manage the real homelab ArgoCD installation.
- [x] 3.5 Verify `make check` and `local-validate` remain unchanged and ArgoCD-free.

## Verification Notes

- `openspec validate add-local-argocd-reconciliation-exercise --strict` passed.
- Raw Kustomize builds passed for:
  - `k8s/apps/platform/foundation/overlays/local`
  - `k8s/apps/workloads/demo-api/overlays/local`
  - `k8s/targets/local`
- `garden get config --env local --resolve=partial` passed after allowing Garden to write its normal `~/.garden` cache/config files.
- Checked-in ArgoCD Application YAML uses stable `targetRevision: main`; `platform/addons/argocd/apply-local-apps.sh` renders temporary local apply copies from `ARGOCD_REPO_URL` and `ARGOCD_TARGET_REVISION` so the configured runtime repo/revision controls the parent and child Applications that ArgoCD sees.
- `garden workflow local-argocd-reconcile --env local` was exercised as far as this environment can run it before this correction:
  - ArgoCD installed into local kind namespace `argocd` using server-side apply for the upstream install manifest.
  - ArgoCD CRDs, Deployments, and `argocd-application-controller` StatefulSet reached readiness.
  - `AppProject/local-lab` and `Application/app-of-apps` were applied.
  - Reconciliation correctly failed fast when in-cluster ArgoCD could not fetch the configured remote HTTPS Git source. This matches the documented remote HTTPS limitation: the configured branch/repo must be pushed and reachable to ArgoCD; uncommitted local changes and unpushed commits are invisible.
- Follow-up correction verification passed after changing checked-in defaults to `main`, adding `gitops/applications/kustomization.yaml`, and making the apply script render runtime repo/revision into temporary apply manifests. The script now defaults `ARGOCD_TARGET_REVISION` to the current branch, falls back to `main` in detached/no-branch cases, and applies a rendered parent app-of-apps with Kustomize patches so child Applications use the same runtime repo/revision.
- Correction validation rerun passed:
  - `openspec validate add-local-argocd-reconciliation-exercise --strict`
  - `kustomize build k8s/apps/platform/foundation/overlays/local`
  - `kustomize build k8s/apps/workloads/demo-api/overlays/local`
  - `kustomize build gitops/applications`
  - `bash -n platform/addons/argocd/install-local.sh platform/addons/argocd/apply-local-apps.sh platform/addons/argocd/wait-local-reconcile.sh`
  - `garden get config --env local --resolve=partial`
- `git diff --exit-code -- Makefile workflows/local-validate.garden.yml` passed, confirming `make check` and `local-validate` definitions were not changed.
- `grep -Rin "argocd" Makefile workflows/local-validate.garden.yml` produced no matches, confirming the default validation path remains ArgoCD-free.
