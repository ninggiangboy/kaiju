#!/usr/bin/env bash
# Kiểm tra sau triển khai. Chạy tự động ngay sau mỗi lần triển khai ở bậc 3 và
# bậc 4, và chạy được bằng tay ở bậc 2.
#
#   ./infra/scripts/smoke.sh https://staging.kaiju.example.com
#
# Kiểm tra thứ hai là kiểm tra đáng giá nhất: nó là cách tự động DUY NHẤT phát
# hiện "realtime không chạy" — chế độ hỏng đặc trưng của kiến trúc này, vốn
# không sinh ra lỗi nào ở bất kỳ đâu.
set -euo pipefail

BASE="${1:?dùng: smoke.sh <base-url>}"
fail=0

step() { printf '\n▸ %s\n' "$1"; }
ok()   { printf '  ✓ %s\n' "$1"; }
bad()  { printf '  ✗ %s\n' "$1"; fail=1; }

step "Sức khoẻ của từng vai trò"
# Một điểm kiểm tra chung trả về "còn sống" cho mọi vai trò là vô dụng: worker
# vẫn chạy nhưng hàng đợi tồn đọng một giờ thì nó KHÔNG khoẻ.
for role in api realtime; do
  if curl -fsS --max-time 10 "$BASE/internal/health/$role" >/dev/null; then
    ok "$role"
  else
    bad "$role không khoẻ"
  fi
done

step "Luồng đồng bộ không bị đệm"
# Mở luồng và chờ nhịp tim đầu tiên. Nếu máy chủ trung gian đang đệm, phản hồi
# không tới trong thời gian chờ dù ứng dụng hoàn toàn bình thường.
if timeout 20 curl -fsSN --max-time 20 \
      -H 'Accept: text/event-stream' \
      "$BASE/api/sync/stream?probe=1" 2>/dev/null \
    | head -c 1 | grep -q .; then
  ok "nhận được byte đầu tiên trước khi luồng đóng"
else
  bad "không nhận được gì — nhiều khả năng máy chủ trung gian đang đệm"
fi

step "Độ trễ hàng đợi sự kiện"
lag=$(curl -fsS --max-time 10 "$BASE/internal/metrics/outbox-lag-seconds" 2>/dev/null || echo "")
if [[ -z "$lag" ]]; then
  bad "không đọc được chỉ số — tiến trình chuyển tiếp có thể chưa khởi động"
elif awk -v l="$lag" 'BEGIN{exit !(l < 60)}'; then
  ok "độ trễ ${lag}s"
else
  bad "độ trễ ${lag}s vượt ngưỡng"
fi

printf '\n'
[[ $fail -eq 0 ]] && { echo "✓ mọi kiểm tra sau triển khai đều qua"; exit 0; }
echo "✗ có kiểm tra không qua — KHÔNG coi lần triển khai này là thành công"
exit 1
