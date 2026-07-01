## Why

The repo is evolving from a small Garden validation harness into a delivery/CD rehearsal lab. Before adding controllers or policy tooling, the lab needs explicit boundaries so later work does not turn `make check` into a slow all-in-one platform install.

## What Changes

- Clarify the repo as a small public-safe delivery/CD lab, not the real homelab.
- Make the validation-first Garden loop a protected default path.
- Document which later workflows are optional exercises rather than `make check` dependencies.
- Add only lightweight command-grounded interview mapping in this foundation change.

## Capabilities

### New Capabilities
- `delivery-lab-boundaries`: Defines the public-safe scope and relationship to `homelab-k8s` prior art.
- `validation-loop`: Defines the protected default local validation behavior.

### Modified Capabilities

## Impact

- Affects README and docs only.
- Establishes constraints for later OpenSpec changes.
- Does not add platform components, controllers, cluster dependencies, or new runtime behavior.
