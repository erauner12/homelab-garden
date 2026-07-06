## Why

The lab can deploy and reconcile demo state, but it does not yet describe what release is intended or how manifests, images, revisions, and validation evidence relate. A small release intent and artifact identity model makes future promotion, risk review, and tenant-wave simulations concrete without creating a controller.

## What Changes

- Define a lightweight release intent document or data model for the demo API.
- Define artifact identity fields such as Git revision, image reference or digest, manifest path, environment, and validation evidence references.
- Keep the model file-based and read-only for future workflows; no custom CRD/controller.
- Support local and hcloud lab references without targeting the real homelab.

## Capabilities

### New Capabilities
- `release-intent-artifact-identity`: Defines a lightweight release intent and artifact identity model for delivery-lab workflows.

### Modified Capabilities

## Impact

- Future implementation may add docs, sample release intent files, validation scripts, and read-only consumers.
- Enables rollout risk review and tenant-wave simulation to reference the same intended release shape.
- Does not generate PRs, mutate clusters, or introduce a DeliveryPlan CRD/controller.
