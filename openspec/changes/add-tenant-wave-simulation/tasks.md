## 1. Model and Fixtures

- [x] 1.1 Confirm `add-release-intent-artifact-identity` provides the simulated release input.
- [x] 1.2 Define three public-safe sample tenants and their wave assignments.
- [x] 1.3 Define simple per-tenant gate states and stop-on-blocker semantics.
- [x] 1.4 Define how rollout risk review output can optionally feed tenant gate evidence.

## 2. Simulation Output

- [x] 2.1 Add a non-mutating simulation command, script, or workflow that renders wave order and tenant status.
- [x] 2.2 Render blockers, unknowns, eligible next wave, and held waves in Markdown or structured JSON.
- [x] 2.3 Label output as simulation-only and non-authoritative.

## 3. Safety Boundaries

- [x] 3.1 Verify the simulation does not generate PRs, apply manifests, patch clusters, sync ArgoCD, promote Rollouts, or run Terraform.
- [x] 3.2 Verify sample tenants contain no real customer, private homelab, provider, or secret data.
- [x] 3.3 Verify no DeliveryPlan CRD, custom controller, or reconciler is introduced.

## 4. Integration Notes

- [x] 4.1 Document how rollout risk review output may feed tenant gate states after `add-rollout-risk-review-workflow` exists.
- [x] 4.2 Document how hcloud remains an explicit disposable lab target if used as optional evidence.
