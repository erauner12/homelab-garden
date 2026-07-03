#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/hcloud-common.sh"

manifest_url="${ARGOCD_INSTALL_MANIFEST_URL:-https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml}"
namespace="argocd"

"${kubectl_cmd[@]}" cluster-info >/dev/null
"${kubectl_cmd[@]}" create namespace "${namespace}" --dry-run=client -o yaml | "${kubectl_cmd[@]}" apply -f -
"${kubectl_cmd[@]}" apply --server-side=true --force-conflicts -n "${namespace}" -f "${manifest_url}"

"${kubectl_cmd[@]}" wait --for=condition=Established crd/applications.argoproj.io --timeout=120s
"${kubectl_cmd[@]}" wait --for=condition=Established crd/appprojects.argoproj.io --timeout=120s
"${kubectl_cmd[@]}" -n "${namespace}" wait --for=condition=Available deployment --all --timeout=300s
"${kubectl_cmd[@]}" -n "${namespace}" rollout status statefulset/argocd-application-controller --timeout=300s

cat <<EOF
Disposable hcloud ArgoCD is ready in namespace/${namespace} on context ${context}.
Kubeconfig: ${resolved_kubeconfig}
Install source: ${manifest_url}
EOF
