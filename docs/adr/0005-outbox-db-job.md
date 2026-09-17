# ADR-0005: Transactional outbox bằng database và job nền, không dùng Kafka/CDC

- **Trạng thái:** Accepted
- **Ngày:** 2026-09-17
- **Liên quan:** [ADR-0001](0001-modular-monolith-multi-app.md), [ADR-0002](0002-postgres-only.md), [ADR-0003](0003-redis-scope.md), [events-and-outbox.md](../04-system-design/events-and-outbox.md)

## Bối cảnh

Các module giao tiếp bất đồng bộ với nhau bằng domain event: đổi trạng thái issue
thì phải gửi notification, cập nhật search index, chạy automation rule, ghi
activity. Nếu phát event trực tiếp trong bộ nhớ, một lần app chết giữa chừng là
mất event mà dữ liệu đã đổi — và không có cách nào biết để sửa.

Yêu cầu đặt ra từ đầu: **không Kafka, không CDC**, giữ hệ thống ở mức "đơn giản
nhưng đầy đủ".

## Quyết định

Domain event được ghi vào **bảng `outbox` trong Postgres, cùng transaction với
thay đổi nghiệp vụ**. Một relay worker trong app role `worker` đọc bảng này bằng
`FOR UPDATE SKIP LOCKED` và dispatch tới consumer, kèm retry có backoff, dead
letter và công cụ replay.

Cơ chế theo dõi sự kiện có sẵn của framework nền **không được dùng**; framework
đó chỉ được dùng để kiểm tra biên giới module.

## Lý do

- Ghi cùng transaction là điều kiện duy nhất để không bao giờ xảy ra "dữ liệu đã
  đổi nhưng event mất" hoặc ngược lại.
- `SKIP LOCKED` cho phép nhiều worker chạy song song mà không cần message broker.
  `LISTEN/NOTIFY` kéo độ trễ xuống mức vài chục mili giây.
- Kafka đắt về vận hành và chỉ đáng giá khi cần nhiều consumer group độc lập,
  replay dài hạn, hoặc thông lượng rất cao. Không có nhu cầu nào trong số đó.
- CDC bắt thay đổi ở mức row chứ không ở mức **ý định nghiệp vụ**. Consumer cần
  biết "issue đã được transition bởi ai, từ trạng thái nào", không phải "cột
  status của dòng X đổi giá trị".
- Cơ chế theo dõi sự kiện sẵn có của framework nền chỉ dispatch **trong cùng
  tiến trình**; ở đây consumer chạy ở app role khác nên nó không tới được.
  Duy trì hai cơ chế song song sẽ rối hơn là tự viết một cơ chế đầy đủ.

## Hệ quả

- Giao hàng là **at-least-once**, nên **mọi consumer bắt buộc phải idempotent**.
  Đây là ràng buộc khó nhất và phải được test tử tế.
- Phải tự xây và tự bảo trì: retry, backoff, dead letter, replay, shard theo
  aggregate để giữ thứ tự. Không được lược bớt phần nào — thiếu dead letter thì
  một event hỏng sẽ chặn hoặc lặp vô hạn.
- `event_version` phải có **ngay từ event đầu tiên**. Thêm vào sau khi đã có dữ
  liệu là rất đau.
- Bảng outbox cần retention job, nếu không nó sẽ là bảng lớn nhất hệ thống.
- Connection dùng cho `LISTEN/NOTIFY` **không được nằm trong Hikari pool**, vì
  pool sẽ trả và reset nó, làm mất listener một cách âm thầm.
- Tải ghi của Postgres tăng thêm một dòng cho mỗi domain event. Chấp nhận được ở
  quy mô hiện tại.

## Phương án đã loại

**Kafka.** Chi phí vận hành lớn, thêm một hệ phân tán có trạng thái phải hiểu và
phải vận hành, trong khi không có nhu cầu nào tương xứng.

**CDC (Debezium).** Vẫn cần Kafka hoặc tương đương ở phía sau, và event ở mức row
không mang đủ ý nghĩa nghiệp vụ.

**Cơ chế theo dõi sự kiện sẵn có của framework nền.** Hợp với consumer trong cùng
tiến trình, nhưng không dispatch xuyên process — mà đó chính là mô hình triển khai
đã chọn ở [ADR-0001](0001-modular-monolith-multi-app.md).

**Phát event trực tiếp trong bộ nhớ.** Đơn giản nhất và sai nhất: mất event khi
tiến trình chết, không retry, không quan sát được.
