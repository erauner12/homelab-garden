# ArgoCD Plan

ArgoCD is not required for the default local validation loop.

The opt-in disposable reconciliation exercise is:

```bash
garden workflow local-argocd-reconcile --env local
```

That workflow:

1. Installs upstream ArgoCD into the local kind cluster namespace `argocd` by applying `https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`.
2. Waits for the ArgoCD CRDs and Deployments to become ready.
3. Applies the local lab `AppProject` from `gitops/projects/`.
4. Applies a temporary rendered copy of `gitops/app-of-apps.yaml` with the selected repo URL and revision patched in.
5. Waits for `app-of-apps`, `platform-local`, and `demo-api-local` to become Synced and Healthy.
6. Smoke-tests the ArgoCD-reconciled demo API.

The workflow is guarded to kind contexts only and defaults to `kind-homelab-garden` through the Garden `local` environment. It is a lab harness for local reconciliation behavior; it does not deploy to, configure, sync, or manage the real homelab ArgoCD installation.

## Git source and revision

The first implementation intentionally uses a remote HTTPS Git source:

```text
checked-in repoURL: https://github.com/erauner12/homelab-garden.git
checked-in targetRevision: main
runtime ARGOCD_REPO_URL default: origin remote URL
runtime ARGOCD_TARGET_REVISION default: current local branch, falling back to main
```

The checked-in Application YAML uses `main` so it does not permanently point at a feature branch after merge. During the local exercise, `platform/addons/argocd/apply-local-apps.sh` renders temporary copies for the local cluster: it patches the AppProject source repo, patches the parent app-of-apps source, and adds parent Kustomize source patches so `platform-local` and `demo-api-local` are applied with the same runtime `repoURL` and `targetRevision`.

Override the runtime source when needed:

```bash
ARGOCD_REPO_URL=https://github.com/erauner12/homelab-garden.git \
ARGOCD_TARGET_REVISION=my-branch \
garden workflow local-argocd-reconcile --env local
```

ArgoCD fetches the configured remote revision from inside the cluster. The repo and branch must be reachable to in-cluster ArgoCD over HTTPS. Uncommitted local changes are invisible. Local commits are also invisible until pushed to the configured remote revision. Use the default `make check` and `local-validate` loop for fast pre-push validation; use this workflow only after the GitOps manifests and source paths exist on the remote revision ArgoCD can fetch.

For a private GitHub repo, apply credentials only to the disposable local ArgoCD namespace at runtime:

```bash
ARGOCD_GITHUB_TOKEN="$(gh auth token)" garden workflow local-argocd-reconcile --env local
```

`GH_TOKEN` is also accepted. The username defaults to `ARGOCD_GITHUB_USERNAME`, `GITHUB_USERNAME`, `GH_USERNAME`, the GitHub repo owner parsed from `ARGOCD_REPO_URL`, then `x-access-token`.

A local file handoff is also supported:

```bash
install -m 0600 secrets/argocd-repo-creds.yaml.template secrets/argocd-repo-creds.local.yaml
# Edit secrets/argocd-repo-creds.local.yaml locally; do not commit it.
garden workflow local-argocd-reconcile --env local
```

The default encrypted source path is `secrets/argocd-repo-creds.sops.yaml`; with `secrets/age/key.txt` present, the workflow decrypts it locally if no runtime token or plaintext credential file is provided. Override it with `ARGOCD_REPO_CREDS_SOPS_FILE=/path/to/secret.sops.yaml`. Override a plaintext file path with `ARGOCD_REPO_CREDS_FILE=/path/to/secret.yaml`.

## Desired-state paths

The child Applications source the same raw-Kustomize-safe paths used by the local Garden deploy actions:

```text
platform-local  -> k8s/apps/platform/foundation/overlays/local
demo-api-local  -> k8s/apps/workloads/demo-api/overlays/local
```

`platform-local` has sync wave `0`; `demo-api-local` has sync wave `1`, so the app-of-apps parent creates the platform Application before the demo Application. The demo app enables automated sync and self-heal, and prune is intentionally not enabled for this first exercise.

## Drift exercise

After `garden workflow local-argocd-reconcile --env local` succeeds, create live drift deliberately:

```bash
kubectl --context kind-homelab-garden -n demo scale deploy demo-api --replicas=0
kubectl --context kind-homelab-garden -n argocd get application demo-api-local -w
kubectl --context kind-homelab-garden -n demo get deploy demo-api -w
```

The exercise passes when ArgoCD detects the live drift and self-heals `Deployment/demo-api` back to the Git-declared replica count from `k8s/apps/workloads/demo-api/overlays/local`.

Possible future Git source modes:

- in-cluster Gitea or Forgejo for local no-push validation
- pinned release branch or tag for repeatable workshop demos

Add in-cluster Git only if the no-commit/no-push local GitOps test becomes valuable enough to justify the harness complexity.
