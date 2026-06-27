#!/usr/bin/env bash
set -euo pipefail

cluster="${KIND_CLUSTER_NAME:-homelab-garden}"
context="kind-${cluster}"

if kind get clusters | grep -Fxq "$cluster"; then
  echo "Kind cluster already exists: $cluster"
else
  kind create cluster --name "$cluster"
fi

kubectl config use-context "$context"
kubectl cluster-info --context "$context"
