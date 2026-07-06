## Context

The hcloud lab already includes scripts for preflight, create, destroy, status, and some inventory/state reporting. This change is a cleanup and safety enhancement layer for those scripts: make status more actionable, warn when resources look old or costly, fail closed on ambiguous targets, and verify teardown with observable checks.

This change depends on the existing hcloud script layout and should not reopen the older `add-ephemeral-hcloud-reconciliation-lab` change in this PR.

## Goals / Non-Goals

**Goals:**
- Extend existing status/inventory output with age, lifetime, resource-class, and rough cost hints.
- Add teardown reminders before and after hcloud exercises where resources may remain active.
- Fail closed before mutation when kubeconfig/context, Terraform state, or expected lab resource identity is ambiguous.
- Verify post-destroy state by checking expected Hetzner resource classes, not only command exit codes.

**Non-Goals:**
- Do not create a new hcloud lifecycle/status framework parallel to the existing scripts.
- Do not auto-destroy resources without explicit operator confirmation.
- Do not edit or resolve stale `add-ephemeral-hcloud-reconciliation-lab` artifacts in this PR.
- Do not manage real homelab resources or add cloud lifecycle to `make check` or local validation.

## Decisions

- Enhance the current lifecycle script entrypoints in place: preflight/create/destroy/status remain the user-facing lifecycle verbs.
- Use existing Terraform state outputs, hcloud labels/names, and script inventory data to produce cost/resource-class/age hints; avoid broad account scans.
- Treat missing or conflicting kubeconfig/context, state, or lab identifiers as a fail-closed condition before mutating workloads or cloud resources.
- Add post-destroy verification and teardown reminders as explicit script output so operators see remaining resources and next steps.

## Risks / Trade-offs

- Hints can become stale → label cost as rough and tie resource-class output to observed state rather than hard-coded guarantees.
- Resource discovery can miss leaks → document naming/label assumptions and show which resource classes were checked.
- Fail-closed checks may block legitimate recovery → provide explicit manual override guidance only where safe and documented.
