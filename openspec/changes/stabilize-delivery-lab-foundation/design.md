## Context

`homelab-garden` already has a fast local loop: Make calls validation scripts and Garden workflows; Garden applies Kustomize overlays to kind; validation covers rendering, schemas, Go contracts, readiness, and smoke tests. Existing docs already state that ArgoCD is intentionally outside the default loop.

## Goals / Non-Goals

**Goals:**
- Preserve `make check` and `local-validate` as the fast ArgoCD-free path.
- Make the delivery/CD lab north-star visible without adding infrastructure.
- Keep `homelab-k8s` as a reference source, not an imported dependency.

**Non-Goals:**
- Install ArgoCD, Kyverno, Rollouts, Prometheus, or ops-agent tooling.
- Add tenant rollout tooling.
- Create detailed interview story docs before commands exist.

## Decisions

- Treat `make check` immutability as a hard invariant: it remains free of ArgoCD, Rollouts, Prometheus, and agent requirements.
- Add roadmap/architecture docs only where they explain executable boundaries and commands.
- Add a lightweight `docs/interview/topic-map.md` only if it maps current or planned commands to interview topics without pretending unfinished workflows already exist.

## Risks / Trade-offs

- Aspirational docs can drift from implementation → keep first docs short and command-grounded.
- Later changes may pressure `make check` to run everything → preserve the invariant in specs and tasks.
