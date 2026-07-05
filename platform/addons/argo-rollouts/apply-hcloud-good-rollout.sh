#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../argocd/hcloud-common.sh"

rollout_namespace="${HCLOUD_ROLLOUT_NAMESPACE:-hcloud-rollouts-demo}"
scenario_path="${root}/scenarios/hcloud-good-rollout"
argocd_namespace="${ARGOCD_NAMESPACE:-argocd}"
required_apps=(app-of-apps-hcloud-lab platform-hcloud-lab demo-api-hcloud-lab)

app_field() {
  local app="$1"
  local field="$2"
  "${kubectl_cmd[@]}" -n "${argocd_namespace}" get application "${app}" -o "jsonpath=${field}" 2>/dev/null || true
}

require_app_synced_healthy() {
  local app="$1"
  if ! "${kubectl_cmd[@]}" -n "${argocd_namespace}" get application "${app}" >/dev/null 2>&1; then
    echo "Application/${app} is missing in namespace ${argocd_namespace}; run hcloud-argocd-reconcile first." >&2
    exit 1
  fi

  local sync health
  sync="$(app_field "${app}" '{.status.sync.status}')"
  health="$(app_field "${app}" '{.status.health.status}')"
  if [[ "${sync}" != "Synced" || "${health}" != "Healthy" ]]; then
    echo "Application/${app} baseline is not healthy: sync=${sync:-unknown} health=${health:-unknown}. Run hcloud-argocd-reconcile first." >&2
    exit 1
  fi
}

if [[ "${rollout_namespace}" != "hcloud-rollouts-demo" ]]; then
  cat >&2 <<EOF
Refusing unexpected hcloud Rollout namespace: ${rollout_namespace}
This workflow intentionally keeps the Rollout separate from the ArgoCD-managed demo namespace.
EOF
  exit 1
fi

for app in "${required_apps[@]}"; do
  require_app_synced_healthy "${app}"
done

"${kubectl_cmd[@]}" create namespace "${rollout_namespace}" --dry-run=client -o yaml | "${kubectl_cmd[@]}" apply -f -
kustomize build "${scenario_path}" | "${kubectl_cmd[@]}" apply -f -

cat <<EOF
Applied isolated hcloud Rollout scenario to ${context}.
Kubeconfig: ${resolved_kubeconfig}
Namespace: ${rollout_namespace}
Scenario: ${scenario_path}
EOF
