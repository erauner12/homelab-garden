## 1. Demo API Contract

- [x] 1.1 Add documented health and readiness endpoint behavior for the demo API.
- [x] 1.2 Add documented metrics output for request, error, latency, and simulation-state signals.
- [x] 1.3 Add bounded healthy, degraded, failing, and latency simulation modes.
- [x] 1.4 Add reset behavior for any mutable simulation state.

## 2. Kubernetes and Validation Integration

- [x] 2.1 Wire probes or smoke checks to the stable health/readiness endpoints where appropriate.
- [x] 2.2 Keep the metrics endpoint usable without installing Prometheus.
- [x] 2.3 Document which signals future health gates may treat as automation-grade.
- [x] 2.4 Verify the default local validation loop does not require hcloud credentials or real homelab resources.

## 3. Verification

- [x] 3.1 Test healthy endpoint responses in the local kind path.
- [x] 3.2 Test each simulation mode and reset behavior.
- [x] 3.3 Confirm observability output contains no secrets, real homelab identifiers, private domains, or provider state.
