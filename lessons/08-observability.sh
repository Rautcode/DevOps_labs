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

part "PART B · Hands-on: trigger an alert"
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

part "PART C · Tidy up"
step "Stop the monitoring tools (the app keeps running)" "prometheus, grafana and blackbox stopped." <<'CMD'
dco rm -sf prometheus grafana blackbox 2>&1 | tail -3
CMD

deeper "Observability Zero to Hero (Abhishek Veeramalla)|https://github.com/iam-veeramalla/observability-zero-to-hero" "observability-for-devops (Shubham Londhe)|https://github.com/LondheShubham153/observability-for-devops"
explain "Done! Next: bash lab.sh 09"
