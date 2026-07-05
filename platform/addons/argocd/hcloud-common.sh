#!/usr/bin/env bash

hcloud_argocd_init() {
  root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
  expected_context="${HCLOUD_LAB_CONTEXT:-admin@homelab-garden-hcloud-lab}"
  context="${KUBE_CONTEXT:-${expected_context}}"
  kubeconfig="${KUBECONFIG:-${root}/infra/hcloud-lab/generated/kubeconfig}"

  if [[ "${context}" != "${expected_context}" ]]; then
    cat >&2 <<EOF
Refusing to target non-hcloud-lab context: ${context}
Expected ephemeral hcloud context: ${expected_context}
EOF
    exit 1
  fi

  if [[ "${kubeconfig}" == *:* || "${kubeconfig}" == *$'\n'* || "${kubeconfig}" == *$'\r'* ]]; then
    cat >&2 <<EOF
Refusing composite or multiline KUBECONFIG for hcloud lab: ${kubeconfig}
Use only infra/hcloud-lab/generated/kubeconfig for this workflow.
EOF
    exit 1
  fi

  if [[ ! -f "${kubeconfig}" ]]; then
    cat >&2 <<EOF
Missing hcloud lab kubeconfig: ${kubeconfig}
Run the explicit hcloud Terraform/OpenTofu apply path first; this workflow never applies infrastructure.
EOF
    exit 1
  fi

  resolved_kubeconfig="$(python3 - "${kubeconfig}" <<'PY'
import sys
from pathlib import Path
print(Path(sys.argv[1]).expanduser().resolve())
PY
)"
  expected_kubeconfig="$(python3 - "${root}/infra/hcloud-lab/generated/kubeconfig" <<'PY'
import sys
from pathlib import Path
print(Path(sys.argv[1]).expanduser().resolve())
PY
)"

  if [[ "${resolved_kubeconfig}" != "${expected_kubeconfig}" ]]; then
    cat >&2 <<EOF
Refusing hcloud lab workflow with unexpected kubeconfig path:
  got:      ${resolved_kubeconfig}
  expected: ${expected_kubeconfig}
This prevents accidental use of the real homelab or local kind kubeconfig.
EOF
    exit 1
  fi

  kubectl_cmd=(kubectl --kubeconfig "${resolved_kubeconfig}" --context "${context}")

  if ! kubectl --kubeconfig "${resolved_kubeconfig}" config get-contexts "${context}" --no-headers >/dev/null 2>&1; then
    cat >&2 <<EOF
Kubeconfig ${resolved_kubeconfig} does not contain context ${context}.
This workflow targets only the ephemeral hcloud lab cluster.
EOF
    exit 1
  fi
}

hcloud_argocd_init
