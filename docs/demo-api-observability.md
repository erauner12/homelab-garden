# Demo API Observability Surface

The demo API is a tiny standard-library HTTP service used only by this public lab. It exposes stable local signals that later health-gate and rollout work can consume without adding Prometheus, ServiceMonitor resources, Rollouts `AnalysisTemplate` metrics, hcloud lifecycle steps, or any real homelab integration.

## Endpoints

| Method | Path | Healthy behavior | Purpose |
| --- | --- | --- | --- |
| `GET` | `/` | `200 text/plain` with `homelab-garden demo-api ok` | Backward-compatible smoke response. |
| `GET` | `/healthz` | `200 application/json` with `healthy: true` | Liveness/process health. |
| `GET` | `/readyz` | `200 application/json` with `ready: true` | Kubernetes readiness and smoke readiness. |
| `GET` | `/version` | `200 application/json` with app/version only | Diagnostic build identity. |
| `GET` | `/metrics` | `200 text/plain; version=0.0.4` | Prometheus-compatible text for local inspection. |
| `POST` | `/simulate?mode=<mode>` | Configure simulation mode | Controlled lab-only simulation. |
| `POST` | `/simulate/reset` | Reset to healthy mode | Clear mutable simulation state. |

The Kubernetes Deployment and Rollout probes use `/healthz` for liveness and `/readyz` for readiness. The existing smoke expectation for `/` remains `homelab-garden demo-api ok`.

## Simulation modes

Simulation state is in-memory and scoped to the running demo API process. Restarting the pod or calling `POST /simulate/reset` returns the app to healthy behavior.

| Mode | Configure | Behavior |
| --- | --- | --- |
| `healthy` | `POST /simulate?mode=healthy` | Default. `/`, `/healthz`, and `/readyz` return successful responses. |
| `degraded` | `POST /simulate?mode=degraded` | `/healthz` and `/readyz` stay successful but report degraded status; `/` returns a degraded text body. |
| `failing` | `POST /simulate?mode=failing` | `/` returns `503`, `/healthz` returns `500`, and `/readyz` returns `503`; `/metrics` and simulation controls remain available for diagnosis/reset. |
| `latency` | `POST /simulate?mode=latency&latency_ms=250` | Adds deterministic latency to `/`, `/healthz`, and `/readyz`. Latency is clamped to `0..2000` ms. |

## Metrics

`/metrics` uses Prometheus-compatible text so it is machine-readable without requiring a Prometheus server in this change.

Current signals stay intentionally small: request count, 5xx error count, simple request-duration summary, active simulation mode, and configured latency.

## Health gate v2

`validation/health.sh` emits a v2 decision envelope with `decision`, `reasons`, `evidence`, `environment`, and `target_guard`. Automation must advance only on `decision: pass`; `fail`, `degraded`, and `unknown` exit non-zero. When `DEMO_API_BASE_URL` is set, the gate reads `/healthz`, `/readyz`, `/metrics`, and `/version` without requiring Prometheus.

## Safety and validation boundaries

The endpoint output is intentionally public-safe: it contains app name, version, status, mode, latency, and aggregate counters only. It must not include secrets, provider credentials, private domains, Terraform state, or real homelab identifiers.

Default local validation stays hcloud-free. `make check` uses local render/schema/contract checks plus the local Garden workflow against `kind-homelab-garden`; it does not require Hetzner credentials, Terraform/OpenTofu apply, or real homelab access. Hcloud workflows remain opt-in and guarded by their existing kubeconfig/context setup.

The Python demo API is managed as a small uv project under `k8s/apps/workloads/demo-api`. It intentionally has no runtime dependencies beyond the Python standard library.

Run app-level endpoint tests without a cluster:

```bash
make demo-api-test
# or directly:
cd k8s/apps/workloads/demo-api
uv run pytest
```

