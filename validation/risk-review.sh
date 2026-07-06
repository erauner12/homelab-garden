#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${script_dir}/.." && pwd)"

args=()
if [[ -n "${RELEASE_INTENT_PATH:-}" ]]; then
  args+=(--intent "${RELEASE_INTENT_PATH}")
fi
if [[ -n "${RISK_REVIEW_ENVIRONMENT:-}" ]]; then
  args+=(--env "${RISK_REVIEW_ENVIRONMENT}")
fi
if [[ -n "${HEALTH_GATE_EVIDENCE_PATH:-}" ]]; then
  args+=(--health-evidence "${HEALTH_GATE_EVIDENCE_PATH}")
fi
if [[ -n "${POLICY_EVIDENCE_PATH:-}" ]]; then
  args+=(--policy-evidence "${POLICY_EVIDENCE_PATH}")
fi
if [[ -n "${ARGOCD_EVIDENCE_PATH:-}" ]]; then
  args+=(--argocd-evidence "${ARGOCD_EVIDENCE_PATH}")
fi
if [[ -n "${ROLLOUTS_EVIDENCE_PATH:-}" ]]; then
  args+=(--rollouts-evidence "${ROLLOUTS_EVIDENCE_PATH}")
fi
if [[ -n "${HCLOUD_EVIDENCE_PATH:-}" ]]; then
  args+=(--hcloud-evidence "${HCLOUD_EVIDENCE_PATH}")
fi

cd "${root}"
exec python3 "${script_dir}/risk_review.py" "${args[@]}"
