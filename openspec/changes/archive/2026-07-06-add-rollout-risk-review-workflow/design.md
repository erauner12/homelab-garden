## Context

`read-only-investigation-report` already defines a non-mutating report with Summary, Environment, GitOps Status, Rollout Status, Workload Status, Health Signals, Events, Logs, and next-action sections. This change should reuse that collector/reporting shape where possible, but change the question: investigation asks "what is happening now?" while risk review asks "is this intended rollout ready to start?"

This change follows `add-release-intent-artifact-identity` and should provide evidence that `add-tenant-wave-simulation` can reference later.

## Goals / Non-Goals

**Goals:**
- Add a pre-rollout mode to the read-only reporting pattern.
- Anchor readiness assessment on release intent and artifact identity.
- Reuse investigation-style evidence collectors for ArgoCD, Rollouts, health, policy, and hcloud lifecycle status where available.
- Make blockers, risks, unknowns, and missing evidence explicit before rollout.

**Non-Goals:**
- Do not build a second incident/runtime investigation report system.
- Do not sync ArgoCD, promote Rollouts, patch workloads, apply manifests, run Terraform, create PRs, or remediate resources.
- Do not score real homelab rollout risk.

## Decisions

- Implement risk review as a mode or extension of the read-only investigation/reporting pattern, sharing collectors and output conventions where practical.
- Keep release intent as the primary input that describes the intended rollout; live/runtime evidence is supporting context.
- Treat missing health-gate v2 output, policy validation result, ArgoCD/Rollouts state, or hcloud lifecycle status as explicit unknowns or blockers rather than silently ignoring them.
- For hcloud mode, require target-guard success before reading cluster or lifecycle evidence.

## Risks / Trade-offs

- Reusing investigation collectors can blur the two workflows → documentation and report headings must distinguish runtime investigation from pre-rollout readiness.
- Reports can look authoritative without enough evidence → require explicit unknowns and evidence provenance.
- Scope can drift into remediation → enforce read-only behavior in requirements and tests.
