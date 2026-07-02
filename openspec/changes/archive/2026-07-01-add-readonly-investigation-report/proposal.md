# Proposal: Read-only investigation report

## Why

The delivery lab needs a deterministic way to inspect the demo API state after validation, GitOps reconciliation, or rollout exercises without mutating the cluster. The report should be safe to run in partially installed environments and useful for demos.

## What Changes

- Add a read-only `investigate-demo` Garden workflow.
- Add a repo-local shell script that gathers Kubernetes, optional ArgoCD, optional Argo Rollouts, health, event, and log context.
- Render the collected context as Markdown with clear safe next actions and approval-required actions.
- Keep generated investigation reports out of Git.

## Non-Goals

- No cluster mutation: no apply, delete, patch, scale, sync, promote, rollback, or remediation.
- No agent implementation or autonomous action selection.
- No requirement that ArgoCD or Argo Rollouts be installed.
