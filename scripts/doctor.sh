#!/usr/bin/env bash
set -euo pipefail

missing=()

for tool in go kind kubectl kustomize kubeconform garden; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf 'ok: %s\n' "$tool"
  else
    printf 'missing: %s\n' "$tool"
    missing+=("$tool")
  fi
done

if ((${#missing[@]} > 0)); then
  echo
  echo "Missing required tool(s): ${missing[*]}"
  echo "Install the missing prerequisites, then run 'make doctor' again."
  exit 1
fi

echo
echo "All required tools are available."
