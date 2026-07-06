## Context

The existing `policy-validation` spec covers Kyverno CLI checks without installing an admission controller. This change intentionally comes after that capability: it reuses the policy/fixture discipline from CLI validation, then separately proves live admission semantics.

## Goals / Non-Goals

**Goals:**
- Demonstrate Kyverno admission allow and deny behavior in a disposable cluster.
- Reuse or align with existing `policy-validation` fixtures so policy intent stays consistent.
- Support local kind first and hcloud lab second with explicit guards.
- Keep policies small, public-safe, and focused on delivery-lab guardrails.
- Provide cleanup so admission policy does not contaminate unrelated exercises.

**Non-Goals:**
- Do not add the admission exercise to `make check`, `local-validate`, or `make policy-validate`.
- Do not replace CLI policy validation or make live admission the fast validation path.
- Do not mirror the real homelab policy set wholesale.
- Do not require a long-running policy platform in the lab.

## Decisions

- Use a new workflow or documented command separate from `policy-validate` so developers can choose CLI validation or live admission intentionally.
- Start from policies already proven or represented by `policy-validation` where possible, then add admission-specific fixtures only when needed.
- Include both an allowed fixture and a denied fixture so the exercise proves the webhook is active.
- For hcloud, require the kubeconfig/context guard before installing Kyverno or applying fixtures.

## Risks / Trade-offs

- Admission controllers can interfere with other lab workflows → namespace the exercise and include cleanup.
- Hcloud webhook failures can be confusing → collect Kyverno pod status, policy status, and admission error messages as diagnostics.
- Policy scope can drift toward production complexity → keep this exercise small and not a copy of the real homelab policy set.
