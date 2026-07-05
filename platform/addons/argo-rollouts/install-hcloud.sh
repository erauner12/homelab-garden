#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../argocd/hcloud-common.sh"

namespace="${ARGO_ROLLOUTS_NAMESPACE:-argo-rollouts}"
version="${ARGO_ROLLOUTS_VERSION:-v1.7.2}"

"${kubectl_cmd[@]}" create namespace "${namespace}" --dry-run=client -o yaml | "${kubectl_cmd[@]}" apply -f -
"${kubectl_cmd[@]}" apply -n "${namespace}" -f "https://github.com/argoproj/argo-rollouts/releases/download/${version}/install.yaml"
"${kubectl_cmd[@]}" -n "${namespace}" rollout status deployment/argo-rollouts --timeout=180s

cat <<EOF
Argo Rollouts ${version} is installed on hcloud lab context ${context}.
Kubeconfig: ${resolved_kubeconfig}
Namespace: ${namespace}
EOF
