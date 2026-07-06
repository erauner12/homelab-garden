# Tenant Wave Simulation

Tenant wave simulation is a read-only, non-authoritative report for discussing staged delivery across exactly three public-safe sample tenants. It does not generate PRs, apply manifests, patch clusters, sync ArgoCD, promote Rollouts, run Terraform, create hcloud resources, or reconcile a custom resource.

## Run

```bash
make tenant-wave-simulation
python3 validation/tenant_wave_simulation.py
```

The script emits structured JSON to stdout. To save a generated report locally:

```bash
TENANT_WAVE_SIMULATION_REPORT_PATH="reports/tenant-wave/demo-api-local.json" python3 validation/tenant_wave_simulation.py
```

Generated reports are local artifacts only; do not treat them as deployment authority.

## Inputs

The simulation consumes release intent as the simulated release input. By default it reads `release-intents/demo-api-local.json`; pass `--intent` or set `RELEASE_INTENT_PATH` to use a different checked-in sample. The output references the app, environment, Git revision, manifest path, and image identity from release intent.

Rollout risk review evidence is optional. Pass `--risk-review` or set `RISK_REVIEW_EVIDENCE_PATH` to a rollout risk review JSON report. Missing risk review evidence is reported as an explicit unknown but still produces output.

## Sample tenants and waves

The first simulation is deliberately tiny and public-safe:

| Wave | Tenant | Meaning |
| --- | --- | --- |
| 1 | `sample-canary` | first sample tenant |
| 2 | `sample-neighborhood` | second sample tenant |
| 3 | `sample-community` | third sample tenant |

These are not customer names, private homelab tenants, provider accounts, or production targets.

## Gate behavior

Release intent, artifact identity, and optional risk-review evidence set shared gates; tenant entries then show whether each wave is eligible, held, blocked, or waiting on review.

## Hcloud boundary

If the hcloud release intent is used, it remains only an explicit disposable `hcloud-lab` simulation context. The simulator does not read provider credentials, run Terraform/OpenTofu, use kubeconfigs, or mutate Hetzner/hcloud resources.

## No controller or CRD

The wave model lives in the report renderer and docs. It is not a `DeliveryPlan` CRD, controller, reconciler, or cluster-side planner.
