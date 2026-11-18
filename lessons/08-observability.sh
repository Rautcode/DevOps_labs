# Observability: monitoring, dashboards and alerts (about 2h)
title "Module 08 · Observability"
mission "Customers told you the site was down before your own tools did. Your mission: build the monitoring that tells YOU first: metrics, dashboards and alerts that fire when users are really affected."
explain "Monitoring tells you the site is broken BEFORE your users do. Prometheus checks the site every 15 seconds, Grafana draws graphs, and alert rules notify you when the error budget is burning too fast."

part "PART A · Start monitoring"
learn "Monitoring basics" "Prometheus checks targets every 15 seconds and stores the results as time series. Grafana draws graphs from them, and alert rules are queries that raise an alert when they are true for long enough. Probing the site from outside measures what a real visitor experiences."
art "The monitoring flow" <<'ART'
   your app --(/metrics)--> [ Prometheus ] --stores--> numbers over time
                                  |                          |
                                  v                          v
                            [ Alertmanager ]            [ Grafana ]
                            "page the human"            graphs and dashboards
ART
mcq "Who does the checking in Prometheus?" "Prometheus scrapes (asks) each target every few seconds|Each app pushes email|You open the website by hand|Grafana" 1 "Prometheus pulls metrics from each target on a schedule."
step "Start the app plus Prometheus, Grafana and a probe" "Containers Started: blackbox, prometheus, grafana (plus api and web)." <<'CMD'
dco up -d 2>&1 | tail -5
CMD
step "Wait for the first checks, then ask: is the site up?" "Two results with value 1 = up (one for the homepage, one for /healthz). 0 would mean down." <<'CMD'
sleep 45; curl -s 'localhost:9090/api/v1/query?query=probe_success' | grep -o '"instance":"[^"]*"\|"value":\[[^]]*\]'
CMD
step "Validate the monitoring config" "SUCCESS ... 7 rules found" <<'CMD'
docker run --rm --entrypoint promtool -v "$PWD/08-observability:/etc/prometheus:ro" prom/prometheus:v2.55.1 check config /etc/prometheus/prometheus.yml 2>&1 | grep -E "SUCCESS|FAILED"
CMD
step "List the alerts that exist" "EndpointDown, ErrorBudgetFastBurn, ErrorBudgetSlowBurn, SlowResponses" <<'CMD'
curl -s localhost:9090/api/v1/rules | grep -o '"name":"[A-Z][A-Za-z]*"' | sort -u
CMD
step "Find the dashboard" "A dashboard titled 'DevLab: availability & latency'. Open http://localhost:3000 in your browser and look at it (no login needed in this lab)." <<'CMD'
curl -s 'localhost:3000/api/search?query=DevLab' | grep -o '"title":"[^"]*"'
CMD

part "PART B · PromQL: ask questions of your metrics"
learn "The Prometheus query language" "Every metric is a time series: a name, labels (key=value pairs that identify the series) and a value that changes over time. PromQL selects series and does maths on them. A SELECTOR picks series by name and labels: probe_success{instance=\"http://web:8080/healthz\"}; use =~ for a regex match and != to exclude. A GAUGE goes up and down (is the site up? how long did the probe take?). A COUNTER only ever goes up (total requests) and resets when a program restarts, so you never read it raw: rate(counter[5m]) gives the per-second average over the last 5 minutes. AGGREGATIONS combine series: sum, avg, max, count, with by (label) to keep a label. Comparison operators filter: probe_duration_seconds > 0.5 returns only the series that are over half a second. This is the language every alert and dashboard in this module is written in. The shortcut pq runs a query for you (it calls Prometheus' HTTP API)."
art "Anatomy of a query" <<'ART'
   sum by (job) ( rate( http_requests_total{status=~"5.."}[5m] ) )
   |   |           |     |                  |              |
   |   |           |     |                  |              +- look at the last 5 minutes
   |   |           |     |                  +- only 5xx status codes (regex)
   |   |           |     +- the metric (a counter) with label filters
   |   |           +- per-second rate (counters need rate)
   |   +- keep one result per job
   +- add the series together
ART
step "Is everything up? (up is 1 for a target that was scraped successfully)" "A line per target with => 1: the two probe targets and Prometheus itself." ok '=> 1' <<'CMD'
pq 'up'
CMD
step "Select ONE series with a label filter" "One line: the /healthz probe, => 1 (the site is answering)." ok 'healthz.*=> 1' <<'CMD'
pq 'probe_success{instance="http://web:8080/healthz"}'
CMD
step "A gauge: how long did each probe take, in seconds?" "Two lines, each a small number of seconds." ok 'probe_duration_seconds' <<'CMD'
pq 'probe_duration_seconds'
CMD
step "Do maths on it: the same, in milliseconds" "The same values times 1000." ok '=> ' <<'CMD'
pq 'probe_duration_seconds * 1000'
CMD
step "Filter with a comparison: which probes took longer than half a second?" "(no data): none did. That is exactly the SlowResponses alert condition, and it is quiet." ok 'no data' <<'CMD'
pq 'probe_duration_seconds > 0.5'
CMD
mcq "http_requests_total is a counter that only goes up. Which query gives requests PER SECOND?" "http_requests_total|rate(http_requests_total[5m])|sum(http_requests_total)|http_requests_total[5m]" 2 "rate() turns an ever-growing counter into a per-second speed, and copes with counter resets. Reading the raw total tells you little."
step "A real counter: how many queries has Prometheus itself answered?" "One line with a number: the counter of /api/v1/query requests as of the last scrape (every 15 seconds). It may be 0 at first and keeps growing as you ask more questions." ok 'handler="/api/v1/query"' <<'CMD'
pq 'prometheus_http_requests_total{handler="/api/v1/query"}'
CMD
step "Turn the counter into a rate (per second, averaged over 2 minutes)" "A small number per second, often below 1 and possibly 0 at first. Each query you run adds to it; run the step again after a minute." ok '=> ' <<'CMD'
pq 'rate(prometheus_http_requests_total{handler="/api/v1/query"}[2m])'
CMD
step "Aggregate: how many targets are up in each job?" "job=probe => 2 and job=prometheus => 1." ok 'probe.*=> 2' <<'CMD'
pq 'sum by (job) (up)'
CMD
step "Availability over time: the share of successful probes in the last 5 minutes" "A number between 0 and 1 (1 = every probe succeeded). The SLO alerts use exactly this." ok '=> ' <<'CMD'
pq 'avg_over_time(probe_success{instance="http://web:8080/healthz"}[5m])'
CMD
step "See how the lab's alert rules use the same language" "The expr: lines of rules.yml: avg_over_time, rate-style recording rules and comparisons." ok 'expr' <<'CMD'
grep -n "expr" 08-observability/rules.yml | head -5
CMD
predict "You run: probe_success == 0. The site is healthy. What do you get?" "A line with => 0|(no data), because no series matches|An error|=> 1" 2 "A comparison FILTERS: it keeps only series where the condition is true. Nothing is down, so nothing is returned. An alert fires when its expression returns anything."
task "Write a query" "Write a PromQL query that returns how many targets are up right now, and save the QUERY (just the text) into playground/promql.txt. For example:  echo 'YOUR QUERY' > playground/promql.txt   The lab will run your query and compare the number." "sum(up) adds up all the 1s. count(up) counts the series. Try them with pq first." <<'X'
[ -s playground/promql.txt ] && [ "$(pq "$(cat playground/promql.txt)" | awk '{print $NF}')" = "$(pq 'sum(up)' | awk '{print $NF}')" ]
---
echo 'sum(up)' > playground/promql.txt
X
quiz "Why do you wrap a counter in rate() instead of looking at its raw value?" "reset|per second|speed|always|grows|total|increase|only goes up|change|restart|trend" "A counter only ever grows and starts again from zero when the program restarts. rate() shows how FAST it grows, which is what you can alert on and graph, and it handles the resets."

part "PART C · Hands-on: trigger an alert"
explain "Now break the site on purpose and watch the monitoring notice. Open http://localhost:9090/alerts in your browser first."
learn "Alerts and burn rate" "A good alert fires when users are affected, not when a machine is merely busy. The for: 1m setting makes an alert wait a minute before firing, which avoids false alarms from short blips. Burn-rate alerts fire when the error budget is being used up too fast."
task "Stop the API and wait for the EndpointDown alert" "Type:  docker stop devlab-api-1   Then open http://localhost:9090/alerts in your browser and refresh it every 15 seconds. EndpointDown goes to PENDING, then to FIRING after a minute. When you can see it, type  check  here." "It can take up to 2 minutes. Prometheus checks every 15 seconds and the alert waits 1 minute before firing, to avoid false alarms." <<'X'
curl -s localhost:9090/api/v1/alerts | grep -q EndpointDown
---
docker stop devlab-api-1 >/dev/null; for i in $(seq 1 40); do curl -s localhost:9090/api/v1/alerts | grep -q EndpointDown && exit 0; sleep 5; done; exit 1
X
step "Fix it: start the API again" '{"ok":true}. The alert will resolve by itself soon.' <<'CMD'
docker start devlab-api-1 >/dev/null; sleep 12; curl -s localhost:8080/healthz
CMD
quiz "Why alert on 'error budget burn rate' instead of 'CPU above 80%'?" "user|symptom|noise|page|impact|budget|false|matter|customer" "Burn-rate alerts fire when users are actually affected and the SLO is at risk. CPU alerts fire often without any user impact and cause alert fatigue."

part "PART D · Tidy up"
step "Stop the monitoring tools (the app keeps running)" "prometheus, grafana and blackbox stopped." <<'CMD'
dco rm -sf prometheus grafana blackbox 2>&1 | tail -3
CMD

deeper "Observability Zero to Hero (Abhishek Veeramalla)|https://github.com/iam-veeramalla/observability-zero-to-hero" "observability-for-devops (Shubham Londhe)|https://github.com/LondheShubham153/observability-for-devops"
explain "Done! Next: bash lab.sh 09"
