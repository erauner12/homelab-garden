# Release Intent and Artifact Identity

Release intent is a small, file-based description of the demo API release a lab workflow wants to review. It is not a Kubernetes API, not a custom resource, and not deployment authority. Garden, Kustomize, and the optional ArgoCD exercises remain the mechanisms that render, apply, or reconcile resources.

## Files

Samples live in `release-intents/*.json` and are validated by:

```bash
make release-intent
```

The checked-in samples are public-safe:

- `release-intents/demo-api-local.json` targets the local kind lab.
- `release-intents/demo-api-hcloud-lab.json` targets only the disposable `hcloud-lab` path and contains no provider credentials, kubeconfig, private domains, or real homelab targets.

## Minimal model

Each intent document uses `schemaVersion: homelab-garden.release-intent/v1alpha1` and `kind: ReleaseIntent` with these required fields:

| Field | Meaning |
| --- | --- |
| `metadata.name` | Human-readable sample name. |
| `app.id` | Application identifier; currently `demo-api`. |
| `environment` | Explicit target: `local` or `hcloud-lab` only. |
| `git.revision` | Git revision or symbolic lab revision to review. |
| `manifest.path` | Repository-relative Kustomize target or overlay path. |
| `image.reference` | Image reference for the deployable artifact. |
| `image.identityMode` | `digest` when immutable, `tag` when the lab only has a tag. |
| `validationEvidence[]` | References to commands, paths, URIs, or summary IDs; large reports stay outside the intent file. |
| `authority` | Must state that the file is non-authoritative, does not mutate clusters, and does not create PRs. |

## Artifact identity

Use `image.identityMode: digest` when `image.reference` includes an immutable `@sha256:` digest. Use `image.identityMode: tag` only as an explicit fallback and include `image.risk` so downstream reports can call out mutable tag risk instead of treating the image as fully pinned.

## Read-only consumers

Future rollout risk review should read release intent as pre-rollout context: intended environment, Git revision, manifest path, image identity certainty, and validation evidence provenance. Missing release intent or missing required identity fields should become blockers or unknowns in the report, not an excuse to claim readiness.

Future tenant-wave simulation should reference the same release intent as the release being simulated across sample tenants. It should not generate PRs, edit desired state, sync ArgoCD, promote Rollouts, or mutate clusters; it only uses the release identity and optional risk-review evidence to explain wave order and stop conditions.

## Safety boundary

Release intent files must not reference the real homelab cluster, production-only state, private domains, provider credentials, kubeconfigs, or secrets. The validator rejects required-field omissions, unsupported environments, digest/tag identity mismatches, deployment-authority flags, and obvious real-homelab or credential-like references.
