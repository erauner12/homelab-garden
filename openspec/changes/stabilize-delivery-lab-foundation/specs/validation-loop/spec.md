## ADDED Requirements

### Requirement: Default validation loop remains controller-free
The default local validation path SHALL remain executable without ArgoCD, Argo Rollouts, Prometheus, or ops-agent tooling.

#### Scenario: Developer runs make check
- **WHEN** a developer runs `make check`
- **THEN** the command SHALL validate the local Kustomize/Garden path without installing or requiring ArgoCD, Argo Rollouts, Prometheus, or ops-agent tooling.

### Requirement: Local validation answers component-readiness questions
The `local-validate` workflow SHALL continue to answer whether Kustomize entrypoints render, schemas pass, repo contracts pass, Garden can apply the platform and demo app, and readiness and smoke checks pass.

#### Scenario: Developer runs local validate
- **WHEN** a developer runs `garden workflow local-validate --env local`
- **THEN** the workflow SHALL run static validation, schema validation, contract validation, platform deploy, demo app deploy, and demo app smoke checks.
