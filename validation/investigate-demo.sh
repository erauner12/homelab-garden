#!/usr/bin/env bash
set -uo pipefail

context="${KUBECONTEXT:-${KUBE_CONTEXT:-kind-homelab-garden}}"
namespace="${APP_NAMESPACE:-demo}"
name="${DEMO_APP_NAME:-demo-api}"
argocd_namespace="${ARGOCD_NAMESPACE:-argocd}"
selector="app.kubernetes.io/name=${name}"
report_path="${INVESTIGATION_REPORT_PATH:-}"

run() {
  "$@" 2>&1 || true
}

section_cmd() {
  local title="$1"
  shift
  printf '### %s\n\n' "$title"
  printf '```text\n'
  run "$@"
  printf '\n```\n\n'
}

has_crd() {
  kubectl --context "$context" get crd "$1" >/dev/null 2>&1
}

render_report() {
  local current_context argocd_status rollouts_status health_output health_status timestamp
  timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  current_context="$(run kubectl config current-context)"

  argocd_status="not_installed"
  if has_crd applications.argoproj.io; then
    argocd_status="installed"
  fi

  rollouts_status="not_installed"
  if has_crd rollouts.argoproj.io; then
    rollouts_status="installed"
  fi

  health_output="$(KUBE_CONTEXT="$context" APP_NAMESPACE="$namespace" DEMO_APP_NAME="$name" ./validation/health.sh 2>&1)"
  health_status="$?"

  cat <<EOF
# demo-api Investigation Report

Generated: ${timestamp}

## Summary

- target: ${name}
- namespace: ${namespace}
- kube_context: ${current_context:-unknown}
- argocd: ${argocd_status}
- rollouts: ${rollouts_status}
- health_check_exit_code: ${health_status}
- mode: read_only

## Environment

### Kubernetes Context

\`\`\`text
$(run kubectl config get-contexts "$context")
\`\`\`

### Relevant Namespaces

\`\`\`text
$(run kubectl --context "$context" get namespaces "$namespace" "$argocd_namespace" platform)
\`\`\`

## GitOps Status

EOF

  if [[ "$argocd_status" == "not_installed" ]]; then
    cat <<'EOF'
argocd: not_installed

EOF
  else
    section_cmd "ArgoCD Applications" kubectl --context "$context" -n "$argocd_namespace" get applications app-of-apps platform-local demo-api-local -o wide
    section_cmd "app-of-apps" kubectl --context "$context" -n "$argocd_namespace" get application app-of-apps -o yaml
    section_cmd "platform-local" kubectl --context "$context" -n "$argocd_namespace" get application platform-local -o yaml
    section_cmd "demo-api-local" kubectl --context "$context" -n "$argocd_namespace" get application demo-api-local -o yaml
  fi

  cat <<EOF
## Rollout Status

EOF

  if [[ "$rollouts_status" == "not_installed" ]]; then
    cat <<'EOF'
rollouts: not_installed

EOF
  else
    section_cmd "Rollout" kubectl --context "$context" -n "$namespace" get rollout "$name" -o wide
    section_cmd "Rollout Details" kubectl --context "$context" -n "$namespace" get rollout "$name" -o yaml
    section_cmd "ReplicaSets" kubectl --context "$context" -n "$namespace" get replicasets -l "$selector" -o wide
    section_cmd "AnalysisRuns" kubectl --context "$context" -n "$namespace" get analysisruns -o wide
  fi

  cat <<EOF
## Workload Status

EOF
  section_cmd "Deployments" kubectl --context "$context" -n "$namespace" get deployments -l "$selector" -o wide
  section_cmd "Pods" kubectl --context "$context" -n "$namespace" get pods -l "$selector" -o wide
  section_cmd "Services" kubectl --context "$context" -n "$namespace" get services -l "$selector" -o wide

  cat <<EOF
## Health Signals

### validation/health.sh

\`\`\`text
${health_output}
\`\`\`

## Recent Events

EOF
  section_cmd "Namespace Events" kubectl --context "$context" -n "$namespace" get events --sort-by=.lastTimestamp

  cat <<EOF
## Recent Logs

EOF
  section_cmd "demo-api Logs" kubectl --context "$context" -n "$namespace" logs -l "$selector" --tail=80 --all-containers=true

  cat <<'EOF'
## Safe Next Actions

- Re-run this investigation after any approved change.
- Inspect the reported Kubernetes, ArgoCD, or Rollouts resources with read-only `kubectl get`, `kubectl describe`, or `kubectl logs` commands.
- Compare the live status above with the rendered desired state in `k8s/apps/workloads/demo-api/overlays/local` and `gitops/applications/demo-api-local.yaml`.

## Approval-Required Actions

The following actions are intentionally not performed by this report and require explicit operator approval:

- Change live Kubernetes resources.
- Trigger GitOps sync or reconciliation.
- Promote, abort, retry, or roll back a rollout.
- Delete pods, ReplicaSets, AnalysisRuns, Applications, or other resources.
- Apply remediation manifests or edit desired state.
EOF
}

if [[ -n "$report_path" ]]; then
  mkdir -p "$(dirname "$report_path")"
  render_report | tee "$report_path"
else
  render_report
fi
