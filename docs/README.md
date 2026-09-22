# Tài liệu dự án Kaiju

Kaiju là một hệ quản lý dự án kiểu Jira, xây dựng theo hướng **local-first** và
**realtime**. Thư mục này chứa toàn bộ tài liệu của dự án, từ brief sản phẩm cho
tới thiết kế hệ thống chi tiết.

Tài liệu viết bằng tiếng Việt, thuật ngữ kỹ thuật giữ nguyên tiếng Anh để khớp
với tên class, table và API trong code.

---

## Bảy phần tài liệu

| # | Phần | Nội dung | Trạng thái |
|---|---|---|---|
| 01 | [Brief](01-brief/) | Vấn đề, đối tượng, phạm vi, nguyên tắc phát triển | ✅ Hoàn thiện |
| 02 | [Requirement](02-requirement/) | Yêu cầu chức năng, phi chức năng, ràng buộc | ✅ Hoàn thiện |
| 03 | [Features & Use cases](03-features/) | Danh mục feature có trạng thái, roadmap theo phase, use case chi tiết | ✅ Hoàn thiện (use case: Phase 0–2) |
| 04 | [System Design](04-system-design/) | Kiến trúc tổng thể, backend, frontend, realtime, vận hành | ✅ Hoàn thiện |
| 05 | [UX/UI Design](05-ux-ui-design/) | Wireframe, design system, luồng màn hình | 🟨 Đang làm |
| 06 | [ERD](06-erd/) | Mô hình dữ liệu, entity, quan hệ, DDL | ⬜ Chưa bắt đầu |
| 07 | [Detail Design](07-detail-design/) | Thiết kế mức code: package, class, API contract | ⬜ Chưa bắt đầu |

Ngoài ra:

- **[Glossary](glossary.md)** — từ điển thuật ngữ dùng chung. Đọc trước tiên.
- **[ADR](adr/)** — 16 quyết định kiến trúc đã chốt, mỗi quyết định một file.

---

## Thứ tự đọc đề xuất

**Nếu bạn mới tham gia dự án:**

1. [Glossary](glossary.md) — nắm từ vựng, đặc biệt cặp `account` / `member`
2. [Brief](01-brief/) — hiểu dự án đang giải quyết gì và với nguyên tắc nào
3. [ADR](adr/) — đọc lướt 16 quyết định để biết cái gì đã chốt và vì sao
4. [System Design → README](04-system-design/) rồi [architecture.md](04-system-design/architecture.md)
5. [Roadmap](03-features/roadmap.md) — biết đang ở đâu và sắp làm gì

**Nếu bạn chuẩn bị implement một feature:**

1. [Feature catalog](03-features/README.md) — tìm ID feature, kiểm tra `Depends`
2. Use case tương ứng trong [usecases/](03-features/usecases/)
3. Tài liệu thiết kế liên quan trong [04-system-design/](04-system-design/)
4. [constraints.md](02-requirement/constraints.md) — rà lại các ràng buộc không được vi phạm

---

## Quy ước

### Ngôn ngữ

- Nội dung tài liệu: tiếng Việt
- Thuật ngữ kỹ thuật: giữ tiếng Anh (`aggregate`, `outbox`, `sync engine`, `bitmask`…)
- Commit message: **tiếng Anh**, theo Conventional Commits
- Tên file, tên thư mục, tên định danh trong code: tiếng Anh

### ID trong tài liệu

| Loại | Dạng | Ví dụ | Nơi định nghĩa |
|---|---|---|---|
| Yêu cầu chức năng | `FR-<nhóm>-<nn>` | `FR-IDN-04` | [functional.md](02-requirement/functional.md) |
| Yêu cầu phi chức năng | `NFR-<nn>` | `NFR-07` | [non-functional.md](02-requirement/non-functional.md) |
| Ràng buộc | `CON-<nn>` | `CON-03` | [constraints.md](02-requirement/constraints.md) |
| Feature | `KJ-<MODULE>-<nn>` | `KJ-SYNC-07` | [03-features/README.md](03-features/README.md) |
| Use case | `UC-<nhóm>-<nn>` | `UC-AUTH-02` | [usecases/](03-features/usecases/) |
| ADR | 4 chữ số | `ADR-0006` | [adr/](adr/) |

ID **không bao giờ được tái sử dụng**. Khi một mục bị bỏ, giữ nguyên ID và đánh
dấu `DEFERRED` hoặc `DROPPED` thay vì xoá dòng.

### Cập nhật trạng thái feature

Trạng thái feature chỉ tồn tại ở **một chỗ duy nhất**: bảng trong
[03-features/README.md](03-features/README.md). Không nhân bản trạng thái sang
roadmap hay bất kỳ tài liệu nào khác, để tránh lệch.

Quy tắc: đổi trạng thái sang `IN_PROGRESS` khi bắt đầu, sang `DONE` chỉ khi
feature đã **đầy đủ** theo Definition of Done của phase, không phải khi luồng
chính chạy được.

### Khi nào phải viết ADR mới

Viết ADR khi một quyết định thoả **ít nhất một** điều kiện sau:

- Khó đảo ngược (đổi sẽ phải sửa nhiều module hoặc migrate dữ liệu)
- Ảnh hưởng xuyên nhiều module hoặc cả backend lẫn frontend
- Loại bỏ một phương án mà người khác có thể sẽ đề xuất lại sau này

Không viết ADR cho lựa chọn cục bộ trong một module, hoặc cho những thứ đổi lại
được trong một buổi.

### Khi quyết định thực tế lệch khỏi tài liệu

Tài liệu mô tả các quyết định đưa ra **trước** khi implement. Quá trình implement
sẽ có lúc chứng minh một quyết định nào đó là sai hoặc không khả thi. Khi đó:

- **Cập nhật tài liệu trong cùng commit** với code đi chệch, không để lại sau
- **Không xoá và không ẩn quyết định cũ.** ADR đã `Accepted` thì viết ADR mới và
  đánh dấu cái cũ là superseded; tài liệu thiết kế thì giữ lại phát biểu cũ trong
  một ghi chú `> **Đã thay đổi (YYYY-MM-DD):**` nêu rõ cách cũ, cách mới và lý do
- Yêu cầu hay feature bị bỏ thì **giữ nguyên ID**, đổi trạng thái và ghi lý do

Lịch sử của một quyết định — kể cả quyết định sai — là thông tin có giá trị. Sửa
tài liệu như thể quyết định cũ chưa từng tồn tại thì lần sau sẽ tranh luận lại
đúng vấn đề đó.

Hướng dẫn đầy đủ kèm bảng chọn cơ chế: [`CLAUDE.md`](../CLAUDE.md).

### Đánh dấu chỗ chưa chốt

Dùng blockquote, không đoán và không để trống:

```markdown
> **Chưa chốt:** cách cấp `seq` khi số lượng ghi đồng thời trên một project vượt ngưỡng.
```

---

## Cấu trúc repository

```
kaiju/
├── docs/        # tài liệu (thư mục này)
├── backend/     # Spring Boot, Gradle multi-module
├── frontend/    # Next.js
└── infra/       # Docker Compose, Dockerfile, reverse proxy, script vận hành
```

Chi tiết trách nhiệm từng thư mục: [04-system-design/README.md](04-system-design/README.md).

Các luật bất biến rút gọn cho mọi phiên làm việc nằm ở [`CLAUDE.md`](../CLAUDE.md) ở gốc repo.
