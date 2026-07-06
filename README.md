# homelab-garden

Local testing harness for Kubernetes delivery patterns from my homelab.

This repo is intentionally small and public-safe. It is not the real homelab
configuration. It is a lab for testing the important delivery shape locally:

- render Kubernetes desired state with Kustomize
- apply it through Garden against a local kind cluster
- run validation and smoke checks before anything reaches a real GitOps repo
- keep an opt-in disposable ArgoCD path for testing the GitOps reconciliation contract

## What This Tests

The default local workflow tests rendered manifests, Kubernetes schemas, repo contracts, and running components:

```text
Kustomize render -> Kubernetes schema validation -> Go contract validation -> Garden apply -> Kubernetes readiness -> smoke checks
```

Garden is the local harness. Kustomize is the desired-state renderer. ArgoCD is
reserved for opt-in GitOps reconciliation testing.

## Repo Shape

```text
k8s/apps/      app/domain-owned Kubernetes desired state
k8s/targets/   thin target composition indexes over app-owned overlays
policy/         local policy-as-code checks and Kyverno CLI fixtures
release-intents/ public-safe release intent and artifact identity samples
validation/     scripts used by Garden tests
scripts/        local kind cluster helpers
docs/           design notes and validation philosophy
```

## Local Loop

Prerequisites for the local loop:

- `go` for contract tests
- `uv` for demo API Python endpoint tests
- `kind` for the local Kubernetes cluster
- `kubectl` for cluster inspection
- `kustomize` for rendering manifests
- `kubeconform` for Kubernetes schema validation
- `garden` for local workflow orchestration

Optional policy validation also needs `kyverno` CLI.

Check tool availability before running the full loop:

```bash
make doctor
```

Create or reuse the dedicated kind cluster, validate, inspect, and tear down:

```bash
make kind-up
make check
make kind-status
make kind-down
```

The local environment defaults to `kind-homelab-garden`. `make check` runs
the repository validators, Go contract tests, partial Garden config resolution,
and the local Garden validation workflow. Static validation checks that each
Kustomize entrypoint renders. Schema validation pipes the rendered YAML through
`kubeconform -strict -summary`.
Go contract tests check repo-specific labels, layer/path boundaries, expected
namespaces, workload safety, and Service-to-Deployment selectors. The demo API
Python endpoint tests are uv-managed and can be run with `make demo-api-test`.
The workflow
deploys `k8s/apps/platform/foundation/overlays/local` and
`k8s/apps/workloads/demo-api/overlays/local`, while static/schema validation
also renders `k8s/targets/local`. The workflow then smoke-tests the in-cluster
services. The demo API also exposes stable `/healthz`, `/readyz`, `/version`,
`/metrics`, and lab-only simulation endpoints; see
[`docs/demo-api-observability.md`](docs/demo-api-observability.md).

## Release Intent Samples

See [`docs/release-intent.md`](docs/release-intent.md) for the public-safe `demo-api` samples in `release-intents/`.

## Optional Local ArgoCD Reconciliation

The default local loop remains ArgoCD-free. To test GitOps reconciliation behavior, run the separate disposable local exercise after the branch you want ArgoCD to reconcile has been pushed:

```bash
garden workflow local-argocd-reconcile --env local
```

This installs upstream ArgoCD only into the local kind cluster (`kind-homelab-garden` by default), applies a rendered temporary copy of `gitops/app-of-apps.yaml`, waits for `platform-local` and `demo-api-local` to become synced/healthy, and smoke-tests the ArgoCD-reconciled demo API. It never deploys to, configures, syncs, or manages the real homelab ArgoCD installation.

The checked-in ArgoCD Applications use the stable default `targetRevision: main`. At runtime, `platform/addons/argocd/apply-local-apps.sh` patches temporary copies so the applied parent and child Applications use `ARGOCD_REPO_URL` (default: `origin`) and `ARGOCD_TARGET_REVISION` (default: current local branch, falling back to `main`). The repo/branch must be reachable to in-cluster ArgoCD over HTTPS. Uncommitted local changes and unpushed commits are invisible to ArgoCD until pushed to the configured revision.

If the GitHub repo is private, pass credentials only at local runtime. The simplest path is:

```bash
ARGOCD_GITHUB_TOKEN="$(gh auth token)" garden workflow local-argocd-reconcile --env local
```

`GH_TOKEN` is also accepted, and `ARGOCD_GITHUB_USERNAME` can override the username. The repo also supports a SOPS-encrypted local source at `secrets/argocd-repo-creds.sops.yaml`; with `secrets/age/key.txt` present, the workflow decrypts it locally and applies only the live Secret to the disposable kind ArgoCD namespace. For a plaintext local handoff instead, copy `secrets/argocd-repo-creds.yaml.template` to the gitignored `secrets/argocd-repo-creds.local.yaml`, edit in the token locally, then run the same workflow. See `secrets/README.md` for details.

After the workflow is healthy, test self-heal drift manually:

```bash
kubectl --context kind-homelab-garden -n demo scale deploy demo-api --replicas=0
kubectl --context kind-homelab-garden -n argocd get application demo-api-local -w
```

ArgoCD should restore `Deployment/demo-api` to the Git-declared replica count. Prune is intentionally disabled for the first demo app exercise.

See `docs/argocd-plan.md` for source paths, ordering, and limitations.

## Optional Hcloud ArgoCD Self-Heal Validation

After the ephemeral hcloud lab cluster has already been provisioned and `garden workflow hcloud-argocd-reconcile --env hcloud-lab` has succeeded, validate ArgoCD self-heal behavior without running Terraform or reinstalling ArgoCD:

```bash
ARGOCD_GITHUB_TOKEN="$(gh auth token)" garden workflow hcloud-argocd-self-heal --env hcloud-lab
```

The workflow reuses the hcloud kubeconfig/context guard, verifies `app-of-apps-hcloud-lab`, `platform-hcloud-lab`, and `demo-api-hcloud-lab` are Synced/Healthy, scales `deployment/demo-api` in namespace `demo` up by one replica, waits for ArgoCD to restore the reconciled replica count, then runs the existing demo API smoke test. It does not run Terraform apply/destroy, create/delete Hetzner resources, or target the real homelab.

## Optional Hcloud Progressive Delivery Validation

After the ephemeral hcloud lab cluster has already been provisioned and the hcloud ArgoCD baseline is Synced/Healthy, validate Argo Rollouts on hcloud without changing Terraform or replacing the ArgoCD-managed demo Deployment:

```bash
garden workflow hcloud-rollout-demo --env hcloud-lab
```

The workflow reuses the hcloud kubeconfig/context guard, installs Argo Rollouts in the ephemeral cluster, applies a good Rollout scenario in the isolated `hcloud-rollouts-demo` namespace, waits for Rollout health, emits structured health output, smoke-tests the Rollout Service, then re-checks and smoke-tests the ArgoCD-managed `demo-api-hcloud-lab` demo. The hcloud Rollout scenario is intentionally separate from the `demo` namespace so it does not compete with the ArgoCD-managed `Deployment/demo-api`.

Before merge, ArgoCD baseline validation still depends on the configured hcloud Applications being able to fetch their remote `targetRevision`; push the branch or run the baseline from `main` as appropriate. The isolated Rollout scenario itself is applied from the current checkout by Garden.

## Optional Read-only Investigation

Render a Markdown investigation report for `demo-api` without changing cluster state:

```bash
garden workflow investigate-demo --env local
```

The report includes environment, GitOps, rollout, workload, health, event, and log context. ArgoCD and Argo Rollouts are optional; if their CRDs are absent, the report marks them `not_installed` and continues. By default the report is written to stdout. To also save it locally, set `INVESTIGATION_REPORT_PATH`, for example `reports/investigation/$(date -u +%Y%m%dT%H%M%SZ)-demo-api.md`; generated reports are ignored by Git.

## Optional Rollout Risk Review

Render a read-only JSON pre-rollout readiness report from release intent plus optional evidence:

```bash
garden workflow rollout-risk-review --env local
```

Risk review is not incident investigation: investigation gathers runtime context, while risk review assesses whether an intended rollout has enough evidence to start. Missing release intent blocks readiness; missing health, policy, ArgoCD, Rollouts, or hcloud lifecycle evidence is reported as explicit unknowns. See [`docs/rollout-risk-review.md`](docs/rollout-risk-review.md).

## Optional Policy Validation

Run local Kyverno CLI checks separately from the default loop:

```bash
make policy-validate
```

This invokes `garden workflow policy-validate --env local`, which runs the
Garden exec test `policy-validation`, which invokes `validation/policy.sh`
against fixtures in `policy/kyverno/tests`. Kyverno CLI is optional: `make check`
does not install or require Kyverno.

Ownership is split deliberately. Go contract tests own repo-specific rendered
state invariants: labels, layer boundaries, namespace assumptions, Kustomize
structure, and Service-to-Deployment selector matching. Kyverno policies own
admission-style guardrails such as mutable image tags, probes, resource
requirements, and privileged containers when admission parity is the point.

## Public Safety

This repo should never contain real homelab secrets, Terraform state, local
`.env` files, provider credentials, or private domain configuration.
