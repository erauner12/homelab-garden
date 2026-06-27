# Validation Loop

The default local loop intentionally avoids ArgoCD.

It answers:

- do the Kustomize entrypoints render?
- can Garden apply the rendered resources to the dedicated kind cluster?
- do the workloads become ready?
- do smoke checks pass against the running service from inside the cluster?

Run it with the README local loop commands.

That keeps the inner loop focused on components, not GitOps reconciliation.

A future ArgoCD workflow can answer a different question:

- do the ArgoCD `Application` resources point at the right desired state?
- does app-of-apps wiring reconcile in the expected order?
- do sync and health status match the running cluster?

Garden is the harness in both modes. ArgoCD appears only when GitOps
reconciliation is the thing under test.
