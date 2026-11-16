#!/usr/bin/env bash
# Online, consistent SQLite backup of the running compose stack (VACUUM INTO = safe while the API is serving).
# Run from repo root: bash 11-capstone/backup.sh
set -euo pipefail
export MSYS_NO_PATHCONV=1
C="docker compose -f 03-compose/docker-compose.yml --env-file .env"
OUT="backups/devlab-$(date +%Y%m%d-%H%M%S).sqlite"
mkdir -p backups
$C exec -T api node -e "
  const { DatabaseSync } = require('node:sqlite');
  require('fs').rmSync('/tmp/b.sqlite', { force: true });
  new DatabaseSync('/data/database.sqlite').exec(\"VACUUM INTO '/tmp/b.sqlite'\");"
docker cp "$($C ps -q api):/tmp/b.sqlite" "$OUT"
echo "backup written: $OUT ($(wc -c < "$OUT") bytes)"
