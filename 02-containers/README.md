# 02 · Containers (Beginner, ~4h)

**Goal:** package the API and the web page as small, secure, reproducible images.

| File | What it teaches |
|---|---|
| [Dockerfile.api](Dockerfile.api) | multi-stage build, layer caching, non-root user, healthcheck |
| [Dockerfile.web](Dockerfile.web) | serve static files from unprivileged nginx, patch base-image CVEs |
| [nginx.conf.template](nginx.conf.template) | reverse proxy, caching headers, runtime DNS resolution, envsubst templating |

## Do it (from the repo root)
```bash
docker build -f 02-containers/Dockerfile.api -t devlab-api:lab app/api
docker build -f 02-containers/Dockerfile.web -t devlab-web:lab .
docker images | grep devlab                              # compare sizes
docker run --rm -d --name api -p 5000:5000 -e JWT_SECRET=$(openssl rand -hex 24) -e ADMIN_PASSWORD=x devlab-api:lab
curl localhost:5000/healthz ; docker ps                # STATUS shows (healthy) after ~15s
docker rm -f api
```
**Check:** `curl` returns `{"ok":true}` and `docker ps` shows `healthy`.

## Understand
- **Layers and cache.** `package*.json` is copied *before* the source, so editing code does not reinstall dependencies. Edit a file, rebuild, watch `CACHED`.
- **Multi-stage.** Build tools and dev dependencies never reach the final image: smaller and a smaller attack surface.
- **Non-root.** `USER 1000:1000`. A compromised process cannot write to the image or bind privileged ports.
- **Healthcheck.** The orchestrator needs to know "alive" from "ready".
- **`.dockerignore`.** [app/api/.dockerignore](../app/api/.dockerignore) keeps `.env`, local databases, tests and `node_modules` **out of the image**. Without it secrets and junk would be baked into every layer.

## Break it
1. Create `app/api/.env` with a fake value, remove `app/api/.dockerignore`, rebuild, and run `docker run --rm devlab-api:lab ls -a /app`. Is `.env` inside the image? Restore the ignore file and delete the fake `.env`.
2. Change the web base image to `nginx:latest` (root user). Does the container still start? Why is that worse?
3. In the nginx template replace `proxy_pass $api;` with a fixed `proxy_pass http://api:5000;`, start the web container **without** the api. It crashes at startup. That is why the template resolves the upstream per request: a real bug found while building this lab.

## Industry notes
- Pin base images (tag now, **digest** later) and rebuild regularly: unpatched base images are the #1 source of CVEs (module 09 measures this).
- One process per container, logs to stdout, config from env, no state inside the container.
- Never put secrets in `ENV`/`ARG`/`COPY`; use runtime injection.

**Next:** [03 · Compose](../03-compose/README.md)
