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
| [uc-08-field.md](uc-08-field.md) — Custom field & Screen | 6 | ✅ Đã viết |
| [uc-09-search.md](uc-09-search.md) — Search & Query | 7 | ✅ Đã viết |
| [uc-10-board.md](uc-10-board.md) — Board | 8 | ✅ Đã viết |
| [uc-11-sprint.md](uc-11-sprint.md) — Sprint & Scrum | 9 | ✅ Đã viết |
| [uc-12-roadmap.md](uc-12-roadmap.md) — Roadmap & Timeline | 10 | ✅ Đã viết |
| [uc-13-time.md](uc-13-time.md) — Time tracking | 11 | ✅ Đã viết |
| [uc-14-version.md](uc-14-version.md) — Version & Release | 12 | ✅ Đã viết |
| [uc-15-dashboard.md](uc-15-dashboard.md) — Dashboard & Report | 13 | ✅ Đã viết |
| [uc-16-automation.md](uc-16-automation.md) — Automation | 14 | ✅ Đã viết |
| [uc-17-bulk.md](uc-17-bulk.md) — Bulk & Import/Export | 15 | ✅ Đã viết |
| [uc-18-integration.md](uc-18-integration.md) — Integration & Public API | 16 | ✅ Đã viết |
| [uc-19-sync.md](uc-19-sync.md) — Sync engine | 0 | ✅ Đã viết |

Số trong tên file là **thứ tự viết**, tăng dần và không tái sử dụng — giống
cách đánh ID feature — để đọc theo đúng thứ tự dự kiến triển khai mà không cần
mở bảng này. Tên phần chữ sau số là dự kiến theo nhóm feature tương ứng trong
[feature catalog](../README.md); có thể đổi khi thực sự viết nếu một nhóm cần
tách thành nhiều use case, nhưng số đã cấp cho một use case đã viết thì giữ
nguyên.

Phần lớn Phase 0 (Nền tảng) không có use case vì đó là hạ tầng thuần
(`KJ-PLT`, `KJ-EVT`) — không có luồng người dùng. `KJ-SYN` là ngoại lệ: xem
ghi chú `> **Changed (2026-09-20):**` ở mục *Cách đánh ID* bên dưới.

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
| **Requirement** | Các `FR-xx` mà section này hiện thực hoá, để đối chiếu với [functional.md](../../02-requirement/functional.md) |
| **Actor** | Ai thực hiện, và cần quyền gì |
| **Tiền điều kiện** | Trạng thái hệ thống trước khi bắt đầu |
| **Luồng chính** | Các bước của kịch bản thành công |
| **Luồng thay thế** | Các nhánh **hợp lệ** khác với luồng chính — hệ thống làm đúng theo ý người dùng, chỉ đi đường khác |
| **Ngoại lệ** | Các trường hợp hệ thống **từ chối, chặn, hoặc báo lỗi** |
| **Hậu điều kiện** | Trạng thái **đã đổi** sau khi hoàn tất — không chép lại luồng chính |
| **Quy tắc nghiệp vụ** | Các ràng buộc phải giữ, đánh số để tham chiếu |
| **Ảnh hưởng tới đồng bộ** | Delta nào phát trên scope nào, client phải làm gì |

Mục cuối là mục riêng của dự án này: vì client giữ dữ liệu trên máy, mỗi use case
phải trả lời câu hỏi "client cần biết gì sau khi việc này xảy ra".

**Mọi mục đều bắt buộc có mặt.** Khi một mục không áp dụng cho section đó, ghi
một dòng nêu lý do thay vì bỏ trống — ví dụ *"Không đổi dữ liệu client — UC này
chỉ đọc."* dưới `### Ảnh hưởng tới đồng bộ`. Riêng *Luồng thay thế* và *Ngoại lệ*
được phép vắng mặt hoàn toàn (không cần dòng "không áp dụng") khi section thật sự
không có nhánh nào thuộc loại đó.

## Cách đánh ID

Bốn tầng, không tầng nào tái sử dụng ID đã cấp:

| Tầng | Dạng | Ví dụ | Phạm vi duy nhất |
|---|---|---|---|
| Use case | `UC-<NHÓM>-nn` | `UC-VER-01` | toàn repo |
| Nhánh trong *Luồng thay thế* | `<UC>/NT-nn` | `UC-VER-01/NT-01` | trong section chứa nó |
| Nhánh trong *Ngoại lệ* | `<UC>/NL-nn` | `UC-VER-01/NL-01` | trong section chứa nó |
| Quy tắc nghiệp vụ | `QT-<NHÓM>-nn` | `QT-VER-03` | toàn repo |

Mỗi file use case mở đầu bằng một dòng `**Feature:**` trỏ tới nhóm `KJ-<NHÓM>-nn`
tương ứng trong [feature catalog](../README.md) — chiều `KJ → UC`. Chiều ngược
lại, `FR → UC`, nằm ở dòng `**Requirement:**` của từng section `## UC-...`
riêng lẻ, không phải ở đầu file, vì một file use case thường phủ nhiều `FR-xx`
khác nhau tuỳ section.

> **Chốt (2026-09-20):** Cố tình **không** thêm cột `FR` vào feature catalog.
> Catalog giữ `KJ → UC`; use case giữ `FR → UC`. Hai chiều đó đã đủ trả lời cả
> "requirement này có use case chưa" lẫn "feature này phục vụ requirement nào",
> qua use case làm bảng nối. Thêm `FR → KJ` trực tiếp là một mapping thứ ba,
> trùng thông tin và sẽ lệch pha theo thời gian — trái nguyên tắc "trạng thái
> chỉ nằm ở một chỗ" mà catalog tự đặt ra.

### Ranh giới NT vs NL

Đây là chỗ dễ nhầm nhất khi viết:

- **NT (Luồng thay thế)** — nhánh người dùng **đi được** và hệ thống làm **đúng
  theo ý họ**, chỉ khác đường với luồng chính. Ví dụ: xoá version đang gán cho
  issue → cho chọn bỏ gán hay chuyển sang version khác; đó là NT, không phải NL.
- **NL (Ngoại lệ)** — hệ thống **từ chối, chặn, hoặc báo lỗi**. Ví dụ: ngày phát
  hành đặt trước ngày bắt đầu; slug đã tồn tại; không đủ quyền.

Một cách kiểm nhanh: nếu sau khi đi hết nhánh đó, cái người dùng muốn làm **đã
xảy ra** (dù bằng cách khác) → NT. Nếu nó **không xảy ra** → NL.

> **Changed (2026-09-20):** ID nhánh trước đây không tồn tại — các bảng *Luồng
> thay thế* / *Ngoại lệ* chỉ có cột "Trường hợp" / "Nhánh" mô tả bằng lời, không
> trích dẫn được từ test hay từ task. Quy tắc nghiệp vụ cũng đánh số lại từ `01`
> trong mỗi file (`QT-nn`), khiến cùng một số mang nhiều nghĩa khác nhau tuỳ file
> và không tham chiếu chéo được. Đổi sang hệ bốn tầng ở trên để mỗi nhánh và mỗi
> quy tắc có đúng một ID duy nhất, toàn repo hoặc trong section, tuỳ tầng.

> **Changed (2026-09-20):** Trước đây Phase 0 (Nền tảng) không có use case, với
> lý do "đó là hạ tầng, không có luồng người dùng". Lý do đó đúng với `KJ-PLT` và
> `KJ-EVT`, nhưng sai với `KJ-SYN`: `FR-SYN-01…10` đều là MUST và đều mô tả hành
> vi người dùng nhìn thấy trực tiếp (hàng đợi offline, hoàn tác khi server từ
> chối, trạng thái kết nối, nhiều tab, xoá dữ liệu cục bộ khi bị thu hồi quyền).
> Bổ sung `uc-19-sync.md` cho các FR này; `KJ-PLT` và `KJ-EVT` tiếp tục không có
> use case vì chúng thật sự là hạ tầng thuần, không có luồng người dùng.
