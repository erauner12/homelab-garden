## Context

Current validation can prove Kubernetes readiness and smoke responses, but later rollout analysis needs application-owned signals. This change is intentionally the first dependency in the sequence so later health and rollout changes do not invent synthetic metrics or require Prometheus before the app has metrics.

## Goals / Non-Goals

**Goals:**
- Expose simple health/readiness responses that validation can parse consistently.
- Expose a small metrics surface with counters or gauges useful for rollout analysis.
- Provide controlled simulation modes for success, degraded health, error responses, and latency without requiring external systems.
- Keep the surface safe for local and hcloud lab use.

**Non-Goals:**
- Do not add Prometheus scraping, ServiceMonitor resources, or Rollouts AnalysisTemplates here.
- Do not add persistent state, tenant routing, authentication, or real homelab integration.
- Do not make simulation controls part of default `make check` unless existing smoke paths already exercise the demo API safely.

## Decisions

- Prefer boring HTTP endpoints such as `/healthz`, `/readyz`, `/metrics`, and a narrowly scoped simulation endpoint or env/config toggle because future workflows need stable contracts more than framework novelty.
- Keep metrics implementation Prometheus-compatible text where practical, but do not require a Prometheus server in this change.
- Bound simulation modes to the demo API deployment only, with clear reset behavior so exercises do not leave long-lived bad state.
- Document which signals are automation-grade candidates and which are diagnostic-only inputs for later health-gate v2.

## Risks / Trade-offs

- Simulation controls can make demos flaky → require deterministic modes, reset behavior, and explicit validation docs.
- Metrics can become too broad → start with a small set tied to rollout decisions such as request count, error count/rate, latency bucket or summary, and active simulation mode.
- Public repo safety → do not expose secrets, real environment names, or production endpoints.
