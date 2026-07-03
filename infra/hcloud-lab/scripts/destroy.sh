#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

usage() {
  cat <<'USAGE'
Usage: infra/hcloud-lab/scripts/destroy.sh [--yes] [--x86|--arm|--profile x86|arm]

Destroys the disposable hcloud lab with Terraform/OpenTofu, then prints remaining
Hetzner inventory matching the lab label. Requires --yes or an interactive typed confirmation.
USAGE
}

yes=false
for arg in "$@"; do
  case "${arg}" in
    -h|--help)
      usage
      exit 0
      ;;
    --yes|-y)
      yes=true
      ;;
  esac
done

profile="$(hcloud_lab_parse_profile "$@")"
hcloud_lab_apply_profile "${profile}"
hcloud_lab_load_token
hcloud_lab_print_profile

tf="$(hcloud_lab_tf)"
stack_dir="$(hcloud_lab_stack_dir)"

if [ "${yes}" != true ]; then
  printf 'This will destroy disposable Hetzner hcloud lab resources managed by %s.\n' "${stack_dir}"
  printf 'Type destroy-hcloud-lab to continue: '
  read -r confirmation
  if [ "${confirmation}" != "destroy-hcloud-lab" ]; then
    printf 'destroy cancelled.\n' >&2
    exit 1
  fi
fi

"${tf}" -chdir="${stack_dir}" destroy

cat <<'EOF'

Remaining hcloud inventory for the disposable lab:
EOF
hcloud_lab_print_inventory
