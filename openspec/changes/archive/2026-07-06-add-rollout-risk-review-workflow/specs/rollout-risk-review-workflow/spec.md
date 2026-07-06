## ADDED Requirements

### Requirement: Risk review reuses the read-only investigation pattern
The rollout risk review SHALL be implemented as a pre-rollout mode or extension of the existing read-only investigation/reporting pattern rather than a separate mutating workflow.

#### Scenario: Risk review report is rendered
- **WHEN** the risk review mode renders a report
- **THEN** it SHALL reuse investigation-style evidence and report conventions where applicable while labeling the output as pre-rollout readiness assessment.

### Requirement: Risk review and investigation purposes are distinct
The system SHALL distinguish runtime investigation from pre-rollout risk review.

#### Scenario: User reads report documentation
- **WHEN** documentation describes investigation and risk review
- **THEN** it SHALL state that investigation gathers runtime or incident context, while risk review assesses readiness before an intended rollout starts.

### Requirement: Risk review consumes release intent and evidence inputs
The rollout risk review SHALL consume release intent and optional health-gate v2 evidence for readiness assessment.

#### Scenario: Evidence is available
- **WHEN** release intent or health-gate v2 output is available
- **THEN** the report SHALL include the evidence source, availability, and how it affects blockers, risks, or unknowns.

#### Scenario: Required release intent is missing
- **WHEN** release intent or required artifact identity fields are missing
- **THEN** the report SHALL mark the missing inputs as blockers or unknowns and SHALL NOT claim the rollout is ready.

### Requirement: Risk review remains read-only
The rollout risk review mode SHALL NOT mutate Git, cluster, ArgoCD, Rollouts, Terraform, or hcloud resources.

#### Scenario: Risk review runs
- **WHEN** a developer runs risk review
- **THEN** it SHALL NOT apply, delete, patch, scale, sync, promote, abort, roll back, run Terraform apply/destroy, create PRs, or remediate resources.

### Requirement: Hcloud risk review evidence is guarded
Risk review against hcloud SHALL verify the disposable `hcloud-lab` target before claiming readiness.

#### Scenario: Hcloud risk review checks readiness
- **WHEN** risk review runs with `--env hcloud-lab`
- **THEN** it SHALL verify the hcloud target guard before reporting the review as ready.
