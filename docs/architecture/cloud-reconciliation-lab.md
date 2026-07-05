# Ephemeral hcloud Reconciliation Lab

This is an optional, explicit lane for a disposable Hetzner Cloud reconciliation exercise. The Terraform/OpenTofu stack can now plan a Talos Kubernetes cluster, but it must not be applied by default.

## Boundaries

| Lane | Purpose | Must not do |
| --- | --- | --- |
| `local kind` | Default local validation and disposable local ArgoCD exercises. | Require Hetzner credentials, Terraform/OpenTofu state, Talos config, or cloud resources. |
| `hcloud-lab` | Optional, explicit, disposable cloud-cluster rehearsal. | Run by default, touch the real homelab, or create resources without an explicit Terraform/OpenTofu apply. |
| `real homelab` | Existing production-ish homelab outside this lab. | Be deployed to, configured, synced, or managed by the hcloud lab workflow. |

Terraform/OpenTofu owns the hcloud infrastructure lifecycle. Garden consumes the materialized kubeconfig at `infra/hcloud-lab/generated/kubeconfig` after an explicit apply, but Garden is not the cloud resource owner and must not auto-apply infrastructure during normal validation or reconciliation.

## Current stack shape

The stack under `infra/hcloud-lab/` uses the Terraform Registry module `hcloud-talos/talos/hcloud` pinned to `3.4.12`.

The configured demo shape is the module's minimal non-HA shape that is useful for a reconciliation rehearsal:

- 1 Talos control-plane node;
- 1 Talos worker node;
- `cax11` by default for both nodes;
- `fsn1` by default;
- `firewall_use_current_ip = true` by default so the public Kubernetes/Talos APIs are limited to the runner's current IP by module firewall rules;
- optional explicit `firewall_kube_api_source` and `firewall_talos_api_source` CIDR lists for rotating runner egress/NAT pools, left null by default;
- strict `homelab-garden-hcloud-lab` cluster-name prefix validation;
- disposable node labels where the module supports node labels.

This is intentionally not HA. Any multi-control-plane or larger worker design should be a separate lifecycle/cost decision.

The stack emits sensitive `kubeconfig` and `talosconfig` outputs and writes them with `local_sensitive_file` under `infra/hcloud-lab/generated/` after apply. Those files, Terraform state, plans, and tfvars must stay out of Git.

## Cost and lifetime

Verify current Hetzner pricing before provisioning. Hetzner's official price-adjustment page says the 2026-06-15 adjustment applies to new cloud orders and rescales, lists prices excluding VAT, and lists EU `CX23` at `€0.0088/hr` / `€5.49/mo` excluding IPv4/VAT after the adjustment: <https://docs.hetzner.com/general/infrastructure-and-availability/price-adjustment/>.

For the documented two-node placeholder shape, server-only compute is roughly:

- 2 × `CX23` = `€0.0176/hr` excluding IPv4/VAT;
- about `€0.42/day` if left up for 24 hours, excluding IPv4/VAT and any other billable resources.

Set a short maximum lifetime before creating resources. Default expectation: destroy the lab the same day, with an intended maximum lifetime of 24 hours unless deliberately extended.

## Prerequisites and missing-prereq behavior

Local tools:

- `tofu` or `terraform`;
- `hcloud` CLI;
- `talosctl`;
- `kubectl`.

Credentials:

- `HCLOUD_TOKEN` in the environment for the hcloud CLI.
- `TF_VAR_hcloud_token="$HCLOUD_TOKEN"` for Terraform/OpenTofu, because the module requires an explicit `hcloud_token` input and Terraform will not implicitly pass `HCLOUD_TOKEN` into that variable.
- `TF_VAR_talos_image_id_arm` or a local `talos_image_id_arm` in `terraform.tfvars`.
- Use a Hetzner Cloud token with permissions appropriate to the action. Hetzner's official API-token docs describe generating project tokens and Read & Write tokens for create/update/delete API calls: <https://docs.hetzner.com/cloud/api/getting-started/generating-api-token/>.

Run the non-mutating preflight before any plan/apply:

```bash
infra/hcloud-lab/scripts/preflight.sh
```

If a required tool or `HCLOUD_TOKEN` is missing, preflight fails before any apply and reports the missing prerequisite. It does not mutate cloud resources.

For runners with rotating public egress, the module's detected current-IP firewall rule can be too narrow for long Garden validations. In that case, set the smallest trusted CIDR range in both `firewall_kube_api_source` and `firewall_talos_api_source` in `terraform.tfvars` before an explicit plan/apply. Keep them null for the default current-IP behavior.

## Sensitive files

Do not commit:

- `terraform.tfvars`;
- `*.tfstate`, `*.tfstate.*`, `*.tfplan`;
- `.terraform/`;
- generated kubeconfigs or talosconfigs;
- generated secret material;
- real tokens or credentials.

Only `terraform.tfvars.example` belongs in Git.

## Explicit lifecycle commands

These commands are documentation for the future real stack. Do not run them unless you intend to create or destroy paid resources.

```bash
cp infra/hcloud-lab/terraform.tfvars.example infra/hcloud-lab/terraform.tfvars
$EDITOR infra/hcloud-lab/terraform.tfvars
infra/hcloud-lab/scripts/preflight.sh
```

Plan explicitly:

```bash
export TF_VAR_hcloud_token="$HCLOUD_TOKEN"
export TF_VAR_talos_image_id_arm=123456 # custom ARM Talos snapshot ID
tofu -chdir=infra/hcloud-lab init
tofu -chdir=infra/hcloud-lab plan -out=hcloud-lab.tfplan
```

Apply explicitly:

```bash
tofu -chdir=infra/hcloud-lab apply hcloud-lab.tfplan
```

Destroy explicitly:

```bash
tofu -chdir=infra/hcloud-lab destroy
```

Equivalent `terraform -chdir=infra/hcloud-lab ...` commands may be used when Terraform is the installed tool.

## Garden reconciliation workflow

After explicit provisioning, run the optional hcloud reconciliation lane with the Terraform-materialized kubeconfig:

```bash
KUBECONFIG=infra/hcloud-lab/generated/kubeconfig kubectl config get-contexts admin@homelab-garden-hcloud-lab
garden workflow hcloud-argocd-reconcile --env hcloud-lab
```

`project.garden.yml` defines `hcloud-lab` with `kubeContext=admin@homelab-garden-hcloud-lab` and `kubeconfigPath=infra/hcloud-lab/generated/kubeconfig`. Garden does not initialize or apply Terraform for this reconciliation workflow; it consumes the kubeconfig path materialized by the explicit Terraform/OpenTofu lifecycle. No Garden Terraform `autoApply` behavior is configured.

The hcloud ArgoCD scripts use `kubectl --kubeconfig infra/hcloud-lab/generated/kubeconfig --context admin@homelab-garden-hcloud-lab` and refuse any other kubeconfig path or context. That keeps the workflow pointed at the ephemeral hcloud cluster only, not local kind or the real homelab kubeconfig.

The hcloud app-of-apps uses hcloud-specific Application names:

- `app-of-apps-hcloud-lab`
- `platform-hcloud-lab`
- `demo-api-hcloud-lab`

The child Applications source app-owned overlays directly (`k8s/apps/platform/foundation/overlays/local` and `k8s/apps/workloads/demo-api/overlays/local`) instead of pointing both Applications at `k8s/targets/hcloud-lab`. This preserves separate platform-before-demo sync waves and avoids two Applications managing the same target index. `k8s/targets/hcloud-lab` remains the raw-Kustomize-safe aggregate render/validation index for the same desired state.

After the hcloud ArgoCD baseline is healthy, `garden workflow hcloud-rollout-demo --env hcloud-lab` can validate Argo Rollouts on the ephemeral cluster. The workflow reuses the same guarded kubeconfig/context convention, installs Rollouts, applies an isolated good Rollout scenario in `hcloud-rollouts-demo`, smoke-tests it, then verifies the ArgoCD-managed `demo-api-hcloud-lab` baseline is still Synced/Healthy. It does not run Terraform/OpenTofu or replace the ArgoCD-managed `demo/demo-api` Deployment.

## Teardown verification

After destroy, verify no expected lab resources remain. Filter by the strict `homelab-garden-hcloud-lab` name prefix and disposable labels where the module exposes them. Also check the project for obvious leftovers with the hcloud CLI and Hetzner Console:

```bash
hcloud server list
hcloud load-balancer list
hcloud network list
hcloud volume list
```

If local files are missing but Terraform state still exists, recover them with `terraform -chdir=infra/hcloud-lab output --raw kubeconfig > infra/hcloud-lab/generated/kubeconfig` and the equivalent `talosconfig` command.

## Target composition status

The archived `adopt-targeted-kustomize-composition` change defined the target strategy: app-owned overlays under `k8s/apps/**`, thin composition indexes under `k8s/targets/<target>`, and raw-Kustomize-safe ArgoCD source paths.

`k8s/targets/hcloud-lab` is now present as a thin raw-Kustomize-safe index over the app-owned overlays selected for the hcloud lab. The hcloud ArgoCD child Applications use the app-owned overlays directly for independent sync/health checks, while the target index remains the aggregate validation entrypoint.
