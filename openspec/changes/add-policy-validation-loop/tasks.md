## 1. Policy Structure

- [x] 1.1 Add `policy/kyverno/` with initial policy and test directories.
- [x] 1.2 Add first valid and invalid policy fixtures.
- [x] 1.3 Add `kyverno-test.yaml` files for the initial policies.

## 2. Validation Entrypoints

- [x] 2.1 Add `validation/policy.sh` with clear missing-tool behavior.
- [x] 2.2 Add a Garden exec test named `policy-validation`.
- [x] 2.3 Add `workflows/policy-validate.garden.yml` that runs the `policy-validation` test.
- [x] 2.4 Add `make policy-validate` that calls `garden workflow policy-validate --env local`.
- [x] 2.5 Confirm `make check` does not invoke policy validation.

## 3. Documentation and Verification

- [x] 3.1 Document Go-contract vs Kyverno-policy ownership.
- [x] 3.2 Run `make contracts` to confirm existing contracts still pass.
- [x] 3.3 Run the new policy validation entrypoint with passing fixtures.
- [x] 3.4 Confirm at least one invalid fixture fails with an actionable message.

## Verification Results

- `make -n check` showed `doctor`, `static`, `schema`, `contracts`, partial Garden config resolution, and `local-validate`; it did not invoke `policy-validate`.
- `make contracts` passed: `ok homelab-garden/tests/contracts`.
- `PATH=/usr/bin:/bin ./validation/policy.sh` confirmed the missing Kyverno CLI error names the tool, install options, and that `make check` does not require Kyverno.
- `./validation/policy.sh` passed with Kyverno CLI `1.16.2`.
- `make policy-validate` passed after starting/reusing the local `kind-homelab-garden` cluster required by Garden's `local` environment provider resolution.
- `kyverno apply policy/kyverno/cluster/disallow-latest-tag.yaml --resource policy/kyverno/tests/disallow-latest-tag/invalid-latest-tag.yaml` reported the expected validation failure for `invalid-latest-tag` with guidance to pin an explicit version or digest.
