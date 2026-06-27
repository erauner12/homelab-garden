# homelab-garden

Local testing harness for Kubernetes delivery patterns from my homelab.

This repo is intentionally small and public-safe. It is not the real homelab
configuration. It is a lab for testing the important delivery shape locally:

- render Kubernetes desired state with Kustomize
- apply it through Garden against a local kind cluster
- run validation and smoke checks before anything reaches a real GitOps repo
- keep a future ArgoCD path for testing the GitOps reconciliation contract

## What This Tests

The default local workflow tests the components running in the cluster:

```text
Kustomize render -> Garden apply -> Kubernetes readiness -> smoke checks
```

A future GitOps workflow will test the ArgoCD reconciliation contract:

```text
seed Git source -> ArgoCD app-of-apps -> sync/health -> smoke checks
```

Garden is the local harness. Kustomize is the desired-state renderer. ArgoCD is
not part of the default local validation loop.

## Repo Shape

```text
platform/       local platform resources rendered with Kustomize
apps/           demo workloads rendered with Kustomize
validation/     scripts used by Garden tests
scripts/        local kind cluster helpers
docs/           design notes and validation philosophy
```

## Local Loop

Create or reuse the dedicated kind cluster, run validation, inspect status, and
tear it down when finished:

```bash
make kind-up
make static
garden get config --env local --resolve=partial
make local-validate
make kind-status
make kind-down
```

The local Garden environment defaults to Kubernetes context
`kind-homelab-garden`. The workflow deploys `platform/overlays/local`, deploys
`apps/demo-api/overlays/local`, then smoke-tests the in-cluster service.

## Public Safety

This repo should never contain real homelab secrets, Terraform state, local
`.env` files, provider credentials, or private domain configuration.
