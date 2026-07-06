## 1. Exercise Scope

- [ ] 1.1 Confirm the existing `policy-validation` capability and fixtures are the prerequisite for this live admission exercise.
- [ ] 1.2 Choose small public-safe Kyverno policies for admission behavior.
- [ ] 1.3 Add compliant and non-compliant fixtures for allow and deny outcomes.
- [ ] 1.4 Document the difference between CLI policy validation and live admission testing.

## 2. Local Admission Path

- [ ] 2.1 Add an optional local Kyverno admission workflow or documented command.
- [ ] 2.2 Install or enable Kyverno only for the disposable local exercise.
- [ ] 2.3 Verify the allowed fixture is admitted and the denied fixture is rejected.
- [ ] 2.4 Ensure `make check`, `local-validate`, and `policy-validate` remain admission-controller-free.

## 3. Hcloud Admission Path

- [ ] 3.1 Add hcloud admission exercise support only behind the hcloud target guard.
- [ ] 3.2 Verify the exercise does not run Terraform apply/destroy or mutate cloud infrastructure.
- [ ] 3.3 Document diagnostics for Kyverno webhook, policy, and admission failures.

## 4. Cleanup and Validation

- [ ] 4.1 Add explicit cleanup instructions for Kyverno policies, fixtures, and optional components.
- [ ] 4.2 Verify cleanup leaves subsequent lab workflows unaffected.
- [ ] 4.3 Confirm no real homelab policy or cluster target is referenced.
