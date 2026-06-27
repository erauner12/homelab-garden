#!/usr/bin/env bash
set -euo pipefail

namespace="${APP_NAMESPACE:-demo}"
name="${DEMO_APP_NAME:-demo-api}"

kubectl -n "$namespace" rollout status "deployment/$name" --timeout=90s

pod="$(kubectl -n "$namespace" get pod -l app.kubernetes.io/name="$name" -o jsonpath='{.items[0].metadata.name}')"
kubectl -n "$namespace" exec "$pod" -- wget -qO- "http://$name" | grep -q "homelab-garden demo-api ok"

echo "Smoke check passed for $name"
