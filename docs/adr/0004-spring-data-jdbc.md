# ADR-0004: Spring Data JDBC + jOOQ thay cho JPA/Hibernate

- **Trạng thái:** Accepted
- **Ngày:** 2026-09-17
- **Liên quan:** [ADR-0002](0002-postgres-only.md), [ADR-0007](0007-build-own-sync-engine.md), [data-access-and-tenancy.md](../04-system-design/data-access-and-tenancy.md)

## Bối cảnh

Backend là Spring Boot theo hướng DDD. Hai nhu cầu định hình lựa chọn tầng truy
cập dữ liệu:

1. Sync engine cần biết **chính xác field nào đã thay đổi** trong mỗi lần ghi, để
   sinh patch cho change log. Gửi nguyên entity xuống client là lãng phí và làm
   hỏng cơ chế trộn thay đổi.
2. JQL ở phase sau sẽ sinh **SQL động** từ một cây cú pháp, bao gồm cả điều kiện
   trên custom field lưu dạng `JSONB`.

## Quyết định

Tầng ghi dùng **Spring Data JDBC**. Truy vấn động dùng **jOOQ**. Truy vấn đơn
giản trả DTO dùng **`JdbcClient`**. Không dùng JPA/Hibernate.

| Việc | Công cụ |
|---|---|
| Ghi, invariant, domain logic | Spring Data JDBC repository |
| Đọc đơn giản (detail, danh sách cố định) | `JdbcClient` |
| Đọc động (JQL, board, backlog, report) | jOOQ |

## Lý do

- Spring Data JDBC **không có dirty checking**, nên việc tính ra field nào đã đổi
  trở thành code tường minh trong application layer — đọc được, test được. Với
  Hibernate, việc này phải móc vào `PostUpdateEventListener` và dựa vào cơ chế
  nội bộ của framework.
- Không có lazy loading nghĩa là **aggregate buộc phải nhỏ**, đúng với nguyên tắc
  thiết kế đã chọn. Framework ép kỷ luật thay vì cho phép lách.
- Không có session cache và second-level cache, nên không có trạng thái ẩn gây
  lệch giữa các instance — quan trọng với hệ nhiều app role.
- Criteria API của JPA dựng truy vấn động từ AST rất khổ; jOOQ làm việc đó sạch
  sẽ, type-safe, và xử lý được `JSONB`.

## Hệ quả

- **Collection con bị xoá và chèn lại toàn bộ** mỗi lần lưu aggregate. Chỉ được
  map vào aggregate những collection nhỏ và có chặn trên; còn lại phải tách thành
  aggregate riêng với repository riêng.
- Tham chiếu xuyên aggregate dùng `AggregateReference`, không dùng tham chiếu
  object. Hệ quả tốt: biên giới aggregate hiện rõ ngay trong code.
- **Phải tự viết converter cho `JSONB`** (`@WritingConverter` / `@ReadingConverter`
  qua `PGobject`) trước khi làm custom field và outbox payload.
- Không có query động sẵn có; mọi truy vấn phức tạp đi qua jOOQ, kéo theo bước
  code generation trong build.
- Mỗi lần gọi repository là một lần xuống database, không có cache ẩn. Cần chú ý
  tránh N+1 do gọi lặp trong vòng lặp — trách nhiệm này chuyển sang người viết code.
- Optimistic locking vẫn có qua `@Version`, dùng cho phát hiện xung đột của sync engine.

## Phương án đã loại

**JPA/Hibernate.** Quen thuộc và nhiều tài liệu, nhưng dirty checking, lazy
loading và session cache đều là trạng thái ẩn, đi ngược lại nhu cầu "biết chính
xác cái gì đã đổi". Bản thân việc phải móc vào listener nội bộ để lấy được thông
tin đó đã là dấu hiệu chọn sai công cụ.

**Chỉ dùng jOOQ cho cả ghi lẫn đọc.** Thống nhất một công cụ, nhưng mất mô hình
aggregate: phải tự viết mapping và tự quản vòng đời entity ở mọi nơi.

**JdbcTemplate thuần.** Kiểm soát tối đa nhưng phải viết tay quá nhiều mapping
lặp lại cho phần ghi.
