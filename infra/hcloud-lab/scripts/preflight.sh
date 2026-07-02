#!/usr/bin/env bash
set -euo pipefail

missing=0

require_cmd() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    printf 'missing required command: %s\n' "$name" >&2
    missing=1
  fi
}

if command -v tofu >/dev/null 2>&1; then
  printf 'found OpenTofu: %s\n' "$(tofu version | head -n 1)"
elif command -v terraform >/dev/null 2>&1; then
  printf 'found Terraform: %s\n' "$(terraform version | head -n 1)"
else
  printf 'missing required command: tofu or terraform\n' >&2
  missing=1
fi

require_cmd hcloud
require_cmd talosctl
require_cmd kubectl

if [ -z "${HCLOUD_TOKEN:-}" ]; then
  printf 'missing environment variable: HCLOUD_TOKEN\n' >&2
  missing=1
fi

if [ -z "${TF_VAR_hcloud_token:-}" ]; then
  if [ -n "${HCLOUD_TOKEN:-}" ]; then
    printf 'missing environment variable: TF_VAR_hcloud_token; export TF_VAR_hcloud_token="$HCLOUD_TOKEN" before terraform/tofu plan or apply\n' >&2
  else
    printf 'missing environment variable: TF_VAR_hcloud_token\n' >&2
  fi
  missing=1
fi

if [ -n "${TF_VAR_talos_image_id_arm:-}" ]; then
  printf 'using existing ARM Talos snapshot override from TF_VAR_talos_image_id_arm; default path creates one with hcloud-talos/imager.\n'
fi

if [ "$missing" -ne 0 ]; then
  printf '\nhcloud lab preflight failed. No Terraform/OpenTofu apply was run and no cloud resources were mutated.\n' >&2
  exit 1
fi

printf 'hcloud lab preflight passed. This check is read-only and did not mutate cloud resources.\n'
