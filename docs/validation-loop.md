# Validation Loop

The default local loop intentionally avoids ArgoCD.

It answers:

- do release intent samples include required identity fields and stay public-safe?
- do the Kustomize entrypoints render?
- does the rendered output satisfy strict built-in Kubernetes schemas?
- does the rendered output satisfy repo contracts for labels, layers,
  namespaces, workload safety, and Service selectors?
- can Garden apply the rendered resources to the dedicated kind cluster?
- do the workloads become ready?
- do smoke checks pass against the running service from inside the cluster?

Run it with:

```bash
make kind-up
make check
make kind-status
make kind-down
```

`make check` runs release intent validation, static render validation, Kubernetes schema validation,
Go contract tests, Garden config resolution, Garden deploys, and the
in-cluster smoke check. Release intent validation checks the public-safe read-only samples in `release-intents/`; static validation proves the app-owned overlays and `k8s/targets/local`
composition index render, schema validation pipes rendered standard Kubernetes
resources through `kubeconform -strict -summary`, and Go contracts enforce
repo-specific delivery rules that Kubernetes schemas cannot express. That keeps
the inner loop focused on components, not GitOps reconciliation.

Policy-as-code checks are a separate optional loop:

```bash
make policy-validate
```

`make policy-validate` calls `garden workflow policy-validate --env local`,
which runs the Garden exec test `policy-validation`, which invokes
`validation/policy.sh` against local Kyverno fixtures. This loop requires the
Kyverno CLI but not the Kyverno admission controller, and it is intentionally not
part of `make check`.

| Boundary | Owner |
| --- | --- |
| Repo labels, layers, namespace assumptions, Kustomize structure, and Service-to-Deployment selectors | Go contract tests |
| Admission-style guardrails such as mutable image tags, probes, resource requirements, and privileged containers | Kyverno CLI policy tests |

The separate `local-argocd-reconcile` workflow answers a different question:

- do the ArgoCD `Application` resources point at the right desired state?
- does app-of-apps wiring reconcile in the expected order?
- do sync and health status match the running cluster?

Garden is the harness in both modes. ArgoCD appears only when GitOps
reconciliation is the thing under test.
