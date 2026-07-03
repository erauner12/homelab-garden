#!/usr/bin/env bash

hcloud_lab_repo_root() {
  local script_dir
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
  cd -- "${script_dir}/../../.." >/dev/null 2>&1 && pwd
}

hcloud_lab_stack_dir() {
  printf '%s/infra/hcloud-lab\n' "$(hcloud_lab_repo_root)"
}

hcloud_lab_tf() {
  if command -v tofu >/dev/null 2>&1; then
    printf 'tofu\n'
  elif command -v terraform >/dev/null 2>&1; then
    printf 'terraform\n'
  else
    printf 'missing required command: tofu or terraform\n' >&2
    return 1
  fi
}

hcloud_lab_load_token() {
  if [ -n "${HCLOUD_TOKEN:-}" ]; then
    export TF_VAR_hcloud_token="${TF_VAR_hcloud_token:-${HCLOUD_TOKEN}}"
    return 0
  fi

  if [ -n "${TF_VAR_hcloud_token:-}" ]; then
    export HCLOUD_TOKEN="${TF_VAR_hcloud_token}"
    return 0
  fi

  local repo_root secret_file age_key_file token
  repo_root="$(hcloud_lab_repo_root)"
  secret_file="${repo_root}/secrets/hcloud-lab.sops.yaml"
  age_key_file="${SOPS_AGE_KEY_FILE:-${repo_root}/secrets/age/key.txt}"

  if [ -f "${secret_file}" ] && [ -f "${age_key_file}" ] && command -v sops >/dev/null 2>&1; then
    token="$(SOPS_AGE_KEY_FILE="${age_key_file}" sops --decrypt --extract '["stringData"]["HCLOUD_TOKEN"]' "${secret_file}")"
    if [ -n "${token}" ]; then
      export HCLOUD_TOKEN="${token}"
      export TF_VAR_hcloud_token="${token}"
      printf 'loaded Hetzner token from encrypted SOPS file (value hidden).\n' >&2
      return 0
    fi
  fi

  printf 'missing Hetzner token: set HCLOUD_TOKEN or TF_VAR_hcloud_token, or provide %s with SOPS_AGE_KEY_FILE=%s\n' "${secret_file}" "${age_key_file}" >&2
  return 1
}

hcloud_lab_apply_profile() {
  local profile="${1:-x86}"

  case "${profile}" in
    x86|cx23|validated)
      export TF_VAR_architecture=x86
      export TF_VAR_control_plane_type=cx23
      export TF_VAR_worker_type=cx23
      export TF_VAR_talos_imager_server_type=cx23
      ;;
    arm|cax11)
      export TF_VAR_architecture=arm
      export TF_VAR_control_plane_type=cax11
      export TF_VAR_worker_type=cax11
      export TF_VAR_talos_imager_server_type=cax11
      ;;
    *)
      printf 'unknown profile: %s (expected x86, cx23, validated, arm, or cax11)\n' "${profile}" >&2
      return 1
      ;;
  esac
}

hcloud_lab_parse_profile() {
  local profile=x86
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --profile)
        profile="${2:-}"
        shift 2
        ;;
      --profile=*)
        profile="${1#--profile=}"
        shift
        ;;
      --x86|--cx23|--validated)
        profile=x86
        shift
        ;;
      --arm|--cax11)
        profile=arm
        shift
        ;;
      *)
        shift
        ;;
    esac
  done
  printf '%s\n' "${profile}"
}

hcloud_lab_print_profile() {
  printf 'profile: architecture=%s control_plane_type=%s worker_type=%s talos_imager_server_type=%s\n' \
    "${TF_VAR_architecture:-}" \
    "${TF_VAR_control_plane_type:-}" \
    "${TF_VAR_worker_type:-}" \
    "${TF_VAR_talos_imager_server_type:-}"
}

hcloud_lab_print_inventory() {
  printf 'servers:\n'
  hcloud server list --selector 'cluster=homelab-garden-hcloud-lab' || true
  printf '\nnetworks:\n'
  hcloud network list --selector 'cluster=homelab-garden-hcloud-lab' || true
  printf '\nprimary IPs:\n'
  hcloud primary-ip list --selector 'cluster=homelab-garden-hcloud-lab' || true
  printf '\nfirewalls:\n'
  hcloud firewall list --selector 'cluster=homelab-garden-hcloud-lab' || true
  printf '\nSSH keys:\n'
  hcloud ssh-key list --selector 'cluster=homelab-garden-hcloud-lab' || true
  printf '\nTalos snapshots/images:\n'
  hcloud image list --selector 'homelab-garden.io/lab=hcloud' || true
  printf '\nload balancers:\n'
  hcloud load-balancer list --selector 'cluster=homelab-garden-hcloud-lab' || true
}
