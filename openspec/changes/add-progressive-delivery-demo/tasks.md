## 1. Rollouts Addon and Manifests

- [ ] 1.1 Add `platform/addons/argo-rollouts/` resources or installer wrapper.
- [ ] 1.2 Add `apps/demo-api/rollouts/canary.yaml` outside the default app overlay.
- [ ] 1.3 Add `apps/demo-api/rollouts/analysis-template.yaml` or equivalent minimal analysis resource.
- [ ] 1.4 Confirm default `make schema` does not validate Rollouts CRs without CRD-aware configuration.

## 2. Scenarios and Workflows

- [ ] 2.1 Add `scenarios/good-rollout/`.
- [ ] 2.2 Add `scenarios/failing-readiness/`.
- [ ] 2.3 Add `scenarios/bad-image/`.
- [ ] 2.4 Add `workflows/rollout-demo.garden.yml`.
- [ ] 2.5 Add `workflows/failure-demo.garden.yml`.

## 3. Health Gate

- [ ] 3.1 Add `validation/health.sh` with readiness/status-only behavior.
- [ ] 3.2 Emit structured pass/fail output from the health script.
- [ ] 3.3 Document automation-grade vs diagnostic-only signals.
- [ ] 3.4 Verify the first demo does not require Prometheus or service mesh traffic shifting.
