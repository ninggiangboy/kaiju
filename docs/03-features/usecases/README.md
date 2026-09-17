# Use cases

Luồng nghiệp vụ chi tiết, viết từ góc nhìn người dùng. Mỗi use case liệt kê đầy
đủ **các nhánh thay thế và ngoại lệ**, vì theo nguyên tắc làm từng tính năng một
nhưng đầy đủ, chính các nhánh này mới là phần quyết định một feature đã xong hay chưa.

**Liên quan:** [Feature catalog](../README.md) · [Roadmap](../roadmap.md) · [identity-and-permission.md](../../04-system-design/identity-and-permission.md)

---

## Phạm vi hiện tại

| Use case | Phase | Trạng thái |
|---|---|---|
| [uc-auth.md](uc-auth.md) — Đăng nhập và phiên làm việc | 1 | ✅ Đã viết |
| [uc-workspace.md](uc-workspace.md) — Workspace | 1 | ✅ Đã viết |
| [uc-member-invite.md](uc-member-invite.md) — Thành viên và lời mời | 1 | ✅ Đã viết |
| [uc-project.md](uc-project.md) — Project | 2 | ✅ Đã viết |

> **Use case cho Phase 3 trở đi chưa được viết, và đó là chủ ý.** Chúng được viết
> ngay trước khi bắt đầu phase tương ứng. Viết trước cả mười sáu phase nghĩa là
> phần lớn sẽ lỗi thời trước khi được dùng tới, và một tài liệu lỗi thời có hại
> hơn là không có tài liệu.

---

## Cấu trúc một use case

| Mục | Nội dung |
|---|---|
| **Actor** | Ai thực hiện, và cần quyền gì |
| **Tiền điều kiện** | Trạng thái hệ thống trước khi bắt đầu |
| **Luồng chính** | Các bước của kịch bản thành công |
| **Luồng thay thế** | Các nhánh hợp lệ khác với luồng chính |
| **Ngoại lệ** | Các trường hợp lỗi và cách hệ thống phản ứng |
| **Hậu điều kiện** | Trạng thái hệ thống sau khi hoàn tất |
| **Quy tắc nghiệp vụ** | Các ràng buộc phải giữ, đánh số để tham chiếu |
| **Ảnh hưởng tới đồng bộ** | Thay đổi nào cần tới client và qua scope nào |

Mục cuối là mục riêng của dự án này: vì client giữ dữ liệu trên máy, mỗi use case
phải trả lời câu hỏi "client cần biết gì sau khi việc này xảy ra".

## Cách đánh ID

`UC-<NHÓM>-<nn>`. ID không tái sử dụng. Mỗi use case liệt kê các feature hiện
thực hoá nó, để đối chiếu với [feature catalog](../README.md).
