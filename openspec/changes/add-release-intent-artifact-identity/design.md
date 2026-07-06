## Context

Current workflows operate directly against checked-in desired state and live clusters. Future pre-rollout review and tenant-wave simulations need a neutral way to say "this is the release we intend to evaluate" without making the lab a production deployment system.

## Goals / Non-Goals

**Goals:**
- Define the minimal identity fields needed to connect Git, image, manifest path, environment, and validation evidence.
- Keep intent files public-safe and suitable for local or hcloud lab exercises.
- Provide enough structure for read-only review workflows to reason about a release.

**Non-Goals:**
- Do not create a custom DeliveryPlan CRD, controller, reconciler, or PR generator.
- Do not manage real homelab release promotion.
- Do not require a registry, signing system, SBOM, or provenance service in the first model.

## Decisions

- Use a simple checked-in or generated data file format, such as YAML or JSON, before considering any API server object.
- Treat image digest as preferred when available, but allow an explicit placeholder or documented tag mode for the small lab if digest plumbing is not ready.
- Include references to validation evidence rather than embedding large logs or reports in the intent model.
- Make environment target explicit (`local` or `hcloud-lab`) so consumers do not infer real homelab targets.

## Risks / Trade-offs

- Too much supply-chain modeling can swamp the lab → keep the first model minimal.
- Tags can be mutable → prefer digests and require risk reports to call out tag-only identity.
- Intent files can be mistaken for deployment authority → document that ArgoCD/Garden workflows remain the execution mechanisms and the intent model is an input or report subject.
