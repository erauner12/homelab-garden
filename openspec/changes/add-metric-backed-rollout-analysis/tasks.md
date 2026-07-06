## 1. Prerequisites

- [ ] 1.1 Confirm `add-demo-api-observability-surface` has implemented the metrics required for analysis.
- [ ] 1.2 Confirm `add-health-gate-v2-decision-model` has stable automation-grade decision output where workflows consume health decisions.
- [ ] 1.3 Document required metrics, thresholds, sample windows, and failure simulation inputs.

## 2. Analysis Implementation

- [ ] 2.1 Add minimal AnalysisTemplate or AnalysisRun resources for the demo API metric query.
- [ ] 2.2 Add an optional lightweight Prometheus path only if direct metric querying is insufficient.
- [ ] 2.3 Keep Prometheus and metric analysis outside `make check` and default local validation.
- [ ] 2.4 Add local workflow wiring for healthy and failing metric-backed rollout scenarios.

## 3. Hcloud and Cleanup

- [ ] 3.1 Add hcloud metric analysis support only behind the existing hcloud target guard.
- [ ] 3.2 Document hcloud resource impact and cleanup for any optional metrics components.
- [ ] 3.3 Verify the ArgoCD-managed demo remains healthy after metric analysis exercises.

## 4. Verification

- [ ] 4.1 Test healthy metric-backed rollout progression.
- [ ] 4.2 Test failing metric-backed rollout stop, abort, or rollback behavior.
- [ ] 4.3 Verify default validation does not require Prometheus or Rollouts analysis resources.
