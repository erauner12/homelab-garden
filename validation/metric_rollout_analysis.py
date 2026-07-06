#!/usr/bin/env python3
"""Render a read-only metric-backed rollout analysis report."""
import argparse
import json
import os
from pathlib import Path
from tempfile import TemporaryDirectory
from urllib.error import HTTPError, URLError
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parents[1]
DECISIONS = {"pass", "review", "block", "unknown"}


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
    if not path:
        return None, "missing"
    path = Path(path)
    try:
        text = path.read_text()
    except OSError as err:
        return None, f"unreadable: {err}"
    try:
        return json.loads(text), None
    except json.JSONDecodeError as err:
        return None, f"invalid JSON: {err}"


def evidence_path(args_value, environ, key):
    return args_value or environ.get(key)


def classify_health(path, blockers, risks, unknowns):
    data, error = read_json(path)
    record = {"name": "healthGateV2", "path": rel(path), "availability": "available" if not error else error}
    if error:
        unknowns.append(issue("health_gate_v2_missing" if error == "missing" else "health_gate_v2_unavailable", "health gate v2 JSON is required", "health_gate_v2"))
        record.update({"decision": None, "effect": "unknown"})
        return record

    decision = data.get("decision") if isinstance(data, dict) else None
    reasons = data.get("reasons", []) if isinstance(data, dict) else []
    record.update({"decision": decision, "reasons": reasons, "effect": f"decision:{decision or 'missing'}"})
    if decision == "pass":
        return record
    if decision == "fail":
        blockers.append(issue("health_gate_v2_failed", f"health gate failed: {reasons}", "health_gate_v2"))
    elif decision == "degraded":
        risks.append(issue("health_gate_v2_degraded", f"health gate degraded: {reasons}", "health_gate_v2"))
    else:
        unknowns.append(issue("health_gate_v2_unknown", f"health gate decision is {decision or 'missing'}", "health_gate_v2"))
    return record


def classify_risk(path, blockers, risks, unknowns):
    data, error = read_json(path)
    record = {"name": "rolloutRiskReview", "path": rel(path), "availability": "available" if not error else error}
    if error:
        unknowns.append(issue("risk_review_missing" if error == "missing" else "risk_review_unavailable", "rollout risk review JSON is required", "risk_review"))
        record.update({"decision": None, "effect": "unknown"})
        return record

    decision = data.get("decision") if isinstance(data, dict) else None
    record.update({"decision": decision, "effect": f"decision:{decision or 'missing'}"})
    if decision == "block":
        blockers.append(issue("risk_review_block", "rollout risk review decision is block", "risk_review"))
    elif decision == "review":
        risks.append(issue("risk_review_requires_review", "rollout risk review requires manual review", "risk_review"))
    elif decision == "unknown" or decision not in {"pass", "review", "block"}:
        unknowns.append(issue("risk_review_unknown", f"rollout risk review decision is {decision or 'missing'}", "risk_review"))
    return record


def classify_wave(path, blockers, risks, unknowns):
    data, error = read_json(path)
    record = {"name": "tenantWaveSimulation", "path": rel(path), "availability": "available" if not error else error}
    if error:
        unknowns.append(issue("tenant_wave_missing" if error == "missing" else "tenant_wave_unavailable", "tenant wave simulation JSON is required", "tenant_wave"))
        record.update({"status": None, "effect": "unknown"})
        return record, {}

    status = data.get("status") if isinstance(data, dict) else None
    tenants = data.get("tenants", []) if isinstance(data, dict) else []
    eligible = [t for t in tenants if isinstance(t, dict) and t.get("status") == "eligible"]
    blocked = status in {"blocked", "block"} or any(isinstance(t, dict) and t.get("status") in {"blocked", "block"} for t in tenants)
    context = {"status": status, "eligibleTenants": [t.get("id") for t in eligible], "tenantCount": len(tenants)}
    record.update({"status": status, "effect": "eligible" if eligible and status == "eligible" else "not_eligible", "context": context})
    if blocked:
        blockers.append(issue("tenant_wave_blocked", f"tenant wave status is {status}", "tenant_wave"))
    elif not (status == "eligible" and eligible):
        risks.append(issue("tenant_wave_not_eligible", f"tenant wave status is {status or 'missing'}", "tenant_wave"))
    return record, context


def fetch_metrics(base_url):
    try:
        with urlopen(base_url.rstrip("/") + "/metrics", timeout=2) as response:
            return response.status, response.read(65536).decode("utf-8", "replace"), None
    except HTTPError as err:
        return err.code, err.read(4096).decode("utf-8", "replace"), str(err)
    except (OSError, URLError) as err:
        return None, "", str(err)


def parse_metrics(text):
    metrics = {}
    modes = {}
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) != 2:
            continue
        name, value = parts
        try:
            number = float(value)
        except ValueError:
            continue
        if name.startswith("demo_api_simulation_mode{"):
            marker = 'mode="'
            if marker in name:
                modes[name.split(marker, 1)[1].split('"', 1)[0]] = number
        else:
            metrics[name] = number
    active_mode = next((mode for mode, value in modes.items() if value == 1), None)
    return {
        "requestsTotal": metrics.get("demo_api_requests_total"),
        "errorsTotal": metrics.get("demo_api_errors_total"),
        "durationCount": metrics.get("demo_api_request_duration_seconds_count"),
        "durationSum": metrics.get("demo_api_request_duration_seconds_sum"),
        "latencyMs": metrics.get("demo_api_simulation_latency_ms"),
        "activeMode": active_mode,
    }


def classify_metrics(base_url, blockers, risks, unknowns):
    if not base_url:
        return {"name": "demoApiMetrics", "availability": "not_configured", "effect": "skipped", "source": "DEMO_API_BASE_URL"}
    status, text, error = fetch_metrics(base_url)
    if status != 200 or error:
        unknowns.append(issue("metric_scrape_unavailable", f"demo API /metrics unavailable: {error or status}", "demo_api_metrics"))
        return {"name": "demoApiMetrics", "availability": "unavailable", "httpStatus": status, "effect": "unknown", "error": error}
    observed = parse_metrics(text)
    if observed["requestsTotal"] is None or observed["errorsTotal"] is None:
        unknowns.append(issue("metric_scrape_unclassified", "required demo API metric names were not found", "demo_api_metrics"))
        effect = "unknown"
    elif observed["activeMode"] == "failing" or (observed["errorsTotal"] or 0) > 0:
        risks.append(issue("demo_api_metric_errors", "demo API metrics show errors or failing simulation mode", "demo_api_metrics"))
        effect = "review"
    else:
        effect = "supports_pass"
    return {"name": "demoApiMetrics", "availability": "available", "httpStatus": status, "effect": effect, "observed": observed}


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
    blockers, risks, unknowns = [], [], []
    health_path = evidence_path(args.health, environ, "HEALTH_GATE_EVIDENCE_PATH")
    risk_path = evidence_path(args.risk_review, environ, "RISK_REVIEW_EVIDENCE_PATH")
    wave_path = evidence_path(args.tenant_wave, environ, "TENANT_WAVE_EVIDENCE_PATH")

    health = classify_health(health_path, blockers, risks, unknowns)
    risk = classify_risk(risk_path, blockers, risks, unknowns)
    wave, wave_context = classify_wave(wave_path, blockers, risks, unknowns)
    metrics = classify_metrics(environ.get("DEMO_API_BASE_URL", ""), blockers, risks, unknowns)

    return {
        "schemaVersion": "homelab-garden.metric-rollout-analysis/v1alpha1",
        "kind": "MetricRolloutAnalysis",
        "mode": "read-only-local-analysis",
        "automationSafe": final_decision(blockers, risks, unknowns) == "pass",
        "decision": final_decision(blockers, risks, unknowns),
        "reasonCodes": [item["code"] for item in blockers + risks + unknowns],
        "blockers": blockers,
        "risks": risks,
        "unknowns": unknowns,
        "metricEvidence": metrics,
        "waveContext": wave_context,
        "evidence": [health, risk, wave, metrics],
        "safety": {
            "readOnly": True,
            "clusterMutation": False,
            "argocdSync": False,
            "prometheusRequired": False,
            "rolloutsAnalysisResources": False,
            "prGeneration": False,
        },
    }


def render_markdown(report):
    lines = [
        "# Metric Rollout Analysis",
        "",
        f"Decision: `{report['decision']}`",
        f"Automation-safe: `{str(report['automationSafe']).lower()}`",
        "",
        "## Reason codes",
    ]
    codes = report["reasonCodes"] or ["none"]
    lines.extend(f"- `{code}`" for code in codes)
    lines.extend(["", "## Metric evidence", "", "```json", json.dumps(report["metricEvidence"], indent=2, sort_keys=True), "```", "", "## Wave context", "", "```json", json.dumps(report["waveContext"], indent=2, sort_keys=True), "```"])
    return "\n".join(lines) + "\n"


def parser():
    p = argparse.ArgumentParser(description="Render a read-only metric-backed rollout analysis report")
    p.add_argument("--health", help="health gate v2 JSON path (or HEALTH_GATE_EVIDENCE_PATH)")
    p.add_argument("--risk-review", help="rollout risk review JSON path (or RISK_REVIEW_EVIDENCE_PATH)")
    p.add_argument("--tenant-wave", help="tenant wave simulation JSON path (or TENANT_WAVE_EVIDENCE_PATH)")
    p.add_argument("--format", choices=("json", "markdown"), default="json")
    p.add_argument("--self-test", action="store_true", help="run deterministic unit checks")
    return p


def write_or_print(report, fmt):
    if fmt == "markdown":
        text = render_markdown(report)
    else:
        text = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if os.environ.get("METRIC_ROLLOUT_ANALYSIS_REPORT_PATH"):
        path = Path(os.environ["METRIC_ROLLOUT_ANALYSIS_REPORT_PATH"])
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
    print(text, end="")


def make_args(**kwargs):
    defaults = {"health": None, "risk_review": None, "tenant_wave": None, "format": "json"}
    defaults.update(kwargs)
    return argparse.Namespace(**defaults)


def write_json(path, data):
    path.write_text(json.dumps(data))
    return str(path)


def self_test():
    with TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        health = write_json(tmp / "health.json", {"decision": "pass", "reasons": []})
        risk = write_json(tmp / "risk.json", {"decision": "pass"})
        wave = write_json(tmp / "wave.json", {"status": "eligible", "tenants": [{"id": "sample-canary", "status": "eligible"}]})
        report = build_report(make_args(health=health, risk_review=risk, tenant_wave=wave), environ={})
        assert report["decision"] == "pass", report
        assert report["automationSafe"] is True, report

        missing = build_report(make_args(), environ={})
        assert missing["decision"] == "unknown", missing
        assert "health_gate_v2_missing" in missing["reasonCodes"], missing

        blocked = build_report(make_args(health=health, risk_review=write_json(tmp / "block.json", {"decision": "block"}), tenant_wave=wave), environ={})
        assert blocked["decision"] == "block", blocked

        review = build_report(make_args(health=health, risk_review=risk, tenant_wave=write_json(tmp / "held.json", {"status": "review", "tenants": []})), environ={})
        assert review["decision"] == "review", review

        parsed = parse_metrics('demo_api_requests_total 2\ndemo_api_errors_total 0\ndemo_api_simulation_mode{mode="healthy"} 1\n')
        assert parsed["requestsTotal"] == 2 and parsed["activeMode"] == "healthy", parsed
        assert "Metric evidence" in render_markdown(report)
    print("metric rollout analysis self-test passed")


def main(argv=None):
    args = parser().parse_args(argv)
    if args.self_test:
        self_test()
        return 0
    report = build_report(args)
    write_or_print(report, args.format)
    return 0 if report["decision"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
