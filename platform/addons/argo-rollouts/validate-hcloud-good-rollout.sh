#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../argocd/hcloud-common.sh"

rollout_namespace="${HCLOUD_ROLLOUT_NAMESPACE:-hcloud-rollouts-demo}"
rollout_name="${DEMO_APP_NAME:-demo-api}"
expected_text="${SMOKE_EXPECTED_TEXT:-homelab-garden demo-api ok}"
check_pod="${SMOKE_CHECK_POD:-${rollout_name}-hcloud-rollout-smoke}"
timeout_seconds="${HCLOUD_ROLLOUT_TIMEOUT_SECONDS:-300}"
poll_seconds="${HCLOUD_ROLLOUT_POLL_SECONDS:-5}"

if [[ "${rollout_namespace}" != "hcloud-rollouts-demo" ]]; then
  cat >&2 <<EOF
Refusing unexpected hcloud Rollout namespace: ${rollout_namespace}
This workflow intentionally keeps the Rollout separate from the ArgoCD-managed demo namespace.
EOF
  exit 1
fi

diagnostics() {
  cat >&2 <<EOF

Hcloud Rollout validation diagnostics for context ${context}
EOF
  echo "--- rollout namespace resources ---" >&2
  "${kubectl_cmd[@]}" -n "${rollout_namespace}" get rollout,analysisrun,replicaset,pod,service -o wide >&2 || true
  echo "--- rollout description ---" >&2
  "${kubectl_cmd[@]}" -n "${rollout_namespace}" describe rollout "${rollout_name}" >&2 || true
  echo "--- recent rollout namespace events ---" >&2
  "${kubectl_cmd[@]}" -n "${rollout_namespace}" get events --sort-by=.lastTimestamp >&2 || true
  echo "--- rollout pod logs ---" >&2
  "${kubectl_cmd[@]}" -n "${rollout_namespace}" logs -l app.kubernetes.io/name="${rollout_name}" --tail=100 --all-containers=true --prefix=true >&2 || true
}

cleanup_smoke_pod() {
  "${kubectl_cmd[@]}" -n "${rollout_namespace}" delete pod "${check_pod}" --ignore-not-found --wait=false >/dev/null 2>&1 || true
}

on_exit() {
  local status=$?
  cleanup_smoke_pod
  if (( status != 0 )); then
    diagnostics
  fi
  exit "${status}"
}
trap on_exit EXIT

wait_for_rollout_healthy() {
  local deadline=$((SECONDS + timeout_seconds))
  echo "Waiting for Rollout/${rollout_name} in namespace ${rollout_namespace} to become Healthy"

  while (( SECONDS < deadline )); do
    local phase message
    phase="$("${kubectl_cmd[@]}" -n "${rollout_namespace}" get rollout "${rollout_name}" -o jsonpath='{.status.phase}' 2>/dev/null || true)"
    message="$("${kubectl_cmd[@]}" -n "${rollout_namespace}" get rollout "${rollout_name}" -o jsonpath='{.status.message}' 2>/dev/null || true)"

    if [[ "${phase}" == "Healthy" ]]; then
      echo "Rollout/${rollout_name} is Healthy"
      return 0
    fi

    printf '  rollout/%s phase=%s %s\n' "${rollout_name}" "${phase:-unknown}" "${message}"
    sleep "${poll_seconds}"
  done

  echo "Timed out waiting for Rollout/${rollout_name} to become Healthy" >&2
  return 1
}

smoke_rollout_service() {
  local url="http://${rollout_name}.${rollout_namespace}.svc.cluster.local"

  cleanup_smoke_pod
  "${kubectl_cmd[@]}" -n "${rollout_namespace}" run "${check_pod}" \
    --image=curlimages/curl:8.8.0 \
    --restart=Never \
    --command -- sleep 300 >/dev/null
  "${kubectl_cmd[@]}" -n "${rollout_namespace}" wait --for=condition=Ready "pod/${check_pod}" --timeout=60s
  "${kubectl_cmd[@]}" -n "${rollout_namespace}" exec "${check_pod}" -- curl -fsS "${url}" | grep -q "${expected_text}"
  echo "Smoke check passed for Rollout service ${url}"
}

wait_for_rollout_healthy
KUBECONFIG="${resolved_kubeconfig}" KUBE_CONTEXT="${context}" APP_NAMESPACE="${rollout_namespace}" DEMO_APP_NAME="${rollout_name}" "${root}/validation/health.sh"
smoke_rollout_service
cleanup_smoke_pod
trap - EXIT

cat <<EOF
Hcloud Rollout validation passed.
Context: ${context}
Kubeconfig: ${resolved_kubeconfig}
Namespace: ${rollout_namespace}
Rollout: ${rollout_name}
EOF
