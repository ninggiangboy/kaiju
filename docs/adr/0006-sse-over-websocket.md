# ADR-0006: SSE cho luồng đồng bộ, mutation qua HTTP POST

- **Trạng thái:** Accepted — cách xác thực luồng đồng bộ được chốt bởi [ADR-0018](0018-sse-stream-cookie-auth.md)
- **Đã thay đổi (2026-09-23):** quyết định dùng SSE giữ nguyên. Câu "xác thực đi tự nhiên qua cookie hoặc header" ở phần Lý do chỉ đúng với cookie: `EventSource` không cho đặt header, và token truy cập không nằm trong cookie. Luồng đồng bộ nay xác thực bằng một cookie riêng loại `stream`, xem [ADR-0018](0018-sse-stream-cookie-auth.md)
- **Ngày:** 2026-09-17
- **Liên quan:** [ADR-0003](0003-redis-scope.md), [ADR-0007](0007-build-own-sync-engine.md), [realtime-and-sync.md](../04-system-design/realtime-and-sync.md)

## Bối cảnh

Client cần nhận thay đổi theo thời gian thực từ server, và phải **không bao giờ
mất delta** khi mất kết nối rồi nối lại. Luồng dữ liệu chính là một chiều
server → client; chiều ngược lại chỉ có mutation do người dùng tạo ra, tần suất
thấp hơn nhiều.

## Quyết định

Luồng đồng bộ dùng **Server-Sent Events**. Trường `id` của mỗi SSE event mang
**cursor** của client; khi kết nối lại, trình duyệt tự gửi `Last-Event-ID` và
server replay từ vị trí đó.

Mutation đi qua **HTTP POST** riêng biệt, kèm idempotency key.

WebSocket để dành cho collaborative rich-text editing ở phase sau, và khi đó sẽ
là **một kênh riêng**, không thay thế luồng đồng bộ này.

## Lý do

- **Lý do quyết định:** `Last-Event-ID` chính là cơ chế resume-from-seq mà sync
  engine cần. Trình duyệt tự lo reconnect, backoff và gửi lại vị trí. Với
  WebSocket, toàn bộ phần đó phải tự viết — và đó đúng là phần dễ sai nhất, vì
  mất delta lúc reconnect là lỗi âm thầm, khó tái hiện.
- Xác thực đi tự nhiên qua cookie hoặc header. Trình duyệt không cho đặt header
  khi mở WebSocket, nên xác thực WS phải nhét token vào query string (lộ trong
  log) hoặc tự viết state machine "chưa xác thực".
- SSE chỉ là một request GET dài, mọi proxy và load balancer đều hiểu, không cần
  cấu hình upgrade.
- Mutation qua POST **là ưu điểm, không phải hạn chế**: mutation cần đúng ngữ
  nghĩa request/response — idempotency key, mã lỗi, validation error có cấu trúc.
  Nhồi những thứ đó vào message WebSocket là tự dựng lại HTTP.
- Vì frontend là local-first với optimistic update, độ trễ một vòng của POST
  không ai cảm nhận được: giao diện đã đổi trước khi request rời máy.

## Hệ quả

- **Phải có heartbeat** (dòng comment `:ping`) mỗi 15–30 giây, nếu không load
  balancer sẽ đóng kết nối idle.
- **Phải tắt buffering ở reverse proxy** (`X-Accel-Buffering: no`, `proxy_buffering off`
  với nginx), nếu không event sẽ bị giữ lại và triệu chứng là "realtime không chạy".
- Giới hạn 6 kết nối mỗi origin trên HTTP/1.1 về lý thuyết là vấn đề khi mở nhiều
  tab, nhưng SharedWorker giữ **đúng một** stream cho mọi tab, cộng thêm HTTP/2
  multiplex, nên vấn đề này biến mất.
- Không có kênh client → server tần suất cao. Presence và typing indicator phải
  dùng POST định kỳ; đủ dùng cho Kaiju, nhưng là giới hạn thật cần biết.
- Server giữ một kết nối mở cho mỗi client đang hoạt động; cần virtual thread để
  không ghim platform thread cho mỗi kết nối.
- Transport phải nằm sau một interface ở phía client, để đổi sang WebSocket sau
  này chỉ phải sửa một chỗ.

## Phương án đã loại

**WebSocket cho luồng đồng bộ.** Phải tự viết reconnect, resume, xác thực và
protocol; đổi lại chỉ được chiều ngược tần suất cao mà hiện chưa cần.

**STOMP trên WebSocket.** Spring có sẵn, nhưng protocol đồng bộ cần `seq`,
resume-from-cursor và ack mutation — STOMP không có chỗ cho những khái niệm đó,
dùng nó sẽ là chống lại framework.

**Long polling.** Hoạt động ở mọi nơi nhưng độ trễ cao hơn và tốn kết nối hơn,
trong khi không đơn giản hơn SSE là bao.
