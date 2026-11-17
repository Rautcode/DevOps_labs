# Module 15 · interview and final (sourced by lab.sh)
part "PART · INTERVIEW"

interview "Find the failing request in the logs" "Interviewer: 'Somebody reports an error when saving a lead. Cause one yourself (send a lead with an invalid email), then find the matching log line in Loki. Save Loki's answer for the query {service=\"api\"} | json | status = 400 into playground/loki.txt.'" "curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service=\"api\"} | json | status = 400' > playground/loki.txt   (logs reach Loki a few seconds after they are written: wait and retry)" <<'X'
dcl rm -sf loki alloy jaeger >/dev/null 2>&1; dcl up -d >/dev/null 2>&1; for i in $(seq 1 30); do curl -s localhost:3100/ready | grep -q ready && break; sleep 3; done; sleep 15; rm -f playground/loki.txt
---
grep -q 'status\\":400' playground/loki.txt
---
for i in $(seq 1 15); do curl -s -X POST localhost:8080/api/inquiries -H "content-type: application/json" -d '{"name":"x","email":"bad"}' >/dev/null; sleep 4; curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service="api"} | json | status = 400' > playground/loki.txt; grep -q 'status\\":400' playground/loki.txt && break; done
X

interview "Turn logs into a number" "Interviewer: 'How many error responses (status 400 or higher) did the API log in the last 15 minutes? Ask Loki with a LogQL aggregation and save the NUMBER only into playground/errors.txt.'" "sum(count_over_time({service=\"api\"} | json | status >= 400 [15m]))  as an instant query:  curl -sG localhost:3100/loki/api/v1/query --data-urlencode 'query=...'  The number is the second item of the value." <<'X'
rm -f playground/errors.txt
---
n=$(tr -d '[:space:]' < playground/errors.txt); [ -n "$n" ] && [ "$n" -ge 1 ]
---
curl -sG localhost:3100/loki/api/v1/query --data-urlencode 'query=sum(count_over_time({service="api"} | json | status >= 400 [15m]))' | grep -oE ',"[0-9]+"\]' | tr -dc '0-9' > playground/errors.txt
X

part "PART · MODULE FINAL"

final "Send a trace" "Exam 1 of 3. Send a trace from a service called exam-service to Jaeger. I will look at the list of services Jaeger knows." "bash 15-logging/send-trace.sh exam-service \"GET /exam\"" <<'X'
true
---
curl -s localhost:16686/api/services | grep -q exam-service
---
bash 15-logging/send-trace.sh exam-service "GET /exam" >/dev/null 2>&1; sleep 3
X

final "Write the query" "Exam 2 of 3. Write the LogQL query that counts API log lines per status code over 15 minutes, and save it into playground/query.txt. It must use count_over_time and the field status." "sum by (status) (count_over_time({service=\"api\"} | json [15m]))" <<'X'
rm -f playground/query.txt
---
grep -q 'count_over_time' playground/query.txt && grep -q 'status' playground/query.txt
---
echo 'sum by (status) (count_over_time({service="api"} | json [15m]))' > playground/query.txt
X

final "Which services log to Loki?" "Exam 3 of 3. Ask Loki for all the values of the label service and save the answer into playground/services.txt. It must include both api and web." "curl -s localhost:3100/loki/api/v1/label/service/values" <<'X'
rm -f playground/services.txt
---
grep -q '"api"' playground/services.txt && grep -q '"web"' playground/services.txt
---
curl -s localhost:3100/loki/api/v1/label/service/values > playground/services.txt
---
dcl rm -sf loki alloy jaeger prometheus grafana blackbox >/dev/null 2>&1
X
