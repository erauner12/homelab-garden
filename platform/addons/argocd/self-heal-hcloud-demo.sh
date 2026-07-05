#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/hcloud-common.sh"

argocd_namespace="${ARGOCD_NAMESPACE:-argocd}"
demo_namespace="${APP_NAMESPACE:-demo}"
demo_deployment="${DEMO_APP_NAME:-demo-api}"
parent_app="${ARGOCD_PARENT_APP:-app-of-apps-hcloud-lab}"
platform_app="${ARGOCD_PLATFORM_APP:-platform-hcloud-lab}"
demo_app="${ARGOCD_DEMO_APP:-demo-api-hcloud-lab}"
timeout_seconds="${ARGOCD_SELF_HEAL_TIMEOUT_SECONDS:-300}"
poll_seconds="${ARGOCD_SELF_HEAL_POLL_SECONDS:-5}"

app_field() {
  local app="$1"
  local field="$2"
  "${kubectl_cmd[@]}" -n "${argocd_namespace}" get application "${app}" -o "jsonpath=${field}" 2>/dev/null || true
}

app_sync() {
  app_field "$1" '{.status.sync.status}'
}

app_health() {
  app_field "$1" '{.status.health.status}'
}

deployment_replicas() {
  "${kubectl_cmd[@]}" -n "${demo_namespace}" get deployment "${demo_deployment}" -o jsonpath='{.spec.replicas}'
}

diagnostics() {
  cat >&2 <<EOF

Self-heal validation diagnostics for hcloud context ${context}
EOF

  echo "--- ArgoCD Applications ---" >&2
  "${kubectl_cmd[@]}" -n "${argocd_namespace}" get applications -o wide >&2 || true

  echo "--- ${demo_app} Application ---" >&2
  "${kubectl_cmd[@]}" -n "${argocd_namespace}" describe application "${demo_app}" >&2 || true

  echo "--- demo Deployment ---" >&2
  "${kubectl_cmd[@]}" -n "${demo_namespace}" get deployment "${demo_deployment}" -o wide >&2 || true
  "${kubectl_cmd[@]}" -n "${demo_namespace}" describe deployment "${demo_deployment}" >&2 || true

  echo "--- demo ReplicaSets and Pods ---" >&2
  "${kubectl_cmd[@]}" -n "${demo_namespace}" get replicasets,pods -o wide >&2 || true

  echo "--- recent demo events ---" >&2
  "${kubectl_cmd[@]}" -n "${demo_namespace}" get events --sort-by=.lastTimestamp >&2 || true

  echo "--- recent demo logs ---" >&2
  "${kubectl_cmd[@]}" -n "${demo_namespace}" logs "deployment/${demo_deployment}" --tail=100 --all-containers=true >&2 || true

  echo "--- recent ArgoCD application-controller logs ---" >&2
  "${kubectl_cmd[@]}" -n "${argocd_namespace}" logs -l app.kubernetes.io/name=argocd-application-controller --tail=100 --all-containers=true --prefix=true >&2 || true

  echo "--- recent ArgoCD repo-server logs ---" >&2
  "${kubectl_cmd[@]}" -n "${argocd_namespace}" logs -l app.kubernetes.io/name=argocd-repo-server --tail=100 --all-containers=true --prefix=true >&2 || true
}

on_exit() {
  local status=$?
  if (( status != 0 )); then
    diagnostics
  fi
}
trap on_exit EXIT

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

require_app_synced_healthy() {
  local app="$1"

  if ! "${kubectl_cmd[@]}" -n "${argocd_namespace}" get application "${app}" >/dev/null 2>&1; then
    fail "Application/${app} is missing in namespace ${argocd_namespace}; run hcloud-argocd-reconcile first."
  fi

  local sync health
  sync="$(app_sync "${app}")"
  health="$(app_health "${app}")"

  if [[ "${sync}" != "Synced" || "${health}" != "Healthy" ]]; then
    fail "Application/${app} baseline is not healthy: sync=${sync:-unknown} health=${health:-unknown}. Run hcloud-argocd-reconcile and retry when healthy."
  fi

  echo "Application/${app} baseline is Synced and Healthy"
}

wait_for_deployment_replicas() {
  local wanted="$1"
  local deadline=$((SECONDS + timeout_seconds))

  echo "Waiting for deployment/${demo_deployment} to return to replicas=${wanted}"
  while (( SECONDS < deadline )); do
    local current sync health
    current="$(deployment_replicas 2>/dev/null || true)"
    sync="$(app_sync "${demo_app}")"
    health="$(app_health "${demo_app}")"

    if [[ "${current}" == "${wanted}" ]]; then
      echo "deployment/${demo_deployment} spec.replicas=${wanted}"
      return 0
    fi

    printf '  deployment/%s replicas=%s; %s sync=%s health=%s\n' \
      "${demo_deployment}" "${current:-unknown}" "${demo_app}" "${sync:-unknown}" "${health:-unknown}"
    sleep "${poll_seconds}"
  done

  fail "Timed out waiting for deployment/${demo_deployment} to return to replicas=${wanted}"
}

wait_for_app_synced_healthy() {
  local app="$1"
  local deadline=$((SECONDS + timeout_seconds))

  "${kubectl_cmd[@]}" -n "${argocd_namespace}" annotate application "${app}" argocd.argoproj.io/refresh=hard --overwrite >/dev/null 2>&1 || true

  echo "Waiting for Application/${app} to be Synced and Healthy"
  while (( SECONDS < deadline )); do
    local sync health message
    sync="$(app_sync "${app}")"
    health="$(app_health "${app}")"
    message="$(app_field "${app}" '{.status.conditions[0].message}')"

    if [[ "${sync}" == "Synced" && "${health}" == "Healthy" ]]; then
      echo "Application/${app} is Synced and Healthy"
      return 0
    fi

    printf '  %s sync=%s health=%s %s\n' "${app}" "${sync:-unknown}" "${health:-unknown}" "${message}"
    sleep "${poll_seconds}"
  done

  fail "Timed out waiting for Application/${app} to be Synced and Healthy"
}

for app in "${parent_app}" "${platform_app}" "${demo_app}"; do
  require_app_synced_healthy "${app}"
done

if ! "${kubectl_cmd[@]}" -n "${demo_namespace}" get deployment "${demo_deployment}" >/dev/null 2>&1; then
  fail "deployment/${demo_deployment} is missing in namespace ${demo_namespace}; baseline is not ready."
fi

"${kubectl_cmd[@]}" -n "${demo_namespace}" rollout status "deployment/${demo_deployment}" --timeout=120s

baseline_replicas="$(deployment_replicas)"
if [[ ! "${baseline_replicas}" =~ ^[0-9]+$ ]]; then
  fail "Could not read numeric baseline replicas for deployment/${demo_deployment}: ${baseline_replicas:-empty}"
fi

drift_replicas=$((baseline_replicas + 1))

cat <<EOF
Creating safe hcloud ArgoCD self-heal drift:
  context: ${context}
  deployment: ${demo_namespace}/${demo_deployment}
  baseline replicas: ${baseline_replicas}
  drift replicas: ${drift_replicas}
EOF

"${kubectl_cmd[@]}" -n "${demo_namespace}" scale "deployment/${demo_deployment}" --replicas="${drift_replicas}"
"${kubectl_cmd[@]}" -n "${argocd_namespace}" annotate application "${demo_app}" argocd.argoproj.io/refresh=hard --overwrite >/dev/null 2>&1 || true

current_replicas="$(deployment_replicas 2>/dev/null || true)"
if [[ "${current_replicas}" == "${drift_replicas}" ]]; then
  echo "Drift applied: deployment/${demo_deployment} replicas=${drift_replicas}"
else
  echo "Deployment replicas are ${current_replicas:-unknown}; ArgoCD may already be self-healing."
fi

wait_for_deployment_replicas "${baseline_replicas}"
"${kubectl_cmd[@]}" -n "${demo_namespace}" rollout status "deployment/${demo_deployment}" --timeout=120s
wait_for_app_synced_healthy "${demo_app}"

trap - EXIT

cat <<EOF
Hcloud ArgoCD self-heal validation passed.
Application/${demo_app} restored deployment/${demo_deployment} to replicas=${baseline_replicas} on ${context}.
EOF
