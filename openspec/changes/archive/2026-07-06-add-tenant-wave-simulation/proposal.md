## Why

The roadmap needs a way to discuss staged delivery across tenants, but a PR generator or custom controller would be too much for the small lab right now. After release intent and pre-rollout risk review exist, a tiny three-tenant wave simulation can model desired state and sequencing while staying read-only or manifest-only.

## What Changes

- Add a small three-tenant desired-state and wave simulation model.
- Use release intent/artifact identity as the input for what is being rolled out.
- Allow rollout risk review output to become optional gate evidence for tenant waves.
- Simulate wave ordering, per-tenant gates, and stop conditions without generating PRs or creating a controller.
- Keep the simulation local/public-safe, with hcloud references explicit and optional.

## Capabilities

### New Capabilities
- `tenant-wave-simulation`: Defines a small three-tenant rollout wave simulation model without PR generation or custom controller behavior.

### Modified Capabilities

## Impact

- Future implementation may add sample tenant files, docs, and a read-only simulation script or workflow.
- Depends on `add-release-intent-artifact-identity` and should follow `add-rollout-risk-review-workflow` if risk evidence is used as tenant gates.
- Does not create a DeliveryPlan CRD/controller and does not mutate the real homelab.
