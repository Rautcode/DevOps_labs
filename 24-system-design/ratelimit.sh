#!/usr/bin/env bash
# A fixed-window rate limiter built on Redis: allow LIMIT requests per WINDOW seconds, then answer 429.
# usage: bash 24-system-design/ratelimit.sh [LIMIT=5] [WINDOW_SECONDS=10] [REQUESTS=8]
limit=${1:-5}; window=${2:-10}; n=${3:-8}
r() { docker exec lab-redis redis-cli "$@" | tr -d '\r'; }
r DEL rl:demo >/dev/null
for i in $(seq 1 "$n"); do
  count=$(r INCR rl:demo)                              # atomic counter: one more request in this window
  [ "$count" = 1 ] && r EXPIRE rl:demo "$window" >/dev/null   # the first request starts the window
  if [ "$count" -le "$limit" ]; then
    echo "request $i: allowed ($count of $limit)"
  else
    echo "request $i: 429 Too Many Requests, retry in $(r TTL rl:demo) s"
  fi
done
