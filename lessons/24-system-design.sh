# System design: caching, queues, rate limiting, load balancing, CDN, sharding, circuit breaker (about 3h)
title "Module 24 · System design"
mission "In the interview they say: design a URL shortener that 10 million people use. You do not need a perfect answer, you need the right building blocks and the reasons for them. This module gives you each block in ten minutes of hands-on practice: you cache, queue, rate-limit, shard and break circuits for real, then put them together."
explain "Seven building blocks appear in almost every system design: caching, queues, rate limiting, load balancing, CDN, sharding and circuit breakers. You will run a small version of each one on your own computer, so that in an interview you can say what happens, not just the word."
docker rm -f lab-redis >/dev/null 2>&1

part "PART A · How to approach a design question"
learn "Five steps, every time" "1) CLARIFY: ask what the system must do and how big it is (users, requests, data), before drawing anything. 2) ESTIMATE: a rough number is enough (requests per second, storage per year). 3) SKETCH the simplest design that works: clients, a service, a database. 4) SCALE the bottlenecks with the building blocks in this module, each with a reason. 5) DISCUSS trade-offs and failure: what if this part dies, what if traffic doubles? Saying why matters more than the exact answer."
art "The usual shape of a scalable system" <<'ART'
   users --> [ CDN ] --> [ load balancer ] --> [ app server ] x N
                                                  |      |      |
                                       [ rate limiter ]  |   [ queue ] --> [ workers ]
                                                         v
                                       [ cache ] --> [ database ] (sharded + replicas)
ART
mcq "1 million users each make 10 requests a day. About how many requests per second is that on average?" "About 12|About 115|About 1,150|About 10,000" 2 "10 million requests per day divided by 86,400 seconds is about 115 per second. Peak traffic is often 2 to 5 times the average."
quiz "Why do interviewers want you to ask questions BEFORE you start drawing?" "requirement|scope|assum|constraint|scale|users|clarif|unknown|different|trade|size" "The right design depends on the requirements and the scale. A chat app for 100 people and one for 100 million are completely different systems, so you must find out which one you are building."

part "PART B · Caching"
learn "Keep answers close" "A cache stores the result of slow work (a database query, a computed page) in fast memory so the next request is instant. The common pattern is CACHE-ASIDE: look in the cache; on a miss, ask the database, then store the answer with a TTL (time to live). Caches exist at every layer: browser, CDN, your app, the database. The hard part is INVALIDATION: when the data changes, how do stale copies disappear? A short TTL is the simplest answer. A full cache evicts old entries, usually the least recently used (LRU)."
art "Caches in layers" <<'ART'
   browser cache -> CDN (edge) -> app cache (Redis) -> database
   fastest, closest ---------------------------------> slowest, truth
   a HIT stops the request early; a MISS goes one layer deeper
ART
step "Start Redis, a fast in-memory store used as a cache" "PONG. Redis is running in a container named lab-redis." ok 'PONG' <<'CMD'
docker rm -f lab-redis >/dev/null 2>&1; docker run -d --name lab-redis redis:7-alpine >/dev/null; sleep 2; rc PING
CMD
step "Store a value and read it back" "hello cache. A cache is just a key and a value in memory." ok 'hello cache' <<'CMD'
rc SET greeting "hello cache" >/dev/null; rc GET greeting
CMD
step "Store a value that expires after 5 seconds (a TTL)" "5 (or 4) seconds left, then after waiting the value is gone: after 6 seconds: []" ok 'after 6 seconds: \[\]' <<'CMD'
rc SET session:1 alice EX 5 >/dev/null; echo "ttl: $(rc TTL session:1) s"; sleep 6; echo "after 6 seconds: [$(rc GET session:1)]"
CMD
predict "A value is cached with a 30 second TTL. The database row changes after 10 seconds. What does a reader see at second 20?" "The new value, instantly|The OLD value, until the TTL ends|An error|Nothing" 2 "A cache does not know the database changed. Readers see the stale copy until the TTL expires or you delete the key. That is the invalidation problem."
step "Cache-aside, first run: a MISS that asks the slow database (2 seconds)" "CACHE MISS, about 2 seconds, then the value is stored for 30 seconds." ok 'CACHE MISS' <<'CMD'
rc DEL user:42 >/dev/null; bash 24-system-design/cache-aside.sh
CMD
step "Run it again: a HIT, instant, and the database is not touched" "CACHE HIT in 0 seconds. This is why caches protect your database from load." ok 'CACHE HIT' <<'CMD'
bash 24-system-design/cache-aside.sh
CMD
step "Set the eviction policy to least recently used" "allkeys-lru. When memory is full, Redis drops the entries nobody asked for lately." ok 'allkeys-lru' <<'CMD'
rc CONFIG SET maxmemory 2mb >/dev/null; rc CONFIG SET maxmemory-policy allkeys-lru >/dev/null; rc CONFIG GET maxmemory-policy
CMD
mcq "What is the hardest part of caching?" "Knowing when cached data is stale (invalidation)|Installing the cache|Choosing a port number|Making the cache faster" 1 "A cache is easy to add. Keeping it correct when the data underneath changes is the difficult part."

part "PART C · Queues"
learn "Do slow work later" "A queue sits between a producer (the web request) and a consumer (a worker). The request says do this job later and returns at once; workers take jobs at their own speed. This smooths traffic spikes (the queue grows instead of the site falling over), lets slow work (email, image resizing, reports) happen in the background, and lets you retry failures. Real queues (SQS, RabbitMQ, Kafka) hand a job out with an acknowledgement: if the worker does not confirm in time, the job is delivered again, so jobs must be safe to repeat (idempotent)."
art "A queue decouples the two sides" <<'ART'
   web request --push--> [ job | job | job | job ] --pop--> worker 1
   (returns at once)          the queue (FIFO)       \--pop--> worker 2
   a spike only makes the queue longer, the site stays up
ART
step "Producers add three jobs while no worker is running" "3. The jobs wait safely in the queue." ok '^3$' <<'CMD'
rc DEL jobs >/dev/null; rc RPUSH jobs "email:welcome" "resize:photo1" "report:daily" >/dev/null; rc LLEN jobs
CMD
step "A worker takes the jobs, oldest first (FIFO: first in, first out)" "worker got: email:welcome, then resize:photo1, then report:daily." ok 'worker got: email:welcome' <<'CMD'
for i in 1 2 3; do echo "worker got: $(rc LPOP jobs)"; done
CMD
step "Is anything left?" "left in the queue: 0." ok 'queue: 0' <<'CMD'
echo "left in the queue: $(rc LLEN jobs)"
CMD
predict "A worker pops a job with this simple command, then crashes before finishing. What happens to the job?" "It is lost|It is retried automatically|It goes to the next worker|It waits in the queue" 1 "A plain pop removes the job for good. Real queues keep it invisible until the worker acknowledges, and redeliver it if no ack arrives (at-least-once delivery)."
task "Order matters" "Add three jobs, first to last: one two three, to a list called tasks:  rc RPUSH tasks one two three   Then take them all out, oldest first, and save what you took, one per line, into playground/order.txt  for example:  for i in 1 2 3; do rc LPOP tasks; done > playground/order.txt   The file must read one, two, three." "RPUSH adds at the end, LPOP takes from the front. That is a queue." <<'X'
[ "$(paste -sd, playground/order.txt 2>/dev/null | tr -d '\r')" = "one,two,three" ]
---
rc DEL tasks >/dev/null; rc RPUSH tasks one two three >/dev/null; for i in 1 2 3; do rc LPOP tasks; done | tr -d '\r' > playground/order.txt
X
quiz "Give two reasons to put a queue between a web request and slow work such as sending an email." "fast|respon|spike|burst|retry|decoupl|buffer|background|async|fail|reliab|smooth|wait" "The user gets a fast answer instead of waiting, spikes are absorbed by the queue, failed jobs can be retried, and workers can be scaled separately from the web servers."

part "PART D · Rate limiting"
learn "Say no before the system falls over" "A rate limiter caps how many requests one client may make in a time window, to stop abuse, accidents (a buggy client in a loop) and overload. Over the limit, answer HTTP 429 Too Many Requests, ideally with a Retry-After header. Algorithms: FIXED WINDOW (a counter per window: simple, but a burst at the edge of two windows can double the rate), SLIDING WINDOW (smoother), TOKEN BUCKET (tokens refill at a steady rate, allowing short bursts). The counter must be shared: if you run five app servers, keep it in Redis, not in each server's memory."
art "Fixed window: 5 requests per 10 seconds" <<'ART'
   second:   0 1 2 3 4 5 6 7 8 9 | 10 ...
   request:  1 2 3 4 5 6 7 8        window resets at second 10
   result:   allowed x5, then 429 429 429
ART
step "Run the Redis rate limiter: 8 requests, 5 allowed per 10 seconds" "The first 5 requests are allowed, the rest get 429 Too Many Requests." ok '429' <<'CMD'
bash 24-system-design/ratelimit.sh 5 10 8
CMD
predict "Five app servers each keep their OWN in-memory counter with a limit of 5. How many requests can one client really make?" "5|Up to 25, one limit per server|0|Unlimited" 2 "Each server counts separately, so the real limit is 5 times 5. That is why the counter must live in a shared store such as Redis."
step "See the rate limiter in this lab's own API" "Lines that mention the limit in app/api/server.js. The same idea, written in the app." ok 'imit' <<'CMD'
grep -n -i "limit" app/api/server.js | head -6
CMD
task "Tune the limit" "Run the rate limiter so that exactly 2 of 6 requests are allowed, and save the output into playground/rl.txt:  bash 24-system-design/ratelimit.sh 2 10 6 > playground/rl.txt" "The three numbers are: how many are allowed, the window in seconds, and how many requests to send." <<'X'
[ "$(grep -c allowed playground/rl.txt 2>/dev/null)" = 2 ] && [ "$(grep -c 429 playground/rl.txt)" = 4 ]
---
bash 24-system-design/ratelimit.sh 2 10 6 > playground/rl.txt
X
mcq "Which HTTP status code means: you sent too many requests?" "401|403|429|503" 3 "429 Too Many Requests. 401 is not signed in, 403 is not allowed, 503 is the service is unavailable."

part "PART E · Load balancing and CDN"
learn "Spread the work, move the content closer" "A LOAD BALANCER spreads requests over many servers and stops sending to dead ones (health checks). Round robin takes turns; least connections picks the least busy server; IP hash keeps one client on one server. A layer 4 balancer works on connections (fast, simple); a layer 7 balancer reads HTTP and can route by path or header. A CDN is a cache with servers around the world: static files (images, scripts, videos) are served from the point closest to the user, and your origin is asked only on a miss. You built a load balancer and an edge cache by hand in module 12 (parts D and G)."
art "Where each one sits" <<'ART'
   user (Mumbai) --> CDN edge (Mumbai) --HIT--> answer in a few ms
                         | MISS
                         v
                    [ load balancer ] --> server A / server B / server C  (the origin)
ART
mcq "Which balancing method keeps one user on the same server, useful when the server holds the user's session in memory?" "Round robin|Least connections|IP hash (sticky)|Random" 3 "IP hash or cookie stickiness sends the same client to the same server. Better still: keep sessions in Redis so any server can answer."
mcq "What should you NOT cache on a shared CDN?" "A logo image|A JavaScript file|A page with one user's private account data|A stylesheet" 3 "Personal pages must not be shared between users. Cache static and public content; mark private responses Cache-Control: private."

part "PART F · Sharding"
learn "Split the data" "One database server eventually runs out of disk, memory or write speed. SHARDING splits the data over several servers, each holding a part, chosen by a SHARD KEY (for example the user id). A good key spreads data and traffic evenly and keeps related rows together; a bad key creates a HOT SHARD that gets most of the traffic. The simple method is hash(key) mod N, but when N changes almost every key moves to a different shard. CONSISTENT HASHING places shards on a ring so adding one moves only about 1/N of the keys. Replicas (copies) are different: they add read capacity and safety, sharding adds write capacity and size."
art "Sharding by user id" <<'ART'
   user:7   --hash--> shard 1
   user:12  --hash--> shard 0       [ shard 0 ]  [ shard 1 ]  [ shard 2 ]
   user:31  --hash--> shard 2        each shard = its own database server
   the router (app or proxy) picks the shard from the key
ART
step "Spread 1000 keys over 3 shards with hash-mod" "Three shards with roughly equal numbers of keys (about 333 each). The hash spreads them evenly." ok 'shard 2' <<'CMD'
node 24-system-design/shard.js mod 3
CMD
predict "You add a 4th shard and keep using hash(key) mod N. Roughly what share of the keys moves to a different shard?" "About 25%|About 50%|About 75%|None" 3 "Going from mod 3 to mod 4 changes the answer for about three quarters of the keys. That means copying most of your data while the system is live."
step "Compare the two strategies when a 4th shard is added" "hash-mod moves about 75% of the keys, consistent hashing about 25%." ok 'consistent hashing' <<'CMD'
node 24-system-design/shard.js compare
CMD
quiz "A chat app stores messages. Which shard key would you choose: the message timestamp, or the conversation id? Why?" "conversation|chat|together|even|hot|distribut|spread|recent|latest|same shard|related" "The timestamp sends all new messages to the newest shard (a hot shard). The conversation id spreads the load and keeps one conversation's messages on one shard, so reading a chat touches one server."

part "PART G · Circuit breaker"
learn "Fail fast when a dependency is down" "When a service your code calls is slow or down, every call waits for a timeout, threads pile up, and the failure spreads to you (a cascading failure). A CIRCUIT BREAKER watches the calls. CLOSED: calls pass through. After a number of failures it goes OPEN: calls fail immediately, without trying, which saves resources and lets the dependency recover. After a cooldown it goes HALF-OPEN and lets one trial call through: success closes it, failure opens it again. Pair it with timeouts, retries with exponential backoff and jitter, and bulkheads (separate pools so one dependency cannot use all your threads)."
art "The three states" <<'ART'
                 failures >= threshold
     [ CLOSED ] ----------------------> [ OPEN ]
     calls flow        ^                 calls fail fast
                       |                      |
        trial worked   |                      | after the cooldown
                       |                      v
                       +----------------- [ HALF-OPEN ]
                      (trial fails: back to OPEN)    one trial call allowed
ART
step "Run the simulation: a dependency is down for 6 seconds" "The breaker OPENS after 3 failures, fast-fails, tries a HALF-OPEN trial, and closes again once the dependency recovers. Compare the waiting time with and without it." ok 'WITHOUT the breaker' <<'CMD'
node 24-system-design/breaker.js 3
CMD
mcq "In which state does the breaker let exactly ONE trial call through?" "CLOSED|OPEN|HALF-OPEN|BROKEN" 3 "HALF-OPEN is the testing state between the cooldown ending and the decision to close or re-open."
task "A more sensitive breaker" "Run the simulation with a failure threshold of 2 and save the output to playground/breaker.txt:  node 24-system-design/breaker.js 2 > playground/breaker.txt   It must show the breaker going OPEN, HALF-OPEN and CLOSED." "The number after the script name is the failure threshold." <<'X'
grep -q 'threshold = 2' playground/breaker.txt 2>/dev/null && grep -q 'OPEN' playground/breaker.txt && grep -q 'HALF-OPEN' playground/breaker.txt && grep -q 'CLOSED' playground/breaker.txt
---
node 24-system-design/breaker.js 2 > playground/breaker.txt
X

part "PART H · Put it together"
learn "Design a URL shortener" "Requirements: turn a long URL into a short code and redirect from the code. Reads (redirects) are about 100 times more common than writes (creating links). Design: a load balancer in front of stateless app servers; a database table code to long URL (shard by code when it grows, replicas for reads); a cache (Redis) for hot codes so most redirects never touch the database; a CDN or edge for the most popular links; a rate limiter on link creation to stop abuse; a queue for slow work such as click analytics, so a redirect never waits for it; timeouts and a circuit breaker around any external service such as a safe-browsing check."
art "A URL shortener" <<'ART'
   click short.ly/ab12 --> CDN/edge --miss--> load balancer --> app servers
                                                                  |   |    \
                                                       cache (Redis)  |     queue --> analytics workers
                                                         miss |       rate limiter (creates only)
                                                              v
                                                   database, sharded by code (+ read replicas)
ART
mcq "Reads are 100 times more common than writes. Which block helps MOST?" "Caching (and a CDN) for popular codes|A bigger write queue|Sharding by timestamp|Removing the database" 1 "When reads dominate, serve them from caches so most requests never reach the database."
quiz "In your own words: where would you use a cache, a queue and a rate limiter in a URL shortener, and why?" "cache|redis|queue|rate|limit|abuse|analytic|redirect|hot|popular|read|write|slow" "Cache the hot code to URL lookups so redirects are instant. Queue the click analytics so redirects never wait for them. Rate-limit link creation so one client cannot flood the system."

part "PART I · Clean up"
step "Stop the practice Redis" "lab-redis removed." ok 'lab-redis' <<'CMD'
docker rm -f lab-redis
CMD
explain "Done! You can now explain and demonstrate the seven building blocks. Practise out loud: pick a system (a chat app, a photo feed, a ride-sharing app) and walk through the five steps from part A."
