## Context

The current delivery lab has three read-only evidence producers: health gate v2, rollout risk review, and tenant wave simulation. The requested metric-backed rollout analysis is not an Argo Rollouts AnalysisRun implementation; it is a local report renderer that combines these artifacts with optional demo API `/metrics` evidence.

## Goals / Non-Goals

**Goals:**
- Render a local read-only rollout analysis decision: `pass`, `review`, `block`, or `unknown`.
- Require health gate v2 JSON, rollout risk review JSON, and tenant wave simulation JSON as inputs.
- Optionally scrape demo API `/metrics` when `DEMO_API_BASE_URL` is set.
- Include metric evidence, wave context, and reason codes in JSON or Markdown output.
- Make only explicit `pass` automation-safe.

**Non-Goals:**
- Do not add Prometheus or require a metrics server.
- Do not add Rollouts `AnalysisTemplate` or `AnalysisRun` resources.
- Do not sync ArgoCD, apply manifests, patch/scale/promote/abort Rollouts, generate PRs, or mutate clusters/cloud resources.
- Do not make hcloud more than diagnostic context from existing guarded evidence.

## Decisions

- Implement a focused Python renderer in `validation/metric_rollout_analysis.py` following existing validation renderers.
- Accept evidence paths by CLI flags and environment variables.
- Treat missing health/risk/wave input as `unknown`.
- Treat risk review `block` as `block`.
- Treat tenant wave non-eligibility as `review` unless the wave is blocked, then `block`.
- Treat configured-but-unavailable metric scraping as `unknown`.
- Keep the analyzer out of `make check`; expose a dedicated self-test target.

## Risks / Trade-offs

- Saved evidence can be stale, so output includes evidence paths and reason codes for review.
- Optional direct metric scraping can be unavailable, so configured scrape failures produce `unknown` rather than pass.
- The analyzer is intentionally advisory; downstream automation must only continue on explicit `pass`.
