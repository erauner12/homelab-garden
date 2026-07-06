# Rollout Risk Review

Rollout risk review is a read-only pre-rollout readiness assessment. It answers: "does the intended `demo-api` rollout have enough evidence to start?"

This is distinct from investigation. `investigate-demo` gathers runtime or incident context for a running target; `rollout-risk-review` reads release intent plus optional evidence before a rollout starts.

## Run

```bash
garden workflow rollout-risk-review --env local
```

The renderer chooses `hcloud-lab` when `KUBE_CONTEXT`/`KUBECONTEXT` matches the disposable hcloud context; otherwise it defaults to `local`. It then reads that environment's release intent sample and renders JSON to stdout. To save a generated report locally:

```bash
RISK_REVIEW_REPORT_PATH="reports/risk-review/demo-api-local.json" garden workflow rollout-risk-review --env local
```

Generated reports under `reports/risk-review/` are ignored by Git.

## Inputs

The report requires the environment release intent (`release-intents/demo-api-local.json` or `release-intents/demo-api-hcloud-lab.json`). It optionally reads health-gate v2 JSON from `HEALTH_GATE_EVIDENCE_PATH`.

## Report contract

The JSON report records release intent identity, a `pass`/`review`/`block`/`unknown` decision, blockers, risks, unknowns, evidence provenance, and hcloud guard outcome when relevant. Missing release intent or required identity blocks readiness. Health-gate evidence, when provided, can pass, degrade, block, or leave the decision unknown.

## Hcloud guard

For `hcloud-lab`, the report includes the disposable hcloud target guard:

- observed `KUBE_CONTEXT`/`KUBECONTEXT` must match `admin@homelab-garden-hcloud-lab` unless `HCLOUD_LAB_CONTEXT` overrides it

## Safety boundary

Risk review does not apply, delete, patch, scale, sync, promote, abort, roll back, run Terraform apply/destroy, generate PRs, or remediate resources. It is a report-only workflow and must not target the real homelab.
