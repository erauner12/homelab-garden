#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

usage() {
  cat <<'USAGE'
Usage: infra/hcloud-lab/scripts/create.sh [--x86|--arm|--profile x86|arm]

Creates the disposable hcloud lab. Default profile is validated x86/cx23.
Use --arm or --profile arm to request the ARM/cax11 profile.
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

"${SCRIPT_DIR}/preflight.sh"

tf="$(hcloud_lab_tf)"
stack_dir="$(hcloud_lab_stack_dir)"
plan_file="hcloud-lab.tfplan"

"${tf}" -chdir="${stack_dir}" init
"${tf}" -chdir="${stack_dir}" plan -out="${plan_file}"
"${tf}" -chdir="${stack_dir}" apply "${plan_file}"

cat <<EOF

hcloud lab created.

KUBECONFIG=${stack_dir}/generated/kubeconfig kubectl get nodes -o wide
KUBECONFIG=${stack_dir}/generated/kubeconfig kubectl get pods -A
${SCRIPT_DIR}/status.sh --profile ${profile}

Generated files stay under ${stack_dir}/generated/ and must not be committed.
EOF
