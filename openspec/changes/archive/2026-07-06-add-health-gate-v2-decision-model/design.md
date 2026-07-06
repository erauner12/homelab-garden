## Context

The current health-gate spec already covers Kubernetes-native checks, structured output, signal classes, and the ordering constraint that app metrics precede Prometheus. This change should not restate those generic requirements. It adds the v2 fields and semantics needed by local/hcloud automation, rollout analysis, and pre-rollout risk review.

This change follows `add-demo-api-observability-surface` and precedes `add-metric-backed-rollout-analysis`.

## Goals / Non-Goals

**Goals:**
- Define a final decision enum such as `pass`, `fail`, `degraded`, and `unknown`.
- Define reason codes and evidence records that explain each decision.
- Include environment identity and target-guard outcome so local and hcloud results are not ambiguous.
- Incorporate demo API observability inputs when available.

**Non-Goals:**
- Do not reclassify every existing signal or rewrite the first health-gate contract.
- Do not install Prometheus or require Argo Rollouts metrics analysis.
- Do not mutate workloads, sync ArgoCD, promote Rollouts, or remediate failures from the health gate.

## Decisions

- Keep v2 as an additive output shape under `rollout-health-gates` rather than a new capability or parallel script.
- Treat `pass` as the only automatically promotable decision; `fail`, `degraded`, and `unknown` require human review or explicit workflow handling.
- Require every non-pass decision to include at least one reason code and evidence record.
- Include target guard outcome as structured evidence so hcloud workflows can fail closed before trusting health data.
- Represent demo API health, readiness, metrics, and simulation mode as evidence inputs, not as hidden script side effects.

## Risks / Trade-offs

- Too many reason codes can make consumers brittle → start with a small stable vocabulary and allow additional diagnostic details separately.
- `degraded` can be misused as pass → explicitly state that only `pass` is safe for automated progression.
- Hcloud and local evidence can diverge → keep a shared decision schema with environment-specific evidence fields.
