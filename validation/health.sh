#!/usr/bin/env bash
set -euo pipefail

namespace="${APP_NAMESPACE:-demo}"
name="${DEMO_APP_NAME:-demo-api}"
context="${KUBECONTEXT:-${KUBE_CONTEXT:-kind-homelab-garden}}"
selector="app.kubernetes.io/name=${name}"

ready_pods="$(kubectl --context "$context" -n "$namespace" get pods -l "$selector" -o jsonpath='{.items[?(@.status.containerStatuses[0].ready==true)].metadata.name}' 2>/dev/null | wc -w | tr -d ' ')"
restart_count="$(kubectl --context "$context" -n "$namespace" get pods -l "$selector" -o jsonpath='{range .items[*]}{range .status.containerStatuses[*]}{.restartCount}{"\n"}{end}{end}' 2>/dev/null | awk '{s+=$1} END {print s+0}')"
rollout_phase="$(kubectl --context "$context" -n "$namespace" get rollout "$name" -o jsonpath='{.status.phase}' 2>/dev/null || true)"
rollout_message="$(kubectl --context "$context" -n "$namespace" get rollout "$name" -o jsonpath='{.status.message}' 2>/dev/null || true)"

status="pass"
if [[ "${ready_pods}" -lt 1 || "${rollout_phase}" != "Healthy" ]]; then
  status="fail"
fi

python3 - "$status" "$namespace" "$name" "$ready_pods" "${rollout_phase:-Unknown}" "$restart_count" "$rollout_message" <<'PY'
import json
import sys

status, namespace, name, ready_pods, rollout_phase, restart_count, rollout_message = sys.argv[1:]
print(json.dumps({
    "status": status,
    "namespace": namespace,
    "rollout": name,
    "signals": {
        "automation_grade": {
            "ready_pods": int(ready_pods),
            "rollout_phase": rollout_phase,
        },
        "diagnostic_only": {
            "restart_count": int(restart_count),
            "rollout_message": rollout_message,
        },
    },
}, indent=2))
PY

[[ "$status" == "pass" ]]
