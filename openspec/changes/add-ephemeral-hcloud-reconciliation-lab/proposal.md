## Why

Local kind validation and the disposable local ArgoCD exercise prove Kubernetes shape and reconciliation concepts, but they do not prove the same flow on real infrastructure. A later optional hcloud lab should provide production-like confidence without making Garden the owner of production CD or touching the real homelab.

## What Changes

- Add an optional `hcloud-lab` cloud reconciliation lane backed by Terraform/OpenTofu and Hetzner Cloud.
- Use Garden only as the orchestration harness for explicit Terraform plan/apply and post-provision validation workflows.
- Reuse the same GitOps desired-state exercise against an ephemeral Hetzner cluster.
- Require explicit teardown documentation and keep all credentials, state, kubeconfig, talosconfig, and tfvars out of Git.
- Keep `make check`, `local-validate`, `policy-validate`, and `local-argocd-reconcile` independent of the hcloud lane.

## Capabilities

### New Capabilities
- `ephemeral-hcloud-reconciliation-lab`: Defines an optional Hetzner/Terraform environment for real-infrastructure GitOps reconciliation rehearsal.

### Modified Capabilities

## Impact

- Later implementation may add `infra/hcloud-lab/`, `workflows/hcloud-argocd-reconcile.garden.yml`, and `docs/architecture/cloud-reconciliation-lab.md`.
- Introduces optional external dependencies: Hetzner Cloud token, Terraform/OpenTofu, Talos tooling, and cloud spend.
- Does not affect the default local validation loop or real homelab ArgoCD.
