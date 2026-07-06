## 1. V2 Decision Envelope

- [x] 1.1 Add the v2 final decision enum with `pass`, `fail`, `degraded`, and `unknown` semantics.
- [x] 1.2 Define a small stable reason-code vocabulary for non-pass decisions.
- [x] 1.3 Define evidence record fields for source, signal, observed value or summary, classification, and decision contribution.

## 2. Environment and Guard Evidence

- [x] 2.1 Add environment identity to v2 output for local and `hcloud-lab` runs.
- [x] 2.2 Record target-guard outcome as structured evidence.
- [x] 2.3 Fail closed with a non-pass decision when hcloud target identity cannot be verified.

## 3. Demo API Observability Integration

- [x] 3.1 Integrate demo API health, readiness, metrics, and simulation state after `add-demo-api-observability-surface` is implemented.
- [ ] 3.2 Add fixtures for pass, fail, degraded, unknown, and ambiguous-target decisions.
- [x] 3.3 Document that only `decision: pass` is safe for automated progression.

## 4. Downstream Consumers

- [ ] 4.1 Document how metric-backed rollout analysis will consume v2 health decisions.
- [ ] 4.2 Document how rollout risk review will display v2 decisions, reason codes, and evidence.
