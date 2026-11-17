# Module 08 · interview and final (sourced by lab.sh)
part "PART · INTERVIEW"

interview "Is the site up?" "Interviewer: 'Do not tell me you looked at the site in a browser. Ask Prometheus: is the health endpoint probe (instance http://web:8080/healthz) up? Save the value, 1 for up or 0 for down, into playground/up.txt.'" "The metric is probe_success. Use the Prometheus HTTP API:  curl -sG localhost:9090/api/v1/query --data-urlencode 'query=probe_success'  and read the value at the end of the result." <<'X'
dco up -d >/dev/null 2>&1; sleep 45; rm -f playground/up.txt
---
[ "$(tr -d '[:space:]' < playground/up.txt)" = "1" ] && curl -sG localhost:9090/api/v1/query --data-urlencode 'query=probe_success{instance="http://web:8080/healthz"}' | grep -q ',"1"\]'
---
curl -sG localhost:9090/api/v1/query --data-urlencode 'query=probe_success{instance="http://web:8080/healthz"}' | grep -o ',"[01]"\]' | tr -dc '01' > playground/up.txt
X

interview "Make the alarm ring" "Interviewer: 'Show me the alerting works. Cause a real outage of the API and wait until the EndpointDown alert shows up in Prometheus (pending is enough). I will look at the alerts API.'" "docker stop devlab-api-1  then check  curl -s localhost:9090/api/v1/alerts  every 15 seconds. It can take 1 to 2 minutes." <<'X'
true
---
curl -s localhost:9090/api/v1/alerts | grep -q EndpointDown
---
docker stop devlab-api-1 >/dev/null 2>&1; for i in $(seq 1 40); do curl -s localhost:9090/api/v1/alerts | grep -q EndpointDown && break; sleep 5; done
---
docker start devlab-api-1 >/dev/null 2>&1; sleep 14
X

part "PART · MODULE FINAL"

final "How many alert rules?" "Exam 1 of 3. Count the ALERTING rules (not the recording rules) that Prometheus has loaded and save the number into playground/alerts.txt." "curl -s localhost:9090/api/v1/rules  lists every rule with a \"type\". Count the ones whose type is alerting." <<'X'
rm -f playground/alerts.txt
---
n=$(curl -s localhost:9090/api/v1/rules | grep -o '"type":"alerting"' | wc -l | tr -d ' '); [ "$n" -ge 1 ] && [ "$(tr -d '[:space:]' < playground/alerts.txt)" = "$n" ]
---
curl -s localhost:9090/api/v1/rules | grep -o '"type":"alerting"' | wc -l | tr -d ' ' > playground/alerts.txt
X

final "Write your own alert" "Exam 2 of 3. Write a Prometheus rule file playground/exam-rules.yml containing an alert named ExamAlert that fires when probe_success == 0 for 30 seconds. It must pass promtool check rules." "Shape:  groups: - name: exam  rules: - alert: ExamAlert  expr: probe_success == 0  for: 30s  . Copy the style from 08-observability/rules.yml. Validate with promtool in Docker." <<'X'
rm -f playground/exam-rules.yml
---
[ -f playground/exam-rules.yml ] && grep -q ExamAlert playground/exam-rules.yml && docker run --rm --entrypoint promtool -v "$PWD/playground:/w" prom/prometheus:v2.55.1 check rules /w/exam-rules.yml >/dev/null 2>&1
---
printf 'groups:\n  - name: exam\n    rules:\n      - alert: ExamAlert\n        expr: probe_success == 0\n        for: 30s\n        labels:\n          severity: ticket\n' > playground/exam-rules.yml
X

final "Find the dashboard" "Exam 3 of 3. Ask Grafana (http://localhost:3000, API /api/search) for the provisioned dashboard whose title mentions DevLab and save the result into playground/dash.txt." "curl -s 'localhost:3000/api/search?query=DevLab' > playground/dash.txt" <<'X'
rm -f playground/dash.txt
---
grep -q 'availability' playground/dash.txt
---
curl -s 'localhost:3000/api/search?query=DevLab' > playground/dash.txt
---
dco rm -sf prometheus grafana blackbox >/dev/null 2>&1
X
