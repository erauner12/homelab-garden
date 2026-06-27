#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
Planned GitOps validation path:

1. Deploy ArgoCD into the local cluster.
2. Seed a Git source containing the same Kustomize entrypoints.
3. Apply an app-of-apps Application.
4. Wait for ArgoCD sync and health.
5. Run the same smoke checks against reconciled workloads.

This is intentionally separate from the default local validation loop.
EOF
