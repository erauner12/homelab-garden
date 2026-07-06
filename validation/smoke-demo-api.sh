#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/smoke-service.sh"

SMOKE_NAMESPACE="${APP_NAMESPACE:-demo}" \
SMOKE_NAME="${DEMO_APP_NAME:-demo-api}" \
SMOKE_EXPECTED_TEXT="homelab-garden demo-api ok" \
SMOKE_LABEL="demo" \
smoke_service_main

"${kubectl_cmd[@]}" -n "$namespace" exec "$check_pod" -- curl -fsS "$url/healthz" | grep -q '"healthy": true'
"${kubectl_cmd[@]}" -n "$namespace" exec "$check_pod" -- curl -fsS "$url/readyz" | grep -q '"ready": true'
"${kubectl_cmd[@]}" -n "$namespace" exec "$check_pod" -- curl -fsS "$url/metrics" | grep -q 'demo_api_requests_total'

echo "Smoke check passed for $name"
