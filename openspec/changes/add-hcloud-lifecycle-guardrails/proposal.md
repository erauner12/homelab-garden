## Why

The hcloud lab already has explicit lifecycle scripts for preflight, create, destroy, status, inventory, and state reporting. The remaining gap is not a new lifecycle foundation; it is stronger guardrails around the existing scripts so disposable cloud resources do not linger or target the wrong lab.

## What Changes

- Enhance the existing hcloud lifecycle scripts with age/lifetime warnings and teardown reminders.
- Add rough cost and resource-class hints to existing status/inventory output where the data is already available or easy to derive.
- Fail closed when kubeconfig/context, Terraform state, or hcloud resource identity is ambiguous.
- Strengthen post-destroy verification so remaining expected lab resources are reported clearly.
- Keep Terraform/OpenTofu lifecycle explicit and outside default local validation.

## Capabilities

### New Capabilities
- `hcloud-lifecycle-guardrails`: Defines targeted guardrail enhancements for the existing disposable hcloud lab lifecycle scripts.

### Modified Capabilities

## Impact

- Future implementation should update existing hcloud preflight/create/destroy/status scripts and docs rather than create a parallel lifecycle system.
- Builds on the current hcloud lab scripts and validation workflows; stale `add-ephemeral-hcloud-reconciliation-lab` should be archived or revisited separately, not edited in this PR.
- Does not create, mutate, or destroy real homelab resources.
