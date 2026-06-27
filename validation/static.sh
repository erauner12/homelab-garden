#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for path in \
  "$ROOT/platform/overlays/local" \
  "$ROOT/apps/demo-api/overlays/local"
do
  echo "Rendering $path"
  kustomize build "$path" >/dev/null
done

echo "Static validation passed"
