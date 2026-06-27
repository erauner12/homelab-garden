# Validation Loop

The default local loop intentionally avoids ArgoCD.

It answers:

- do the Kustomize entrypoints render?
- can Garden apply the rendered resources to the dedicated kind cluster?
- do the workloads become ready?
- do smoke checks pass against the running service from inside the cluster?

Run it with:

```bash
make kind-up
make static
garden get config --env local --resolve=partial
make local-validate
make kind-status
make kind-down
```

That keeps the inner loop fast and focused on component behavior. It tests the
running components, not GitOps reconciliation.

A future ArgoCD workflow can answer a different question:

- do the ArgoCD `Application` resources point at the right desired state?
- does app-of-apps wiring reconcile in the expected order?
- do sync and health status match the running cluster?

Garden is the harness in both modes. ArgoCD is included only when the GitOps
reconciliation contract is the thing under test.
