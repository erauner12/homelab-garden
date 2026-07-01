# Delivery/CD Control-Plane Lab: Plan

## Goal

Evolve `homelab-garden` into a small, runnable delivery/CD control-plane lab without making it the real homelab or a broad Kubernetes sandbox.

The lab should demonstrate one coherent story:

```text
code/config -> validation -> policy -> GitOps desired state -> ArgoCD sync
-> progressive rollout -> health evaluation -> pause/rollback -> read-only investigation
```

User choices for this plan:

- Keep the repo small and demo-focused first.
- Use `homelab-k8s` as prior art, not as a dependency.
- Make the first GitOps wave plain ArgoCD/app-of-apps, not Kargo-style promotion.
- Keep this as an architecture memo, not a commit-by-commit implementation script.

## Background

`homelab-garden` already has the right inner-loop shape. `README.md:3-11` describes it as a small public-safe local harness for rendering desired state, applying it with Garden, validating before real GitOps, and keeping ArgoCD as a future reconciliation path. `README.md:15-22` and `docs/validation-loop.md:5-27` define the existing flow:

```text
Kustomize render -> schema validation -> Go contract validation -> Garden apply -> readiness -> smoke checks
```

That boundary should stay intact. `docs/gitops-boundaries.md:3-13` separates desired-state rendering, local workload validation, and GitOps reconciliation validation. `docs/argocd-plan.md:5-19` already sketches the next reconciliation loop: Garden creates/selects the cluster, deploys ArgoCD, seeds a Git source, applies app-of-apps, waits for sync/health, then runs smoke checks.

The current seams are useful and should be extended rather than replaced:

- `Makefile:1-33` is the local command facade.
- `workflows/local-validate.garden.yml:1-17` is the ordered Garden workflow.
- `validation.garden.yml:1-39` wraps static, schema, contract, and smoke checks as Garden tests.
- `tests/contracts/contracts_test.go:15-21` defines core label/layer/namespace invariants.
- `tests/contracts/contracts_test.go:40-48` renders the platform and demo app overlays.
- `tests/contracts/contracts_test.go:51-135` already uses negative fixtures for contract failures.

`homelab-k8s` should be referenced for proven patterns only: ArgoCD Application conventions in `homelab-k8s/docs/argocd/application-authoring.md:20-92`, multi-source ordering rationale in `homelab-k8s/docs/argocd/application-authoring.md:95-121`, and Kyverno test conventions in `homelab-k8s/policies/kyverno/README.md:207-260`.

`kagent-garden` provides a useful Kustomize/Garden composition pattern to adapt at a smaller scale: manifests are owned by app/domain overlays, while `k8s/targets/<target>` acts as a thin non-owning composition index. For this repo, that pattern is valuable because Garden and ArgoCD can consume the same raw-Kustomize-safe desired-state paths for `local` and later `hcloud-lab` targets.

## Approach

Keep Garden outside the delivery platform and Kubernetes controllers inside it:

| Layer | Responsibility |
| --- | --- |
| Make | Stable local entrypoints: `doctor`, `kind-up`, `check`, `kind-status`, `kind-down`. |
| Garden | Ordered local workflows and exercise harness. |
| Kustomize | Desired-state rendering interface shared by Garden and ArgoCD; app-owned overlays plus thin target indexes should stay raw-Kustomize-safe. |
| Contract tests | Repo-specific safety invariants that schemas cannot express. |
| Kyverno | Policy-as-code checks locally first, admission guardrails later. |
| ArgoCD | Production GitOps reconciler; only run locally here as a disposable reconciliation exercise when ArgoCD behavior is under test. |
| Argo Rollouts | Later progressive-delivery exercise after ArgoCD works. |
| Health tooling | Later rollout promotion/rollback signal model. |
| Ops-agent tooling | Read-only investigation report only; no cluster mutation. |

The implementation order should protect the fast loop. Hard invariant: `make check` must remain ArgoCD-free, Rollouts-free, Prometheus-free, and agent-free. Instead, add separate workflows that prove progressively larger delivery-platform contracts:

1. `local-validate`: existing inner loop, kept fast.
2. `policy-validate`: local Kyverno CLI checks against rendered fixtures.
3. `adopt-targeted-kustomize-composition`: introduce app-owned overlays and thin `k8s/targets/<target>` indexes so Garden and ArgoCD can share raw-Kustomize-safe desired-state paths.
4. `local-argocd-reconcile`: disposable local ArgoCD exercise for app-of-apps, sync/health, ordering, drift, and self-heal behavior.
5. `rollout-demo`: Argo Rollouts canary/analysis exercise using the smallest useful health signal.
6. `failure-demo`: bad rollout pauses/aborts/rolls back.
7. `investigate-demo`: read-only context collection and report rendering.

The repo should remain an interview rehearsal system: each layer should answer one production delivery-platform question, and each workflow should have a short acceptance command plus a short explanation of what it proves.

## Work Items

### 1. Normalize the repo narrative

Add or update docs so the repo explains the delivery-control-plane boundary before adding more infrastructure.

Target docs:

- `docs/homelab-roadmap.md`
- `docs/architecture/delivery-control-plane.md`
- `docs/interview/topic-map.md`
- `README.md`

Keep the existing message from `docs/validation-loop.md:3`: the default local loop intentionally avoids ArgoCD. The roadmap should make ArgoCD a separate exercise, not a hidden dependency of `make check`.

Acceptance shape:

```bash
make doctor
make kind-up
garden workflow local-validate --env local
make kind-status
make kind-down
```

### 2. Strengthen validation without widening the platform

Extend the current validation structure before adding controllers.

Recommended additions:

- Add `validation/render.sh` if rendering logic starts duplicating across `static.sh`, `schema.sh`, and tests.
- Add `validation/policy.sh` only after Kyverno policies exist.
- Add contract fixtures for standard labels, namespace/layer boundaries, image tags, resource requirements, privileged containers, selectors, and probes.
- Defer Rollouts-specific fixtures until the Rollouts CRDs and examples exist.

Use `tests/contracts/contracts_test.go:51-135` as the fixture pattern. Keep ownership clear:

| Check type | Owner |
| --- | --- |
| Kubernetes API shape | `validation/schema.sh` with `kubeconform` |
| Repo invariants | Go contract tests |
| Policy-as-code parity with admission | Kyverno CLI tests |
| Non-negotiable runtime enforcement | Kyverno admission, later |

Avoid turning any one layer into a duplicate of the others.

Acceptance shape:

```bash
make static
make schema
make contracts
garden workflow local-validate --env local
```

### 3. Add Kyverno as local policy first

Add Kyverno after contract fixtures are stronger, because policy failures should be explainable against known unsafe examples.

Target shape:

```text
policy/kyverno/
  require-standard-labels.yaml
  require-resource-requests.yaml
  require-probes.yaml
  disallow-latest-tag.yaml
  restrict-privileged-containers.yaml
  tests/
validation/policy.sh
workflows/policy-validate.garden.yml
```

Use a workflow-shaped entrypoint for consistency:

```text
make policy-validate -> garden workflow policy-validate --env local
policy-validate workflow -> Garden exec test policy-validation -> validation/policy.sh
```

Model the test layout after `homelab-k8s/policies/kyverno/README.md:207-260`: one test directory per policy, `kyverno-test.yaml`, valid and invalid fixtures, and `kyverno test ... --detailed-results`.

Kyverno should be used in two stages:

1. CLI checks in `policy-validate` / CI-style workflows.
2. Admission enforcement only after the local policy suite is stable.

### 4. Adopt targeted Kustomize composition

Before ArgoCD or hcloud work depends on repo paths, adapt the useful part of the `kagent-garden` pattern in a smaller form.

Target shape:

```text
k8s/apps/platform/.../base
k8s/apps/platform/.../overlays/local
k8s/apps/workloads/demo-api/base
k8s/apps/workloads/demo-api/overlays/local
k8s/targets/local/kustomization.yaml
# later, when hcloud exists:
k8s/targets/hcloud-lab/kustomization.yaml
```

Rules:

- app/domain overlays own manifests;
- `k8s/targets/<target>` is a thin composition index, not a resource owner;
- ArgoCD source paths must be raw-Kustomize-safe;
- Garden-only `patchResources`, template syntax, or shell-derived values must stay outside ArgoCD-owned source paths;
- target identity (`local`, `hcloud-lab`) stays separate from cluster mechanism (`kind`, Hetzner/Terraform).

Implement this as a minimal bridge first if a full move would slow down the first implementation slice. The first slice only needs to prove that Garden and ArgoCD can consume the same raw-Kustomize-safe desired-state roots; it should not become a broad directory migration.

### 5. Add a local ArgoCD reconciliation exercise

Implement the existing `docs/argocd-plan.md:5-19` path as an optional disposable local exercise, but keep it outside `local-validate`. Garden remains the pre-CD validation harness; ArgoCD owns real GitOps reconciliation after changes are pushed.

Target shape:

```text
platform/addons/argocd/
gitops/projects/
gitops/applications/
gitops/app-of-apps.yaml
workflows/local-argocd-reconcile.garden.yml
```

Start with app-of-apps managing two child applications sourced from the raw-Kustomize-safe composition paths introduced by `adopt-targeted-kustomize-composition`:

```text
platform-local -> k8s/apps/platform/.../overlays/local or the platform portion of k8s/targets/local
demo-api-local -> k8s/apps/workloads/demo-api/overlays/local or the demo portion of k8s/targets/local
```

Use the current remote branch first unless local no-push GitOps becomes valuable enough to justify in-cluster Gitea/Forgejo. That matches the simplicity recommendation in `docs/argocd-plan.md:17-23`. Platform must reconcile before the demo app so namespace/platform dependencies are explicit. Do not point ArgoCD at paths that require Garden `patchResources`, Garden variables, or shell-derived local state.

Pin the first drift behavior: enable automated sync with self-heal for the demo app, keep prune disabled initially, and make the exercise demonstrate remediation of live drift. A later exercise can show manual sync or drift reporting if needed.

Use `homelab-k8s/docs/argocd/application-authoring.md:20-92` as a reference for Application fields, but simplify for this lab: labels, project, source path, destination namespace, sync-wave/app ordering, automated sync/self-heal, retry, and revision history are enough.

Acceptance shape:

```bash
garden workflow local-argocd-reconcile --env local
kubectl -n argocd get applications
kubectl -n demo get deploy,svc
```

Then test drift deliberately:

```bash
kubectl -n demo scale deploy demo-api --replicas=0
```

The exercise is successful when the disposable local ArgoCD install detects the drift and self-heals the demo workload back to Git-declared desired state. This workflow must not deploy to, configure, or manage the real homelab ArgoCD installation.

### 6. Add progressive delivery only after reconciliation works

Add Argo Rollouts once ArgoCD can sync the app from Git. The first Rollouts exercise should be simple: one demo API rollout, one AnalysisTemplate, one success path, one failure path.

Target shape:

```text
platform/addons/argo-rollouts/
apps/demo-api/rollouts/canary.yaml
apps/demo-api/rollouts/analysis-template.yaml
scenarios/good-rollout/
scenarios/failing-readiness/
scenarios/bad-image/
workflows/rollout-demo.garden.yml
workflows/failure-demo.garden.yml
```

Do not start with service mesh traffic shifting. The first objective is to explain progressive rollout state, analysis, pause/abort behavior, and rollback semantics.

### 7. Add health gates as explicit signal policy

Health gates should distinguish automation-grade signals from diagnostic-only signals.

Target shape:

```text
observability/health-queries/
validation/health.sh
docs/architecture/health-gates.md
```

Start with Kubernetes readiness and rollout status only. Add demo API metrics and Prometheus-style queries after the readiness-only Rollouts demo works. The health gate should produce structured output and document which signals are safe enough for automated rollback.

Example signal categories:

- Automation-grade: readiness failure, crash loop, severe success-rate regression, severe p95 latency regression.
- Diagnostic-only: isolated logs, one-off trace anomalies, low-volume error blips, unrelated dependency alerts.

### 8. Add read-only investigation after the first failure demo

The first assistant-like workflow should collect context and render a report. It should not deploy, patch, scale, promote, or roll back.

Target shape:

```text
tools/ops-agent/collect_context.py
tools/ops-agent/render_report.py
tools/ops-agent/prompts/deployment-investigation.md
workflows/investigate-demo.garden.yml
```

Collected context should include Kubernetes workload state, recent events, ArgoCD sync/health when installed, Rollouts status when installed, recent logs, health-query output when available, and the desired version. Optional systems should be skipped with an explicit `not_installed` / `not_available` status rather than becoming hard dependencies. The report should separate safe next actions from actions requiring approval.

Principle: agent proposes; platform enforces.

### 9. Defer tenant waves and `rolloutctl` until the first CD story works

Tenant-wave generation is valuable, but it is a second story. Add it after one ArgoCD app, one Rollouts demo, and one failure investigation work end to end.

Later target shape:

```text
tenants/tenants.yaml
tenants/waves.yaml
tenants/desired-state/
tools/rolloutctl/
```

`rolloutctl` should first print and validate a rollout plan; writing desired-state changes can come next. Do not call GitHub APIs in the first version. Kargo remains later prior art.

### 10. Add interview story docs as the final polish layer

After workflows exist, add one concise `docs/interview/topic-map.md` first. Split it into separate story docs only when the commands exist and the single page gets too dense.

Each story entry should include situation, design, safety properties, failure modes, tradeoffs, and a 30-second soundbite. Keep these docs grounded in commands that actually work.

## Non-goals for the first wave

- Do not make `make check` install or require ArgoCD.
- Do not add Kargo before the ArgoCD-only reconciliation workflow works.
- Do not add tenant-wave tooling before the first ArgoCD + Rollouts story works.
- Do not start with service mesh traffic shifting.
- Do not require Prometheus for the first Rollouts demo.
- Do not build a custom controller before the scripted desired-state flow is useful.
- Do not let the ops-agent mutate cluster state.
- Do not import private homelab state, secrets, provider credentials, or domain configuration.

## Open Questions

- Should Kyverno admission enforcement be a separate workflow after CLI policy tests, or bundled into the same milestone once policies pass locally?
- After the readiness-only Rollouts demo works, should the next health source be demo API metrics or a lightweight Prometheus install?

## References

- `README.md:3-22` — current repo purpose and local workflow.
- `docs/validation-loop.md:3-39` — validation-first boundary and future ArgoCD questions.
- `docs/gitops-boundaries.md:3-13` — desired state vs local validation vs GitOps reconciliation.
- `docs/argocd-plan.md:5-23` — future ArgoCD workflow and Git source options.
- `Makefile:1-33` — local command facade.
- `workflows/local-validate.garden.yml:1-17` — current Garden workflow.
- `validation.garden.yml:1-39` — Garden test actions.
- `tests/contracts/contracts_test.go:40-135` — rendered contract and fixture pattern.
- `homelab-k8s/docs/argocd/application-authoring.md:20-121` — ArgoCD Application prior art.
- `homelab-k8s/policies/kyverno/README.md:207-260` — Kyverno policy test prior art.
- Garden workflow config: https://docs.garden.io/reference/workflow-config
- Garden Kubernetes deploy actions: https://docs.garden.io/reference/action-types/deploy/kubernetes
- Argo CD automated sync: https://argo-cd.readthedocs.io/en/latest/user-guide/auto_sync/
- Argo Rollouts: https://argo-rollouts.readthedocs.io/en/stable/
- Kyverno introduction: https://kyverno.io/docs/introduction/
- Kyverno CLI: https://kyverno.io/docs/subprojects/kyverno-cli/
