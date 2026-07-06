#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${root}/validation/smoke-pod.sh"

smoke_service_main() {
  namespace="${SMOKE_NAMESPACE:?SMOKE_NAMESPACE is required}"
  name="${SMOKE_NAME:?SMOKE_NAME is required}"
  expected_text="${SMOKE_EXPECTED_TEXT:?SMOKE_EXPECTED_TEXT is required}"
  context="${KUBECONTEXT:-${KUBE_CONTEXT:-kind-homelab-garden}}"
  url="${SMOKE_URL:-http://${name}.${namespace}.svc.cluster.local}"
  label="${SMOKE_LABEL:-$namespace}"
  check_pod=""

  kubectl_cmd=(kubectl --context "$context")

  cleanup() {
    if [[ -n "$check_pod" ]]; then
      "${kubectl_cmd[@]}" -n "$namespace" delete pod "$check_pod" --ignore-not-found --wait=false >/dev/null 2>&1 || true
    fi
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
  check_pod="$(create_smoke_pod "$namespace")"
  "${kubectl_cmd[@]}" -n "$namespace" wait --for=condition=Ready "pod/$check_pod" --timeout=60s

  "${kubectl_cmd[@]}" -n "$namespace" exec "$check_pod" -- curl -fsS "$url" | grep -q "$expected_text"

}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  smoke_service_main "$@"
  echo "Smoke check passed for $name"
fi
