#!/usr/bin/env python3
import json
import os
import subprocess
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parents[1]


def getenv(name, default=""):
    return os.environ.get(name, default)


def kubectl(context, namespace, args):
    cmd = ["kubectl", "--context", context, "-n", namespace, *args]
    try:
        return subprocess.run(cmd, check=False, capture_output=True, text=True, timeout=10).stdout.strip()
    except (OSError, subprocess.TimeoutExpired):
        return ""


def env_or_kubectl(env_name, context, namespace, args, default=""):
    value = getenv(env_name)
    if value != "":
        return value
    return kubectl(context, namespace, args) or default


def as_int(value, default=0):
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def add_reason(reasons, code):
    if code not in reasons:
        reasons.append(code)


def evidence(source, signal, observed, classification, contribution):
    return {
        "source": source,
        "signal": signal,
        "observed": observed,
        "classification": classification,
        "contribution": contribution,
    }


def target_guard(environment, context, expected_context, kubeconfig):
    guard = {
        "environment": environment,
        "verified": True,
        "reason": "local_guard_not_required",
        "expected_context": expected_context if environment == "hcloud-lab" else None,
        "observed_context": context,
    }
    if environment != "hcloud-lab":
        return guard

    expected_kubeconfig = str((ROOT / "infra/hcloud-lab/generated/kubeconfig").resolve())
    guard.update({"expected_kubeconfig": expected_kubeconfig})
    if context != expected_context:
        guard.update(verified=False, reason="hcloud_context_mismatch")
    elif not kubeconfig:
        guard.update(verified=False, reason="hcloud_kubeconfig_missing")
    elif ":" in kubeconfig or "\n" in kubeconfig or "\r" in kubeconfig:
        guard.update(verified=False, reason="hcloud_kubeconfig_ambiguous")
    else:
        observed = str(Path(kubeconfig).expanduser().resolve())
        guard["observed_kubeconfig"] = observed
        if observed != expected_kubeconfig:
            guard.update(verified=False, reason="hcloud_kubeconfig_unexpected")
        else:
            guard["reason"] = "hcloud_target_verified"
    return guard


def fetch(base_url, path):
    try:
        with urlopen(base_url.rstrip("/") + path, timeout=2) as response:
            return response.status, response.read(4096).decode("utf-8", "replace")
    except HTTPError as err:
        return err.code, err.read(4096).decode("utf-8", "replace")
    except (OSError, URLError) as err:
        return None, str(err)


def parse_json(body):
    try:
        return json.loads(body)
    except json.JSONDecodeError:
        return None


def collect():
    namespace = getenv("APP_NAMESPACE", "demo")
    name = getenv("DEMO_APP_NAME", "demo-api")
    context = getenv("KUBECONTEXT", getenv("KUBE_CONTEXT", "kind-homelab-garden"))
    expected_context = getenv("HCLOUD_LAB_CONTEXT", "admin@homelab-garden-hcloud-lab")
    environment = getenv("HEALTH_ENVIRONMENT") or ("hcloud-lab" if context == expected_context else "local")
    selector = f"app.kubernetes.io/name={name}"

    ready_names = env_or_kubectl(
        "HEALTH_READY_POD_NAMES",
        context,
        namespace,
        ["get", "pods", "-l", selector, "-o", "jsonpath={.items[?(@.status.containerStatuses[0].ready==true)].metadata.name}"],
    )
    ready_pods = getenv("HEALTH_READY_PODS") or str(len(ready_names.split()))
    restart_count = env_or_kubectl(
        "HEALTH_RESTART_COUNT",
        context,
        namespace,
        ["get", "pods", "-l", selector, "-o", 'jsonpath={range .items[*]}{range .status.containerStatuses[*]}{.restartCount}{"\\n"}{end}{end}'],
        "0",
    )
    restart_count = sum(as_int(line) for line in restart_count.splitlines())
    rollout_phase = env_or_kubectl("HEALTH_ROLLOUT_PHASE", context, namespace, ["get", "rollout", name, "-o", "jsonpath={.status.phase}"], "Unknown")
    rollout_message = env_or_kubectl("HEALTH_ROLLOUT_MESSAGE", context, namespace, ["get", "rollout", name, "-o", "jsonpath={.status.message}"])

    return {
        "namespace": namespace,
        "name": name,
        "context": context,
        "environment": environment,
        "expected_context": expected_context,
        "ready_pods": as_int(ready_pods, None),
        "restart_count": restart_count,
        "rollout_phase": rollout_phase or "Unknown",
        "rollout_message": rollout_message,
        "kubeconfig": getenv("KUBECONFIG"),
        "demo_api_base_url": getenv("DEMO_API_BASE_URL"),
    }


def decide(data):
    reasons = []
    records = []
    guard = target_guard(data["environment"], data["context"], data["expected_context"], data["kubeconfig"])

    if not guard["verified"]:
        add_reason(reasons, "target_guard_unverified")
    records.append(evidence("target_guard", "target_identity", guard, "automation-grade", "blocking" if not guard["verified"] else "supports_pass"))

    if data["ready_pods"] is None:
        add_reason(reasons, "ready_pods_unknown")
        ready_contribution = "unknown"
    elif data["ready_pods"] < 1:
        add_reason(reasons, "no_ready_pods")
        ready_contribution = "blocking"
    else:
        ready_contribution = "supports_pass"
    records.append(evidence("kubernetes", "ready_pods", data["ready_pods"], "automation-grade", ready_contribution))

    if data["rollout_phase"] == "Unknown":
        add_reason(reasons, "rollout_unknown")
        rollout_contribution = "unknown"
    elif data["rollout_phase"] != "Healthy":
        add_reason(reasons, "rollout_not_healthy")
        rollout_contribution = "blocking"
    else:
        rollout_contribution = "supports_pass"
    records.append(evidence("argo_rollouts", "rollout_phase", data["rollout_phase"], "automation-grade", rollout_contribution))
    records.append(evidence("kubernetes", "restart_count", data["restart_count"], "diagnostic-only", "diagnostic"))
    if data["rollout_message"]:
        records.append(evidence("argo_rollouts", "rollout_message", data["rollout_message"], "diagnostic-only", "diagnostic"))

    if data["demo_api_base_url"]:
        collect_demo_api(data["demo_api_base_url"], reasons, records)

    if any(code in reasons for code in ("target_guard_unverified", "no_ready_pods", "rollout_not_healthy", "demo_api_failing")):
        decision = "fail"
    elif any(code in reasons for code in ("ready_pods_unknown", "rollout_unknown", "demo_api_unreachable")):
        decision = "unknown"
    elif "demo_api_degraded" in reasons:
        decision = "degraded"
    else:
        decision = "pass"

    return {
        "decision": decision,
        "reasons": reasons,
        "evidence": records,
        "environment": {
            "environment": data["environment"],
            "context": data["context"],
            "namespace": data["namespace"],
            "app": data["name"],
        },
        "target_guard": guard,
    }


def collect_demo_api(base_url, reasons, records):
    for path, signal in (("/healthz", "http_healthz"), ("/readyz", "http_readyz")):
        status, body = fetch(base_url, path)
        parsed = parse_json(body or "") if status is not None else None
        observed = parsed if parsed is not None else {"http_status": status, "summary": body[:200]}
        if status is None:
            add_reason(reasons, "demo_api_unreachable")
            contribution = "blocking"
        elif status >= 500 or (parsed and parsed.get("status") in ("failing", "not_ready")):
            add_reason(reasons, "demo_api_failing")
            contribution = "blocking"
        elif parsed and parsed.get("status") == "degraded":
            add_reason(reasons, "demo_api_degraded")
            contribution = "degrading"
        else:
            contribution = "supports_pass"
        records.append(evidence("demo_api", signal, observed, "automation-grade", contribution))

    status, body = fetch(base_url, "/metrics")
    mode = None
    for line in (body or "").splitlines():
        if line.startswith('demo_api_simulation_mode{mode="') and line.endswith(" 1"):
            mode = line.split('"', 2)[1]
            break
    records.append(evidence("demo_api", "metrics", {"http_status": status, "simulation_mode": mode, "summary": (body or "")[:200]}, "diagnostic-only", "diagnostic"))

    status, body = fetch(base_url, "/version")
    records.append(evidence("demo_api", "version", parse_json(body or "") or {"http_status": status, "summary": (body or "")[:200]}, "diagnostic-only", "diagnostic"))


def self_test():
    base = {
        "namespace": "demo",
        "name": "demo-api",
        "context": "kind-homelab-garden",
        "environment": "local",
        "expected_context": "admin@homelab-garden-hcloud-lab",
        "ready_pods": 1,
        "restart_count": 0,
        "rollout_phase": "Healthy",
        "rollout_message": "",
        "kubeconfig": "",
        "demo_api_base_url": "",
    }
    assert decide(dict(base))["decision"] == "pass"
    failed = decide({**base, "ready_pods": 0})
    assert failed["decision"] == "fail" and "no_ready_pods" in failed["reasons"]
    guarded = decide({**base, "environment": "hcloud-lab", "kubeconfig": "/tmp/nope"})
    assert guarded["decision"] == "fail" and "target_guard_unverified" in guarded["reasons"]
    unknown = decide({**base, "ready_pods": None})
    assert unknown["decision"] == "unknown" and "ready_pods_unknown" in unknown["reasons"]
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
