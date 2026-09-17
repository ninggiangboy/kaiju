#!/usr/bin/env bash
# Post-deployment checks. Run automatically right after every tier 3 and tier 4
# deployment, and by hand against tier 2.
#
#   ./infra/scripts/smoke.sh https://staging.kaiju.example.com
#
# The second check is the most valuable of the three: it is the ONLY automatic
# way to detect "realtime does not work" - this architecture's characteristic
# failure mode, which produces no error anywhere.
set -euo pipefail

BASE="${1:?usage: smoke.sh <base-url>}"
fail=0

step() { printf '\n> %s\n' "$1"; }
ok()   { printf '  PASS %s\n' "$1"; }
bad()  { printf '  FAIL %s\n' "$1"; fail=1; }

step "Per-role health"
# A shared probe that returns "alive" for every role is useless: a worker can be
# running while its queue is an hour behind, and it is NOT healthy.
for role in api realtime; do
  if curl -fsS --max-time 10 "$BASE/internal/health/$role" >/dev/null; then
    ok "$role"
  else
    bad "$role is not healthy"
  fi
done

step "Sync stream is not buffered"
# Open the stream and wait for the first heartbeat. If the reverse proxy is
# buffering, nothing arrives within the timeout even though the application is
# perfectly fine.
if timeout 20 curl -fsSN --max-time 20 \
      -H 'Accept: text/event-stream' \
      "$BASE/api/sync/stream?probe=1" 2>/dev/null \
    | head -c 1 | grep -q .; then
  ok "first byte arrived before the stream closed"
else
  bad "nothing arrived - most likely the reverse proxy is buffering"
fi

step "Event queue lag"
lag=$(curl -fsS --max-time 10 "$BASE/internal/metrics/outbox-lag-seconds" 2>/dev/null || echo "")
if [[ -z "$lag" ]]; then
  bad "could not read the metric - the relay process may not have started"
elif awk -v l="$lag" 'BEGIN{exit !(l < 60)}'; then
  ok "lag ${lag}s"
else
  bad "lag ${lag}s is over the threshold"
fi

printf '\n'
[[ $fail -eq 0 ]] && { echo "PASS: every post-deployment check succeeded"; exit 0; }
echo "FAIL: a check did not pass - do NOT treat this deployment as successful"
exit 1
