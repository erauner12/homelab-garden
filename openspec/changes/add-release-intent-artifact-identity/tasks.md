## 1. Model Definition

- [ ] 1.1 Define the minimal release intent fields for app, environment, Git revision, manifest path, image identity, and validation evidence references.
- [ ] 1.2 Define artifact identity handling for immutable digests and tag-only fallback.
- [ ] 1.3 Document that release intent is non-authoritative and not a custom CRD/controller.

## 2. Samples and Validation

- [ ] 2.1 Add public-safe local sample release intent for the demo API.
- [ ] 2.2 Add disposable hcloud sample release intent only if hcloud lab inputs are explicit and non-secret.
- [ ] 2.3 Add validation for required fields and forbidden real-homelab references.

## 3. Consumers

- [ ] 3.1 Document how rollout risk review will consume release intent.
- [ ] 3.2 Document how tenant-wave simulation will reference release intent without generating PRs.
- [ ] 3.3 Verify no workflow treats release intent as deployment authority.
