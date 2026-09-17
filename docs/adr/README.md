# Architecture Decision Records

Mỗi file trong thư mục này ghi lại **một quyết định đã chốt**: bối cảnh lúc quyết
định, lựa chọn cuối cùng, lý do, hệ quả phải sống chung, và các phương án đã loại.

Mục đích là để sáu tháng sau không phải tranh luận lại từ đầu, và để người mới
hiểu vì sao hệ thống trông như hiện tại thay vì trông như cách thông thường.

**Liên quan:** [Docs index](../README.md) · [constraints.md](../02-requirement/constraints.md) · [System Design](../04-system-design/)

---

## Danh sách

| # | Quyết định | Trạng thái |
|---|---|---|
| [0001](0001-modular-monolith-multi-app.md) | Modular monolith triển khai thành nhiều app, không phải microservice | Accepted |
| [0002](0002-postgres-only.md) | PostgreSQL là datastore duy nhất, không dùng MongoDB | Accepted |
| [0003](0003-redis-scope.md) | Redis chỉ làm cache, pub/sub, lock, rate limit — không phải source of truth | Accepted |
| [0004](0004-spring-data-jdbc.md) | Spring Data JDBC + jOOQ thay cho JPA/Hibernate | Accepted |
| [0005](0005-outbox-db-job.md) | Transactional outbox bằng database và job nền, không dùng Kafka/CDC | Accepted |
| [0006](0006-sse-over-websocket.md) | SSE cho luồng đồng bộ, mutation qua HTTP POST | Accepted |
| [0007](0007-build-own-sync-engine.md) | Tự xây sync engine thay vì dùng thư viện sync có sẵn | Accepted |
| [0008](0008-nextjs-as-spa-shell.md) | Next.js dùng như SPA shell, không SSR dữ liệu nghiệp vụ | Accepted |
| [0009](0009-magic-link-only.md) | Magic link là phương thức xác thực duy nhất | Accepted |
| [0010](0010-bitmask-permission.md) | Phân quyền bằng bitmask hai cấp | Accepted |
| [0011](0011-account-vs-member.md) | Tách account toàn cục khỏi member theo workspace | Accepted |
| [0012](0012-shared-schema-tenancy-rls.md) | Multi-tenancy shared-schema kèm Row Level Security | Accepted |
| [0013](0013-explicit-two-way-migration.md) | Migration chạy tường minh và đi được hai chiều, không chạy lúc ứng dụng khởi động | Accepted |

---

## Quy ước

**Trạng thái:** `Proposed` → `Accepted` → `Superseded by ADR-xxxx` hoặc `Deprecated`.
ADR đã `Accepted` **không sửa nội dung**; muốn đổi quyết định thì viết ADR mới và
đánh dấu cái cũ là superseded. Lịch sử sai lầm cũng là thông tin có giá trị.

**Khi nào viết ADR mới:** khi quyết định khó đảo ngược, ảnh hưởng xuyên nhiều
module, hoặc loại bỏ một phương án mà người khác có thể đề xuất lại. Không viết
cho lựa chọn cục bộ trong một module.

## Template

```markdown
# ADR-00xx: <Tiêu đề ở dạng khẳng định>

- **Trạng thái:** Accepted
- **Ngày:** YYYY-MM-DD
- **Liên quan:** ADR-00yy, <tài liệu>

## Bối cảnh
Tình huống và ràng buộc tại thời điểm quyết định.

## Quyết định
Một câu khẳng định, rõ ràng.

## Lý do
Vì sao chọn phương án này.

## Hệ quả
Những gì phải sống chung, cả tốt lẫn xấu. Phần này quan trọng nhất.

## Phương án đã loại
Từng phương án và lý do loại.
```
