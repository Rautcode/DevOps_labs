#!/usr/bin/env bash
# The cache-aside pattern: look in the cache first; only on a miss ask the slow database, then remember the answer.
# Needs the practice Redis (container lab-redis). Run it twice and compare.
r() { docker exec lab-redis redis-cli "$@" | tr -d '\r'; }
key="user:42"
start=$SECONDS
value=$(r GET "$key")
if [ -n "$value" ]; then
  echo "CACHE HIT : $value   (took $((SECONDS - start)) s, the database was not touched)"
else
  echo "CACHE MISS: asking the slow database ..."
  sleep 2                                   # pretend this is a slow query
  value="Asha, plan=pro"
  r SET "$key" "$value" EX 30 >/dev/null     # remember it for 30 seconds (the TTL)
  echo "            got: $value   (took $((SECONDS - start)) s) and stored it in the cache for 30 s"
fi
