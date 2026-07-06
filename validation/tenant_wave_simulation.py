#!/usr/bin/env python3
"""Render a read-only tenant wave simulation report."""
import argparse
import json
import os
from pathlib import Path
from tempfile import TemporaryDirectory

from release_intent import validate_intent

ROOT = Path(__file__).resolve().parents[1]
ALLOWED_ENVIRONMENTS = {"local", "hcloud-lab"}
SAMPLE_TENANTS = (
    {"id": "sample-canary", "displayName": "Sample Canary", "wave": 1},
    {"id": "sample-neighborhood", "displayName": "Sample Neighborhood", "wave": 2},
    {"id": "sample-community", "displayName": "Sample Community", "wave": 3},
)


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


def read_json(path):
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
    return environ.get("TENANT_WAVE_ENVIRONMENT") or environ.get("GARDEN_ENVIRONMENT") or "local"


def default_intent_path(env):
    return ROOT / "release-intents" / f"demo-api-{env or 'local'}.json"


def configured_risk_review_path(environ):
    for key in ("RISK_REVIEW_EVIDENCE_PATH", "ROLLOUT_RISK_REVIEW_PATH", "RISK_REVIEW_REPORT_PATH"):
        if environ.get(key):
            return environ[key]
    return None


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


def load_intent(path, requested_env, blockers, unknowns):
    path = Path(path)
    if not path.exists():
        blockers.append(issue("release_intent_missing", f"release intent not found: {rel(path)}", "release_intent"))
        return None

    data, error = read_json(path)
    if error:
        blockers.append(issue("release_intent_unreadable", error, "release_intent"))
        return None

    for error in validate_intent(path):
        blockers.append(issue("release_intent_invalid", error, "release_intent"))

    if not isinstance(data, dict):
        unknowns.append(issue("release_intent_unclassified", "release intent was not a JSON object", "release_intent"))
        return None

    env = data.get("environment")
    if requested_env and env and requested_env != env:
        blockers.append(issue("release_intent_environment_mismatch", f"requested env {requested_env} does not match release intent env {env}", "release_intent"))
    if env not in ALLOWED_ENVIRONMENTS:
        blockers.append(issue("unsupported_environment", f"tenant wave simulation supports only local or hcloud-lab, got {env}", "environment"))
    return data


def load_risk_review(path, blockers, risks, unknowns):
    if not path:
        unknowns.append(issue("risk_review_missing", "no rollout risk review JSON was provided; set RISK_REVIEW_EVIDENCE_PATH to use one", "risk_review"))
        return {"path": None, "availability": "missing", "decision": None, "effect": "unknown"}

    data, error = read_json(path)
    if error:
        unknowns.append(issue("risk_review_unavailable", error, "risk_review"))
        return {"path": rel(path), "availability": "unavailable", "decision": None, "effect": "unknown", "detail": error}

    decision = data.get("decision") if isinstance(data, dict) else None
    if decision == "block":
        blockers.append(issue("risk_review_block", "rollout risk review decision is block", "risk_review"))
        effect = "blocks_simulation"
    elif decision == "unknown":
        unknowns.append(issue("risk_review_unknown", "rollout risk review decision is unknown", "risk_review"))
        effect = "requires_review"
    elif decision == "review":
        risks.append(issue("risk_review_requires_review", "rollout risk review decision requires manual review", "risk_review"))
        effect = "requires_review"
    elif decision == "pass":
        effect = "allows_simulation"
    else:
        unknowns.append(issue("risk_review_unclassified", f"rollout risk review decision is {decision or 'missing'}", "risk_review"))
        effect = "unknown"

    return {"path": rel(path), "availability": "available", "decision": decision, "effect": effect}


def image_gate(intent, risks):
    image = intent.get("image") if isinstance(intent, dict) and isinstance(intent.get("image"), dict) else {}
    if image.get("identityMode") == "digest" and "@sha256:" in image.get("reference", ""):
        return {"state": "pass", "message": "digest-pinned image identity"}
    if image.get("identityMode") == "tag":
        message = image.get("risk") or "tag-only image identity is mutable"
        risks.append(issue("tag_only_image_identity", message, "release_intent"))
        return {"state": "review", "message": message}
    return {"state": "unknown", "message": "image identity is missing or unclassified"}


def risk_gate_state(risk_review):
    decision = risk_review.get("decision")
    if decision == "pass":
        return "pass", "risk review passed"
    if decision == "block":
        return "block", "risk review blocked rollout"
    if decision == "review":
        return "review", "risk review requires manual review"
    if decision == "unknown":
        return "unknown", "risk review decision is unknown"
    return "unknown", "risk review evidence is missing or unclassified"


def wave_policy(blockers, risks, unknowns, image, risk_review):
    if blockers:
        return None, "blocked"
    if image["state"] == "review":
        return None, "manual-review"
    if risk_review.get("decision") in {"unknown", "review"}:
        return None, "review"
    # Missing optional risk review stays visible in unknowns, but digest + no blockers may still start wave 1.
    if image["state"] == "pass":
        return 1, "eligible"
    return None, "review"


def build_tenants(eligible_wave, overall_status, blockers, unknowns, image, risk_review):
    risk_state, risk_message = risk_gate_state(risk_review)
    tenants = []
    for tenant in SAMPLE_TENANTS:
        wave = tenant["wave"]
        tenant_blockers = []
        tenant_unknowns = []
        if blockers:
            status = "blocked"
            tenant_blockers = blockers
            wave_state = "blocked"
            wave_message = "simulation stopped by blocker"
        elif eligible_wave == wave:
            status = overall_status
            wave_state = "eligible"
            wave_message = "first wave may start; later waves wait for prior wave completion"
            if risk_state == "unknown":
                tenant_unknowns = unknowns
        else:
            status = "held"
            wave_state = "held"
            wave_message = "held by ordered wave policy until earlier waves complete"
            if overall_status in {"manual-review", "review"}:
                status = overall_status
                wave_message = "held until manual review clears current gates"
                tenant_unknowns = unknowns

        tenants.append(
            {
                "id": tenant["id"],
                "displayName": tenant["displayName"],
                "wave": wave,
                "status": status,
                "gates": [
                    {"name": "releaseIntent", "state": "block" if blockers else "pass", "message": "release intent provides simulated release input"},
                    {"name": "artifactIdentity", "state": image["state"], "message": image["message"]},
                    {"name": "rolloutRiskReview", "state": risk_state, "message": risk_message},
                    {"name": "waveOrder", "state": wave_state, "message": wave_message},
                ],
                "blockers": tenant_blockers,
                "unknowns": tenant_unknowns,
            }
        )
    return tenants


def build_report(args, environ=None):
    environ = dict(os.environ if environ is None else environ)
    env = args.env or default_env(environ)
    intent_path = Path(args.intent or environ.get("RELEASE_INTENT_PATH") or default_intent_path(env))
    blockers, risks, unknowns = [], [], []

    intent = load_intent(intent_path, env, blockers, unknowns)
    env = args.env or (intent.get("environment") if isinstance(intent, dict) else env)
    risk_review = load_risk_review(args.risk_review or configured_risk_review_path(environ), blockers, risks, unknowns)
    image = image_gate(intent or {}, risks)
    eligible_wave, overall_status = wave_policy(blockers, risks, unknowns, image, risk_review)
    tenants = build_tenants(eligible_wave, overall_status, blockers, unknowns, image, risk_review)
    held_waves = [wave for wave in sorted({tenant["wave"] for tenant in SAMPLE_TENANTS}) if wave != eligible_wave]

    return {
        "schemaVersion": "homelab-garden.tenant-wave-simulation/v1alpha1",
        "kind": "TenantWaveSimulation",
        "mode": "read-only-tenant-wave-simulation",
        "simulationOnly": True,
        "authoritative": False,
        "nonAuthoritativeReason": "Report-only model; does not generate PRs, sync ArgoCD, apply manifests, run Terraform, or mutate clusters.",
        "status": overall_status,
        "intent": intent_summary(intent, intent_path, env),
        "riskReview": risk_review,
        "waveOrder": [{"wave": tenant["wave"], "tenantIds": [tenant["id"]]} for tenant in SAMPLE_TENANTS],
        "tenants": tenants,
        "blockers": blockers,
        "risks": risks,
        "unknowns": unknowns,
        "eligibleNextWave": eligible_wave,
        "heldWaves": held_waves,
    }


def parser():
    p = argparse.ArgumentParser(description="Render a read-only tenant wave simulation report")
    p.add_argument("--intent", help="release intent JSON path")
    p.add_argument("--env", choices=sorted(ALLOWED_ENVIRONMENTS), help="expected simulation environment")
    p.add_argument("--risk-review", help="rollout risk review JSON path")
    p.add_argument("--self-test", action="store_true", help="run deterministic unit checks")
    return p


def write_or_print(report):
    text = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if os.environ.get("TENANT_WAVE_SIMULATION_REPORT_PATH"):
        path = Path(os.environ["TENANT_WAVE_SIMULATION_REPORT_PATH"])
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
    print(text, end="")


def make_args(**kwargs):
    defaults = {"intent": None, "env": None, "risk_review": None}
    defaults.update(kwargs)
    return argparse.Namespace(**defaults)


def write_json(path, data):
    path.write_text(json.dumps(data))
    return str(path)


def self_test():
    local_intent = str(ROOT / "release-intents/demo-api-local.json")
    hcloud_intent = str(ROOT / "release-intents/demo-api-hcloud-lab.json")
    missing_risk = build_report(make_args(intent=local_intent), environ={})
    assert missing_risk["simulationOnly"] is True, missing_risk
    assert missing_risk["authoritative"] is False, missing_risk
    assert len(missing_risk["tenants"]) == 3, missing_risk
    assert missing_risk["eligibleNextWave"] == 1, missing_risk
    assert any(item["code"] == "risk_review_missing" for item in missing_risk["unknowns"]), missing_risk

    tag_only = build_report(make_args(intent=hcloud_intent, env="hcloud-lab"), environ={})
    assert tag_only["status"] == "manual-review", tag_only
    assert tag_only["eligibleNextWave"] is None, tag_only
    assert any(item["code"] == "tag_only_image_identity" for item in tag_only["risks"]), tag_only

    with TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        block_path = write_json(tmp / "risk-block.json", {"decision": "block", "blockers": [{"code": "demo"}]})
        unknown_path = write_json(tmp / "risk-unknown.json", {"decision": "unknown"})
        pass_path = write_json(tmp / "risk-pass.json", {"decision": "pass"})

        blocked = build_report(make_args(intent=local_intent, risk_review=block_path), environ={})
        assert blocked["status"] == "blocked", blocked
        assert any(item["code"] == "risk_review_block" for item in blocked["blockers"]), blocked

        unknown = build_report(make_args(intent=local_intent, risk_review=unknown_path), environ={})
        assert unknown["status"] == "review", unknown
        assert unknown["eligibleNextWave"] is None, unknown

        passed = build_report(make_args(intent=local_intent, risk_review=pass_path), environ={})
        assert passed["status"] == "eligible", passed
        assert passed["eligibleNextWave"] == 1, passed

    print("tenant wave simulation self-test passed")


def main(argv=None):
    args = parser().parse_args(argv)
    if args.self_test:
        self_test()
        return 0
    write_or_print(build_report(args))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
