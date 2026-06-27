# homelab-garden

Local testing harness for Kubernetes delivery patterns from my homelab.

This repo is intentionally small and public-safe. It is not the real homelab
configuration. It is a lab for testing the important delivery shape locally:

- render Kubernetes desired state with Kustomize
- apply it through Garden against a local kind cluster
- run validation and smoke checks before anything reaches a real GitOps repo
- keep a future ArgoCD path for testing the GitOps reconciliation contract

## What This Tests

The default local workflow tests rendered repo contracts and running components:

```text
Kustomize render -> contract validation -> Garden apply -> Kubernetes readiness -> smoke checks
```

Garden is the local harness. Kustomize is the desired-state renderer. ArgoCD is
reserved for future GitOps reconciliation testing.

## Repo Shape

```text
platform/       local platform resources rendered with Kustomize
apps/           demo workloads rendered with Kustomize
validation/     scripts used by Garden tests
scripts/        local kind cluster helpers
docs/           design notes and validation philosophy
```

## Local Loop

Create or reuse the dedicated kind cluster, validate, inspect, and tear down:

```bash
make kind-up
make static
make contracts
garden get config --env local --resolve=partial
make local-validate
make kind-status
make kind-down
```

The local environment defaults to `kind-homelab-garden`. Static validation now
checks both YAML rendering and repo contracts for required labels, layer/path
boundaries, expected namespaces, workload safety, and Service-to-Deployment
selectors. The workflow deploys `platform/overlays/local` and
`apps/demo-api/overlays/local`, then smoke-tests the in-cluster service.

## Public Safety

This repo should never contain real homelab secrets, Terraform state, local
`.env` files, provider credentials, or private domain configuration.
