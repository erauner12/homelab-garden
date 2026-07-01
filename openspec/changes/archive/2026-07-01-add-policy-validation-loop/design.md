## Context

This change depends on `stabilize-delivery-lab-foundation` preserving the default validation-loop boundary. The repo already has Go contract tests for rendered-manifest invariants: labels, layer boundaries, namespace rules, workload resources/security, and service selectors. Kyverno should add policy-as-code parity for guardrails that could plausibly be enforced at admission, not duplicate every Go contract.

## Goals / Non-Goals

**Goals:**
- Add `policy-validate` as an optional local Kyverno CLI workflow.
- Keep Go contracts focused on repo-specific rendered-state invariants.
- Keep Kyverno focused on admission-style deployment guardrails.
- Produce clear actionable failures when Kyverno is missing or a policy fails.

**Non-Goals:**
- Do not install Kyverno admission controller.
- Do not make `make check` depend on `policy-validate`.
- Do not add Rollouts-specific policies before Rollouts resources exist.

## Decisions

- Use Model B for the user-facing entrypoint: `make policy-validate` calls `garden workflow policy-validate --env local`, the workflow runs a Garden exec test named `policy-validation`, and the test invokes `validation/policy.sh`.
- Use singular `policy/kyverno/` to match the lab vocabulary and the existing `policy` layer concept.
- Start with CLI tests and fixtures modeled after `homelab-k8s` prior art, but keep the policy set small.
- Keep ownership explicit:
  - Go contracts own repo labels, layers, namespace assumptions, Kustomize structure, and Service-to-Deployment selector matching.
  - Kyverno owns admission-style guardrails such as disallowing latest tags, requiring probes, requiring resources, and restricting privileged containers.

## Risks / Trade-offs

- Rule duplication can confuse failures → document ownership and avoid implementing the same rule twice unless admission parity is the point.
- Adding Kyverno increases tool requirements → keep it outside `make check` initially and report missing CLI clearly.
