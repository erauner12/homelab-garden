# Kyverno Policy Validation

This directory contains local Kyverno CLI policy tests for guardrails that could
reasonably become admission policies later. The policies are validated locally
with fixtures; this repo does not install the Kyverno admission controller.

## Ownership Boundary

| Check type | Owner |
| --- | --- |
| Repo labels, layer labels, namespace assumptions, Kustomize structure, and Service-to-Deployment selector matching | Go contract tests in `tests/contracts` |
| Admission-style guardrails such as mutable image tags, probes, resource requirements, and privileged containers | Kyverno policies and CLI tests in `policy/kyverno` |

Do not duplicate every Go contract as a Kyverno policy. Add a Kyverno rule when
admission parity is the point; keep repo-layout invariants in Go contracts.

## Run

```bash
make policy-validate
```

`make policy-validate` runs `garden workflow policy-validate --env local`, which
runs the Garden exec test `policy-validation`, which invokes
`validation/policy.sh`.

Kyverno CLI is optional for the default loop. `make check` intentionally does not
run policy validation.
