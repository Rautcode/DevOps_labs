# 24 · System design (Job-ready extra, ~3h)

> **Guided version:** `bash lab.sh 24`. It opens after module 12. This page is the reference.

**Goal:** answer "design X for 10 million users" by combining seven building blocks, each of which you run in miniature.

## The five steps (every time)
1. **Clarify** the requirements and the scale. 2. **Estimate** (requests per second, storage). 3. **Sketch** the simplest design. 4. **Scale** the bottlenecks with the blocks below. 5. **Discuss** trade-offs and failure.

## The seven blocks
| Block | Idea | Hands-on here |
|---|---|---|
| **Caching** | keep answers in fast memory; cache-aside, TTL, LRU; invalidation is the hard part | Redis: `SET ... EX`, a cache-aside script (MISS then HIT), eviction policy |
| **Queues** | decouple slow work; FIFO, acknowledgements, retries, idempotent jobs | a Redis list as a queue (`RPUSH` / `LPOP`) |
| **Rate limiting** | fixed window, sliding window, token bucket; HTTP 429; shared counter | `ratelimit.sh`: INCR plus EXPIRE in Redis |
| **Load balancing** | round robin, least connections, IP hash; layer 4 vs 7; health checks | module 12, part D (nginx) |
| **CDN** | cache at the edge, near the user; origin only on a miss | module 12, part G (nginx `proxy_cache`: MISS then HIT) |
| **Sharding** | split data by a shard key; hot shards; hash-mod vs consistent hashing | `shard.js`: 75% of keys move vs 25% |
| **Circuit breaker** | CLOSED, OPEN, HALF-OPEN; fail fast; timeouts, backoff, bulkheads | `breaker.js`: a simulated outage |

**Concepts only (no hands-on):** replication and the CAP trade-off (leader and followers, consistency or availability during a network split) and queue versus event log (what Kafka adds: partitions, offsets, replay, idempotent consumers). Each has a spoken answer in the lab and in [INTERVIEW-ANSWERS.md](../INTERVIEW-ANSWERS.md).

## Files
`cache-aside.sh`, `ratelimit.sh`, `shard.js`, `breaker.js`. Read them: each is under 40 lines.

## Practise out loud
Pick a system (URL shortener, chat app, news feed, ride sharing) and spend 10 minutes on the five steps. Record yourself once; it is uncomfortable and very effective.

## Where to read more
See [STUDY-GUIDE.md](../STUDY-GUIDE.md) and [RESOURCES.md](../RESOURCES.md).
