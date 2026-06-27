#!/usr/bin/env bash
set -euo pipefail

namespace="${APP_NAMESPACE:-demo}"
name="${DEMO_APP_NAME:-demo-api}"
url="http://${name}.${namespace}.svc.cluster.local"
check_pod="${name}-smoke"

cleanup() {
  kubectl -n "$namespace" delete pod "$check_pod" --ignore-not-found --wait=false >/dev/null 2>&1 || true
}
trap cleanup EXIT

kubectl -n "$namespace" rollout status "deployment/$name" --timeout=90s
cleanup
kubectl -n "$namespace" run "$check_pod" \
  --image=curlimages/curl:8.8.0 \
  --restart=Never \
  --command -- sleep 300 >/dev/null
kubectl -n "$namespace" wait --for=condition=Ready "pod/$check_pod" --timeout=60s

kubectl -n "$namespace" exec "$check_pod" -- curl -fsS "$url" | grep -q "homelab-garden demo-api ok"

echo "Smoke check passed for $name"
