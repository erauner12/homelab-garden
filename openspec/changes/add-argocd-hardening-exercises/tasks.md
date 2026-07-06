## 1. Prerequisites and Scope

- [ ] 1.1 Require existing local or hcloud ArgoCD sync/health and self-heal evidence before hardening scenarios run.
- [ ] 1.2 Define lab-owned resources and namespaces safe for bounded prune, AppProject denial, and sync-option safety tests.
- [ ] 1.3 Document how this change adds safety behaviors beyond the baseline reconciliation and hcloud self-heal specs.

## 2. Hardening Scenarios

- [ ] 2.1 Demonstrate prune only against disposable lab-owned resources.
- [ ] 2.2 Demonstrate AppProject denial for a denied source, destination, namespace, or resource kind.
- [ ] 2.3 Demonstrate lab-scoped sync option safety behavior without broadening permissions.
- [ ] 2.4 Add blast-radius reporting before each bounded destructive or denial scenario.

## 3. Local and Hcloud Paths

- [ ] 3.1 Add optional local hardening workflow or documented commands.
- [ ] 3.2 Add hcloud hardening support only behind the hcloud target guard.
- [ ] 3.3 Verify hcloud hardening does not run Terraform apply/destroy or mutate cloud infrastructure.

## 4. Safety Verification

- [ ] 4.1 Confirm hardening exercises are not invoked by `make check` or local validation.
- [ ] 4.2 Confirm prune scenarios cannot target shared platform, real homelab, or non-lab resources.
- [ ] 4.3 Document cleanup and recovery for failed hardening exercises.
