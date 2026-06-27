#!/usr/bin/env bash
set -euo pipefail

cluster="${KIND_CLUSTER_NAME:-homelab-garden}"
context="kind-${cluster}"

if ! kind get clusters | grep -Fxq "$cluster"; then
  echo "Kind cluster does not exist: $cluster"
  exit 0
fi

kubectl cluster-info --context "$context"
kubectl get nodes --context "$context"
kubectl get namespaces --context "$context"
