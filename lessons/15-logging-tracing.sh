# Logging and tracing: logs, queries and traces (about 2h)
title "Module 15 · Logging and tracing"
explain "Metrics tell you THAT something is wrong. Logs tell you WHAT happened. Traces tell you WHERE the time went across services. Together they are called observability. You will collect every container's logs into Loki, query them like a database, and look at a trace in Jaeger."

part "PART A · Logs"
step "Start the app plus Loki (log storage), Alloy (the collector) and Jaeger (traces)" "loki, alloy and jaeger Started." ok 'alloy' <<'CMD'
dcl rm -sf loki alloy jaeger >/dev/null 2>&1; dcl up -d 2>&1 | grep -E "loki|alloy|jaeger"
CMD
step "Wait until Loki is ready" "loki is ready (it needs about 20 seconds to start)." ok 'loki is ready' <<'CMD'
for i in $(seq 1 30); do curl -s localhost:3100/ready | grep -q ready && { echo "loki is ready"; break; }; sleep 3; done
CMD
step "Make the API log different things (success, failure, bad input)" "Three status codes: 200, 401 and 400. Each request writes one log line." ok '401' <<'CMD'
curl -s -w ' <%{http_code}>\n' localhost:8080/api/form-token | grep -o '<[0-9]*>'; curl -s -w ' <%{http_code}>\n' localhost:8080/api/auth/me | grep -o '<[0-9]*>'; curl -s -X POST -w ' <%{http_code}>\n' localhost:8080/api/inquiries -H "content-type: application/json" -d '{"name":"x","email":"not-an-email"}' | grep -o '<[0-9]*>'
CMD
step "Read the raw logs the app wrote" "JSON lines like {\"level\":\"info\",\"method\":\"POST\",\"path\":\"/api/inquiries\",\"status\":400,...}. One JSON object per line = 'structured logging'. Machines can search it." ok 'status' <<'CMD'
sleep 3; dc logs api --tail 6 --no-log-prefix
CMD
step "Ask Loki: show API log lines mentioning 'inquiries'" "The status of each matching request. Loki stores logs from ALL containers and you search them with a query language called LogQL." ok 'status' <<'CMD'
for i in $(seq 1 25); do curl -s -X POST localhost:8080/api/inquiries -H "content-type: application/json" -d '{"name":"x","email":"bad"}' >/dev/null; out=$(curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service="api"} |= "inquiries"' --data-urlencode 'limit=10'); echo "$out" | grep -q 'status\\":[0-9]' && break; sleep 3; done; echo "$out" | grep -o 'status\\":[0-9]*' | sort | uniq -c
CMD
step "Count the errors in the last 15 minutes (LogQL aggregation)" "A number. 'status >= 400' counts client and server errors. This is how you turn logs into numbers." ok '"value":\[' <<'CMD'
curl -sG localhost:3100/loki/api/v1/query --data-urlencode 'query=sum(count_over_time({service="api"} | json | status >= 400 [15m]))' | grep -o '"value":\[[^]]*\]'
CMD
task "Cause an error, then find it in Loki" "1) Send a request with an invalid email:  curl -s -X POST localhost:8080/api/inquiries -H \"content-type: application/json\" -d '{\"name\":\"x\",\"email\":\"bad\"}'   2) Wait 10 seconds. 3) Run this query and confirm you see status 400:  curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service=\"api\"} | json | status = 400'  . You can also open http://localhost:3000, go to Explore, choose the Loki data source, and run {service=\"api\"}." "Logs reach Loki a few seconds after they are written. Wait 10 seconds and try again." <<'X'
curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service="api"} | json | status = 400' | grep -q 'status\\":400'
---
for i in $(seq 1 15); do curl -s -X POST localhost:8080/api/inquiries -H "content-type: application/json" -d '{"name":"x","email":"bad"}' >/dev/null; sleep 4; curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service="api"} | json | status = 400' | grep -q 'status\\":400' && break; done
X
quiz "Why does the API write logs as JSON instead of plain sentences?" "search|machine|parse|filter|query|structure|field|count|tool" "JSON has named fields (status, path, ms), so a log system can filter and count them (status >= 400). Plain sentences need fragile text matching."

part "PART B · Traces"
explain "A trace follows ONE request through the system as a tree of 'spans': each span is one step with a start time and a duration. Real apps create spans with an OpenTelemetry library. Here you will send one by hand so you can see exactly what a trace is."
step "Send a trace with two spans (a parent and a child)" "sent trace <id> (HTTP 200)" ok 'HTTP 200' <<'CMD'
bash 15-logging/send-trace.sh devlab-checkout "GET /checkout"
CMD
step "Read it back from Jaeger" "Two span names: 'GET /checkout' (the whole request) and 'SELECT leads' (a database call inside it). Open http://localhost:16686 and search for service devlab-checkout to see the waterfall picture." ok 'SELECT leads' <<'CMD'
sleep 3; curl -s 'localhost:16686/api/traces?service=devlab-checkout' | grep -o '"operationName":"[^"]*"' | sort -u
CMD
task "Send your own trace" "Send a trace from a service called my-service:  bash 15-logging/send-trace.sh my-service \"my first span\"   Then check it exists:  curl -s localhost:16686/api/services" "The service name must be exactly my-service." <<'X'
curl -s localhost:16686/api/services | grep -q my-service
---
bash 15-logging/send-trace.sh my-service "my first span"; sleep 3
X
quiz "Logs, metrics, traces: which one answers 'which step of this slow request took the time'?" "trace" "Traces. Metrics say the site is slow, logs say what happened, a trace shows where the time went inside one request."

part "PART C · Tidy up"
step "Stop the logging and monitoring tools (the app keeps running)" "removed" ok "Removed|Stopped|removed" <<'CMD'
dcl rm -sf loki alloy jaeger prometheus grafana blackbox 2>&1 | tail -6
CMD

explain "Done! Next: bash lab.sh 16"
