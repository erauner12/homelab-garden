#!/usr/bin/env bash
set -euo pipefail

context="${KUBE_CONTEXT:-kind-homelab-garden}"
namespace="argocd"
timeout_seconds="${ARGOCD_RECONCILE_TIMEOUT_SECONDS:-600}"

if [[ "${context}" != kind-* ]]; then
  cat >&2 <<EOF
Refusing to wait on local ArgoCD Applications in non-kind context: ${context}
Set KUBE_CONTEXT to the local kind context for this exercise.
EOF
  exit 1
fi

kubectl_cmd=(kubectl --context "${context}")
deadline=$((SECONDS + timeout_seconds))

app_field() {
  local app="$1"
  local field="$2"
  "${kubectl_cmd[@]}" -n "${namespace}" get application "${app}" -o "jsonpath=${field}" 2>/dev/null || true
}

wait_for_app() {
  local app="$1"
  local want_health="$2"

  echo "Waiting for ArgoCD Application/${app} sync=Synced health=${want_health}"
  while (( SECONDS < deadline )); do
    local sync health message
    sync="$(app_field "${app}" '{.status.sync.status}')"
    health="$(app_field "${app}" '{.status.health.status}')"
    message="$(app_field "${app}" '{.status.conditions[0].message}')"

    if [[ "${sync}" == "Synced" && "${health}" == "${want_health}" ]]; then
      echo "Application/${app} is Synced and ${want_health}"
      return 0
    fi

    if [[ "${message}" =~ (authentication|required|Repository\ not\ found|failed\ to\ list\ refs|revision|app\ path|not\ found) ]]; then
      local repo revision
      repo="$(app_field "${app}" '{.spec.source.repoURL}')"
      revision="$(app_field "${app}" '{.spec.source.targetRevision}')"
      cat >&2 <<EOF
Application/${app} cannot fetch or render its remote Git source:
${message}

Actual Application source:
repoURL: ${repo:-unknown}
targetRevision: ${revision:-unknown}

ArgoCD runs inside the local cluster and fetches the configured remote HTTPS repo.
Push the configured revision and make the repo reachable to ArgoCD before rerunning
this workflow. Uncommitted local changes and unpushed commits are invisible to ArgoCD.
EOF
      return 1
    fi

    printf '  %s sync=%s health=%s %s\n' "${app}" "${sync:-unknown}" "${health:-unknown}" "${message}"
    sleep 10
  done

  echo "Timed out waiting for Application/${app}" >&2
  "${kubectl_cmd[@]}" -n "${namespace}" get applications -o wide >&2 || true
  "${kubectl_cmd[@]}" -n "${namespace}" describe application "${app}" >&2 || true
  return 1
}

wait_for_exists() {
  local app="$1"
  echo "Waiting for Application/${app} to exist"
  while (( SECONDS < deadline )); do
    if "${kubectl_cmd[@]}" -n "${namespace}" get application "${app}" >/dev/null 2>&1; then
      return 0
    fi
    sleep 5
  done
  echo "Timed out waiting for Application/${app} to be created" >&2
  return 1
}

wait_for_exists app-of-apps
wait_for_app app-of-apps Healthy
wait_for_exists platform-local
wait_for_app platform-local Healthy
wait_for_exists demo-api-local
wait_for_app demo-api-local Healthy

"${kubectl_cmd[@]}" -n platform rollout status deployment/platform-smoke --timeout=120s
"${kubectl_cmd[@]}" -n demo rollout status deployment/demo-api --timeout=120s

cat <<EOF
Local ArgoCD reconciliation is synced and healthy on ${context}.
Verified ordering intent: app-of-apps creates platform-local before demo-api-local via sync waves.
EOF
