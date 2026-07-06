## 1. Reporting Mode Design

- [x] 1.1 Define risk review as a pre-rollout mode or extension of the existing read-only investigation/reporting pattern.
- [x] 1.2 Document investigation as runtime/incident context and risk review as pre-rollout readiness assessment.
- [x] 1.3 Reuse existing report conventions where practical while adding readiness-specific blockers, risks, unknowns, and evidence provenance.

## 2. Evidence Inputs

- [x] 2.1 Consume release intent and artifact identity from `add-release-intent-artifact-identity`.
- [x] 2.2 Consume health-gate v2 decisions, reason codes, and evidence when available.
- [x] 2.3 Consume read-only ArgoCD state, Rollouts state, policy validation result, and hcloud lifecycle status when available.
- [x] 2.4 Mark missing, stale, or unavailable evidence as blockers or unknowns according to the report contract.

## 3. Safety Controls

- [x] 3.1 Enforce that risk review does not apply, delete, patch, scale, sync, promote, abort, roll back, run Terraform apply/destroy, create PRs, or remediate resources.
- [x] 3.2 Reuse hcloud target guards before reading hcloud cluster or lifecycle evidence.
- [x] 3.3 Verify the workflow does not target the real homelab.

## 4. Verification

- [x] 4.1 Test report rendering with complete release intent and healthy evidence.
- [x] 4.2 Test report rendering with missing release intent, missing health-gate v2 output, and missing policy validation result.
- [x] 4.3 Test local and hcloud report modes without mutating resources.
