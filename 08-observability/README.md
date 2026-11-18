# 08 · Observability and SLOs (Advanced, ~4h)

> **Guided version:** run `bash lab.sh 08` from the repo root. It explains each step, has you type the commands yourself, and checks your hands-on tasks. This page is the reference.

**Goal:** know the site is healthy *before* customers tell you. Probes, dashboards, and error-budget alerts.

| File | Purpose |
|---|---|
| [compose.observability.yml](compose.observability.yml) | Prometheus + Blackbox exporter + Grafana, layered over the app stack |
| [prometheus.yml](prometheus.yml) | scrape + probe config |
| [rules.yml](rules.yml) | recording rules and **multi-window burn-rate alerts** (7 rules, validated with `promtool`) |
| [grafana/](grafana) | auto-provisioned data source and dashboard |

Black-box monitoring is used because it needs **no change to the app**: it measures what a visitor experiences.

## Do it (from the repo root)
```bash
C="docker compose -f 03-compose/docker-compose.yml -f 08-observability/compose.observability.yml --env-file .env"
$C up -d --build
```
- Prometheus: http://localhost:9090 (Status → Targets, Alerts)
- Grafana: http://localhost:3000 → dashboard **"DevLab: availability & latency"** (anonymous admin, lab only)

Validate the config yourself:
```bash
docker run --rm --entrypoint promtool -v "$PWD/08-observability:/etc/prometheus:ro" prom/prometheus:v2.55.1 check config /etc/prometheus/prometheus.yml
```
**Check:** in Prometheus run `probe_success`; both targets return `1`.

## Do the alert experiment
```bash
docker stop devlab-api-1          # watch Alerts: EndpointDown -> pending -> firing (~1-2 min)
docker start devlab-api-1         # it resolves
```
Then watch `slo:error_ratio:rate5m` rise on the dashboard against the 0.5% budget line.

## PromQL: ask your metrics questions
The lab shortcut `pq 'QUERY'` runs an instant query (it calls `http://localhost:9090/api/v1/query`). Or type the same queries into the Prometheus web page.
```promql
up                                                           # 1 = scraped fine
probe_success{instance="http://web:8080/healthz"}            # one series, by label
probe_duration_seconds * 1000                                # arithmetic: seconds to ms
probe_duration_seconds > 0.5                                 # a filter: only slow probes (the SlowResponses alert)
rate(prometheus_http_requests_total{handler="/api/v1/query"}[2m])   # a COUNTER as a per-second rate
sum by (job) (up)                                            # aggregation, keep the job label
avg_over_time(probe_success{instance="http://web:8080/healthz"}[5m])   # availability over 5 minutes
```
- **Gauge** (goes up and down) vs **counter** (only goes up, resets on restart): never read a counter raw, use `rate()` or `increase()`.
- Selectors: `=`, `!=`, `=~` (regex), `!~`. Aggregations: `sum`, `avg`, `max`, `count` with `by (label)`.
- `histogram_quantile(0.95, sum by (le) (rate(x_bucket[5m])))` gives a p95 latency from a histogram.

## Concepts
- **The four golden signals:** latency, traffic, errors, saturation.
- **SLI → SLO → error budget** ([10-sre/slo.md](../10-sre/slo.md)). **Burn-rate alerts** page only when the budget is genuinely at risk: far less noise than "CPU > 80%".
- **Metrics vs logs vs traces:** this module is metrics. Logs are `docker logs` / `kubectl logs`.

## Exercises
1. Add an alert for TLS certificate expiry (`probe_ssl_earliest_cert_expiry`) once you probe an HTTPS URL.
2. Add Alertmanager and route `severity=page` to a webhook (use https://webhook.site) and `ticket` to email.
3. Add Loki + Promtail (or Grafana Alloy) for logs and correlate a 502 with the API logs.
4. Install the Prometheus Operator / kube-prometheus-stack in module 06's cluster and monitor Kubernetes itself.
5. **Expert:** add `prom-client` to the API for real application metrics (RED: rate, errors, duration) and define an SLO on request latency.

Stop everything: `$C down` (add `-v` to also delete data).

**More practice (second helping on another app):** [observability-for-devops](https://github.com/LondheShubham153/observability-for-devops). See [RESOURCES.md](../RESOURCES.md) for the full list.

**Next:** [09 · Security](../09-security/README.md)
