# ArgoCD Plan

ArgoCD is not required for the default local validation loop.

Add it when the repo needs to test the GitOps reconciliation contract:

```text
Garden creates or selects local cluster
Garden deploys ArgoCD
Garden seeds a Git source
Garden applies app-of-apps
ArgoCD reconciles the same Kustomize paths
Garden waits for sync and health
Garden runs smoke checks
```

Possible Git source modes:

- remote GitHub branch for a realistic end-to-end path
- in-cluster Gitea or Forgejo for local no-push validation

Start with the remote branch mode if simplicity matters. Add in-cluster Git only
if the no-commit/no-push local GitOps test becomes valuable enough to justify
the harness complexity.
