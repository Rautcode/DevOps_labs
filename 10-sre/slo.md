# Service Level Objectives: DevLab sample site

| SLI (what we measure) | Source | SLO | Window |
|---|---|---|---|
| **Availability**: successful `GET /healthz` probes through the public proxy | `probe_success` (blackbox exporter) | **99.5%** | 30 days |
| **Latency**: homepage probe under 500 ms | `probe_duration_seconds` | 95% of probes | 30 days |

## Error budget
99.5% over 30 days leaves **0.5%, about 3 h 36 min**, of allowed downtime. Budget burn is alerted in
[`08-observability/rules.yml`](../08-observability/rules.yml):
- **Fast burn** (14.4x over 1h *and* 5m): page. At this rate the whole budget is gone in about 2 days.
- **Slow burn** (6x over 6h *and* 1h): ticket.

## Policy
- More than 50% budget left: normal release cadence.
- Less than 25% left: only reliability work and critical fixes.
- Budget exhausted: feature freeze until the 30-day window recovers.

## Why 99.5% and not 99.99%?
A lead-generation site with a single SQLite writer cannot honestly promise more. Each extra nine costs roughly 10x more (redundancy, multi-region). Choose the SLO your users actually need.
