#!/usr/bin/env bash
set -euo pipefail

for overlay in \
  platform/overlays/local \
  apps/demo-api/overlays/local
do
  echo "==> Schema validation: ${overlay}"
  kustomize build "${overlay}" | kubeconform -strict -summary
done
