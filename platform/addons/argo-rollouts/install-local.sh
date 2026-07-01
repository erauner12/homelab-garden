#!/usr/bin/env bash
set -euo pipefail

context="${KUBE_CONTEXT:-${KUBECONTEXT:-kind-homelab-garden}}"
namespace="${ARGO_ROLLOUTS_NAMESPACE:-argo-rollouts}"
version="${ARGO_ROLLOUTS_VERSION:-v1.7.2}"

kubectl --context "$context" create namespace "$namespace" --dry-run=client -o yaml | kubectl --context "$context" apply -f -
kubectl --context "$context" apply -n "$namespace" -f "https://github.com/argoproj/argo-rollouts/releases/download/${version}/install.yaml"
kubectl --context "$context" -n "$namespace" rollout status deployment/argo-rollouts --timeout=180s
