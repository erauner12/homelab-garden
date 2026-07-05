## Why

The hcloud reconciliation workflow proves that ArgoCD can install, apply app-of-apps, and sync the demo stack on the ephemeral Hetzner lab cluster. It does not provide a repeatable, guarded check that ArgoCD self-heal corrects safe live drift after reconciliation is already healthy.

A durable self-heal validation workflow should let operators prove that behavior on `hcloud-lab` without running Terraform, creating or deleting Hetzner resources, reinstalling ArgoCD, or risking the real homelab.

## What Changes

- Add a separate `garden workflow hcloud-argocd-self-heal --env hcloud-lab` workflow.
- Reuse the existing hcloud kubeconfig/context guard from `platform/addons/argocd/hcloud-common.sh`.
- Gate the workflow on existing hcloud ArgoCD Applications being present, Synced, and Healthy, especially `demo-api-hcloud-lab`.
- Induce controlled demo drift by scaling `deployment/demo-api` in namespace `demo` away from the current Git-reconciled replica count.
- Wait for ArgoCD to restore the deployment and for `demo-api-hcloud-lab` to return to Synced/Healthy.
- Run the existing demo API smoke test through Garden after self-heal.
- Emit actionable diagnostics on failure.

## Capabilities

### New Capabilities
- `hcloud-argocd-self-heal-validation`: Defines safe, opt-in self-heal validation for the ephemeral hcloud lab ArgoCD installation.

### Modified Capabilities
- None.

## Impact

- Adds a new hcloud-only Garden Run action, workflow, script, and documentation.
- Does not add Terraform apply/destroy, Hetzner resource lifecycle operations, or real homelab targeting.
- Does not affect `make check`, `local-validate`, `policy-validate`, or local ArgoCD workflows.
