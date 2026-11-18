# Module 24 · interview and final (sourced by lab.sh)
redis_up() { [ "$(docker inspect -f '{{.State.Running}}' lab-redis 2>/dev/null)" = true ] || { docker rm -f lab-redis >/dev/null 2>&1; docker run -d --name lab-redis redis:7-alpine >/dev/null; sleep 2; }; }

part "PART · INTERVIEW"

interview "Cache it" "Interviewer: 'Product pages are slow because every view hits the database. A Redis cache is available (the practice container lab-redis). Store the product with the key product:7 and the value Blue Mug, so that it expires by itself within one minute.'" "rc SET <key> <value> EX <seconds>  (rc is the shortcut for redis-cli in the practice container)" <<'X'
redis_up; rc DEL product:7 >/dev/null
---
[ "$(rc GET product:7 | tr -d '\r')" = "Blue Mug" ] && t=$(rc TTL product:7 | tr -d '\r') && [ "$t" -ge 1 ] && [ "$t" -le 60 ]
---
rc SET product:7 "Blue Mug" EX 60 >/dev/null
X

interview "Protect the login" "Interviewer: 'Someone is hammering our login page. Show me a rate limiter that allows 3 requests per 10 seconds. Run the lab's limiter with 8 requests, so that exactly 3 are allowed, and save its output in playground/rl3.txt.'" "bash 24-system-design/ratelimit.sh LIMIT WINDOW REQUESTS > file" <<'X'
redis_up; rm -f playground/rl3.txt
---
[ "$(grep -c allowed playground/rl3.txt 2>/dev/null)" = 3 ] && [ "$(grep -c 429 playground/rl3.txt)" = 5 ]
---
bash 24-system-design/ratelimit.sh 3 10 8 > playground/rl3.txt
X

part "PART · MODULE FINAL"

final "A work queue" "Exam 1 of 3. Using a Redis list called emails, add four jobs in this order: a, b, c, d. Then let a worker take the FIRST TWO jobs. Afterwards exactly c and d must remain in the queue, in that order." "RPUSH adds at the end, LPOP takes from the front (twice). Check with: rc LRANGE emails 0 -1" <<'X'
redis_up; rc DEL emails >/dev/null
---
[ "$(rc LRANGE emails 0 -1 | tr -d '\r' | paste -sd,)" = "c,d" ]
---
rc RPUSH emails a b c d >/dev/null; rc LPOP emails >/dev/null; rc LPOP emails >/dev/null
X

final "Choose a sharding strategy" "Exam 2 of 3. You will add a 4th database shard to a live cluster and want to move as few keys as possible. Run the sharding comparison, read the result, and save the name of the better strategy (one word: mod or consistent) into playground/fewer.txt." "node 24-system-design/shard.js compare   then   echo consistent > playground/fewer.txt   (or mod, whichever moves fewer keys)" <<'X'
rm -f playground/fewer.txt
---
grep -qi consistent playground/fewer.txt 2>/dev/null && ! grep -qi '^mod' playground/fewer.txt
---
echo consistent > playground/fewer.txt
X

final "Stop the cascade" "Exam 3 of 3. A payment provider is slow. Run the circuit breaker simulation with a failure threshold of 2 and save the output to playground/cb.txt. The output must show the breaker going OPEN, HALF-OPEN and CLOSED." "node 24-system-design/breaker.js 2 > playground/cb.txt" <<'X'
rm -f playground/cb.txt
---
grep -q 'threshold = 2' playground/cb.txt 2>/dev/null && grep -q 'OPEN' playground/cb.txt && grep -q 'HALF-OPEN' playground/cb.txt && grep -q 'CLOSED' playground/cb.txt
---
node 24-system-design/breaker.js 2 > playground/cb.txt
X

docker rm -f lab-redis >/dev/null 2>&1
