#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
context="${KUBE_CONTEXT:-kind-homelab-garden}"
namespace="argocd"
fallback_repo="https://github.com/erauner12/homelab-garden.git"
current_branch="$(git -C "${root}" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
if [[ "${current_branch}" == "HEAD" ]]; then
  current_branch=""
fi
repo_url="${ARGOCD_REPO_URL:-$(git -C "${root}" remote get-url origin 2>/dev/null || echo "${fallback_repo}")}"
revision="${ARGOCD_TARGET_REVISION:-${current_branch:-main}}"

if [[ "${context}" != kind-* ]]; then
  cat >&2 <<EOF
Refusing to apply local ArgoCD Applications into non-kind context: ${context}
Set KUBE_CONTEXT to the local kind context for this exercise.
EOF
  exit 1
fi

kubectl_cmd=(kubectl --context "${context}")

if [[ "${repo_url}" != https://* ]]; then
  cat >&2 <<EOF
Refusing non-HTTPS ArgoCD repo URL for this first local exercise: ${repo_url}
Set ARGOCD_REPO_URL to a reachable HTTPS Git URL.
EOF
  exit 1
fi

if [[ -n "${current_branch}" && "${current_branch}" != "${revision}" ]]; then
  echo "warning: local branch is ${current_branch}; ArgoCD will fetch targetRevision ${revision}." >&2
fi

if [[ -n "$(git -C "${root}" status --porcelain 2>/dev/null || true)" ]]; then
  cat >&2 <<EOF
warning: this working tree has uncommitted changes.
ArgoCD fetches ${repo_url} at revision ${revision},
so uncommitted local changes and unpushed commits are invisible to this exercise.
EOF
fi

render_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${render_dir}"
}
trap cleanup EXIT

mkdir -p "${render_dir}/projects"
cat >"${render_dir}/projects/local-lab.yaml" <<EOF
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: local-lab
  namespace: argocd
  labels:
    app.kubernetes.io/name: local-lab
    app.kubernetes.io/part-of: homelab-garden
spec:
  description: Minimal project for the disposable local ArgoCD reconciliation exercise.
  sourceRepos:
    - ${repo_url}
  destinations:
    - server: https://kubernetes.default.svc
      namespace: argocd
    - server: https://kubernetes.default.svc
      namespace: platform
    - server: https://kubernetes.default.svc
      namespace: demo
  clusterResourceWhitelist:
    - group: ""
      kind: Namespace
  namespaceResourceWhitelist:
    - group: "*"
      kind: "*"
EOF

python3 - "${root}/gitops/app-of-apps.yaml" "${render_dir}/app-of-apps.yaml" "${repo_url}" "${revision}" <<'PY'
import json
import sys
from pathlib import Path

src, dst, repo_url, revision = sys.argv[1:]
repo_value = json.dumps(repo_url)
revision_value = json.dumps(revision)
text = Path(src).read_text()
text = text.replace("repoURL: https://github.com/erauner12/homelab-garden.git", f"repoURL: {repo_url}", 1)
text = text.replace("targetRevision: main", f"targetRevision: {revision}", 1)
needle = "    path: gitops/applications\n"
patch = f"""    kustomize:
      patches:
        - target:
            group: argoproj.io
            version: v1alpha1
            kind: Application
          patch: |-
            - op: replace
              path: /spec/source/repoURL
              value: {repo_value}
            - op: replace
              path: /spec/source/targetRevision
              value: {revision_value}
"""
if needle not in text:
    raise SystemExit("expected app-of-apps source path not found")
text = text.replace(needle, needle + patch, 1)
Path(dst).write_text(text)
PY

"${kubectl_cmd[@]}" -n "${namespace}" get deployment argocd-server >/dev/null
"${kubectl_cmd[@]}" apply -f "${render_dir}/projects/"
"${kubectl_cmd[@]}" apply -f "${render_dir}/app-of-apps.yaml"

cat <<EOF
Applied local lab AppProject and rendered parent app-of-apps Application to ${context}.
ArgoCD repoURL: ${repo_url}
ArgoCD targetRevision: ${revision}
The checked-in Application YAML defaults to main; this run applied temporary copies
so the parent and child Applications reconcile ${repo_url} at ${revision}.
EOF
