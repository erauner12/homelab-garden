#!/usr/bin/env python3
"""Render a read-only pre-rollout risk review report.

The report intentionally consumes files and environment metadata only. It does
not call kubectl, garden, argocd, rollouts, terraform, hcloud, gh, or any other
mutation-capable workflow command.
"""
import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from tempfile import TemporaryDirectory

from release_intent import get_nested, validate_intent

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_EXPECTED_HCLOUD_CONTEXT = "admin@homelab-garden-hcloud-lab"
ALLOWED_ENVIRONMENTS = {"local", "hcloud-lab"}
FORBIDDEN_ACTIONS = [
    "apply",
    "delete",
    "patch",
    "scale",
    "sync",
    "promote",
    "abort",
    "rollback",
    "terraform apply",
    "terraform destroy",
    "pull request generation",
    "remediation",
]


def rel(path):
    if path is None:
        return None
    path = Path(path)
    try:
        return str(path.resolve().relative_to(ROOT))
    except ValueError:
        return str(path)


def modified_at(path):
    try:
        stamp = Path(path).stat().st_mtime
    except OSError:
        return None
    return datetime.fromtimestamp(stamp, timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def issue(code, message, source=None):
    out = {"code": code, "message": message}
    if source:
        out["source"] = source
    return out


def evidence_record(name, path=None, availability="missing", effect="unknown", detail=None):
    out = {
        "name": name,
        "path": rel(path),
        "availability": availability,
        "modified_at_utc": modified_at(path) if path else None,
        "effect": effect,
    }
    if detail is not None:
        out["detail"] = detail
    return out


def read_json_file(path):
    path = Path(path)
    try:
        text = path.read_text()
    except OSError as err:
        return None, f"unreadable: {err}"
    try:
        return json.loads(text), None
    except json.JSONDecodeError as err:
        return None, f"invalid JSON: {err}"


def read_evidence(path):
    path = Path(path)
    try:
        text = path.read_text()
    except OSError as err:
        return None, f"unreadable: {err}"
    try:
        return json.loads(text), None
    except json.JSONDecodeError:
        return {"text_summary": text[:500]}, None


def status_text(data):
    if not isinstance(data, dict):
        return ""
    values = []
    for key in ("decision", "status", "result", "phase", "health", "sync", "syncStatus", "healthStatus"):
        value = data.get(key)
        if isinstance(value, str):
            values.append(value.lower())
        elif isinstance(value, dict):
            values.extend(str(v).lower() for v in value.values() if isinstance(v, str))
    return " ".join(values)


def hcloud_target_guard(env, environ):
    expected_context = environ.get("HCLOUD_LAB_CONTEXT", DEFAULT_EXPECTED_HCLOUD_CONTEXT)
    observed_context = environ.get("KUBE_CONTEXT") or environ.get("KUBECONTEXT")
    kubeconfig = environ.get("KUBECONFIG")
    guard = {
        "environment": env,
        "verified": True,
        "reason": "local_guard_not_required",
        "expected_context": expected_context if env == "hcloud-lab" else None,
        "observed_context": observed_context,
        "kubeconfig": kubeconfig,
    }
    if env != "hcloud-lab":
        return guard

    guard["verified"] = False
    if observed_context != expected_context:
        guard["reason"] = "hcloud_context_mismatch"
        return guard

    if kubeconfig:
        if ":" in kubeconfig or "\n" in kubeconfig or "\r" in kubeconfig:
            guard["reason"] = "hcloud_kubeconfig_composite"
            return guard
        expected_kubeconfig = (ROOT / "infra/hcloud-lab/generated/kubeconfig").resolve()
        try:
            observed_kubeconfig = Path(kubeconfig).expanduser().resolve()
        except OSError:
            guard["reason"] = "hcloud_kubeconfig_unresolved"
            return guard
        if observed_kubeconfig != expected_kubeconfig:
            guard["reason"] = "hcloud_kubeconfig_unexpected"
            return guard

    guard["verified"] = True
    guard["reason"] = "hcloud_context_verified"
    return guard


def default_intent_path(env):
    env = env or "local"
    return ROOT / "release-intents" / f"demo-api-{env}.json"


def load_intent(path, requested_env, blockers, risks, evidence):
    path = Path(path)
    if not path.exists():
        blockers.append(issue("release_intent_missing", f"release intent not found: {rel(path)}", "release_intent"))
        evidence.append(evidence_record("release_intent", path, "missing", "blocks_ready"))
        return None

    data, error = read_json_file(path)
    if error:
        blockers.append(issue("release_intent_unreadable", error, "release_intent"))
        evidence.append(evidence_record("release_intent", path, "unavailable", "blocks_ready", error))
        return None

    evidence.append(evidence_record("release_intent", path, "available", "required_input"))
    for error in validate_intent(path):
        blockers.append(issue("release_intent_invalid", error, "release_intent"))

    env = data.get("environment") if isinstance(data, dict) else None
    if requested_env and env and requested_env != env:
        blockers.append(issue("release_intent_environment_mismatch", f"requested env {requested_env} does not match release intent env {env}", "release_intent"))
    if env == "hcloud-lab":
        image_risk = get_nested(data, "image", "risk")
        if image_risk:
            risks.append(issue("tag_only_image_identity", image_risk, "release_intent"))
    return data


def apply_health(path, blockers, risks, unknowns, evidence):
    if not path:
        unknowns.append(issue("health_gate_v2_missing", "health-gate v2 JSON was not provided", "health_gate_v2"))
        evidence.append(evidence_record("health_gate_v2", None, "missing", "unknown"))
        return
    data, error = read_evidence(path)
    if error:
        unknowns.append(issue("health_gate_v2_unavailable", error, "health_gate_v2"))
        evidence.append(evidence_record("health_gate_v2", path, "unavailable", "unknown", error))
        return
    decision = data.get("decision") if isinstance(data, dict) else None
    reasons = data.get("reasons", []) if isinstance(data, dict) else []
    evidence.append(evidence_record("health_gate_v2", path, "available", f"decision:{decision or 'unclassified'}", {"decision": decision, "reasons": reasons}))
    if decision == "pass":
        return
    if decision == "fail":
        blockers.append(issue("health_gate_v2_failed", f"health gate failed: {reasons}", "health_gate_v2"))
    elif decision == "degraded":
        risks.append(issue("health_gate_v2_degraded", f"health gate degraded: {reasons}", "health_gate_v2"))
    else:
        unknowns.append(issue("health_gate_v2_unknown", f"health gate decision is {decision or 'missing'}", "health_gate_v2"))


def apply_policy(path, blockers, risks, unknowns, evidence):
    if not path:
        unknowns.append(issue("policy_validation_missing", "policy validation evidence was not provided", "policy_validation"))
        evidence.append(evidence_record("policy_validation", None, "missing", "unknown"))
        return
    data, error = read_evidence(path)
    if error:
        unknowns.append(issue("policy_validation_unavailable", error, "policy_validation"))
        evidence.append(evidence_record("policy_validation", path, "unavailable", "unknown", error))
        return
    text = status_text(data)
    evidence.append(evidence_record("policy_validation", path, "available", f"status:{text or 'unclassified'}"))
    if any(word in text for word in ("fail", "failed", "error", "deny", "denied")):
        blockers.append(issue("policy_validation_failed", f"policy validation status is {text}", "policy_validation"))
    elif any(word in text for word in ("pass", "passed", "ok", "success")):
        return
    else:
        risks.append(issue("policy_validation_unclassified", "policy evidence is available but not a recognized pass/fail result", "policy_validation"))


def apply_state(name, path, missing_code, blockers, risks, unknowns, evidence):
    if not path:
        unknowns.append(issue(missing_code, f"{name} evidence was not provided", name))
        evidence.append(evidence_record(name, None, "missing", "unknown"))
        return
    data, error = read_evidence(path)
    if error:
        unknowns.append(issue(f"{name}_unavailable", error, name))
        evidence.append(evidence_record(name, path, "unavailable", "unknown", error))
        return
    text = status_text(data)
    evidence.append(evidence_record(name, path, "available", f"status:{text or 'unclassified'}"))
    if any(word in text for word in ("fail", "failed", "error")):
        blockers.append(issue(f"{name}_failed", f"{name} status is {text}", name))
    elif any(word in text for word in ("degraded", "outofsync", "unhealthy", "progressing", "missing")):
        risks.append(issue(f"{name}_not_ready", f"{name} status is {text}", name))


def final_decision(blockers, risks, unknowns):
    if blockers:
        return "block"
    if risks:
        return "review"
    if unknowns:
        return "unknown"
    return "pass"


def build_report(args, environ=None):
    environ = dict(os.environ if environ is None else environ)
    blockers = []
    risks = []
    unknowns = []
    evidence = []

    intent_path = Path(args.intent) if args.intent else default_intent_path(args.env)
    intent = load_intent(intent_path, args.env, blockers, risks, evidence)
    env = args.env or (intent.get("environment") if isinstance(intent, dict) else None) or "unknown"
    if env not in ALLOWED_ENVIRONMENTS:
        blockers.append(issue("unsupported_environment", f"risk review supports only local or hcloud-lab, got {env}", "environment"))

    guard = hcloud_target_guard(env, environ)
    if env == "hcloud-lab" and args.hcloud_evidence:
        if not guard["verified"]:
            blockers.append(issue("hcloud_target_guard_unverified", "hcloud evidence was requested before the disposable hcloud-lab target guard passed", "target_guard"))
            evidence.append(evidence_record("hcloud_lifecycle", args.hcloud_evidence, "blocked_by_target_guard", "blocks_ready", guard["reason"]))
        else:
            apply_state("hcloud_lifecycle", args.hcloud_evidence, "hcloud_lifecycle_missing", blockers, risks, unknowns, evidence)
    elif env == "hcloud-lab":
        unknowns.append(issue("hcloud_lifecycle_missing", "hcloud lifecycle evidence was not provided", "hcloud_lifecycle"))
        evidence.append(evidence_record("hcloud_lifecycle", None, "missing", "unknown"))

    apply_health(args.health_evidence, blockers, risks, unknowns, evidence)
    apply_policy(args.policy_evidence, blockers, risks, unknowns, evidence)
    apply_state("argocd_state", args.argocd_evidence, "argocd_state_missing", blockers, risks, unknowns, evidence)
    apply_state("rollouts_state", args.rollouts_evidence, "rollouts_state_missing", blockers, risks, unknowns, evidence)

    intent_summary = {
        "path": rel(intent_path),
        "available": isinstance(intent, dict),
        "name": get_nested(intent, "metadata", "name") if isinstance(intent, dict) else None,
        "app": get_nested(intent, "app", "id") if isinstance(intent, dict) else None,
        "environment": intent.get("environment") if isinstance(intent, dict) else env,
        "gitRevision": get_nested(intent, "git", "revision") if isinstance(intent, dict) else None,
        "manifestPath": get_nested(intent, "manifest", "path") if isinstance(intent, dict) else None,
        "image": {
            "reference": get_nested(intent, "image", "reference") if isinstance(intent, dict) else None,
            "identityMode": get_nested(intent, "image", "identityMode") if isinstance(intent, dict) else None,
            "risk": get_nested(intent, "image", "risk") if isinstance(intent, dict) else None,
        },
        "authority": intent.get("authority") if isinstance(intent, dict) else None,
    }

    return {
        "schemaVersion": "homelab-garden.rollout-risk-review/v1alpha1",
        "kind": "RolloutRiskReview",
        "mode": "pre-rollout-readiness-assessment",
        "decision": final_decision(blockers, risks, unknowns),
        "decisionContract": {
            "pass": "release intent and supplied evidence support starting review with no blockers, risks, or unknowns",
            "review": "review required because at least one risk is present",
            "block": "do not start rollout because a required input or guard failed",
            "unknown": "do not claim ready because evidence is missing or unavailable",
        },
        "intent": intent_summary,
        "targetGuard": guard,
        "blockers": blockers,
        "risks": risks,
        "unknowns": unknowns,
        "evidence": evidence,
        "safety": {
            "readOnly": True,
            "forbiddenActions": FORBIDDEN_ACTIONS,
            "realHomelabTargetAllowed": False,
        },
    }


def parser():
    p = argparse.ArgumentParser(description="Render a read-only rollout risk review report")
    p.add_argument("--intent", help="release intent JSON path")
    p.add_argument("--env", choices=sorted(ALLOWED_ENVIRONMENTS), help="expected review environment")
    p.add_argument("--health-evidence", help="optional health-gate v2 JSON evidence path")
    p.add_argument("--policy-evidence", help="optional policy validation evidence path")
    p.add_argument("--argocd-evidence", help="optional read-only ArgoCD state evidence path")
    p.add_argument("--rollouts-evidence", help="optional read-only Argo Rollouts state evidence path")
    p.add_argument("--hcloud-evidence", help="optional hcloud lifecycle evidence path; requires hcloud target guard")
    p.add_argument("--self-test", action="store_true", help="run deterministic unit checks")
    return p


def write_or_print(report):
    text = json.dumps(report, indent=2, sort_keys=True) + "\n"
    out_path = os.environ.get("RISK_REVIEW_REPORT_PATH")
    if out_path:
        path = Path(out_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
    print(text, end="")


def make_args(**kwargs):
    defaults = {
        "intent": None,
        "env": "local",
        "health_evidence": None,
        "policy_evidence": None,
        "argocd_evidence": None,
        "rollouts_evidence": None,
        "hcloud_evidence": None,
    }
    defaults.update(kwargs)
    return argparse.Namespace(**defaults)


def self_test():
    with TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        health = tmp / "health.json"
        policy = tmp / "policy.json"
        argocd = tmp / "argocd.json"
        rollouts = tmp / "rollouts.json"
        hcloud = tmp / "hcloud.json"
        health.write_text(json.dumps({"decision": "pass", "reasons": [], "evidence": []}))
        policy.write_text(json.dumps({"decision": "pass"}))
        argocd.write_text(json.dumps({"syncStatus": "Synced", "healthStatus": "Healthy"}))
        rollouts.write_text(json.dumps({"phase": "Healthy"}))
        hcloud.write_text(json.dumps({"status": "active"}))

        complete = build_report(make_args(
            intent=str(ROOT / "release-intents/demo-api-local.json"),
            health_evidence=str(health),
            policy_evidence=str(policy),
            argocd_evidence=str(argocd),
            rollouts_evidence=str(rollouts),
        ), environ={"KUBE_CONTEXT": "kind-homelab-garden"})
        assert complete["decision"] == "pass", complete

        missing_intent = build_report(make_args(intent=str(tmp / "missing.json")), environ={})
        assert missing_intent["decision"] == "block", missing_intent
        assert any(item["code"] == "release_intent_missing" for item in missing_intent["blockers"])

        missing_evidence = build_report(make_args(intent=str(ROOT / "release-intents/demo-api-local.json")), environ={})
        assert missing_evidence["decision"] == "unknown", missing_evidence
        assert any(item["code"] == "health_gate_v2_missing" for item in missing_evidence["unknowns"])
        assert any(item["code"] == "policy_validation_missing" for item in missing_evidence["unknowns"])

        hcloud_blocked = build_report(make_args(
            intent=str(ROOT / "release-intents/demo-api-hcloud-lab.json"),
            env="hcloud-lab",
            health_evidence=str(health),
            policy_evidence=str(policy),
            argocd_evidence=str(argocd),
            rollouts_evidence=str(rollouts),
            hcloud_evidence=str(hcloud),
        ), environ={"KUBE_CONTEXT": "kind-homelab-garden"})
        assert hcloud_blocked["decision"] == "block", hcloud_blocked
        assert any(item["code"] == "hcloud_target_guard_unverified" for item in hcloud_blocked["blockers"])

        hcloud_review = build_report(make_args(
            intent=str(ROOT / "release-intents/demo-api-hcloud-lab.json"),
            env="hcloud-lab",
            health_evidence=str(health),
            policy_evidence=str(policy),
            argocd_evidence=str(argocd),
            rollouts_evidence=str(rollouts),
            hcloud_evidence=str(hcloud),
        ), environ={"KUBE_CONTEXT": DEFAULT_EXPECTED_HCLOUD_CONTEXT})
        assert hcloud_review["decision"] == "review", hcloud_review
        assert any(item["code"] == "tag_only_image_identity" for item in hcloud_review["risks"])

    print("risk review self-test passed")


def main(argv=None):
    args = parser().parse_args(argv)
    if args.self_test:
        self_test()
        return 0
    report = build_report(args)
    write_or_print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
