## Why

After GitOps reconciliation works, the lab needs a small progressive delivery exercise that demonstrates rollout state, success, failure, and safe health evaluation without requiring a service mesh or full observability stack.

## What Changes

- Add Argo Rollouts as an optional platform addon.
- Add a demo Rollout and minimal analysis path for the demo API.
- Add `rollout-demo` and `failure-demo` workflows.
- Add readiness/status-only health output for the first failure demo.
- Keep Rollouts resources out of the default validation path until CRD-aware validation is intentional.

## Capabilities

### New Capabilities
- `progressive-delivery`: Defines the successful and failing Rollouts demo behavior.
- `rollout-health-gates`: Defines minimal readiness/status health gate behavior and future metrics expansion boundary.

### Modified Capabilities

## Impact

- Adds Argo Rollouts addon resources.
- Adds Rollout and AnalysisTemplate examples outside the default app overlay.
- Adds scenarios and workflows for success/failure exercises.
- Adds `validation/health.sh` for structured readiness/status output.
