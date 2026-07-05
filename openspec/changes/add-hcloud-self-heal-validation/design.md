## Context

`hcloud-argocd-reconcile` already installs/configures disposable hcloud ArgoCD, applies the hcloud app-of-apps, waits for `app-of-apps-hcloud-lab`, `platform-hcloud-lab`, and `demo-api-hcloud-lab`, and smoke-tests the demo API. This change adds the next validation step after that baseline is healthy: prove that ArgoCD self-heal corrects deliberate live drift.

The hcloud lane is optional and targets only the ephemeral `hcloud-lab` cluster. Terraform/OpenTofu remains the cloud lifecycle owner; this validation workflow must not create, modify, or destroy Hetzner infrastructure.

## Goals / Non-Goals

**Goals:**
- Provide `garden workflow hcloud-argocd-self-heal --env hcloud-lab`.
- Assume `hcloud-argocd-reconcile` has already installed ArgoCD and synced apps.
- Refuse non-hcloud kubeconfig/context use through the existing hcloud guard.
- Verify the relevant hcloud Applications are present, Synced, and Healthy before mutating the demo deployment.
- Create safe live drift on `deployment/demo-api` in namespace `demo`.
- Wait for the deployment and ArgoCD Application to self-heal back to the reconciled desired state.
- Run the existing demo smoke test after self-heal.
- Print app, deployment, pod/event, and log diagnostics on failure.

**Non-Goals:**
- Do not run Terraform apply/destroy or Hetzner resource lifecycle operations.
- Do not install/reinstall ArgoCD or apply app-of-apps in the self-heal workflow.
- Do not target the real homelab or local kind cluster.
- Do not make default local validation depend on hcloud or ArgoCD.

## Decisions

- Add a dedicated script `platform/addons/argocd/self-heal-hcloud-demo.sh` and source `hcloud-common.sh` so the same context/kubeconfig checks apply as the existing hcloud ArgoCD scripts.
- Use deployment scaling as the drift primitive. The script records the current healthy replica count as the reconciled baseline, scales up by one replica, then waits for ArgoCD to return `.spec.replicas` to the baseline. Scaling up is less disruptive than scaling down while still changing live state in a way self-heal should correct.
- Keep baseline validation strict. Missing Applications, non-Synced sync status, non-Healthy health status, or a missing demo deployment fail before drift is induced.
- Keep smoke testing as a separate Garden Run step using the existing `hcloud-argocd-smoke-demo-api` action.
- Emit diagnostics from the self-heal script rather than hiding failures behind Garden output.

## Risks / Trade-offs

- ArgoCD may self-heal quickly enough that the drift is brief. The workflow still validates that the deployment returns to the baseline and the Application is Synced/Healthy.
- Scaling up by one replica briefly consumes extra hcloud cluster capacity. This is safer for service availability than scaling down and remains bounded.
- If the cluster is not already reconciled, failing before mutation is less convenient but safer and makes the prerequisite explicit.
