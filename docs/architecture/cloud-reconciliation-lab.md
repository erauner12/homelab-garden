# Ephemeral hcloud Reconciliation Lab

This is an optional, explicit lane for a disposable Hetzner Cloud reconciliation exercise. The Terraform/OpenTofu stack can now plan a Talos Kubernetes cluster, but it must not be applied by default.

## Boundaries

| Lane | Purpose | Must not do |
| --- | --- | --- |
| `local kind` | Default local validation and disposable local ArgoCD exercises. | Require Hetzner credentials, Terraform/OpenTofu state, Talos config, or cloud resources. |
| `hcloud-lab` | Optional, explicit, disposable cloud-cluster rehearsal. | Run by default, touch the real homelab, or create resources without an explicit Terraform/OpenTofu apply. |
| `real homelab` | Existing production-ish homelab outside this lab. | Be deployed to, configured, synced, or managed by the hcloud lab workflow. |

Terraform/OpenTofu owns the hcloud infrastructure lifecycle. Garden may later orchestrate explicit commands and consume Terraform outputs such as a kubeconfig path, but Garden is not the cloud resource owner and must not auto-apply infrastructure during normal validation or reconciliation.

## Current stack shape

The stack under `infra/hcloud-lab/` uses the Terraform Registry module `hcloud-talos/talos/hcloud` pinned to `3.4.12`.

The configured demo shape is the module's minimal non-HA shape that is useful for a reconciliation rehearsal:

- 1 Talos control-plane node;
- 1 Talos worker node;
- `cax11` by default for both nodes;
- `fsn1` by default;
- `firewall_use_current_ip = true` by default so the public Kubernetes/Talos APIs are limited to the runner's current IP by module firewall rules;
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

The archived `adopt-targeted-kustomize-composition` change defined the target strategy: app-owned overlays under `k8s/apps/**`, thin composition indexes under `k8s/targets/<target>`, and raw-Kustomize-safe ArgoCD source paths. It intentionally deferred `k8s/targets/hcloud-lab` until an hcloud reconciliation lane has a real target composition to source.

This foundation slice does not add hcloud ArgoCD Applications or `k8s/targets/hcloud-lab`. Add that target only with the real reconciliation workflow, and keep it a thin raw-Kustomize-safe index over app-owned hcloud overlays.
