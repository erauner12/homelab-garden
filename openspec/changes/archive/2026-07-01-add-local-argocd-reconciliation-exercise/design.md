## Context

This change depends on `stabilize-delivery-lab-foundation` preserving the default validation-loop boundary and Garden-as-pre-CD-harness model, and on `adopt-targeted-kustomize-composition` providing raw-Kustomize-safe desired-state paths for Garden and ArgoCD. Current docs say ArgoCD is reserved for GitOps reconciliation validation. The current `gitops-validate` workflow only prints the planned path. The platform overlay creates namespaces used by the demo app, so a demo-api-only ArgoCD app would hide a namespace dependency.

## Goals / Non-Goals

**Goals:**
- Add an executable disposable local ArgoCD reconciliation exercise separate from `local-validate`.
- Use a simple remote HTTPS Git source first.
- Reconcile platform before demo app through app-of-apps ordering.
- Demonstrate self-heal of live drift.

**Non-Goals:**
- Do not introduce in-cluster Gitea/Forgejo.
- Do not require SSH keys or private repo credentials in the first version.
- Do not enable prune in the first self-heal exercise.
- Do not make `make check` or `local-validate` run ArgoCD.
- Do not use this workflow to deploy to or manage the real homelab ArgoCD installation.

## Decisions

- Use the current remote HTTPS repo URL and current/default branch for the first Git source. Document that uncommitted local changes are invisible to ArgoCD.
- Garden orchestrates a disposable local ArgoCD install, waits for readiness, then applies the parent app-of-apps Application. Garden is the harness; ArgoCD behavior is the thing under test.
- The parent Application manages two children: `platform-local` and `demo-api-local`, sourced from raw-Kustomize-safe app overlays or the `k8s/targets/local` composition defined by `adopt-targeted-kustomize-composition`.
- `platform-local` syncs before `demo-api-local` so namespace/platform dependencies are explicit.
- Demo app automated sync and self-heal are enabled; prune remains disabled initially.

## Risks / Trade-offs

- Remote branch mode does not validate uncommitted local edits → document the limitation and keep local validation as the fast pre-commit path.
- ArgoCD install mechanism can add complexity → choose one simple install path and hide it behind the workflow.
- AppProject copied from `homelab-k8s` would be too broad → create a minimal lab project.
- Garden-only patches or template syntax in ArgoCD source paths would make the exercise false → require raw-Kustomize-safe source paths.
