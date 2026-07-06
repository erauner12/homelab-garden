## Why

The existing read-only investigation pattern gathers runtime or incident context for `demo-api`. The next delivery-lab step is a pre-rollout mode that reuses that reporting pattern to assess readiness before an intended rollout, anchored by release intent and available evidence.

## What Changes

- Add a pre-rollout risk-review mode that extends the existing read-only investigation/reporting approach instead of creating a parallel runtime report system.
- Distinguish investigation as runtime/incident context and risk review as pre-rollout readiness assessment.
- Consume investigation-style evidence when available: release intent, health-gate v2 output, ArgoCD state, Rollouts state, policy validation result, and hcloud lifecycle status.
- Keep the mode read-only: no cluster, Git, ArgoCD, Rollouts, Terraform, or hcloud mutations.

## Capabilities

### New Capabilities
- `rollout-risk-review-workflow`: Defines a read-only pre-rollout risk-review mode built on the existing investigation/reporting pattern.

### Modified Capabilities

## Impact

- Future implementation may extend investigation report templates, read-only collectors, and docs with a pre-rollout mode.
- Depends on `add-release-intent-artifact-identity`; consumes `add-health-gate-v2-decision-model`, ArgoCD/Rollouts state, policy validation results, and hcloud lifecycle guardrails when available.
- Feeds `add-tenant-wave-simulation` as optional gate evidence later.
- Does not target the real homelab or perform rollout actions.
