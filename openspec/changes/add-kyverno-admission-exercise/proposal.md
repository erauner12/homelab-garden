## Why

Kyverno CLI policy validation proves manifests against fixtures, but it does not demonstrate Kubernetes admission behavior. After the existing `policy-validation` capability is in place, a separate admission exercise should show enforce/audit behavior in disposable local and hcloud lab clusters without promoting Kyverno into default validation.

## What Changes

- Add an optional Kyverno admission-controller exercise that depends on the existing `policy-validation` policy set and fixture conventions.
- Keep it separate from `make check`, `local-validate`, and the existing `policy-validate` CLI path.
- Exercise allow and deny cases with public-safe fixtures and clear cleanup.
- Require hcloud target guards before running admission tests against disposable cloud infrastructure.

## Capabilities

### New Capabilities
- `kyverno-admission-exercise`: Defines optional live Kyverno admission behavior exercises for local and disposable hcloud lab clusters.

### Modified Capabilities

## Impact

- Future implementation may add Kyverno install manifests or workflow steps, admission test fixtures, and docs.
- Depends on, and complements, the existing `policy-validation` capability; it does not replace CLI policy validation.
- Does not target the real homelab or add Kyverno to the default validation path.
