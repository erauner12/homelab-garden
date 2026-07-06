## ADDED Requirements

### Requirement: ArgoCD hardening exercises require baseline evidence
The ArgoCD hardening exercises SHALL treat existing local or hcloud sync/self-heal evidence as prerequisite context rather than as the primary new behavior.

#### Scenario: Baseline evidence is missing
- **WHEN** a hardening exercise starts without current ArgoCD sync/health or self-heal evidence for the target lab
- **THEN** it SHALL stop or report the missing prerequisite instead of running prune, AppProject denial, or sync-option safety scenarios.

### Requirement: Prune behavior is bounded
Prune exercises SHALL affect only lab-owned disposable resources selected for the prune scenario.

#### Scenario: Prune exercise removes extra resource
- **WHEN** a lab-owned resource is removed from desired state or introduced as an expected prune target
- **THEN** ArgoCD prune behavior SHALL be demonstrated only for the bounded lab resource and SHALL NOT delete shared platform, real homelab, or non-lab resources.

### Requirement: AppProject denial behavior is demonstrated
The ArgoCD hardening exercises SHALL demonstrate at least one AppProject restriction that blocks an unsafe or out-of-scope operation.

#### Scenario: Application violates project boundary
- **WHEN** the exercise applies or evaluates an Application with a denied source, destination, namespace, or resource kind
- **THEN** ArgoCD SHALL reject or mark the operation invalid and the exercise SHALL report the denied boundary.

### Requirement: Sync option safety is demonstrated
The ArgoCD hardening exercises SHALL demonstrate lab-scoped sync option safety behavior.

#### Scenario: Unsafe sync option behavior is prevented
- **WHEN** a lab fixture attempts behavior that is disallowed by the selected sync options or project policy
- **THEN** the exercise SHALL report the blocked or constrained behavior and SHALL NOT broaden permissions beyond the lab scope.

### Requirement: Blast-radius report precedes hardening actions
The ArgoCD hardening exercises SHALL report intended blast radius before bounded prune, AppProject denial, or sync-option safety scenarios run.

#### Scenario: Hardening action is prepared
- **WHEN** a hardening scenario is about to run
- **THEN** the exercise SHALL report the target Application, namespace, resources, sync options, prune candidates, and environment before applying the scenario.

### Requirement: Hcloud hardening is guarded
ArgoCD hardening exercises against hcloud SHALL target only the disposable `hcloud-lab` cluster.

#### Scenario: Hcloud hardening exercise starts
- **WHEN** a hardening exercise runs with `--env hcloud-lab`
- **THEN** it SHALL verify the hcloud target guard before applying, syncing, pruning, or deleting any resource.
