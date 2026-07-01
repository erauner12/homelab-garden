## 1. Research and Boundary Docs

- [ ] 1.1 Document the `local kind`, `hcloud-lab`, and `real homelab` execution boundaries.
- [ ] 1.2 Confirm the smallest supported non-HA Hetzner/Talos cluster shape for the demo.
- [ ] 1.3 Document expected resource classes, rough hourly cost, and intended maximum cluster lifetime.
- [ ] 1.4 Document required local tools and credentials without committing secrets.
- [ ] 1.5 Document why Terraform owns cloud lifecycle and Garden only orchestrates/consumes outputs.

## 2. Terraform Lab Stack

- [ ] 2.1 Add `infra/hcloud-lab/` with Terraform/OpenTofu stack files.
- [ ] 2.2 Configure the stack to use a minimal disposable cluster shape.
- [ ] 2.3 Expose kubeconfig output or write a kubeconfig path Garden can consume.
- [ ] 2.4 Keep `terraform.tfvars`, state, kubeconfig, talosconfig, and generated secrets out of Git.
- [ ] 2.5 Add a preflight path that fails before Terraform apply when required tools or credentials are missing.
- [ ] 2.6 Add explicit plan/apply/destroy documentation.

## 3. Garden Environment and Workflow

- [ ] 3.1 Add an `hcloud-lab` Garden environment or config overlay.
- [ ] 3.2 Configure Garden to consume Terraform outputs for the hcloud Kubernetes target.
- [ ] 3.3 Keep Terraform `autoApply` disabled.
- [ ] 3.4 Add `workflows/hcloud-argocd-reconcile.garden.yml` without embedding Terraform apply or destroy.
- [ ] 3.5 Reuse the local ArgoCD reconciliation shape against the ephemeral hcloud cluster.
- [ ] 3.6 Choose hcloud-specific Application naming, such as `platform-hcloud-lab` and `demo-api-hcloud-lab`, to avoid ambiguity with local kind apps.

## 4. Verification and Safety

- [ ] 4.1 Verify default local workflows do not require hcloud credentials or Terraform state.
- [ ] 4.2 Verify the hcloud workflow targets only the ephemeral cluster.
- [ ] 4.3 Verify teardown removes expected Hetzner resources with observable hcloud or Terraform checks.
- [ ] 4.4 Document cost, cleanup, maximum lifetime, and failure-recovery notes.
