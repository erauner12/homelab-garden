## Context

Garden's Terraform integration wraps Terraform and can expose stack outputs to Garden providers/actions, but Terraform remains the infrastructure lifecycle owner. The local `terraform-hcloud-talos` reference is a Terraform module for Kubernetes on Hetzner Cloud with Talos, kubeconfig/talosconfig outputs, and support for a small one-control-plane cluster shape. That makes it useful for a later real-infrastructure rehearsal lane, but too heavy for the default loop.

This change depends on the earlier local validation and local ArgoCD exercise boundaries staying intact, plus `adopt-targeted-kustomize-composition` defining a raw-Kustomize-safe `hcloud-lab` target or equivalent app overlays. It is a cloud integration lane, not part of `make check` or the first implementation wave.

## Goals / Non-Goals

**Goals:**
- Add a later optional `hcloud-lab` environment for disposable cloud-cluster reconciliation testing.
- Use explicit Terraform plan/apply/destroy steps; do not create cloud resources as a side effect of default validation or reconciliation workflows.
- Let Garden consume Terraform outputs for the cloud Kubernetes provider or workflow steps.
- Run an ArgoCD reconciliation exercise against an ephemeral Hetzner cluster using the same target-composition pattern as the local exercise.
- Keep cloud credentials, state, kubeconfigs, talosconfigs, and tfvars out of Git.

**Non-Goals:**
- Do not make `make check`, `local-validate`, `policy-validate`, or `local-argocd-reconcile` depend on Hetzner, Terraform, or cloud credentials.
- Do not manage the real homelab ArgoCD installation.
- Do not make Garden the production CD owner.
- Do not start with a large HA cluster unless explicitly chosen for a separate HA lifecycle exercise.

## Decisions

- Model this as a separate environment/lane named `hcloud-lab`, not as an extension of `local`.
- Prefer Garden's Terraform provider/root-stack pattern because the Kubernetes provider or workflow needs Terraform outputs such as kubeconfig path/data.
- Keep Terraform `autoApply` disabled. Operators must run explicit plan/apply before cloud resources are created.
- Keep destroy explicit and documented, with any module-specific delete-protection sequence and post-destroy resource verification called out.
- Start from the smallest supported non-HA cluster shape that can run the reconciliation demo, and document expected cost/lifetime before provisioning.
- Scope ArgoCD installation and Application changes to the ephemeral hcloud cluster only.
- Prefer `k8s/targets/hcloud-lab` or hcloud-specific app overlays as the ArgoCD source paths; they must remain raw-Kustomize-safe.

## Risks / Trade-offs

- Cloud cost or leaked resources → require expected cost/lifetime docs, explicit teardown docs, and resource verification commands.
- Credential or state leakage → forbid committing tfvars, state, kubeconfig, talosconfig, or tokens.
- Module complexity can distract from the CD story → keep the first hcloud lane minimal and document prerequisites with a preflight that fails before Terraform apply.
- Terraform output handling can blur ownership → Terraform owns infrastructure; Garden consumes outputs and runs validation/reconciliation workflows.
