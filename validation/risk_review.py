#!/usr/bin/env python3
"""Render a read-only pre-rollout risk review report."""
import argparse
import json
import os
from pathlib import Path
from tempfile import TemporaryDirectory

from release_intent import validate_intent

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_EXPECTED_HCLOUD_CONTEXT = "admin@homelab-garden-hcloud-lab"
ALLOWED_ENVIRONMENTS = {"local", "hcloud-lab"}


def rel(path):
    if path is None:
        return None
    try:
        return str(Path(path).resolve().relative_to(ROOT))
    except ValueError:
        return str(path)


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
        "effect": effect,
    }
    if detail is not None:
        out["detail"] = detail
    return out


def read_file(path):
    path = Path(path)
    try:
        text = path.read_text()
    except OSError as err:
        return None, f"unreadable: {err}"
    try:
        return json.loads(text), None
    except json.JSONDecodeError as err:
        return None, f"invalid JSON: {err}"


def default_env(environ):
    for key in ("RISK_REVIEW_ENVIRONMENT", "GARDEN_ENVIRONMENT"):
        if environ.get(key):
            return environ[key]
    expected = environ.get("HCLOUD_LAB_CONTEXT", DEFAULT_EXPECTED_HCLOUD_CONTEXT)
    observed = environ.get("KUBE_CONTEXT") or environ.get("KUBECONTEXT")
    return "hcloud-lab" if observed == expected else "local"


def default_intent_path(env):
    return ROOT / "release-intents" / f"demo-api-{env or 'local'}.json"


def hcloud_target_guard(env, environ):
    if env != "hcloud-lab":
        return None
    expected = environ.get("HCLOUD_LAB_CONTEXT", DEFAULT_EXPECTED_HCLOUD_CONTEXT)
    observed = environ.get("KUBE_CONTEXT") or environ.get("KUBECONTEXT")
    verified = observed == expected
    return {
        "environment": env,
        "verified": verified,
        "reason": "hcloud_context_verified" if verified else "hcloud_context_mismatch",
        "expected_context": expected,
        "observed_context": observed,
    }


def load_intent(path, requested_env, blockers, risks, evidence):
    path = Path(path)
    if not path.exists():
        blockers.append(issue("release_intent_missing", f"release intent not found: {rel(path)}", "release_intent"))
        evidence.append(evidence_record("release_intent", path, "missing", "blocks_ready"))
        return None

    data, error = read_file(path)
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

    image = data.get("image") if isinstance(data, dict) and isinstance(data.get("image"), dict) else {}
    if env == "hcloud-lab" and image.get("risk"):
        risks.append(issue("tag_only_image_identity", image["risk"], "release_intent"))
    return data


def classify_health_gate(path, blockers, risks, unknowns, evidence):
    if not path:
        return

    data, error = read_file(path)
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


def final_decision(blockers, risks, unknowns):
    if blockers:
        return "block"
    if risks:
        return "review"
    if unknowns:
        return "unknown"
    return "pass"


def intent_summary(intent, path, env):
    if not isinstance(intent, dict):
        return {
            "path": rel(path),
            "app": None,
            "environment": env,
            "gitRevision": None,
            "manifestPath": None,
            "image": None,
        }
    app = intent.get("app") if isinstance(intent.get("app"), dict) else {}
    git = intent.get("git") if isinstance(intent.get("git"), dict) else {}
    manifest = intent.get("manifest") if isinstance(intent.get("manifest"), dict) else {}
    return {
        "path": rel(path),
        "app": app.get("id"),
        "environment": intent.get("environment"),
        "gitRevision": git.get("revision"),
        "manifestPath": manifest.get("path"),
        "image": intent.get("image"),
    }


def evidence_paths(environ):
    return {"health_gate_v2": environ.get("HEALTH_GATE_EVIDENCE_PATH")}


def build_report(args, environ=None):
    environ = dict(os.environ if environ is None else environ)
    env = args.env or default_env(environ)
    intent_path = Path(args.intent or environ.get("RELEASE_INTENT_PATH") or default_intent_path(env))
    blockers, risks, unknowns, evidence = [], [], [], []

    intent = load_intent(intent_path, env, blockers, risks, evidence)
    env = args.env or (intent.get("environment") if isinstance(intent, dict) else env)
    if env not in ALLOWED_ENVIRONMENTS:
        blockers.append(issue("unsupported_environment", f"risk review supports only local or hcloud-lab, got {env}", "environment"))

    paths = evidence_paths(environ)
    guard = hcloud_target_guard(env, environ)
    classify_health_gate(paths["health_gate_v2"], blockers, risks, unknowns, evidence)

    report = {
        "schemaVersion": "homelab-garden.rollout-risk-review/v1alpha1",
        "kind": "RolloutRiskReview",
        "mode": "pre-rollout-readiness-assessment",
        "decision": final_decision(blockers, risks, unknowns),
        "intent": intent_summary(intent, intent_path, env),
        "blockers": blockers,
        "risks": risks,
        "unknowns": unknowns,
        "evidence": evidence,
    }
    if guard is not None:
        report["targetGuard"] = guard
    return report


def parser():
    p = argparse.ArgumentParser(description="Render a read-only rollout risk review report")
    p.add_argument("--intent", help="release intent JSON path")
    p.add_argument("--env", choices=sorted(ALLOWED_ENVIRONMENTS), help="expected review environment")
    p.add_argument("--self-test", action="store_true", help="run deterministic unit checks")
    return p


def write_or_print(report):
    text = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if os.environ.get("RISK_REVIEW_REPORT_PATH"):
        path = Path(os.environ["RISK_REVIEW_REPORT_PATH"])
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
    print(text, end="")


def make_args(**kwargs):
    defaults = {"intent": None, "env": None}
    defaults.update(kwargs)
    return argparse.Namespace(**defaults)


def write_json(path, data):
    path.write_text(json.dumps(data))
    return str(path)


def self_test():
    with TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        health = write_json(tmp / "health.json", {"decision": "pass", "reasons": [], "evidence": []})

        evidence_env = {"HEALTH_GATE_EVIDENCE_PATH": health}
        complete = build_report(
            make_args(intent=str(ROOT / "release-intents/demo-api-local.json")),
            environ={**evidence_env, "KUBE_CONTEXT": "kind-homelab-garden"},
        )
        assert complete["decision"] == "pass", complete
        assert "decisionContract" not in complete
        assert "safety" not in complete
        assert "targetGuard" not in complete

        checks = [
            (build_report(make_args(intent=str(tmp / "missing.json")), environ={}), "block", "release_intent_missing", "blockers"),
            (build_report(make_args(intent=str(ROOT / "release-intents/demo-api-local.json")), environ={}), "pass", None, None),
            (build_report(make_args(intent=str(ROOT / "release-intents/demo-api-hcloud-lab.json"), env="hcloud-lab"), environ={**evidence_env, "KUBE_CONTEXT": DEFAULT_EXPECTED_HCLOUD_CONTEXT}), "review", "tag_only_image_identity", "risks"),
        ]
        for report, decision, code, bucket in checks:
            assert report["decision"] == decision, report
            if code:
                assert any(item["code"] == code for item in report[bucket]), report

    print("risk review self-test passed")


def main(argv=None):
    args = parser().parse_args(argv)
    if args.self_test:
        self_test()
        return 0
    write_or_print(build_report(args))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
