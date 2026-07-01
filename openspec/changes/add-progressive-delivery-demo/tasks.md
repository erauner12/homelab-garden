## 1. Rollouts Addon and Manifests

- [x] 1.1 Add `platform/addons/argo-rollouts/` resources or installer wrapper.
- [x] 1.2 Add `k8s/apps/workloads/demo-api/rollouts/canary.yaml` or the equivalent app-owned Rollouts path outside the default local target.
- [x] 1.3 Add `k8s/apps/workloads/demo-api/rollouts/analysis-template.yaml` or equivalent minimal analysis resource.
- [x] 1.4 Confirm `adopt-targeted-kustomize-composition` keeps Rollouts CRs out of the default `local` target unless CRD-aware validation is added.
- [x] 1.5 Confirm default `make schema` does not validate Rollouts CRs without CRD-aware configuration.

## 2. Scenarios and Workflows

- [x] 2.1 Add `scenarios/good-rollout/`.
- [x] 2.2 Add `scenarios/failing-readiness/`.
- [x] 2.3 Add `scenarios/bad-image/`.
- [x] 2.4 Add `workflows/rollout-demo.garden.yml`.
- [x] 2.5 Add `workflows/failure-demo.garden.yml`.

## 3. Health Gate

- [x] 3.1 Add `validation/health.sh` with readiness/status-only behavior.
- [x] 3.2 Emit structured pass/fail output from the health script.
- [x] 3.3 Document automation-grade vs diagnostic-only signals.
- [x] 3.4 Verify the first demo does not require Prometheus or service mesh traffic shifting.
