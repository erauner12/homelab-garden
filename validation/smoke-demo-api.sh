#!/usr/bin/env bash
set -euo pipefail

namespace="${APP_NAMESPACE:-demo}"
name="${DEMO_APP_NAME:-demo-api}"
context="${KUBECONTEXT:-${KUBE_CONTEXT:-kind-homelab-garden}}"
url="http://${name}.${namespace}.svc.cluster.local"
check_pod="${name}-smoke"

kubectl_cmd=(kubectl --context "$context")

cleanup() {
  "${kubectl_cmd[@]}" -n "$namespace" delete pod "$check_pod" --ignore-not-found --wait=false >/dev/null 2>&1 || true
}

diagnostics() {
  status=$?
  if [ "$status" -eq 0 ]; then
    return
  fi

  echo "Smoke check failed for $name in namespace $namespace using context $context" >&2
  echo "--- demo namespace pods ---" >&2
  "${kubectl_cmd[@]}" -n "$namespace" get pods -o wide >&2 || true
  echo "--- demo namespace services ---" >&2
  "${kubectl_cmd[@]}" -n "$namespace" get services -o wide >&2 || true
  echo "--- recent demo namespace events ---" >&2
  "${kubectl_cmd[@]}" -n "$namespace" get events --sort-by=.lastTimestamp >&2 || true
  echo "--- deployment logs: $name ---" >&2
  "${kubectl_cmd[@]}" -n "$namespace" logs "deployment/$name" --tail=100 >&2 || true
}

trap cleanup EXIT
trap diagnostics ERR

"${kubectl_cmd[@]}" -n "$namespace" rollout status "deployment/$name" --timeout=90s
cleanup
"${kubectl_cmd[@]}" -n "$namespace" run "$check_pod" \
  --image=curlimages/curl:8.8.0 \
  --restart=Never \
  --command -- sleep 300 >/dev/null
"${kubectl_cmd[@]}" -n "$namespace" wait --for=condition=Ready "pod/$check_pod" --timeout=60s

"${kubectl_cmd[@]}" -n "$namespace" exec "$check_pod" -- curl -fsS "$url" | grep -q "homelab-garden demo-api ok"

echo "Smoke check passed for $name"
