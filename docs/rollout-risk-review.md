# Rollout Risk Review

Rollout risk review is a read-only pre-rollout readiness assessment. It answers: "does the intended `demo-api` rollout have enough evidence to start?"

This is distinct from investigation. `investigate-demo` gathers runtime or incident context for a running target; `rollout-risk-review` reads release intent plus optional evidence before a rollout starts.

## Run

```bash
garden workflow rollout-risk-review --env local
```

The workflow reads the environment's release intent sample and renders JSON to stdout. To save a generated report locally:

```bash
RISK_REVIEW_REPORT_PATH="reports/risk-review/demo-api-local.json" garden workflow rollout-risk-review --env local
```

Generated reports under `reports/risk-review/` are ignored by Git.

## Inputs

Required:

- release intent (`release-intents/demo-api-local.json` or `release-intents/demo-api-hcloud-lab.json`)

Optional evidence paths can be supplied through environment variables:

| Variable | Evidence |
| --- | --- |
| `HEALTH_GATE_EVIDENCE_PATH` | health-gate v2 JSON from `validation/health.sh` |
| `POLICY_EVIDENCE_PATH` | policy validation result |
| `ARGOCD_EVIDENCE_PATH` | read-only ArgoCD state |
| `ROLLOUTS_EVIDENCE_PATH` | read-only Argo Rollouts state |
| `HCLOUD_EVIDENCE_PATH` | hcloud lifecycle evidence for `hcloud-lab` only |

## Report contract

The JSON report includes:

- intended app, environment, Git revision, manifest path, and image identity from release intent
- decision: `pass`, `review`, `block`, or `unknown`
- blockers, risks, and unknowns with stable reason codes
- evidence provenance with source path, availability, freshness when available, and effect on the decision
- hcloud target-guard outcome when relevant
- read-only safety metadata listing forbidden actions

Decision meanings:

| Decision | Meaning |
| --- | --- |
| `pass` | Release intent and supplied evidence have no blockers, risks, or unknowns. |
| `review` | Human review is required because at least one risk is present, such as tag-only image identity. |
| `block` | Do not start the rollout because required input or a guard failed. |
| `unknown` | Do not claim ready because evidence is missing or unavailable. |

Missing release intent or missing required release identity fields are blockers and cannot produce `pass`. Missing health, policy, ArgoCD, Rollouts, or hcloud lifecycle evidence is explicit `unknown` unless another blocker or risk takes precedence.

## Hcloud guard

For `hcloud-lab`, hcloud lifecycle evidence is optional and read-only. If `HCLOUD_EVIDENCE_PATH` is set, the renderer verifies the disposable hcloud target guard before reading that evidence:

- observed `KUBE_CONTEXT`/`KUBECONTEXT` must match `admin@homelab-garden-hcloud-lab` unless `HCLOUD_LAB_CONTEXT` overrides it
- if `KUBECONFIG` is set, it must resolve to `infra/hcloud-lab/generated/kubeconfig`
- composite or multiline kubeconfigs are rejected

A failed hcloud guard blocks the report from claiming readiness and the hcloud evidence is not read.

## Safety boundary

Risk review does not apply, delete, patch, scale, sync, promote, abort, roll back, run Terraform apply/destroy, generate PRs, or remediate resources. It is a report-only workflow and must not target the real homelab.
