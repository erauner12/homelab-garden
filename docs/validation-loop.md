# Validation Loop

The default loop intentionally avoids ArgoCD.

It answers:

- do the Kustomize entrypoints render?
- can Garden apply the rendered resources to a local cluster?
- do the workloads become ready?
- do smoke checks pass against the running service?

That keeps the inner loop fast and focused on component behavior.

An optional ArgoCD workflow can be added later to answer a different question:

- do the ArgoCD `Application` resources point at the right desired state?
- does app-of-apps wiring reconcile in the expected order?
- do sync and health status match the running cluster?

Garden is the harness in both modes. ArgoCD is included only when the GitOps
reconciliation contract is the thing under test.
