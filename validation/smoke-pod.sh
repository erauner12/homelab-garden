#!/usr/bin/env bash

smoke_pod_manifest_path() {
  local helper_root
  helper_root="${root:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
  printf '%s\n' "${SMOKE_POD_MANIFEST:-${helper_root}/validation/smoke-pod.yaml}"
}

create_smoke_pod() {
  local namespace="${1:?namespace is required}"
  local manifest pod_name
  manifest="$(smoke_pod_manifest_path)"

  if [[ ! -f "${manifest}" ]]; then
    echo "Missing smoke pod manifest: ${manifest}" >&2
    return 1
  fi

  pod_name="$("${kubectl_cmd[@]}" -n "${namespace}" create -f "${manifest}" -o jsonpath='{.metadata.name}')"
  if [[ -z "${pod_name}" ]]; then
    echo "kubectl did not return generated smoke pod name" >&2
    return 1
  fi

  printf '%s\n' "${pod_name}"
}
