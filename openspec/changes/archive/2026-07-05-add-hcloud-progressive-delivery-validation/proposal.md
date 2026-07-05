## Why

The local progressive delivery demo proves a good Argo Rollouts path in kind, and the hcloud ArgoCD reconciliation/self-heal workflows prove GitOps behavior on the ephemeral Hetzner lab cluster. The next lab slice should validate that the same Rollouts primitives can run on `hcloud-lab` without touching Terraform lifecycle or destabilizing the ArgoCD-managed demo stack.

## What Changes

- Add a guarded hcloud Argo Rollouts installer that reuses the existing hcloud kubeconfig/context guard.
- Add an isolated hcloud good-rollout scenario in a separate namespace so it does not compete with the ArgoCD-managed `demo/demo-api` Deployment.
- Add hcloud Garden Run actions and a `hcloud-rollout-demo` workflow for install, apply, health, smoke, and post-checks.
- Keep the workflow opt-in and hcloud-only; do not add it to default local validation/check paths.
- Document live-validation prerequisites and branch/targetRevision caveats.

## Capabilities

### New Capabilities
- `hcloud-progressive-delivery-validation`: Defines safe, opt-in Argo Rollouts validation for the ephemeral hcloud lab cluster.

### Modified Capabilities
- None.

## Impact

- Adds hcloud-only Rollouts scripts, Garden actions/workflow, an isolated scenario, and documentation.
- Adds minimal RBAC needed by the Rollouts analysis job to inspect pods in its namespace.
- Does not run Terraform/OpenTofu apply/destroy or manage Hetzner Cloud infrastructure.
- Does not target local kind or the real homelab.
- Does not affect `make check`, `local-validate`, `policy-validate`, or existing local Rollouts workflows.
