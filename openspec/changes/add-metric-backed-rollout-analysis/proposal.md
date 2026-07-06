## Why

The lab already has separate read-only health, risk, and tenant-wave evidence. It needs one local analyzer that composes those artifacts, optionally reads demo API `/metrics`, and renders a rollout decision without adding cluster-side analysis resources or mutation paths.

## What Changes

- Add a read-only local metric rollout analysis renderer.
- Consume health gate v2 JSON, rollout risk review JSON, and tenant wave simulation JSON.
- Optionally scrape demo API `/metrics` only when `DEMO_API_BASE_URL` is set.
- Output JSON or Markdown with `decision: pass | review | block | unknown`, metric evidence, wave context, and reason codes.
- Keep defaults local, diagnostic, and read-only.

## Capabilities

### New Capabilities
- `metric-backed-rollout-analysis`: Defines local report-only rollout analysis backed by existing evidence artifacts and optional demo API metrics.

### Modified Capabilities

## Impact

- Adds a focused Python renderer, a self-test Make target, optional Garden workflow wiring, and usage docs.
- Does not add Prometheus, Rollouts `AnalysisTemplate`/`AnalysisRun`, ArgoCD sync, cluster mutation, cloud mutation, or PR generation.
- Hcloud references are diagnostic context only when present in existing input evidence.
