## 1. Existing Status and Inventory Enhancements

- [ ] 1.1 Extend existing hcloud status/inventory output with resource age or creation-time evidence where available.
- [ ] 1.2 Add intended-lifetime warnings and teardown reminders for stale disposable lab resources.
- [ ] 1.3 Add rough cost and resource-class hints for expected hcloud servers, load balancers, networks, and related resources.

## 2. Fail-Closed Target Guardrails

- [ ] 2.1 Reuse existing kubeconfig/context and Terraform state inputs to verify the disposable `hcloud-lab` target before mutation.
- [ ] 2.2 Fail before create/destroy/validation steps when lab identity is missing, conflicting, or ambiguous.
- [ ] 2.3 Report ambiguous inputs with actionable recovery guidance.

## 3. Post-Destroy Verification

- [ ] 3.1 Extend the existing destroy path with verification for expected lab resource classes after Terraform/OpenTofu destroy completes.
- [ ] 3.2 Report remaining resources with possible ongoing cost and explicit next steps.
- [ ] 3.3 Document resource discovery limitations and required naming/label/state assumptions.

## 4. Boundary Verification

- [ ] 4.1 Confirm the changes update existing lifecycle scripts instead of creating a parallel status/lifecycle system.
- [ ] 4.2 Confirm default local validation still does not require hcloud credentials, Terraform state, or cloud resources.
- [ ] 4.3 Confirm no real homelab targets, credentials, tfvars, kubeconfigs, talosconfigs, or Terraform state are committed.
