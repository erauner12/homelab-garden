## 1. Documentation Boundary

- [ ] 1.1 Update README to describe the delivery/CD lab boundary and current executable loop.
- [ ] 1.2 Add `docs/homelab-roadmap.md` with the north-star flow and milestone boundaries.
- [ ] 1.3 Add `docs/architecture/delivery-control-plane.md` with layer responsibilities and non-goals.
- [ ] 1.4 Add a lightweight `docs/interview/topic-map.md` only if it stays command-grounded.

## 2. Validation Invariant

- [ ] 2.1 Verify `make check` remains ArgoCD-free, Rollouts-free, Prometheus-free, and agent-free.
- [ ] 2.2 Document that later workflows are optional exercises, not default-loop dependencies.
- [ ] 2.3 Run `make doctor`, `make static`, `make schema`, and `make contracts` after doc updates.
