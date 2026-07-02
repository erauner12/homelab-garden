# hcloud Lab Terraform/OpenTofu Stack

Disposable Hetzner/Talos lab stack for optional reconciliation rehearsals.

This stack uses the Terraform Registry module `hcloud-talos/talos/hcloud` pinned to `3.4.12`, plus the `hcloud-talos/imager` provider to create the ARM Talos snapshot from Talos Image Factory. It is intentionally non-HA: one control-plane node and one worker node, both `cax11` by default.

Nothing in this directory should be applied by default. Planning/apply/destroy are explicit operator actions only.

## Required local inputs

Do not put the Hetzner token in `terraform.tfvars`.

```bash
export HCLOUD_TOKEN=...
export TF_VAR_hcloud_token="$HCLOUD_TOKEN"
```

The default `cax11` nodes are ARM. By default Terraform creates a custom ARM Talos snapshot with `hcloud-talos/imager` and passes its ID to `module.talos.talos_image_id_arm`; no `TF_VAR_talos_image_id_arm` export is required.

The managed snapshot URL follows the Talos Image Factory hcloud ARM raw format documented for the hcloud-talos module:

```text
https://factory.talos.dev/image/<schematic-id>/<talos-version>/hcloud-arm64.raw.xz
```

The default schematic ID is Talos Image Factory's documented vanilla schematic (`customization:`; no extensions): `376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba`. Override `talos_image_factory_schematic_id` only if you have uploaded a custom schematic.

To skip imager and use an existing ARM snapshot, set the optional override:

```bash
export TF_VAR_talos_image_id_arm=123456
```

The module README warns that official Hetzner Talos ISOs can be stale or boot in the wrong mode, so this stack does not default to an official ISO ID.

## Safe preflight

```bash
infra/hcloud-lab/scripts/preflight.sh
```

The preflight checks for `tofu` or `terraform`, `hcloud`, `talosctl`, `kubectl`, `HCLOUD_TOKEN`, and `TF_VAR_hcloud_token`. `TF_VAR_talos_image_id_arm` is only needed when intentionally using an existing snapshot override. It exits before any apply and does not mutate cloud resources.

## Explicit lifecycle

```bash
cp infra/hcloud-lab/terraform.tfvars.example infra/hcloud-lab/terraform.tfvars
$EDITOR infra/hcloud-lab/terraform.tfvars
terraform -chdir=infra/hcloud-lab init
terraform -chdir=infra/hcloud-lab plan -out=hcloud-lab.tfplan
```

Only apply if you intend to create paid, disposable cloud resources:

```bash
terraform -chdir=infra/hcloud-lab apply hcloud-lab.tfplan
terraform -chdir=infra/hcloud-lab destroy
```

Equivalent `tofu -chdir=infra/hcloud-lab ...` commands may be used.

## Generated sensitive files

`local_sensitive_file` writes these after apply:

- `infra/hcloud-lab/generated/kubeconfig`
- `infra/hcloud-lab/generated/talosconfig`

Sensitive outputs are also available if file materialization needs to be bypassed:

```bash
terraform -chdir=infra/hcloud-lab output --raw kubeconfig > infra/hcloud-lab/generated/kubeconfig
terraform -chdir=infra/hcloud-lab output --raw talosconfig > infra/hcloud-lab/generated/talosconfig
```

Do not commit `terraform.tfvars`, state, plans, `.terraform/`, generated kubeconfig, generated talosconfig, or secrets. Use `terraform.tfvars.example` as the only checked-in variable example.
