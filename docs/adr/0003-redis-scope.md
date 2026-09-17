# ADR-0003: Redis chỉ làm cache, pub/sub, lock, rate limit — không phải source of truth

- **Trạng thái:** Accepted
- **Ngày:** 2026-09-17
- **Liên quan:** [ADR-0002](0002-postgres-only.md), [ADR-0006](0006-sse-over-websocket.md)

## Bối cảnh

Hệ thống chạy nhiều instance của nhiều app role. Một số nhu cầu không thể giải
quyết trong bộ nhớ của một tiến trình: phát tán thay đổi tới mọi instance
`realtime`, khoá phân tán, đếm rate limit, và cache kết quả tính quyền.

Redis giải quyết được tất cả, nhưng cũng dễ bị dùng quá tay thành nơi lưu trữ.

## Quyết định

Redis được dùng cho đúng năm việc:

| Việc | Mất dữ liệu thì sao |
|---|---|
| Cache (quyền hiệu lực, metadata workspace/project) | Tính lại từ Postgres |
| Pub/sub phát tán delta giữa các instance `realtime` | Client catch-up lại từ change log khi kết nối lại |
| Distributed lock (kể cả ShedLock cho `scheduler`) | Có thể chạy trùng job một lần |
| Rate limit | Bộ đếm về 0, nới lỏng tạm thời |
| Presence, typing indicator | Biến mất, tự dựng lại sau vài giây |

**Bất biến: mất sạch Redis thì hệ thống chậm đi và suy giảm, nhưng không sai và
không mất dữ liệu.**

## Lý do

- Mỗi thứ lưu ở Redis là một thứ phải nhất quán với Postgres. Giới hạn phạm vi
  khiến câu hỏi "cái nào đúng" không bao giờ phát sinh.
- Redis không tham gia được vào transaction của Postgres, nên bất cứ dữ liệu nào
  bắt buộc phải nhất quán với dữ liệu nghiệp vụ đều không được nằm ở đó.
- Phục hồi sau sự cố đơn giản: khởi động lại Redis rỗng là hệ thống tự ấm lên.

## Hệ quả

- Mọi đường đọc từ Redis đều phải có **đường dự phòng đọc từ Postgres**. Không
  được có code giả định Redis luôn có dữ liệu.
- Cache quyền phải được invalidate tường minh khi role hoặc membership đổi, và
  việc đó phải gắn với sự kiện thu hồi quyền của sync engine.
- Pub/sub của Redis là fire-and-forget: message phát ra khi một instance đang
  chết coi như mất. Điều này **chấp nhận được** vì client luôn có thể catch-up
  bằng cursor — nhưng nghĩa là pub/sub chỉ được dùng để *thúc* việc gửi, không
  bao giờ là nguồn duy nhất của một thay đổi.
- Không dùng Redis làm hàng đợi công việc; hàng đợi nằm ở bảng outbox trong
  Postgres, xem [ADR-0005](0005-outbox-db-job.md).

## Phương án đã loại

**Redis Streams làm hàng đợi thay outbox.** Sẽ mất tính nguyên tử giữa thay đổi
nghiệp vụ và việc phát event — đúng vấn đề outbox sinh ra để tránh.

**Lưu session ở Redis làm nguồn sự thật.** Session và refresh token là dữ liệu
bảo mật, cần bền và cần audit được; chúng nằm ở Postgres. Redis chỉ cache thông
tin đã giải mã của phiên.

**Bỏ Redis, dùng `LISTEN/NOTIFY` của Postgres để fanout.** Về mặt kỹ thuật là
làm được, nhưng sẽ gắn số lượng kết nối đồng bộ vào tải của database chính, và
`NOTIFY` có giới hạn payload. Redis tách được phần fanout tần suất cao ra khỏi
Postgres.
