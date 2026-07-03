#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/hcloud-common.sh"

namespace="argocd"
fallback_repo="https://github.com/erauner12/homelab-garden.git"
current_branch="$(git -C "${root}" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
if [[ "${current_branch}" == "HEAD" ]]; then
  current_branch=""
fi
repo_url="${ARGOCD_REPO_URL:-$(git -C "${root}" remote get-url origin 2>/dev/null || echo "${fallback_repo}")}"
revision="${ARGOCD_TARGET_REVISION:-${current_branch:-main}}"
repo_creds_file="${ARGOCD_REPO_CREDS_FILE:-}"
repo_creds_sops_file="${ARGOCD_REPO_CREDS_SOPS_FILE:-}"
default_repo_creds_file="${root}/secrets/argocd-repo-creds.local.yaml"
default_repo_creds_sops_file="${root}/secrets/argocd-repo-creds.sops.yaml"
default_sops_age_key_file="${root}/secrets/age/key.txt"

yaml_string() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

github_owner_from_url() {
  local url="${1%.git}"
  if [[ "${url}" =~ ^https://github\.com/([^/]+)/[^/]+$ ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
  fi
}

validate_repo_creds_file() {
  local file="$1"
  if [[ ! -f "${file}" ]]; then
    echo "Configured ARGOCD_REPO_CREDS_FILE does not exist: ${file}" >&2
    exit 1
  fi
  if grep -Eq '^[[:space:]]*namespace:[[:space:]]*' "${file}" && ! grep -Eq '^[[:space:]]*namespace:[[:space:]]*["'"'"']?argocd["'"'"']?[[:space:]]*(#.*)?$' "${file}"; then
    echo "Refusing to apply ArgoCD repo credentials outside namespace argocd: ${file}" >&2
    exit 1
  fi
  if ! grep -Eq 'argocd\.argoproj\.io/secret-type:[[:space:]]*["'"'"']?(repository|repo-creds)["'"'"']?' "${file}"; then
    echo "Refusing repo credentials file without ArgoCD repository/repo-creds secret label: ${file}" >&2
    exit 1
  fi
}

apply_repo_credentials_file() {
  local file="$1"
  local label="$2"

  validate_repo_creds_file "${file}"
  "${kubectl_cmd[@]}" -n "${namespace}" apply -f "${file}"
  echo "Applied hcloud ArgoCD repository credentials to ${context}/${namespace} from ${label}: ${file}"
}

apply_sops_repo_credentials() {
  local source_file="$1"
  local decrypted_file="${render_dir}/argocd-repo-creds.decrypted.yaml"

  if ! command -v sops >/dev/null 2>&1; then
    echo "Encrypted ArgoCD repo credentials exist, but sops is not installed: ${source_file}" >&2
    return 1
  fi

  if [[ -z "${SOPS_AGE_KEY_FILE:-}" && -f "${default_sops_age_key_file}" ]]; then
    SOPS_AGE_KEY_FILE="${default_sops_age_key_file}" sops -d "${source_file}" >"${decrypted_file}"
  else
    sops -d "${source_file}" >"${decrypted_file}"
  fi

  apply_repo_credentials_file "${decrypted_file}" "encrypted file"
}

apply_hcloud_repo_credentials() {
  local token username repo_url_json username_json token_json source_label

  if [[ -z "${repo_creds_file}" && -f "${default_repo_creds_file}" ]]; then
    repo_creds_file="${default_repo_creds_file}"
  fi

  if [[ -n "${repo_creds_file}" ]]; then
    apply_repo_credentials_file "${repo_creds_file}" "file"
    return
  fi

  token="${ARGOCD_GITHUB_TOKEN:-${GH_TOKEN:-}}"
  if [[ -z "${token}" ]]; then
    echo "No runtime ArgoCD repository credentials found. Set ARGOCD_GITHUB_TOKEN/GH_TOKEN or ARGOCD_REPO_CREDS_FILE, or provide secrets/argocd-repo-creds.sops.yaml with a local SOPS Age key if ${repo_url} is private." >&2
    return 1
  fi
  if [[ "${token}" == *$'\n'* || "${token}" == *$'\r'* ]]; then
    echo "Refusing multiline ArgoCD GitHub token input." >&2
    exit 1
  fi

  username="${ARGOCD_GITHUB_USERNAME:-${GITHUB_USERNAME:-${GH_USERNAME:-}}}"
  if [[ -z "${username}" ]]; then
    username="$(github_owner_from_url "${repo_url}")"
  fi
  if [[ -z "${username}" ]]; then
    username="x-access-token"
  fi
  if [[ "${username}" == *$'\n'* || "${username}" == *$'\r'* ]]; then
    echo "Refusing multiline ArgoCD GitHub username input." >&2
    exit 1
  fi

  repo_url_json="$(printf '%s' "${repo_url}" | yaml_string)"
  username_json="$(printf '%s' "${username}" | yaml_string)"
  token_json="$(printf '%s' "${token}" | yaml_string)"
  source_label="${ARGOCD_GITHUB_TOKEN:+ARGOCD_GITHUB_TOKEN}"
  source_label="${source_label:-GH_TOKEN}"

  cat <<EOF | "${kubectl_cmd[@]}" -n "${namespace}" apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: homelab-garden-hcloud-lab-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  type: git
  url: ${repo_url_json}
  username: ${username_json}
  password: ${token_json}
EOF
  echo "Applied hcloud ArgoCD repository credentials to ${context}/${namespace} from ${source_label}."
}

apply_encrypted_repo_credentials_if_available() {
  if [[ -z "${repo_creds_sops_file}" && -f "${default_repo_creds_sops_file}" ]]; then
    repo_creds_sops_file="${default_repo_creds_sops_file}"
  fi

  if [[ -z "${repo_creds_sops_file}" ]]; then
    return 1
  fi

  if [[ ! -f "${repo_creds_sops_file}" ]]; then
    echo "Configured ARGOCD_REPO_CREDS_SOPS_FILE does not exist: ${repo_creds_sops_file}" >&2
    exit 1
  fi

  if [[ -z "${SOPS_AGE_KEY_FILE:-}" && -z "${SOPS_AGE_KEY:-}" && ! -f "${default_sops_age_key_file}" ]]; then
    echo "Encrypted ArgoCD repo credentials found, but no SOPS Age key is available. Set SOPS_AGE_KEY_FILE or copy secrets/age/key.txt locally." >&2
    return 1
  fi

  apply_sops_repo_credentials "${repo_creds_sops_file}"
}

if [[ "${repo_url}" != https://* ]]; then
  cat >&2 <<EOF
Refusing non-HTTPS ArgoCD repo URL for this hcloud exercise: ${repo_url}
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
cat >"${render_dir}/projects/hcloud-lab.yaml" <<EOF
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: hcloud-lab
  namespace: argocd
  labels:
    app.kubernetes.io/name: hcloud-lab
    app.kubernetes.io/part-of: homelab-garden
spec:
  description: Minimal project for the disposable hcloud ArgoCD reconciliation exercise.
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

python3 - "${root}/gitops/app-of-apps-hcloud-lab.yaml" "${render_dir}/app-of-apps-hcloud-lab.yaml" "${repo_url}" "${revision}" <<'PY'
import json
import sys
from pathlib import Path

src, dst, repo_url, revision = sys.argv[1:]
repo_value = json.dumps(repo_url)
revision_value = json.dumps(revision)
text = Path(src).read_text()
text = text.replace("repoURL: https://github.com/erauner12/homelab-garden.git", f"repoURL: {repo_url}", 1)
text = text.replace("targetRevision: main", f"targetRevision: {revision}", 1)
needle = "    path: gitops/applications-hcloud-lab\n"
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
    raise SystemExit("expected hcloud app-of-apps source path not found")
text = text.replace(needle, needle + patch, 1)
Path(dst).write_text(text)
PY

"${kubectl_cmd[@]}" -n "${namespace}" get deployment argocd-server >/dev/null
if ! apply_hcloud_repo_credentials; then
  apply_encrypted_repo_credentials_if_available || true
fi
"${kubectl_cmd[@]}" apply -f "${render_dir}/projects/"
"${kubectl_cmd[@]}" apply -f "${render_dir}/app-of-apps-hcloud-lab.yaml"
"${kubectl_cmd[@]}" -n "${namespace}" annotate application app-of-apps-hcloud-lab argocd.argoproj.io/refresh=hard --overwrite >/dev/null

cat <<EOF
Applied hcloud lab AppProject and rendered parent app-of-apps Application to ${context}.
Kubeconfig: ${resolved_kubeconfig}
ArgoCD repoURL: ${repo_url}
ArgoCD targetRevision: ${revision}
Child Applications use hcloud-specific names: platform-hcloud-lab and demo-api-hcloud-lab.
EOF
