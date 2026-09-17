#!/usr/bin/env bash
# Tier 3 - deploy to the VPS. Run this ON that host.
#
# The order below is mandatory (CON-69), not a convention:
#
#   migration -> worker and scheduler -> api and realtime
#
# Background processes must understand the new event format BEFORE anything
# produces it. Bringing api up first means that for a few dozen seconds, events
# in the new format are handled by a worker that does not know it.
set -euo pipefail

ENV_FILE="${KAIJU_ENV_FILE:-/etc/kaiju/staging.env}"
COMPOSE="docker compose --env-file $ENV_FILE -f $(dirname "$0")/../staging/docker-compose.yml"

[[ -f "$ENV_FILE" ]] || { echo "missing $ENV_FILE"; exit 1; }
# shellcheck disable=SC1090
source "$ENV_FILE"

case "${KAIJU_IMAGE:-}" in
  ""|*:latest|*:main|*:dev)
    echo "KAIJU_IMAGE must be an immutable tag bound to a commit (CON-70), got '${KAIJU_IMAGE:-empty}'"
    exit 1;;
esac

echo "> Pulling ${KAIJU_IMAGE}"
$COMPOSE pull

echo "> Migration"
$COMPOSE run --rm migrate

echo "> worker and scheduler"
$COMPOSE up -d --no-deps worker scheduler

echo "> api and realtime"
$COMPOSE up -d --no-deps api realtime frontend caddy

echo "> Post-deployment checks"
sleep 10
"$(dirname "$0")/smoke.sh" "https://${KAIJU_DOMAIN}"
