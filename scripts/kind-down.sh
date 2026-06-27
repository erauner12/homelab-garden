#!/usr/bin/env bash
set -euo pipefail

cluster="${KIND_CLUSTER_NAME:-homelab-garden}"

if kind get clusters | grep -Fxq "$cluster"; then
  kind delete cluster --name "$cluster"
else
  echo "Kind cluster does not exist: $cluster"
fi
