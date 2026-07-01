#!/usr/bin/env bash
set -euo pipefail

namespace="${SMOKE_NAMESPACE:?SMOKE_NAMESPACE is required}"
name="${SMOKE_NAME:?SMOKE_NAME is required}"
expected_text="${SMOKE_EXPECTED_TEXT:?SMOKE_EXPECTED_TEXT is required}"
context="${KUBECONTEXT:-${KUBE_CONTEXT:-kind-homelab-garden}}"
url="${SMOKE_URL:-http://${name}.${namespace}.svc.cluster.local}"
check_pod="${SMOKE_CHECK_POD:-${name}-smoke}"
label="${SMOKE_LABEL:-$namespace}"

kubectl_cmd=(kubectl --context "$context")

cleanup() {
  "${kubectl_cmd[@]}" -n "$namespace" delete pod "$check_pod" --ignore-not-found --wait=false >/dev/null 2>&1 || true
}

cleanup_existing_check_pod() {
  if ! "${kubectl_cmd[@]}" -n "$namespace" get pod "$check_pod" >/dev/null 2>&1; then
    return
  fi

  echo "Removing stale smoke pod $check_pod in namespace $namespace"
  if "${kubectl_cmd[@]}" -n "$namespace" delete pod "$check_pod" --ignore-not-found --wait=true --timeout=60s >/dev/null 2>&1; then
    return
  fi

  echo "Stale smoke pod $check_pod did not delete cleanly; forcing removal" >&2
  "${kubectl_cmd[@]}" -n "$namespace" delete pod "$check_pod" --ignore-not-found --force --grace-period=0 --wait=false >/dev/null 2>&1 || true
  "${kubectl_cmd[@]}" -n "$namespace" wait --for=delete "pod/$check_pod" --timeout=30s >/dev/null 2>&1 || true
}

diagnostics() {
  status=$?
  if [ "$status" -eq 0 ]; then
    return
  fi

  echo "Smoke check failed for $name in namespace $namespace using context $context" >&2
  echo "--- $label namespace pods ---" >&2
  "${kubectl_cmd[@]}" -n "$namespace" get pods -o wide >&2 || true
  echo "--- $label namespace services ---" >&2
  "${kubectl_cmd[@]}" -n "$namespace" get services -o wide >&2 || true
  echo "--- recent $label namespace events ---" >&2
  "${kubectl_cmd[@]}" -n "$namespace" get events --sort-by=.lastTimestamp >&2 || true
  echo "--- deployment logs: $name ---" >&2
  "${kubectl_cmd[@]}" -n "$namespace" logs "deployment/$name" --tail=100 >&2 || true
}

trap cleanup EXIT
trap diagnostics ERR

"${kubectl_cmd[@]}" -n "$namespace" rollout status "deployment/$name" --timeout=90s
cleanup_existing_check_pod
"${kubectl_cmd[@]}" -n "$namespace" run "$check_pod" \
  --image=curlimages/curl:8.8.0 \
  --restart=Never \
  --command -- sleep 300 >/dev/null
"${kubectl_cmd[@]}" -n "$namespace" wait --for=condition=Ready "pod/$check_pod" --timeout=60s

"${kubectl_cmd[@]}" -n "$namespace" exec "$check_pod" -- curl -fsS "$url" | grep -q "$expected_text"

echo "Smoke check passed for $name"
