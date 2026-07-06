## ADDED Requirements

### Requirement: Local analyzer consumes evidence artifacts
Metric-backed rollout analysis SHALL run as a read-only local report renderer that consumes health gate v2 JSON, rollout risk review JSON, and tenant wave simulation JSON.

#### Scenario: Required evidence is present
- **WHEN** the analyzer is given health, risk, and wave JSON inputs
- **THEN** it SHALL render a JSON or Markdown report containing `decision`, metric evidence, wave context, and reason codes.

#### Scenario: Required evidence is missing
- **WHEN** any health, risk, or wave JSON input is missing or unreadable
- **THEN** the analyzer SHALL return `decision: unknown` with an actionable reason code.

### Requirement: Analyzer applies conservative decision rules
Metric-backed rollout analysis SHALL make only explicit `pass` automation-safe.

#### Scenario: Risk review blocks rollout
- **WHEN** rollout risk review JSON contains `decision: block`
- **THEN** the analyzer SHALL return `decision: block`.

#### Scenario: Tenant wave is not eligible
- **WHEN** tenant wave simulation JSON does not show an eligible wave
- **THEN** the analyzer SHALL return `decision: review` or `decision: block` when the wave itself is blocked.

#### Scenario: All required gates explicitly pass
- **WHEN** health gate decision is pass, risk review decision is pass, tenant wave is eligible, and configured metric scraping is available
- **THEN** the analyzer SHALL return `decision: pass` and mark the report automation-safe.

### Requirement: Demo API metrics are optional and direct
Metric-backed rollout analysis SHALL optionally scrape demo API `/metrics` only when `DEMO_API_BASE_URL` is set.

#### Scenario: Metrics are not configured
- **WHEN** `DEMO_API_BASE_URL` is unset
- **THEN** the analyzer SHALL skip metric scraping and keep defaults local and read-only.

#### Scenario: Metric scrape is unavailable
- **WHEN** `DEMO_API_BASE_URL` is set but `/metrics` cannot be read or parsed for required metric names
- **THEN** the analyzer SHALL return `decision: unknown` with metric evidence explaining the failure.

### Requirement: Analyzer has no mutation path
Metric-backed rollout analysis SHALL NOT add Prometheus, Rollouts `AnalysisTemplate`/`AnalysisRun`, ArgoCD sync, cluster mutation, cloud mutation, or PR generation.

#### Scenario: Analyzer runs locally
- **WHEN** a developer runs the analyzer or its optional workflow
- **THEN** it SHALL read local evidence files and optional demo API metrics only, without applying Kubernetes manifests or changing external systems.

#### Scenario: Hcloud appears in evidence
- **WHEN** input evidence references `hcloud-lab`
- **THEN** the analyzer SHALL treat hcloud only as diagnostic context and SHALL NOT add cloud or cluster mutations.
