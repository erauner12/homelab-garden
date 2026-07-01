## Context

This change depends on `add-local-argocd-reconciliation-exercise` proving that the demo app can reconcile from Git in a disposable local ArgoCD exercise first. The first progressive delivery story should come after ArgoCD reconciliation works. The current schema validation path only renders standard platform and demo app overlays with strict kubeconform checks, so adding Rollouts CRs directly to default overlays could break the fast loop unless CRD-aware validation is added.

## Goals / Non-Goals

**Goals:**
- Demonstrate one successful progressive rollout and one failure path.
- Use one demo app, one Rollout, and one minimal AnalysisTemplate or equivalent mechanism.
- Start health gates with Kubernetes readiness, rollout status, and restart/crash-loop signals.
- Produce structured health output suitable for later automation.

**Non-Goals:**
- Do not require Prometheus for the first demo.
- Do not add service mesh traffic shifting.
- Do not add tenant waves or `rolloutctl`.
- Do not add Rollouts CRs to the default schema validation path without CRD-aware validation.

## Decisions

- Keep Rollouts manifests under `apps/demo-api/rollouts/` or scenario-specific paths rather than the default `apps/demo-api/overlays/local` path.
- Add `validation/health.sh` in the same change so `failure-demo` has an explicit pass/fail signal.
- Start with readiness/status-only checks; add demo API metrics before Prometheus in a later change.
- Treat Rollouts as an optional exercise workflow, not part of `make check`.

## Risks / Trade-offs

- Rollouts CRDs can break strict schema validation → keep CRs out of the default schema path or add separate CRD-aware validation later.
- Health gates can become observability-stack work → keep the first signal boring and Kubernetes-native.
- Failure semantics can be unclear → document what pause, abort, or rollback behavior the demo is proving.
