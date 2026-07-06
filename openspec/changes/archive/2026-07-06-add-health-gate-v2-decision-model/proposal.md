## Why

The existing `rollout-health-gates` capability already requires structured output and signal-class documentation. The next step is a true v2 contract: a final decision enum, reason codes, evidence shape, environment/target-guard outcome, and degraded/unknown semantics that downstream rollout and risk-review workflows can consume safely.

## What Changes

- Add a v2 health decision envelope to the existing `rollout-health-gates` capability.
- Define final decision values, reason codes, evidence records, degraded/unknown handling, and environment/target-guard fields.
- Consume demo API observability inputs after `add-demo-api-observability-surface` exists.
- Treat existing structured output and automation-vs-diagnostic signal guidance as prerequisites, not new generic requirements.

## Capabilities

### New Capabilities

### Modified Capabilities
- `rollout-health-gates`: Adds v2-only decision semantics and evidence fields to the existing health-gate capability.

## Impact

- Future implementation may update `validation/health.sh`, hcloud guard output, rollout demo wiring, and risk-review consumers.
- Depends on `add-demo-api-observability-surface` for app-owned health, metrics, and simulation inputs.
- Enables `add-metric-backed-rollout-analysis` to consume stable health decisions later.
- Does not add Prometheus, mutate the real homelab, or create a custom controller.
