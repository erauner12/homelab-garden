## ADDED Requirements

### Requirement: Existing hcloud status reports age and lifetime hints
The existing hcloud status or inventory path SHALL include age and intended-lifetime hints for disposable lab resources when that information is available.

#### Scenario: Developer checks active hcloud lab status
- **WHEN** a developer runs the existing hcloud status path for an active lab
- **THEN** it SHALL report resource age or creation-time evidence, compare it with the documented intended lifetime, and show a teardown reminder when the lab may be stale.

### Requirement: Existing hcloud status reports rough cost and resource-class hints
The existing hcloud status or inventory path SHALL surface rough cost and resource-class hints for expected disposable lab resources.

#### Scenario: Status finds expected lab resources
- **WHEN** status or inventory finds expected hcloud servers, load balancers, networks, or related resources
- **THEN** it SHALL report their resource classes and rough cost hints, clearly marked as estimates or guidance.

### Requirement: Hcloud lifecycle scripts fail closed on ambiguous target identity
Existing hcloud lifecycle and validation scripts SHALL fail before mutation when kubeconfig/context, Terraform state, or expected hcloud resource identity is ambiguous.

#### Scenario: Target identity cannot be verified
- **WHEN** an hcloud lifecycle or validation script cannot verify that it is targeting the disposable `hcloud-lab` cluster or expected lab resources
- **THEN** it SHALL stop before creating, modifying, deleting, or validating resources and report the ambiguous inputs.

### Requirement: Post-destroy verification checks expected lab resource removal
The existing hcloud destroy path SHALL verify that expected disposable lab resource classes are removed or intentionally absent after destroy completes.

#### Scenario: Post-destroy verification succeeds
- **WHEN** Terraform/OpenTofu destroy completes and verification finds no expected disposable lab servers, load balancers, networks, or related resources
- **THEN** the destroy path SHALL report success with the resource classes checked.

#### Scenario: Post-destroy verification finds remaining resources
- **WHEN** post-destroy verification finds expected disposable lab resources still present
- **THEN** it SHALL report the remaining resources, warn about possible ongoing cost, and provide explicit teardown or investigation next steps.

### Requirement: Hcloud teardown reminders are visible but opt-in
Hcloud teardown reminders SHALL be visible in hcloud lifecycle output without making hcloud access part of default local validation.

#### Scenario: Developer runs local checks
- **WHEN** a developer runs `make check` or local validation workflows
- **THEN** those commands SHALL NOT require Hetzner Cloud credentials, Terraform state, or hcloud lifecycle status access.
