# progressive-delivery Specification

## Purpose

Define the optional local progressive delivery exercise for the demo API. This capability proves successful and failed Argo Rollouts behavior without making Rollouts part of the default validation path.

## Requirements

### Requirement: Successful progressive rollout demo
The system SHALL provide a `rollout-demo` workflow that demonstrates a successful progressive rollout for the demo API.

#### Scenario: Developer runs rollout demo
- **WHEN** a developer runs the rollout demo workflow
- **THEN** the workflow SHALL deploy or reconcile the demo Rollout and show successful progression using the configured minimal analysis path.

### Requirement: Failed rollout demo
The system SHALL provide a `failure-demo` workflow that demonstrates failed rollout detection and pause, abort, or rollback behavior.

#### Scenario: Developer runs failure demo
- **WHEN** a developer runs the failure demo workflow
- **THEN** the workflow SHALL apply a controlled bad scenario and show that rollout progression stops or recovers according to the documented behavior.

### Requirement: No service mesh required first
The first progressive delivery demo SHALL NOT require service mesh or ingress traffic shifting.

#### Scenario: Cluster lacks service mesh
- **WHEN** the local kind cluster has no service mesh installed
- **THEN** the first rollout and failure demos SHALL still be executable.

### Requirement: Rollouts CRs stay out of default schema path
Argo Rollouts custom resources SHALL NOT be added to the default local schema validation path unless CRD-aware schema validation is added in the same change.

#### Scenario: Developer runs make schema
- **WHEN** a developer runs the default schema validation
- **THEN** validation SHALL not fail because Rollouts CRDs are absent from kubeconform schema configuration.
