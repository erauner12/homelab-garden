#!/usr/bin/env bash
set -euo pipefail

SMOKE_NAMESPACE="${APP_NAMESPACE:-demo}" \
SMOKE_NAME="${DEMO_APP_NAME:-demo-api}" \
SMOKE_EXPECTED_TEXT="homelab-garden demo-api ok" \
SMOKE_HEALTH_PATH="/healthz" \
SMOKE_READY_PATH="/readyz" \
SMOKE_METRICS_PATH="/metrics" \
SMOKE_LABEL="demo" \
"$(dirname "$0")/smoke-service.sh"
