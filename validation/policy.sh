#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$ROOT/policy/kyverno/tests"

if ! command -v kyverno >/dev/null 2>&1; then
  cat >&2 <<'EOF'
ERROR: kyverno CLI is required for optional policy validation, but it was not found.

Install Kyverno CLI, then rerun:
  macOS: brew install kyverno
  Linux/other: https://kyverno.io/docs/kyverno-cli/install/

This workflow is optional. Skip `make policy-validate` if you do not need local
policy-as-code checks; `make check` does not require Kyverno.
EOF
  exit 127
fi

if [[ ! -d "$TEST_DIR" ]]; then
  echo "ERROR: Kyverno test directory not found: $TEST_DIR" >&2
  exit 1
fi

echo "Using: $(kyverno version 2>&1 | head -n 1)"
echo "Running Kyverno policy tests in $TEST_DIR"

kyverno test "$TEST_DIR" --detailed-results

echo "Policy validation passed"
