## 1. Model Definition

- [x] 1.1 Define the minimal release intent fields for app, environment, Git revision, manifest path, image identity, and validation evidence references.
- [x] 1.2 Define artifact identity handling for immutable digests and tag-only fallback.
- [x] 1.3 Document that release intent is non-authoritative and not a custom CRD/controller.

## 2. Samples and Validation

- [x] 2.1 Add public-safe local sample release intent for the demo API.
- [x] 2.2 Add disposable hcloud sample release intent only if hcloud lab inputs are explicit and non-secret.
- [x] 2.3 Add validation for required fields and forbidden real-homelab references.

## 3. Consumers

- [x] 3.1 Document how rollout risk review will consume release intent.
- [x] 3.2 Document how tenant-wave simulation will reference release intent without generating PRs.
- [x] 3.3 Verify no workflow treats release intent as deployment authority.
