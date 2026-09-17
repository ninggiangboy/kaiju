#!/usr/bin/env bash
# Bậc 3 — triển khai lên VPS. Chạy TRÊN máy chủ đó.
#
# Thứ tự dưới đây là bắt buộc (CON-69), không phải quy ước:
#
#   migration → worker và scheduler → api và realtime
#
# Lý do: tiến trình nền phải hiểu được định dạng sự kiện mới TRƯỚC KHI có ai
# sinh ra chúng. Đưa api lên trước nghĩa là trong vài chục giây, sự kiện định
# dạng mới bị xử lý bởi worker chưa biết định dạng đó.
set -euo pipefail

ENV_FILE="${KAIJU_ENV_FILE:-/etc/kaiju/staging.env}"
COMPOSE="docker compose --env-file $ENV_FILE -f $(dirname "$0")/../staging/docker-compose.yml"

[[ -f "$ENV_FILE" ]] || { echo "thiếu $ENV_FILE"; exit 1; }
# shellcheck disable=SC1090
source "$ENV_FILE"

case "${KAIJU_IMAGE:-}" in
  ""|*:latest|*:main|*:dev)
    echo "KAIJU_IMAGE phải là thẻ cố định gắn với commit (CON-70), đang là '${KAIJU_IMAGE:-trống}'"
    exit 1;;
esac

echo "▸ Tải ảnh ${KAIJU_IMAGE}"
$COMPOSE pull

echo "▸ Migration"
$COMPOSE run --rm migrate

echo "▸ worker và scheduler"
$COMPOSE up -d --no-deps worker scheduler

echo "▸ api và realtime"
$COMPOSE up -d --no-deps api realtime frontend caddy

echo "▸ Kiểm tra sau triển khai"
sleep 10
"$(dirname "$0")/smoke.sh" "https://${KAIJU_DOMAIN}"
