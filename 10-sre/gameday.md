# Game day: break it on purpose

Run on the compose stack with observability up. Write your **prediction first**, run it, then compare.
Set `C="docker compose -f 03-compose/docker-compose.yml -f 08-observability/compose.observability.yml --env-file .env"`.

| # | Inject | Command | Expect | Learn |
|---|---|---|---|---|
| 1 | Kill the API | `docker stop devlab-api-1` | `EndpointDown` fires in 1-2 min; site returns 502 | detection time, runbook quality |
| 2 | Crash loop | set `JWT_SECRET=short` in `.env`, `$C up -d api` | container restarts, logs say FATAL | fail-fast config validation |
| 3 | Memory pressure | lower the api memory limit to `32M`, `$C up -d` | OOMKilled | limits vs requests |
| 4 | Lose the database | delete `/data/database.sqlite`, then run `restore.sh` | data gone, then back | RPO / RTO: measure both |
| 5 | Bad deploy | break `nginx.conf.template`, rebuild web | healthcheck stops the rollout | health checks gate deploys |
| 6 | Frozen dependency | `docker pause devlab-api-1` for 60s | timeouts, latency alert | timeouts and retries |

Kubernetes variants: `kubectl delete pod devlab-api-0`, `kubectl drain <node>`, `kubectl scale sts/devlab-api --replicas=3` (find out why that last one is wrong).

Finish by writing a [postmortem](postmortem-template.md) for one scenario.
