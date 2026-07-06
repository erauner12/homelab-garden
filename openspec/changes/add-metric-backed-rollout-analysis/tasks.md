## 1. Prerequisites and Artifacts

- [x] 1.1 Confirm demo API exposes `/metrics` for optional direct local scraping.
- [x] 1.2 Confirm health gate v2, rollout risk review, and tenant wave simulation provide JSON evidence for composition.
- [x] 1.3 Update proposal, design, and spec to the read-only local analyzer scope.

## 2. Analysis Implementation

- [x] 2.1 Add a focused local Python renderer for metric rollout analysis.
- [x] 2.2 Consume health gate v2 JSON, rollout risk review JSON, tenant wave simulation JSON, and optional demo API `/metrics`.
- [x] 2.3 Emit JSON or Markdown with `decision`, metric evidence, wave context, and reason codes.
- [x] 2.4 Implement conservative decision rules where only explicit `pass` is automation-safe.

## 3. Read-only Wiring and Docs

- [x] 3.1 Add a dedicated self-test Make target outside default `make check`.
- [x] 3.2 Add optional thin Garden workflow wiring for local report rendering.
- [x] 3.3 Document running, inputs, decision interpretation, and hcloud diagnostic-only boundary.

## 4. Verification

- [x] 4.1 Run Python compile checks for new/touched Python.
- [x] 4.2 Run analyzer self-test / Make target.
- [x] 4.3 Run `openspec validate --all --strict`.
