# Design: Read-only investigation report

## Approach

Use a single Bash script under `validation/` because existing Garden validation entrypoints already live there. The script only runs read-only commands (`kubectl get`, `kubectl logs`, `kubectl config current-context`, and the existing `validation/health.sh`) and writes Markdown to stdout by default.

A Garden exec run action wraps the script with the configured local kube context, and a workflow exposes the user-facing `investigate-demo` entrypoint.

## Optional Systems

- ArgoCD is considered installed only when the `applications.argoproj.io` CRD is present. If absent, the report renders `argocd: not_installed`.
- Argo Rollouts is considered installed only when the `rollouts.argoproj.io` CRD is present. If absent, the report renders `rollouts: not_installed`.

## Safety

The script avoids mutation verbs entirely. Approval-required operations are documented as examples only in the generated report and are never executed.

## Report Output

The script writes Markdown to stdout by default. If `INVESTIGATION_REPORT_PATH` is set, it writes the same Markdown to that path. Generated files under `reports/investigation/` are ignored.
