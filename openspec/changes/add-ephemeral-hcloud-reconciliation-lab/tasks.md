## 1. Research and Boundary Docs

- [x] 1.1 Document the `local kind`, `hcloud-lab`, and `real homelab` execution boundaries.
- [x] 1.2 Confirm the smallest supported non-HA Hetzner/Talos cluster shape for the demo.
- [x] 1.3 Document expected resource classes, rough hourly cost, and intended maximum cluster lifetime.
- [x] 1.4 Document required local tools and credentials without committing secrets.
- [x] 1.5 Document why Terraform owns cloud lifecycle and Garden only orchestrates/consumes outputs.
- [x] 1.6 Confirm `adopt-targeted-kustomize-composition` has defined the `hcloud-lab` target strategy before implementing ArgoCD source paths.

## 2. Terraform Lab Stack

- [x] 2.1 Add `infra/hcloud-lab/` with Terraform/OpenTofu stack files.
- [x] 2.2 Configure the stack to use a minimal disposable cluster shape.
- [x] 2.3 Expose kubeconfig output or write a kubeconfig path Garden can consume.
- [x] 2.4 Keep `terraform.tfvars`, state, kubeconfig, talosconfig, and generated secrets out of Git.
- [x] 2.5 Add a preflight path that fails before Terraform apply when required tools or credentials are missing.
- [x] 2.6 Add explicit plan/apply/destroy documentation.
- [x] 2.7 Add operator lifecycle scripts for validated x86/cx23 create, status inspection, and confirmed teardown.

## 3. Garden Environment and Workflow

- [ ] 3.1 Add an `hcloud-lab` Garden environment or config overlay.
- [ ] 3.2 Configure Garden to consume Terraform outputs for the hcloud Kubernetes target.
- [ ] 3.3 Keep Terraform `autoApply` disabled.
- [ ] 3.4 Add `workflows/hcloud-argocd-reconcile.garden.yml` without embedding Terraform apply or destroy.
- [ ] 3.5 Reuse the local ArgoCD reconciliation shape against the ephemeral hcloud cluster.
- [ ] 3.6 Use `k8s/targets/hcloud-lab` or hcloud-specific app overlays as raw-Kustomize-safe ArgoCD source paths.
- [ ] 3.7 Choose hcloud-specific Application naming, such as `platform-hcloud-lab` and `demo-api-hcloud-lab`, to avoid ambiguity with local kind apps.
- [x] 3.8 Verify hcloud ArgoCD source paths render with Kustomize alone.

## 4. Verification and Safety

- [x] 4.1 Verify default local workflows do not require hcloud credentials or Terraform state.
- [ ] 4.2 Verify the hcloud workflow targets only the ephemeral cluster.
- [ ] 4.3 Verify teardown removes expected Hetzner resources with observable hcloud or Terraform checks.
- [x] 4.4 Document cost, cleanup, maximum lifetime, and failure-recovery notes.
