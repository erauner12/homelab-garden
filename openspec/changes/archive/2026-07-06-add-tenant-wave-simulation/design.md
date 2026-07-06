## Context

Tenant delivery is useful for interview and roadmap storytelling, but building a real planner or controller would overfit the lab. The smallest useful next step is a deterministic simulation over three tenants and waves that can render expected actions and blockers.

This change depends on `add-release-intent-artifact-identity` for the release being simulated. It should consume `add-rollout-risk-review-workflow` output only as optional gate evidence after that report exists.

## Goals / Non-Goals

**Goals:**
- Model exactly a small set of sample tenants, starting with three.
- Represent desired release identity, wave order, per-tenant status, and stop conditions.
- Optionally reference pre-rollout risk review output as gate evidence.
- Produce a simulation report showing intended sequence and gates.
- Stay separate from PR generation and cluster mutation.

**Non-Goals:**
- Do not build a custom DeliveryPlan CRD, controller, reconciler, or PR generator.
- Do not deploy per-tenant workloads unless a later implementation spec promotes a specific exercise.
- Do not model production tenancy, private customer data, or real homelab tenants.

## Decisions

- Use static sample data files for tenants and waves so the behavior is reviewable in Git.
- Use release intent to identify the artifact being simulated, rather than inventing a second release identity model.
- Treat rollout risk review output as optional gate evidence; missing risk evidence should render as unknown, not block the simulation tool from producing output.
- Keep wave policy simple: ordered waves, per-tenant gate status, and stop-on-blocker semantics.
- Render simulation output as Markdown or structured JSON for later review integration.

## Risks / Trade-offs

- Simulation can be mistaken for deployment automation → clearly label it as non-mutating and non-authoritative.
- Tenant model can grow quickly → cap the first exercise at three tenants and simple wave fields.
- Without real cluster state or risk evidence, results are hypothetical → require unknowns to be explicit.
