#!/usr/bin/env bash
# Send one tiny trace (a parent span and a child span) to Jaeger using the OpenTelemetry HTTP format.
# Real apps do this with an OpenTelemetry library; sending it by hand shows what a trace actually IS.
#   bash 15-logging/send-trace.sh <service-name> [root-span-name]
set -euo pipefail
svc="${1:?usage: send-trace.sh <service-name> [root-span-name]}"
root="${2:-GET /checkout}"
now=$(( $(date +%s) * 1000000000 ))
trace=$(printf '%016x%016x' "$RANDOM$RANDOM" "$RANDOM$RANDOM")
parent=$(printf '%016x' "$RANDOM$RANDOM")
child=$(printf '%016x' "$RANDOM$RANDOM$RANDOM")
body="{
 \"resourceSpans\":[{\"resource\":{\"attributes\":[{\"key\":\"service.name\",\"value\":{\"stringValue\":\"$svc\"}}]},
 \"scopeSpans\":[{\"scope\":{\"name\":\"lab\"},\"spans\":[
  {\"traceId\":\"$trace\",\"spanId\":\"$parent\",\"name\":\"$root\",\"kind\":2,\"startTimeUnixNano\":\"$now\",\"endTimeUnixNano\":\"$((now+500000000))\"},
  {\"traceId\":\"$trace\",\"spanId\":\"$child\",\"parentSpanId\":\"$parent\",\"name\":\"SELECT leads\",\"kind\":3,\"startTimeUnixNano\":\"$((now+100000000))\",\"endTimeUnixNano\":\"$((now+400000000))\"}
 ]}]}]}"
# (No "-o /dev/null": on Windows Git Bash that breaks curl. We read the status code from the end of the output instead.)
out=$(curl -s -w $'\n%{http_code}' -X POST http://localhost:4318/v1/traces -H 'content-type: application/json' -d "$body")
code=${out##*$'\n'}
echo "sent trace $trace (HTTP $code)"
[ "$code" = 200 ]
