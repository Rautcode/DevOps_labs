# 15 · Logging and tracing (Specialist, ~2h)

> **Guided version:** run `bash lab.sh 15` from the repo root. It explains each step, has you type the commands yourself, and checks your hands-on tasks. This page is the reference.

**Goal:** collect every container's logs in one place and query them, and understand what a trace is. Metrics (module 08) say *that* something is wrong; logs say *what* happened; traces say *where the time went*.

| File | What it is |
|---|---|
| [compose.logging.yml](compose.logging.yml) | Loki (log store), Alloy (collector), Jaeger (traces), layered on the app + monitoring stack |
| [config.alloy](config.alloy) | tells Alloy to discover every Docker container and ship its logs to Loki |
| [send-trace.sh](send-trace.sh) | sends a two-span trace to Jaeger by hand, to show what a trace is |

The API writes **structured logs**: one JSON object per request (`method`, `path`, `status`, `ms`), so a log system can filter and count them. Health probes are left out to keep logs readable.

## Try it (from the repo root)
```bash
DCL="docker compose -f 03-compose/docker-compose.yml -f 08-observability/compose.observability.yml -f 15-logging/compose.logging.yml --env-file .env"
$DCL up -d
curl -s -X POST localhost:8080/api/inquiries -H "content-type: application/json" -d '{"name":"x","email":"bad"}'
curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service="api"} | json | status = 400'
bash 15-logging/send-trace.sh devlab-checkout "GET /checkout"          # then open http://localhost:16686
```
Open Grafana at http://localhost:3000 → **Explore** → data source **Loki** → `{service="api"}`.

## LogQL cheat sheet
| Query | Meaning |
|---|---|
| `{service="api"}` | all API logs |
| `{service="api"} \|= "inquiries"` | lines containing the text |
| `{service="api"} \| json \| status >= 400` | parse JSON, keep errors |
| `sum(count_over_time({service="api"} \| json \| status >= 400 [15m]))` | number of errors in 15 minutes |

## Concepts
- **Structured logging** (JSON) beats sentences: fields can be filtered and counted.
- **A trace** is a tree of **spans** (one step each, with start time and duration) following one request. Real apps create spans with **OpenTelemetry** libraries; the lab sends one by hand so you see the format.
- **The three pillars:** metrics (numbers over time), logs (events), traces (request journeys).

## Break it
1. Stop `alloy` and generate requests: what is missing in Loki? Start it again.
2. Log something sensitive (a password) and discover why you must never do that. Add a rule that drops it.
3. Query for the slowest requests: `{service="api"} | json | ms > 100`.

## Industry notes
- Alloy replaces Promtail, which reached end of life in 2026.
- Never log secrets, tokens or personal data; set retention limits; add a request/trace id to every log line so logs and traces connect.
- Next steps: auto-instrument the API with OpenTelemetry, send traces to Jaeger/Tempo, and link traces to logs in Grafana.
- The Alloy container mounts the Docker socket, which is powerful. Acceptable for a lab, not for production hosts.

**More practice (second helping on another app):** [observability-for-devops](https://github.com/LondheShubham153/observability-for-devops), [otel-playground](https://github.com/LondheShubham153/otel-playground). See [RESOURCES.md](../RESOURCES.md) for the full list.

**Next:** [16 · Postgres](../16-postgres/README.md)
