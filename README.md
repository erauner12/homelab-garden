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
validation/     scripts used by Garden tests
scripts/        local kind cluster helpers
docs/           design notes and validation philosophy
```

## Local Loop

Prerequisites for the local loop:

- `go` for contract tests
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
static render validation, Kubernetes schema validation, Go contract tests,
partial Garden config resolution, and the local Garden validation workflow.
Static validation checks that each Kustomize entrypoint renders. Schema validation pipes the rendered YAML through `kubeconform -strict -summary`.
Go contract tests check repo-specific labels, layer/path boundaries, expected
namespaces, workload safety, and Service-to-Deployment selectors. The workflow
deploys `k8s/apps/platform/foundation/overlays/local` and
`k8s/apps/workloads/demo-api/overlays/local`, while static/schema validation
also renders `k8s/targets/local`. The workflow then smoke-tests the in-cluster
services.

## Optional Local ArgoCD Reconciliation

The default local loop remains ArgoCD-free. To test GitOps reconciliation behavior, run the separate disposable local exercise after the branch you want ArgoCD to reconcile has been pushed:

```bash
garden workflow local-argocd-reconcile --env local
```

This installs upstream ArgoCD only into the local kind cluster (`kind-homelab-garden` by default), applies a rendered temporary copy of `gitops/app-of-apps.yaml`, waits for `platform-local` and `demo-api-local` to become synced/healthy, and smoke-tests the ArgoCD-reconciled demo API. It never deploys to, configures, syncs, or manages the real homelab ArgoCD installation.

The checked-in ArgoCD Applications use the stable default `targetRevision: main`. At runtime, `platform/addons/argocd/apply-local-apps.sh` patches temporary copies so the applied parent and child Applications use `ARGOCD_REPO_URL` (default: `origin`) and `ARGOCD_TARGET_REVISION` (default: current local branch, falling back to `main`). The repo/branch must be reachable to in-cluster ArgoCD over HTTPS; this first version does not configure private repository credentials. Uncommitted local changes and unpushed commits are invisible to ArgoCD until pushed to the configured revision.

After the workflow is healthy, test self-heal drift manually:

```bash
kubectl --context kind-homelab-garden -n demo scale deploy demo-api --replicas=0
kubectl --context kind-homelab-garden -n argocd get application demo-api-local -w
```

ArgoCD should restore `Deployment/demo-api` to the Git-declared replica count. Prune is intentionally disabled for the first demo app exercise.

See `docs/argocd-plan.md` for source paths, ordering, and limitations.

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
