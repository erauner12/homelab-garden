#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

usage() {
  cat <<'USAGE'
Usage: infra/hcloud-lab/scripts/status.sh [--x86|--arm|--profile x86|arm]

Prints Terraform state, Hetzner inventory, and Kubernetes status when kubeconfig exists.
Does not apply or destroy resources.
USAGE
}

for arg in "$@"; do
  case "${arg}" in
    -h|--help)
      usage
      exit 0
      ;;
  esac
done

profile="$(hcloud_lab_parse_profile "$@")"
hcloud_lab_apply_profile "${profile}"
hcloud_lab_load_token
hcloud_lab_print_profile

tf="$(hcloud_lab_tf)"
stack_dir="$(hcloud_lab_stack_dir)"
kubeconfig="${stack_dir}/generated/kubeconfig"

echo
printf 'Terraform/OpenTofu state summary:\n'
if [ -f "${stack_dir}/terraform.tfstate" ] || [ -d "${stack_dir}/.terraform" ]; then
  "${tf}" -chdir="${stack_dir}" state list || true
else
  printf 'no local Terraform/OpenTofu state or .terraform directory found under %s\n' "${stack_dir}"
fi

echo
printf 'hcloud inventory for the disposable lab:\n'
hcloud_lab_print_inventory

echo
if [ -f "${kubeconfig}" ]; then
  printf 'Kubernetes status from %s:\n' "${kubeconfig}"
  KUBECONFIG="${kubeconfig}" kubectl get nodes -o wide || true
  KUBECONFIG="${kubeconfig}" kubectl get pods -A || true
else
  printf 'no generated kubeconfig found at %s; skipping kubectl checks.\n' "${kubeconfig}"
fi
