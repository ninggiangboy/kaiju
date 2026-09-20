# Use cases

Luồng nghiệp vụ chi tiết, viết từ góc nhìn người dùng. Mỗi use case liệt kê đầy
đủ **các nhánh thay thế và ngoại lệ**, vì theo nguyên tắc làm từng tính năng một
nhưng đầy đủ, chính các nhánh này mới là phần quyết định một feature đã xong hay chưa.

**Liên quan:** [Feature catalog](../README.md) · [Roadmap](../roadmap.md) · [identity-and-permission.md](../../04-system-design/identity-and-permission.md)

---

## Phạm vi hiện tại

| Use case | Phase | Trạng thái |
|---|---|---|
| [uc-01-auth.md](uc-01-auth.md) — Đăng nhập và phiên làm việc | 1 | ✅ Đã viết |
| [uc-02-workspace.md](uc-02-workspace.md) — Workspace | 1 | ✅ Đã viết |
| [uc-03-member-invite.md](uc-03-member-invite.md) — Thành viên và lời mời | 1 | ✅ Đã viết |
| [uc-04-project.md](uc-04-project.md) — Project | 2 | ✅ Đã viết |
| [uc-05-issue.md](uc-05-issue.md) — Issue | 3 | ✅ Đã viết |
| [uc-06-collaboration.md](uc-06-collaboration.md) — Collaboration | 4 | ✅ Đã viết |
| [uc-07-workflow.md](uc-07-workflow.md) — Workflow | 5 | ✅ Đã viết |
| uc-08-field.md — Custom field & Screen | 6 | ⬜ Chưa viết |
| uc-09-search.md — Search & Query | 7 | ⬜ Chưa viết |
| uc-10-board.md — Board | 8 | ⬜ Chưa viết |
| uc-11-sprint.md — Sprint & Scrum | 9 | ⬜ Chưa viết |
| uc-12-roadmap.md — Roadmap & Timeline | 10 | ⬜ Chưa viết |
| uc-13-time.md — Time tracking | 11 | ⬜ Chưa viết |
| uc-14-version.md — Version & Release | 12 | ⬜ Chưa viết |
| uc-15-dashboard.md — Dashboard & Report | 13 | ⬜ Chưa viết |
| uc-16-automation.md — Automation | 14 | ⬜ Chưa viết |
| uc-17-bulk.md — Bulk & Import/Export | 15 | ⬜ Chưa viết |
| uc-18-integration.md — Integration & Public API | 16 | ⬜ Chưa viết |

Số trong tên file là **thứ tự viết**, tăng dần và không tái sử dụng — giống
cách đánh ID feature — để đọc theo đúng thứ tự dự kiến triển khai mà không cần
mở bảng này. Tên phần chữ sau số là dự kiến theo nhóm feature tương ứng trong
[feature catalog](../README.md); có thể đổi khi thực sự viết nếu một nhóm cần
tách thành nhiều use case, nhưng số đã cấp cho một use case đã viết thì giữ
nguyên. Phase 0 (Nền tảng) không có use case vì đó là hạ tầng, không có luồng
người dùng.

> **Changed (2026-09-20):** Quyết định trước đây là chỉ viết use case ngay
> trước khi bắt đầu phase tương ứng, để tránh tài liệu lỗi thời trước khi được
> dùng tới. Người dùng chọn đổi hướng: hoàn thiện toàn bộ docs — kể cả use case
> của các phase sau — trước khi bắt đầu implementation, rồi mới bổ sung nội
> dung từng use case. Rủi ro lỗi thời vẫn còn và người dùng đã chấp nhận đánh
> đổi đó; khi một use case được viết mà phát hiện lệch với feature catalog hoặc
> system design, phải cập nhật cả hai theo quy tắc ở
> [CLAUDE.md — Recording decisions that depart from the docs](../../../CLAUDE.md#recording-decisions-that-depart-from-the-docs).

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
