# 07 — Detail Design (mức code)

**Trạng thái: ⬜ Chưa bắt đầu**

Phần này sẽ chứa thiết kế ở mức code: cấu trúc package, class chính, API
contract, và định nghĩa domain event. Đây là tầng nằm giữa system design và code
thật, viết theo từng phase chứ không viết trước toàn bộ.

**Liên quan:** [System Design](../04-system-design/) · [backend-modules.md](../04-system-design/backend-modules.md) · [Roadmap](../03-features/roadmap.md)

---

## Sẽ chứa gì

- **Cấu trúc package** chi tiết của từng module backend, theo bốn tầng DDD
- **Class chính**: aggregate root, value object, command/query handler, repository
- **API contract**: endpoint, request/response, mã lỗi, quy ước phân trang —
  hoặc đặc tả OpenAPI nếu sinh tự động
- **Catalog domain event**: tên, payload, ai phát, ai tiêu thụ, phiên bản
- **Protocol đồng bộ** ở mức field: định dạng SSE event, định dạng mutation
- Cấu trúc thư mục và component chính của `frontend/`
- Quy ước đặt tên và tổ chức test theo từng module

## Phụ thuộc vào

- [04-system-design/](../04-system-design/) — kiến trúc và các quy ước phải chốt trước
- [06-erd/](../06-erd/) — mô hình dữ liệu phải có trước khi thiết kế repository
- [03-features/usecases/](../03-features/usecases/) — API contract bám theo use case

## Khi nào bắt đầu

Theo từng phase, ngay trước khi viết code của phase đó. Tài liệu ở đây được cập
nhật **cùng lúc** với code, không viết một lần rồi bỏ mặc — nếu lệch với code thì
nó có hại hơn là không có.

## Ràng buộc đã chốt mà thiết kế phải tuân theo

| Ràng buộc | Nguồn |
|---|---|
| Module không được import package internal của module khác, không được truy vấn bảng của module khác, giao tiếp bất đồng bộ chỉ qua domain event | [backend-modules.md](../04-system-design/backend-modules.md) |
| Tầng ghi dùng Spring Data JDBC; query động dùng jOOQ; read đơn giản dùng `JdbcClient`. Không dùng JPA/Hibernate | [ADR-0004](../adr/0004-spring-data-jdbc.md) |
| Mutation nghiệp vụ ở frontend không được đi qua Server Action của Next.js | [ADR-0008](../adr/0008-nextjs-as-spa-shell.md) |
| Mọi thay đổi dữ liệu phải sinh bản ghi change log kèm patch chỉ chứa field đã đổi | [realtime-and-sync.md](../04-system-design/realtime-and-sync.md) |
| Mọi consumer của domain event phải idempotent | [events-and-outbox.md](../04-system-design/events-and-outbox.md) |
