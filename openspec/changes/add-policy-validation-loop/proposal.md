## Why

The lab needs policy-as-code checks before GitOps reconciliation so unsafe deployment intent can fail locally with clear messages. This should be a separate policy validation loop, not a new dependency of `make check`.

## What Changes

- Add a local Kyverno CLI policy validation capability.
- Separate repo-specific Go contract ownership from cluster-enforceable Kyverno policy ownership.
- Add a workflow-shaped Garden/Make entrypoint for policy validation without installing Kyverno admission.
- Keep `make check` unchanged in this change.

## Capabilities

### New Capabilities
- `policy-validation`: Defines local Kyverno CLI policy validation and ownership boundaries with Go contracts.

### Modified Capabilities

## Impact

- Adds `policy/kyverno/` policy and test structure.
- Adds `validation/policy.sh`, a Garden exec test, `workflows/policy-validate.garden.yml`, and a Make target.
- Adds Kyverno CLI as an optional validation tool dependency.
- Does not install Kyverno admission controller.
