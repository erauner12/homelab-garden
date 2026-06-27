# homelab-garden

Local testing harness for Kubernetes delivery patterns from my homelab.

This repo is intentionally small and public-safe. It is not the real homelab
configuration. It is a lab for testing the important delivery shape locally:

- render Kubernetes desired state with Kustomize
- apply it through Garden against a local cluster
- run validation and smoke checks before anything reaches a real GitOps repo
- keep an optional ArgoCD path for testing the GitOps reconciliation contract

## What This Tests

The default workflow tests the components running in the cluster:

```text
Kustomize render -> Garden apply -> Kubernetes readiness -> smoke checks
```

The optional GitOps workflow will test the ArgoCD contract:

```text
seed Git source -> ArgoCD app-of-apps -> sync/health -> smoke checks
```

Garden is the local harness. Kustomize is the desired-state renderer. ArgoCD is
only included when the thing under test is GitOps reconciliation behavior.

## Repo Shape

```text
platform/       local platform resources rendered with Kustomize
apps/           demo workloads rendered with Kustomize
validation/     scripts used by Garden tests
docs/           design notes and validation philosophy
```

## First Commands

Create or select a local Kubernetes cluster, then run:

```bash
garden get config --env local --resolve=partial
garden deploy platform --env local
garden deploy demo-api --env local
garden test static-validation --env local
garden test smoke-demo-api --env local
```

The initial skeleton assumes you provide the local cluster. A future workflow can
own Kind or Talos lifecycle directly.

## Public Safety

This repo should never contain real homelab secrets, Terraform state, local
`.env` files, provider credentials, or private domain configuration.
