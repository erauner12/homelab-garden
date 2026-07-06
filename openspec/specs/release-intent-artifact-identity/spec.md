# release-intent-artifact-identity Specification

## Purpose

Define a minimal, file-based release intent and artifact identity model for public-safe delivery-lab workflows. The model gives read-only consumers enough context to connect app, environment, Git revision, manifest path, image identity, and validation evidence without becoming deployment authority.

## Requirements

### Requirement: Release intent identifies the intended change
The release intent model SHALL identify the intended demo API release without requiring a Kubernetes custom resource.

#### Scenario: Release intent is authored
- **WHEN** a release intent document is created for the demo API
- **THEN** it SHALL include the intended environment, Git revision, manifest path or overlay, and application identifier.

### Requirement: Artifact identity is explicit
The artifact identity model SHALL identify deployable artifacts with stable fields suitable for risk review and lab validation.

#### Scenario: Artifact identity is inspected
- **WHEN** a workflow reads artifact identity
- **THEN** it SHALL find an image reference and SHOULD prefer an immutable digest when available, with tag-only identity clearly represented as less certain.

### Requirement: Validation evidence can be referenced
The release intent model SHALL allow validation evidence references without embedding large reports.

#### Scenario: Validation evidence exists
- **WHEN** local validation, health-gate, rollout, or hcloud validation evidence is available
- **THEN** the release intent SHALL be able to reference the evidence path, URI, or summary identifier.

### Requirement: Release intent remains non-authoritative
The release intent model SHALL NOT reconcile, mutate, promote, or deploy resources by itself.

#### Scenario: Release intent is consumed
- **WHEN** a workflow reads release intent
- **THEN** the workflow SHALL treat it as input or report context and SHALL NOT require a custom DeliveryPlan CRD, controller, or reconciler.

### Requirement: Real homelab target is excluded
Release intent examples for this lab SHALL target only local or disposable hcloud lab environments.

#### Scenario: Example release intent is reviewed
- **WHEN** a sample or fixture release intent is checked in
- **THEN** it SHALL NOT reference the real homelab cluster, private domains, provider credentials, or production-only state.
