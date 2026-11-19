# Logging and tracing: logs, queries and traces (about 2h)
title "Module 15 · Logging and tracing"
mission "The graph says errors went up, but WHICH requests, from WHERE, and slow in WHICH service? Your mission: search logs, follow one request across services with a trace, and use all three signals together."
explain "Metrics tell you THAT something is wrong. Logs tell you WHAT happened. Traces tell you WHERE the time went across services. Together they are called observability. You will collect every container's logs into Loki, query them like a database, and look at a trace in Jaeger."

part "PART A · Logs"
learn "Logs, metrics and traces" "Metrics are numbers over time, logs are events, and traces follow one request through the system. Loki stores logs and indexes only their labels, which keeps it cheap. Alloy is the collector that reads every container's output and ships it to Loki. LogQL is the query language."
say "What are the three pillars of observability?" "Metrics are numbers over time that tell me that something is wrong. Logs are event records that tell me what happened. Traces follow one request across services and tell me where the time went. I use them together: an alert from metrics, logs to find the error, and a trace to find the slow service."
art "The three pillars" <<'ART'
   METRICS  numbers over time        "errors went up"      (that)
   LOGS     events with detail       "user 7 got HTTP 500"  (what)
   TRACES   one request's journey    "slow in the database" (where)
ART
mcq "A request is slow and you want to know WHICH service is slow. Which signal?" "Traces|Metrics only|Logs only|DNS" 1 "A trace shows the time spent in each step across services."
why "dcl up -d::start the app and the logging tools|Loki::stores logs|Alloy::collects them|Jaeger::stores and shows traces" "Logs from containers are lost when a container is removed. A log system collects them centrally, so you can search them later."
step "Start the app plus Loki (log storage), Alloy (the collector) and Jaeger (traces)" "loki, alloy and jaeger Started." ok 'alloy' <<'CMD'
dcl rm -sf loki alloy jaeger >/dev/null 2>&1; dcl up -d 2>&1 | grep -E "loki|alloy|jaeger"
CMD
why "for ...; do ...; done::keep checking|curl localhost:3100/ready::ask Loki if it is ready" "Databases and log stores need a few seconds to start. Waiting for ready avoids confusing empty results."
step "Wait until Loki is ready" "loki is ready (it needs about 20 seconds to start)." ok 'loki is ready' <<'CMD'
for i in $(seq 1 30); do curl -s localhost:3100/ready | grep -q ready && { echo "loki is ready"; break; }; sleep 3; done
CMD
why "curl ... form-token / me / inquiries::three requests with different outcomes|grep -o::print only the status codes" "We create log lines of different kinds, so there is something interesting to search for: a success, an unauthorised call and a bad request."
step "Make the API log different things (success, failure, bad input)" "Three status codes: 200, 401 and 400. Each request writes one log line." ok '401' <<'CMD'
curl -s -w ' <%{http_code}>\n' localhost:8080/api/form-token | grep -o '<[0-9]*>'; curl -s -w ' <%{http_code}>\n' localhost:8080/api/auth/me | grep -o '<[0-9]*>'; curl -s -X POST -w ' <%{http_code}>\n' localhost:8080/api/inquiries -H "content-type: application/json" -d '{"name":"x","email":"not-an-email"}' | grep -o '<[0-9]*>'
CMD
why "dc logs api --tail 6::the last lines|--no-log-prefix::without the container name" "The app writes one JSON object per line. Structured logs like this are easy for a machine to filter."
step "Read the raw logs the app wrote" "JSON lines like {\"level\":\"info\",\"method\":\"POST\",\"path\":\"/api/inquiries\",\"status\":400,...}. One JSON object per line = 'structured logging'. Machines can search it." ok 'status' <<'CMD'
sleep 3; dc logs api --tail 6 --no-log-prefix
CMD
why "curl -G ... query_range::ask Loki for lines in a time range|{service=api}::select the API logs" "Instead of reading files on each server, you ask one place. The selector in braces picks the stream, like labels in Prometheus."
step "Ask Loki: show API log lines mentioning 'inquiries'" "The status of each matching request. Loki stores logs from ALL containers and you search them with a query language called LogQL." ok 'status' <<'CMD'
for i in $(seq 1 25); do curl -s -X POST localhost:8080/api/inquiries -H "content-type: application/json" -d '{"name":"x","email":"bad"}' >/dev/null; out=$(curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service="api"} |= "inquiries"' --data-urlencode 'limit=10'); echo "$out" | grep -q 'status\\":[0-9]' && break; sleep 3; done; echo "$out" | grep -o 'status\\":[0-9]*' | sort | uniq -c
CMD
why "count_over_time::count log lines in a window|json::parse each line as JSON|status >= 400::only the failures" "LogQL combines search and maths. This turns raw lines into one number you could graph or alert on."
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
learn "Traces and spans" "A trace is the journey of one request. It is made of spans: each span is one step with a start time and a duration, and a child span sits inside its parent. A trace view shows where the time went. Real apps create spans with OpenTelemetry libraries."
say "What is distributed tracing?" "A trace is the journey of one request through the system, made of spans, each representing one operation with a start time and a duration. A trace ID is passed between services, so I can see the whole path and find which step is slow or failing. I used Jaeger to view traces and OpenTelemetry to produce them."
art "A trace as a timeline" <<'ART'
   GET /checkout   |==================================| 480 ms   (the parent span)
     auth          |==|                                  40 ms
     database        |==============|                   220 ms   <- the slow part
     payment                         |==========|       180 ms
   one trace id connects the spans across services
ART
why "send-trace.sh::sends a sample trace|a parent span and a child span::one request and one step inside it" "A trace is the journey of one request. Each span is one step with a start time and a duration. Services pass a trace ID along so the steps connect."
step "Send a trace with two spans (a parent and a child)" "sent trace <id> (HTTP 200)" ok 'HTTP 200' <<'CMD'
bash 15-logging/send-trace.sh devlab-checkout "GET /checkout"
CMD
why "curl .../api/traces?service=::ask Jaeger for the traces of a service|grep -o operationName::list the step names" "You can see both spans in the store. In the Jaeger web page you would see them as a timeline showing where the time went."
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
why "dcl rm -sf ...::stop and remove those services" "Free the memory. The app itself keeps running."
step "Stop the logging and monitoring tools (the app keeps running)" "removed" ok "Removed|Stopped|removed" <<'CMD'
dcl rm -sf loki alloy jaeger prometheus grafana blackbox 2>&1 | tail -6
CMD

deeper "Observability Zero to Hero (Abhishek Veeramalla)|https://github.com/iam-veeramalla/observability-zero-to-hero" "otel-playground: real OpenTelemetry (Shubham Londhe)|https://github.com/LondheShubham153/otel-playground"
explain "Done! Next: bash lab.sh 16"
