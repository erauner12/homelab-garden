#!/usr/bin/env bash
set -euo pipefail

for overlay in \
  k8s/apps/platform/foundation/overlays/local \
  k8s/apps/workloads/demo-api/overlays/local \
  k8s/targets/local
do
  echo "==> Schema validation: ${overlay}"
  kustomize build "${overlay}" | kubeconform -strict -summary
done
