# ADR-0001: Modular monolith triển khai thành nhiều app, không phải microservice

- **Trạng thái:** Accepted
- **Ngày:** 2026-09-17
- **Liên quan:** [ADR-0005](0005-outbox-db-job.md), [architecture.md](../04-system-design/architecture.md), [backend-modules.md](../04-system-design/backend-modules.md)

## Bối cảnh

Kaiju có nhiều vùng nghiệp vụ tách bạch (identity, issue, workflow, board,
automation…) và nhiều loại tải rất khác nhau: request HTTP ngắn, kết nối đồng bộ
dài hạn, job nền chạy lâu, tác vụ định kỳ. Các loại tải này cần scale độc lập.

Đây là dự án cá nhân, một người phát triển, chưa có ràng buộc về tổ chức đội ngũ
— yếu tố vốn là lý do chính đáng nhất để chọn microservice.

## Quyết định

Một codebase duy nhất trong `backend/`, chia thành các module theo bounded
context, build ra **một artifact**. Artifact đó được triển khai thành **bốn app
role** chọn bằng Spring profile: `api`, `realtime`, `worker`, `scheduler`. Mỗi
role scale độc lập.

Biên giới module được **enforce bằng công cụ** (Spring Modulith verification
trong test), không chỉ bằng kỷ luật.

## Lý do

- Bốn loại tải cần scale khác nhau, nhưng **không** cần vòng đời phát hành khác
  nhau. Multi-app đáp ứng nhu cầu thật mà không trả giá của microservice.
- Một transaction database duy nhất là điều kiện để [outbox](0005-outbox-db-job.md)
  hoạt động đúng. Tách service sẽ kéo theo distributed transaction hoặc saga.
- Refactor biên giới module trong monolith là đổi tên package; trong microservice
  là đổi hợp đồng mạng và migrate dữ liệu. Ở giai đoạn biên giới còn chưa chắc
  chắn, chi phí sai khác nhau một trời một vực.
- Nếu biên giới được enforce nghiêm, tách một module ra service riêng về sau chỉ
  là đổi transport.

## Hệ quả

- **Phải** enforce biên giới bằng test ngay từ đầu. Không có ranh giới mạng ép
  buộc, nên chỉ cần buông lỏng vài tháng là các module dính chặt vào nhau và mất
  luôn khả năng tách.
- Ba luật bất di bất dịch: không import package internal của module khác, không
  truy vấn bảng của module khác, giao tiếp bất đồng bộ chỉ qua domain event.
- Mọi app role dùng chung một schema database, nên thay đổi schema ảnh hưởng tất
  cả — migration phải tương thích ngược khi rolling update.
- Mỗi role cần cấu hình connection pool riêng; nếu dùng chung cấu hình sẽ cạn
  `max_connections` của Postgres khi scale.
- Một lỗi nghiêm trọng ở tầng platform có thể hạ toàn bộ role. Chấp nhận, đổi lại
  vận hành đơn giản hơn nhiều.

## Phương án đã loại

**Microservice ngay từ đầu.** Với một người phát triển và biên giới nghiệp vụ còn
chưa ổn định, chi phí vận hành (service discovery, distributed tracing, hợp đồng
API, deploy nhiều pipeline) không đổi lại được giá trị nào. Mất luôn transaction
chung, kéo theo phải làm saga cho những thao tác hiện chỉ là một transaction.

**Monolith một app duy nhất.** Đơn giản hơn nhưng không scale riêng được: job nền
nặng sẽ cạnh tranh tài nguyên với request HTTP, và kết nối đồng bộ dài hạn ghim
tài nguyên của tiến trình phục vụ API.

**Tách riêng service realtime.** Có vẻ hợp lý vì đặc tính tải khác hẳn, nhưng
service đó cần đọc change log và kiểm tra quyền — tức là cần chính schema và
chính logic phân quyền của phần còn lại. Tách ra chỉ tạo ra nhân bản, trong khi
profile `realtime` đã giải quyết đúng vấn đề tải.
