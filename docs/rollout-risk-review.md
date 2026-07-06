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

The report requires the environment release intent (`release-intents/demo-api-local.json` or `release-intents/demo-api-hcloud-lab.json`) and can read optional evidence paths from environment variables:

| Variable | Evidence |
| --- | --- |
| `HEALTH_GATE_EVIDENCE_PATH` | health-gate v2 JSON from `validation/health.sh` |
| `POLICY_EVIDENCE_PATH` | policy validation result |
| `ARGOCD_EVIDENCE_PATH` | read-only ArgoCD state |
| `ROLLOUTS_EVIDENCE_PATH` | read-only Argo Rollouts state |
| `HCLOUD_EVIDENCE_PATH` | hcloud lifecycle evidence for `hcloud-lab` only |

## Report contract

The JSON report records release intent identity, a `pass`/`review`/`block`/`unknown` decision, blockers, risks, unknowns, evidence provenance, and hcloud guard outcome when relevant. Missing release intent or required identity blocks readiness; missing health, policy, ArgoCD, Rollouts, or hcloud lifecycle evidence is explicit `unknown` unless a blocker or risk takes precedence.

## Hcloud guard

For `hcloud-lab`, hcloud lifecycle evidence is optional and read-only. If `HCLOUD_EVIDENCE_PATH` is set, the renderer verifies the disposable hcloud target guard before reading that evidence:

- observed `KUBE_CONTEXT`/`KUBECONTEXT` must match `admin@homelab-garden-hcloud-lab` unless `HCLOUD_LAB_CONTEXT` overrides it

A failed hcloud guard blocks the report from claiming readiness and the hcloud evidence is not read.

## Safety boundary

Risk review does not apply, delete, patch, scale, sync, promote, abort, roll back, run Terraform apply/destroy, generate PRs, or remediate resources. It is a report-only workflow and must not target the real homelab.
