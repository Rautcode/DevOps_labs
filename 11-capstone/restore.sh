#!/usr/bin/env bash
# Disaster recovery drill: restore a backup into the api volume. Usage: bash 11-capstone/restore.sh backups/<file>
set -euo pipefail
export MSYS_NO_PATHCONV=1
BK="${1:?usage: restore.sh <backup file>}"
C="docker compose -f 03-compose/docker-compose.yml --env-file .env"
$C stop api
docker run --rm -v devlab_api-data:/data -v "$PWD/$(dirname "$BK"):/b:ro" node:24-slim sh -c \
  "rm -f /data/database.sqlite-wal /data/database.sqlite-shm && cp /b/$(basename "$BK") /data/database.sqlite && chown 1000:1000 /data/database.sqlite*"
$C start api
echo "restored from $BK. Verify: curl localhost:8080/healthz"
