#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for path in \
  "$ROOT/k8s/apps/platform/foundation/overlays/local" \
  "$ROOT/k8s/apps/workloads/demo-api/overlays/local" \
  "$ROOT/k8s/targets/local"
do
  echo "Rendering $path"
  kustomize build "$path" >/dev/null
done

echo "Static validation passed"
