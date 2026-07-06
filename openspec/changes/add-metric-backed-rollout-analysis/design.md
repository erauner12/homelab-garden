## Context

The existing progressive delivery capability intentionally avoids Prometheus and service mesh dependencies. This change comes later in the sequence: app metrics first, structured health decisions second, metric-backed Rollouts analysis third.

## Goals / Non-Goals

**Goals:**
- Demonstrate Argo Rollouts AnalysisRun behavior using demo API metrics.
- Keep Prometheus optional, minimal, and scoped to the lab environment using it.
- Support local first, with hcloud usage only behind explicit hcloud lab guards.
- Preserve Kubernetes-native health and smoke tests as the fallback path.

**Non-Goals:**
- Do not add Prometheus to the default local validation path.
- Do not require service mesh, ingress controllers, production traffic, or real homelab metrics.
- Do not introduce a custom CRD/controller for delivery planning.

## Decisions

- Use demo API metrics as the source of truth for analysis queries; do not invent metrics in workflow scripts.
- Add a minimal Prometheus installation only for workflows that actually need query execution, and document how to skip or clean it up.
- Start with a small success-rate or error-rate query before adding latency SLOs or multi-window analysis.
- Keep hcloud metric analysis opt-in and require the hcloud target guard before installing or querying metrics components.

## Risks / Trade-offs

- Prometheus can expand the lab footprint → keep it optional and isolated from `make check`.
- Metric timing can make analysis flaky → define warmup/sample windows and use deterministic simulation modes.
- Hcloud costs can increase → document resource impact and require teardown verification if Prometheus is installed there.
