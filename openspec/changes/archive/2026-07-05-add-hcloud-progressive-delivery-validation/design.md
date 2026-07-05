## Context

`rollout-demo` already installs Argo Rollouts locally and applies `scenarios/good-rollout`. `hcloud-argocd-reconcile` already installs disposable hcloud ArgoCD, applies the hcloud app-of-apps, waits for `app-of-apps-hcloud-lab`, `platform-hcloud-lab`, and `demo-api-hcloud-lab`, then smoke-tests the ArgoCD-managed demo API. `hcloud-argocd-self-heal` adds a guarded drift/self-heal check after that baseline is healthy.

This change adds the next validation step: run Argo Rollouts on the ephemeral hcloud cluster while preserving the ArgoCD-managed demo. Terraform/OpenTofu remains the only owner of hcloud infrastructure lifecycle.

## Goals / Non-Goals

**Goals:**
- Provide `garden workflow hcloud-rollout-demo --env hcloud-lab`.
- Reuse the existing hcloud kubeconfig/context guard before any hcloud mutation.
- Install Argo Rollouts into the ephemeral hcloud lab cluster.
- Apply a good Rollout scenario and validate health/smoke on hcloud.
- Keep the Rollout scenario isolated from the ArgoCD-managed `demo/demo-api` Deployment.
- Verify the hcloud ArgoCD-managed demo remains Synced/Healthy and smoke-tested after the Rollout validation.
- Keep the workflow out of default local validation/check paths.

**Non-Goals:**
- Do not run Terraform/OpenTofu apply/destroy or create/delete Hetzner Cloud resources.
- Do not replace the hcloud ArgoCD-managed demo Deployment with a Rollout in this slice.
- Do not add a hcloud failure workflow unless it can be kept isolated and coherent.
- Do not require Prometheus, service mesh traffic shifting, or Rollouts CLI plugins.

## Decisions

- Add hcloud-specific Rollouts scripts under `platform/addons/argo-rollouts/` and source `platform/addons/argocd/hcloud-common.sh` for the established guardrails.
- Run the hcloud Rollout in namespace `hcloud-rollouts-demo`, not `demo`, to avoid two controllers using the same selector for the ArgoCD-managed `demo-api` workload.
- Add `scenarios/hcloud-good-rollout/` as a small hcloud overlay over the existing Rollout resources plus the existing demo Service. Patch only the analysis command namespace.
- Add Role/RoleBinding resources to the Rollout base so the analysis Job can list pods in whichever namespace Kustomize targets.
- Use Kubernetes-native checks: Rollout `.status.phase`, `validation/health.sh`, and an in-cluster curl smoke pod against the Service.
- End the workflow by running the existing hcloud ArgoCD reconcile wait and demo smoke actions to prove the main GitOps demo remains healthy.
- Live validation found that `firewall_use_current_ip` can be too narrow for runners with rotating public egress, so the hcloud lab root module now exposes explicit Kubernetes and Talos API source CIDR variables while leaving them null by default.

## Risks / Trade-offs

- Installing Argo Rollouts and leaving the isolated demo namespace behind consumes small cluster resources. The workflow is idempotent and scoped to the ephemeral hcloud lab.
- The workflow validates the checked-out scenario via direct Kubernetes apply; the ArgoCD-managed baseline still depends on whatever remote revision hcloud ArgoCD is configured to fetch.
- Before merge, live validation requires any ArgoCD baseline revision under test to be pushed/reachable. After merge, the stable `main` targetRevision path can validate the whole lane without branch overrides.
