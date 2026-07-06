## 1. Demo API Contract

- [ ] 1.1 Add documented health and readiness endpoint behavior for the demo API.
- [ ] 1.2 Add documented metrics output for request, error, latency, and simulation-state signals.
- [ ] 1.3 Add bounded healthy, degraded, failing, and latency simulation modes.
- [ ] 1.4 Add reset behavior for any mutable simulation state.

## 2. Kubernetes and Validation Integration

- [ ] 2.1 Wire probes or smoke checks to the stable health/readiness endpoints where appropriate.
- [ ] 2.2 Keep the metrics endpoint usable without installing Prometheus.
- [ ] 2.3 Document which signals future health gates may treat as automation-grade.
- [ ] 2.4 Verify the default local validation loop does not require hcloud credentials or real homelab resources.

## 3. Verification

- [ ] 3.1 Test healthy endpoint responses in the local kind path.
- [ ] 3.2 Test each simulation mode and reset behavior.
- [ ] 3.3 Confirm observability output contains no secrets, real homelab identifiers, private domains, or provider state.
