## 1. Policy Structure

- [ ] 1.1 Add `policy/kyverno/` with initial policy and test directories.
- [ ] 1.2 Add first valid and invalid policy fixtures.
- [ ] 1.3 Add `kyverno-test.yaml` files for the initial policies.

## 2. Validation Entrypoints

- [ ] 2.1 Add `validation/policy.sh` with clear missing-tool behavior.
- [ ] 2.2 Add a Garden exec test named `policy-validation`.
- [ ] 2.3 Add `workflows/policy-validate.garden.yml` that runs the `policy-validation` test.
- [ ] 2.4 Add `make policy-validate` that calls `garden workflow policy-validate --env local`.
- [ ] 2.5 Confirm `make check` does not invoke policy validation.

## 3. Documentation and Verification

- [ ] 3.1 Document Go-contract vs Kyverno-policy ownership.
- [ ] 3.2 Run `make contracts` to confirm existing contracts still pass.
- [ ] 3.3 Run the new policy validation entrypoint with passing fixtures.
- [ ] 3.4 Confirm at least one invalid fixture fails with an actionable message.
