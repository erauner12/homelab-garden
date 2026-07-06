#!/usr/bin/env python3
import json
import os
import subprocess
import sys
from urllib.error import HTTPError, URLError
from urllib.request import urlopen


def kubectl(context, namespace, args):
    cmd = ["kubectl", "--context", context, "-n", namespace, *args]
    try:
        return subprocess.run(cmd, check=False, capture_output=True, text=True, timeout=10).stdout.strip()
    except (OSError, subprocess.TimeoutExpired):
        return ""


def fetch_json(base_url, path):
    try:
        with urlopen(base_url.rstrip("/") + path, timeout=2) as response:
            body = response.read(4096).decode("utf-8", "replace")
            return response.status, json.loads(body)
    except HTTPError as err:
        body = err.read(4096).decode("utf-8", "replace")
        try:
            return err.code, json.loads(body)
        except json.JSONDecodeError:
            return err.code, {"summary": body[:200]}
    except (OSError, URLError, json.JSONDecodeError) as err:
        return None, {"summary": str(err)[:200]}


def collect():
    namespace = os.environ.get("APP_NAMESPACE", "demo")
    name = os.environ.get("DEMO_APP_NAME", "demo-api")
    context = os.environ.get("KUBECONTEXT", os.environ.get("KUBE_CONTEXT", "kind-homelab-garden"))
    expected_context = os.environ.get("HCLOUD_LAB_CONTEXT", "admin@homelab-garden-hcloud-lab")
    environment = os.environ.get("HEALTH_ENVIRONMENT") or ("hcloud-lab" if context == expected_context else "local")
    selector = f"app.kubernetes.io/name={name}"

    ready_names = kubectl(context, namespace, ["get", "pods", "-l", selector, "-o", "jsonpath={.items[?(@.status.containerStatuses[0].ready==true)].metadata.name}"])
    rollout_phase = kubectl(context, namespace, ["get", "rollout", name, "-o", "jsonpath={.status.phase}"]) or "Unknown"

    return {
        "namespace": namespace,
        "name": name,
        "context": context,
        "environment": environment,
        "expected_context": expected_context,
        "ready_pods": len(ready_names.split()),
        "rollout_phase": rollout_phase,
        "demo_api_base_url": os.environ.get("DEMO_API_BASE_URL", ""),
    }


def demo_api_signal(status, observed):
    if status is None:
        return "demo_api_unreachable", "unknown"
    if status >= 500 or observed.get("status") in ("failing", "not_ready"):
        return "demo_api_failing", "blocking"
    if observed.get("status") == "degraded":
        return "demo_api_degraded", "degrading"
    return None, "supports_pass"


def collect_demo_api(base_url, reasons, records):
    for path, signal in (("/healthz", "http_healthz"), ("/readyz", "http_readyz")):
        status, observed = fetch_json(base_url, path)
        reason, contribution = demo_api_signal(status, observed)
        if reason:
            reasons.add(reason)
        records.append({
            "source": "demo_api",
            "signal": signal,
            "observed": observed if status is None else {"http_status": status, **observed},
            "classification": "automation-grade",
            "contribution": contribution,
        })


def final_decision(reasons):
    if reasons & {"target_guard_unverified", "no_ready_pods", "rollout_not_healthy", "demo_api_failing"}:
        return "fail"
    if reasons & {"ready_pods_unknown", "rollout_unknown", "demo_api_unreachable"}:
        return "unknown"
    if "demo_api_degraded" in reasons:
        return "degraded"
    return "pass"


def decide(data):
    reasons = set()
    records = []
    guard = {
        "environment": data["environment"],
        "verified": True,
        "reason": "local_guard_not_required",
        "expected_context": data["expected_context"] if data["environment"] == "hcloud-lab" else None,
        "observed_context": data["context"],
    }
    if data["environment"] == "hcloud-lab":
        if data["context"] == data["expected_context"]:
            guard["reason"] = "hcloud_context_verified"
        else:
            guard.update(verified=False, reason="hcloud_context_mismatch")
            reasons.add("target_guard_unverified")

    ready = data["ready_pods"]
    if ready is None:
        reasons.add("ready_pods_unknown")
        ready_contribution = "unknown"
    elif ready < 1:
        reasons.add("no_ready_pods")
        ready_contribution = "blocking"
    else:
        ready_contribution = "supports_pass"
    records.append({"source": "kubernetes", "signal": "ready_pods", "observed": ready, "classification": "automation-grade", "contribution": ready_contribution})

    phase = data["rollout_phase"]
    if phase == "Unknown":
        reasons.add("rollout_unknown")
        rollout_contribution = "unknown"
    elif phase != "Healthy":
        reasons.add("rollout_not_healthy")
        rollout_contribution = "blocking"
    else:
        rollout_contribution = "supports_pass"
    records.append({"source": "argo_rollouts", "signal": "rollout_phase", "observed": phase, "classification": "automation-grade", "contribution": rollout_contribution})

    if data["demo_api_base_url"]:
        collect_demo_api(data["demo_api_base_url"], reasons, records)

    return {
        "decision": final_decision(reasons),
        "reasons": sorted(reasons),
        "evidence": records,
        "environment": {
            "environment": data["environment"],
            "context": data["context"],
            "namespace": data["namespace"],
            "app": data["name"],
        },
        "target_guard": guard,
    }


def self_test():
    base = {
        "namespace": "demo",
        "name": "demo-api",
        "context": "kind-homelab-garden",
        "environment": "local",
        "expected_context": "admin@homelab-garden-hcloud-lab",
        "ready_pods": 1,
        "rollout_phase": "Healthy",
        "demo_api_base_url": "",
    }
    assert decide(dict(base))["decision"] == "pass"
    failed = decide({**base, "ready_pods": 0})
    assert failed["decision"] == "fail" and "no_ready_pods" in failed["reasons"]
    guarded = decide({**base, "environment": "hcloud-lab"})
    assert guarded["decision"] == "fail" and "target_guard_unverified" in guarded["reasons"]
    unknown = decide({**base, "ready_pods": None})
    assert unknown["decision"] == "unknown" and "ready_pods_unknown" in unknown["reasons"]

    assert final_decision({"demo_api_degraded"}) == "degraded"
    assert demo_api_signal(200, {"status": "degraded"})[1] == "degrading"
    print("health output check passed")


def main():
    if sys.argv[1:] == ["--self-test"]:
        self_test()
        return 0
    out = decide(collect())
    print(json.dumps(out, indent=2, sort_keys=True))
    return 0 if out["decision"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
