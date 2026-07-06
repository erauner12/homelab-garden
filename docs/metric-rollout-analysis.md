# Metric Rollout Analysis

Metric rollout analysis is a read-only local renderer. It composes existing evidence into a rollout decision; it does not create Rollouts `AnalysisTemplate`/`AnalysisRun` resources, install Prometheus, sync ArgoCD, mutate a cluster, or generate PRs.

## Run

Self-test:

```bash
make metric-rollout-analysis
```

Render JSON from saved evidence:

```bash
HEALTH_GATE_EVIDENCE_PATH=reports/health/demo-api-local.json \
RISK_REVIEW_EVIDENCE_PATH=reports/risk-review/demo-api-local.json \
TENANT_WAVE_EVIDENCE_PATH=reports/tenant-wave/demo-api-local.json \
python3 validation/metric_rollout_analysis.py
```

Render Markdown:

```bash
python3 validation/metric_rollout_analysis.py \
  --health reports/health/demo-api-local.json \
  --risk-review reports/risk-review/demo-api-local.json \
  --tenant-wave reports/tenant-wave/demo-api-local.json \
  --format markdown
```

Save output locally with `METRIC_ROLLOUT_ANALYSIS_REPORT_PATH=reports/metric-rollout/demo-api-local.json`.

## Inputs

Required evidence:

- Health gate v2 JSON from `validation/health.py` (`HEALTH_GATE_EVIDENCE_PATH` or `--health`).
- Rollout risk review JSON from `validation/risk_review.py` (`RISK_REVIEW_EVIDENCE_PATH` or `--risk-review`).
- Tenant wave simulation JSON from `validation/tenant_wave_simulation.py` (`TENANT_WAVE_EVIDENCE_PATH` or `--tenant-wave`).

Optional metric evidence:

- Set `DEMO_API_BASE_URL` to scrape demo API `/metrics` directly.
- If `DEMO_API_BASE_URL` is unset, metric scrape evidence is marked `not_configured` and skipped.
- If `DEMO_API_BASE_URL` is set but `/metrics` is unavailable or missing required metric names, the decision is `unknown`.

## Decision rules

`decision` is one of `pass`, `review`, `block`, or `unknown`.

- Missing health, risk, or wave input => `unknown`.
- Risk review `decision: block` => `block`.
- Tenant wave not eligible => `review` or `block` when the wave is blocked.
- Metric scrape unavailable when configured => `unknown`.
- Only explicit `pass` is automation-safe (`automationSafe: true`).

## Output

The report includes:

- `decision` and `automationSafe`.
- `reasonCodes` for unknown/review/block causes.
- `metricEvidence` from optional `/metrics` scraping.
- `waveContext` with eligible tenant context.
- `safety` flags documenting that the renderer is read-only and local.

## Hcloud boundary

Hcloud may appear in input evidence as diagnostic context from the existing guarded workflows. This analyzer does not read cloud credentials, run Terraform/OpenTofu, call Kubernetes, sync ArgoCD, or mutate hcloud resources.
