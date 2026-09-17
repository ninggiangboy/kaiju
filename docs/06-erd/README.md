# 06 — ERD (mô hình dữ liệu)

**Trạng thái: ⬜ Chưa bắt đầu**

Phần này sẽ chứa mô hình dữ liệu chi tiết. Việc phân tích entity và DDL được
**hoãn có chủ đích** sang một vòng làm việc riêng, để vòng này tập trung chốt
kiến trúc và luồng nghiệp vụ.

**Liên quan:** [data-access-and-tenancy.md](../04-system-design/data-access-and-tenancy.md) · [Glossary](../glossary.md) · [ADR-0011](../adr/0011-account-vs-member.md) · [ADR-0012](../adr/0012-shared-schema-tenancy-rls.md)

---

## Sẽ chứa gì

- Sơ đồ ERD theo từng bounded context
- Định nghĩa entity: thuộc tính, kiểu, ràng buộc, giá trị mặc định
- Quan hệ và cardinality, chỉ rõ quan hệ nào nằm trong cùng aggregate
- Chiến lược index cho từng bảng, kèm truy vấn mà index đó phục vụ
- Partition cho các bảng append-only (change log, activity, outbox)
- DDL hoặc Flyway migration tương ứng
- Chính sách RLS cho từng bảng

## Phụ thuộc vào

- [04-system-design/data-access-and-tenancy.md](../04-system-design/data-access-and-tenancy.md) — chiến lược truy cập dữ liệu và tenancy
- [03-features/roadmap.md](../03-features/roadmap.md) — chỉ mô hình hoá phạm vi của phase sắp làm

## Khi nào bắt đầu

Ngay trước khi implement **Phase 0**, và mở rộng dần theo từng phase. Không mô
hình hoá trọn vẹn 16 phase ngay từ đầu: phần lớn sẽ phải sửa khi tới nơi, và một
ERD đầy đủ sớm tạo cảm giác an toàn giả.

## Ràng buộc đã chốt mà ERD bắt buộc phải tuân theo

Đây là các bất biến đã quyết, ERD không được vi phạm:

| # | Ràng buộc | Nguồn |
|---|---|---|
| 1 | **Mọi bảng nghiệp vụ đều có cột `workspace_id`**, kể cả khi đã có `project_id`. Denormalize có chủ đích để mọi truy vấn lọc được tenant ngay tại bảng đó | [ADR-0012](../adr/0012-shared-schema-tenancy-rls.md) |
| 2 | **Không bảng nghiệp vụ nào được có khoá ngoại tới bảng toàn cục** ngoài `workspace`. Cụ thể: không có FK tới `account` | [ADR-0011](../adr/0011-account-vs-member.md) |
| 3 | **Mọi tham chiếu tới con người đều trỏ tới `member`**, không trỏ tới `account` | [ADR-0011](../adr/0011-account-vs-member.md) |
| 4 | Các cột nối giữa vùng toàn cục và vùng tenant (`member.account_id`, bảng ánh xạ account ↔ workspace) **không khai báo FK constraint**, vì tương lai có thể nằm khác shard | [ADR-0011](../adr/0011-account-vs-member.md) |
| 5 | **Mọi bảng nghiệp vụ bật Row Level Security** theo `workspace_id` | [ADR-0012](../adr/0012-shared-schema-tenancy-rls.md) |
| 6 | Shard key của toàn hệ thống là `workspace_id`. Chưa shard thật, nhưng mô hình không được cản trở việc đó | [ADR-0012](../adr/0012-shared-schema-tenancy-rls.md) |
| 7 | `project.key` unique **theo workspace**, không unique toàn cục | [uc-project.md](../03-features/usecases/uc-project.md) |
| 8 | Aggregate phải nhỏ; collection con được map vào aggregate phải có chặn trên về số lượng, vì Spring Data JDBC xoá và chèn lại toàn bộ collection khi lưu | [ADR-0004](../adr/0004-spring-data-jdbc.md) |
| 9 | Người rời workspace **không bị xoá cứng**; dòng `member` được giữ lại ở trạng thái vô hiệu để mọi tham chiếu lịch sử còn nguyên | [uc-member-invite.md](../03-features/usecases/uc-member-invite.md) |
