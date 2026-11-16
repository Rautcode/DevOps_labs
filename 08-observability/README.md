# 08 · Observability and SLOs (Advanced, ~4h)

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

**Next:** [09 · Security](../09-security/README.md)
