## 1. OpenSpec Artifacts

- [x] 1.1 Create the `add-hcloud-self-heal-validation` OpenSpec change.
- [x] 1.2 Document goals, non-goals, decisions, and safety boundaries.
- [x] 1.3 Add requirements for the hcloud self-heal workflow, safety guard, baseline gate, drift, smoke test, and diagnostics.

## 2. Hcloud Self-Heal Workflow

- [x] 2.1 Add a guarded hcloud self-heal script that sources `platform/addons/argocd/hcloud-common.sh`.
- [x] 2.2 Verify hcloud ArgoCD Applications exist and are Synced/Healthy before mutating the demo workload.
- [x] 2.3 Induce bounded drift by scaling `deployment/demo-api` in namespace `demo` away from the healthy baseline replica count.
- [x] 2.4 Wait for ArgoCD to restore the deployment replica count and return `demo-api-hcloud-lab` to Synced/Healthy.
- [x] 2.5 Emit diagnostics for app status, deployment, pods/events, and logs on failure.
- [x] 2.6 Add a Garden Run action for the self-heal script.
- [x] 2.7 Add `workflows/hcloud-argocd-self-heal.garden.yml` without install/apply/Terraform lifecycle steps.
- [x] 2.8 Run the existing hcloud demo smoke Run action after self-heal.

## 3. Documentation and Validation

- [x] 3.1 Document the new workflow and prerequisite that `hcloud-argocd-reconcile` has already succeeded.
- [x] 3.2 Run `garden validate --env hcloud-lab`.
- [x] 3.3 Run bash syntax checks for new scripts.
- [x] 3.4 Run `openspec validate add-hcloud-self-heal-validation --strict`.
- [x] 3.5 If the live hcloud cluster is reachable and healthy, run `ARGOCD_GITHUB_TOKEN="$(gh auth token)" garden workflow hcloud-argocd-self-heal --env hcloud-lab`.
