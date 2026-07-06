## Why

The current progressive delivery demo can prove Rollouts behavior with Kubernetes-native health, but it does not yet show metric-backed analysis. After the demo API exposes metrics, the lab can add a small optional analysis path without making Prometheus a default dependency.

## What Changes

- Add metric-backed Rollouts analysis for demo API canary or blue/green exercises.
- Depend on the demo API metrics surface and health-gate v2 decision model.
- Add Prometheus only when needed for the analysis path, and keep it optional and lab-scoped.
- Keep metric analysis outside `make check` and separate from the real homelab.

## Capabilities

### New Capabilities
- `metric-backed-rollout-analysis`: Defines optional Argo Rollouts analysis behavior backed by demo API metrics and an optional lightweight Prometheus path.

### Modified Capabilities

## Impact

- Future implementation may add AnalysisTemplates, optional Prometheus manifests, workflow steps, and documentation for local and hcloud lab use.
- Depends on `add-demo-api-observability-surface` and should consume `add-health-gate-v2-decision-model` results where appropriate.
- Does not require service mesh, ingress traffic shifting, or real homelab integration.
