## Why

The demo API is now used by health gates, smoke tests, and rollout exercises, but it does not yet expose a stable surface for readiness, metrics, or controlled failure simulation. Adding that surface first gives later automation something app-owned and deterministic to evaluate before introducing Prometheus-backed analysis.

## What Changes

- Add a small demo API observability contract for health, readiness, metrics, and simulation controls.
- Keep endpoints public-safe, deterministic, and suitable for local kind and disposable hcloud lab exercises.
- Define simulation modes that future rollout and health-gate workflows can enable without changing production-like infrastructure.
- Do not add Prometheus, Rollouts analysis, or new default `make check` requirements in this change.

## Capabilities

### New Capabilities
- `demo-api-observability-surface`: Defines health, metrics, and simulation behavior exposed by the demo API for later validation workflows.

### Modified Capabilities

## Impact

- Future implementation may touch demo API code, Kubernetes manifests, smoke validation, and documentation.
- Enables later health-gate v2 and metric-backed Rollouts analysis changes.
- Does not target or mutate the real homelab and does not add cloud dependencies.
