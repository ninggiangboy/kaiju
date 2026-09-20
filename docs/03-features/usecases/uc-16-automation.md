# UC-AUT — Automation

Tự động hoá công việc lặp lại bằng quy tắc kích hoạt/điều kiện/hành động, tổng
quát hoá cùng khái niệm đã dùng cho bước chuyển workflow (UC-WKF-03..05) nhưng
không gắn riêng với một bước chuyển. Quy tắc không chạy với danh nghĩa "hệ
thống" — nó luôn chạy **dưới danh nghĩa một người cụ thể** và bị kiểm tra quyền
như chính người đó đang thao tác, đúng invariant #29 của
[CLAUDE.md](../../../CLAUDE.md#architecture): "background jobs, automation rules
and bulk operations enter another way" chứ không phải một đường tắt bỏ qua
kiểm tra quyền.

**Phase:** 14 · **Feature:** KJ-AUT-01 → KJ-AUT-10
**Liên quan:** [uc-05-issue.md](uc-05-issue.md) · [uc-07-workflow.md](uc-07-workflow.md) · [identity-and-permission.md](../../04-system-design/identity-and-permission.md) · [events-and-outbox.md](../../04-system-design/events-and-outbox.md) · [roadmap.md — Phase 14](../roadmap.md)

---

## UC-AUT-01 — Mô hình quy tắc: kích hoạt, điều kiện, hành động

**Requirement:** FR-AUT-01
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** không có

### Luồng chính

1. Tạo quy tắc: một **điều kiện kích hoạt** (khi nào chạy), không hoặc nhiều
   **điều kiện lọc** (chạy tiếp hay dừng), và một hoặc nhiều **hành động** theo
   thứ tự, thực hiện tuần tự
2. Một điều kiện lọc không thoả → dừng quy tắc tại đó, không chạy các hành động
   phía sau, không báo lỗi (đây là hành vi có chủ đích, không phải ngoại lệ)

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-AUT-01/NT-01 | Hai quản trị viên sửa cùng một quy tắc gần như đồng thời | Ghi sau thắng ở mức toàn bộ quy tắc (điều kiện + hành động lưu như một khối cấu hình), không hợp nhất từng phần — cùng cách UC-DSH-01/NT-02 xử lý bố cục dashboard dùng chung |
| UC-AUT-01/NT-02 | Tạo/sửa quy tắc khi mất kết nối | Vào hàng đợi bền cục bộ, áp dụng lạc quan lên danh sách quy tắc hiển thị |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-AUT-01/NL-01 | Không có quyền quản trị project | Không hiển thị chức năng tạo/sửa quy tắc |

### Hậu điều kiện

Quy tắc tồn tại ở cấp project, có thể bật hoặc tắt ngay (xem UC-AUT-10) mà
không cần xoá.

### Ảnh hưởng tới đồng bộ

Quy tắc (điều kiện, hành động) là dữ liệu cấu hình, nằm trong sync scope
`proj:{projectId}`. Tạo/sửa quy tắc phát delta cho chính nó — khác với **hiệu
ứng của việc chạy quy tắc** (đổi issue, thêm bình luận…), luôn đi theo delta
của use case sở hữu dữ liệu đó (xem UC-AUT-04).

---

## UC-AUT-02 — Các loại điều kiện kích hoạt

**Requirement:** FR-AUT-03
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** quy tắc đã tồn tại (UC-AUT-01)

### Luồng chính

1. Kích hoạt theo **sự kiện nghiệp vụ**: issue được tạo, trường đổi giá trị,
   bước chuyển trạng thái xảy ra, bình luận được thêm — quy tắc là một bên
   tiêu thụ domain event qua outbox, cùng cơ chế mọi consumer khác đã dùng từ
   Phase 0 (xem [events-and-outbox.md](../../04-system-design/events-and-outbox.md#bên-tiêu-thụ-dự-kiến))
2. Kích hoạt **theo lịch**: chạy định kỳ theo biểu thức thời gian, không gắn
   với một sự kiện cụ thể
3. Kích hoạt **thủ công**: thành viên tự bấm chạy quy tắc trên một issue hoặc
   một tập issue đã chọn

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-AUT-02/NT-01 | Sự kiện kích hoạt được relay worker gửi lại (delivery ít nhất một lần) | Quy tắc phải là consumer idempotent, chống trùng theo `(consumer, event_id)` giống mọi consumer khác — chạy lại không được tạo hiệu ứng nhân đôi (ví dụ gửi hai bình luận cho cùng một lần khớp điều kiện) |

### Hậu điều kiện

Quy tắc được đánh giá đúng một lần cho mỗi sự kiện kích hoạt thực tế, bất kể
event được relay worker gửi lại bao nhiêu lần.

### Ảnh hưởng tới đồng bộ

Bản thân việc đánh giá kích hoạt không phát delta — chỉ hành động thực thi sau
đó mới phát, theo cơ chế ở UC-AUT-04.

---

## UC-AUT-03 — Các loại điều kiện lọc

**Requirement:** FR-AUT-04
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** quy tắc đã tồn tại (UC-AUT-01)

### Luồng chính

1. Đặt điều kiện lọc trên trường của issue (hệ thống hoặc tuỳ biến), dùng lại
   đúng bộ toán tử và cách dịch sang SQL đã có ở tầng truy vấn động
   ([uc-09-search.md — UC-SRC-01/UC-SRC-02](uc-09-search.md#uc-src-02--dựng-sql-động-từ-cây-cú-pháp))
   — không viết lại một trình phân tích điều kiện riêng cho automation
2. Nhiều điều kiện lọc trong một quy tắc kết hợp bằng AND; không thoả một
   điều kiện là dừng quy tắc (xem UC-AUT-01)

### Hậu điều kiện

Điều kiện lọc là một phần cấu hình của quy tắc, đi theo delta của quy tắc chứa
nó (UC-AUT-01).

### Ảnh hưởng tới đồng bộ

Điều kiện lọc nằm trong sync scope `proj:{projectId}` như cấu hình quy tắc; sửa
điều kiện phát delta cho chính quy tắc, không phát delta riêng.

---

## UC-AUT-04 — Các loại hành động

**Requirement:** FR-AUT-05
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** quy tắc đã tồn tại và đang bật (UC-AUT-01, UC-AUT-10)

### Luồng chính

1. Hành động khả dụng: đổi trường, thực hiện bước chuyển trạng thái (đi qua
   đúng luồng UC-WKF-02..05, không ghi thẳng vào trạng thái), thêm bình luận,
   gán người, gửi thông báo, gọi webhook (Phase 16)
2. Mỗi hành động thực hiện như một **lệnh (command) bình thường** của module
   sở hữu dữ liệu đó, đi qua đúng command handler và đúng bước kiểm tra quyền
   ở đó — automation không có một đường ghi dữ liệu tắt nào bỏ qua handler

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-AUT-04/NL-01 | Hành động là một bước chuyển nhưng không có bước chuyển hợp lệ từ trạng thái hiện tại | Bỏ qua hành động đó, ghi vào nhật ký chạy (UC-AUT-09) là "không áp dụng được", tiếp tục các hành động còn lại trong quy tắc |
| UC-AUT-04/NL-02 | Hành động thất bại vì người chạy dưới danh nghĩa (UC-AUT-07) không đủ quyền | Bỏ qua hành động đó, ghi rõ lý do vào nhật ký chạy, tiếp tục các hành động còn lại — một hành động thiếu quyền không làm sập cả quy tắc |

### Hậu điều kiện

Mỗi hành động đã thực hiện để lại đúng trạng thái mà một request thủ công của
người chạy dưới danh nghĩa sẽ để lại — không có trạng thái trung gian đặc thù
riêng cho automation.

### Ảnh hưởng tới đồng bộ

Vì mỗi hành động đi qua đúng command handler của module sở hữu dữ liệu
(QT-AUT-04), nó phát **đúng delta mà use case gốc của dữ liệu đó phát** khi một
người dùng thao tác thủ công — đổi trường phát delta như UC-ISS-03, bước chuyển
phát delta như UC-WKF-02, thêm bình luận phát delta như UC-COL-01. Client không
cần biết delta đến từ automation hay từ một người đang gõ trực tiếp; không có
cơ chế đồng bộ riêng nào cho automation.

---

## UC-AUT-05 — Nhánh rẽ sang issue liên quan

**Requirement:** FR-AUT-02
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** quy tắc đã có ít nhất một hành động (UC-AUT-04)

### Luồng chính

1. Trước khi thực hiện hành động, chọn rẽ nhánh sang issue khác có quan hệ với
   issue kích hoạt: issue cha, issue con trực tiếp (UC-ISS-07), hoặc issue ở
   đầu kia của một liên kết (UC-ISS-08)
2. Hành động sau đó áp dụng lên **issue đã rẽ nhánh tới**, không phải issue
   kích hoạt ban đầu — ví dụ "khi Story chuyển sang Done, với mỗi Sub-task con,
   nếu chưa Done thì chuyển sang Done"

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-AUT-05/NT-01 | Rẽ nhánh tới issue con nhưng issue không có issue con nào | Không thực hiện hành động cho nhánh này, không báo lỗi — tương đương "0 issue khớp" |
| UC-AUT-05/NT-02 | Rẽ nhánh tới issue ở project khác (liên kết xuyên project) | Vẫn cho rẽ nhánh; hành động trên issue đó vẫn kiểm tra quyền của người chạy dưới danh nghĩa **trên project đó**, có thể khác quyền ở project chứa issue kích hoạt |

### Hậu điều kiện

Hành động đã áp dụng đúng lên issue đã rẽ nhánh tới, không lên issue kích hoạt
ban đầu.

### Ảnh hưởng tới đồng bộ

Delta phát cho issue đã rẽ nhánh tới, theo scope `proj:{projectId}` của project
chứa issue đó — khi rẽ nhánh xuyên project (NT-02), delta xuất hiện ở scope của
project đích, không phải scope chứa issue kích hoạt.

---

## UC-AUT-06 — Giá trị động trong nội dung hành động

**Requirement:** FR-AUT-06
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** quy tắc đã có ít nhất một hành động (UC-AUT-04)

### Luồng chính

1. Nội dung hành động (ví dụ văn bản bình luận, giá trị gán cho một trường)
   chèn được giá trị động lấy từ issue kích hoạt hoặc issue đã rẽ nhánh tới
   (tiêu đề, trạng thái, người được gán, giá trị trường tuỳ biến…)
2. Giá trị động được phân giải **tại thời điểm hành động thực thi**, không
   phân giải trước rồi lưu cứng — cùng nguyên tắc hàm dựng sẵn trong truy vấn
   đã áp dụng ở [uc-09-search.md — UC-SRC-03](uc-09-search.md#uc-src-03--hàm-dựng-sẵn-trong-truy-vấn)

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-AUT-06/NT-01 | Giá trị động tham chiếu một trường không tồn tại trên issue tại thời điểm thực thi (ví dụ trường tuỳ biến đã bị xoá mềm) | Thay bằng chuỗi rỗng, ghi cảnh báo vào nhật ký chạy, không chặn toàn bộ hành động |

### Hậu điều kiện

Nội dung hành động đã thực thi phản ánh đúng giá trị issue tại thời điểm chạy,
không phải tại thời điểm quy tắc được cấu hình.

### Ảnh hưởng tới đồng bộ

Không áp dụng riêng — giá trị động chỉ ảnh hưởng nội dung của hành động ở
UC-AUT-04, đi theo đúng delta đã mô tả ở đó.

---

## UC-AUT-07 — Quy tắc chạy dưới danh nghĩa một người và tôn trọng quyền

**Actor:** hệ thống (không có giao diện riêng — áp dụng cho mọi lần chạy của UC-AUT-04, UC-AUT-05)
**Tiền điều kiện:** không có

### Luồng chính

1. Mỗi quy tắc gắn với **một thành viên cụ thể** làm người chạy dưới danh
   nghĩa — mặc định là người tạo quy tắc, có thể đổi sang người khác nếu người
   đổi có quyền quản trị project
2. Khi quy tắc thực hiện hành động, hành động đó đi qua đúng command handler
   với `context` mang danh tính của người chạy dưới danh nghĩa, kiểm tra quyền
   **y hệt như chính người đó đang gửi request** — đúng "bốn chỗ bắt buộc kiểm
   tra" trong [identity-and-permission.md](../../04-system-design/identity-and-permission.md#bốn-chỗ-bắt-buộc-kiểm-tra),
   dòng "Quy tắc tự động"
3. Không có identity "hệ thống" nào có toàn quyền vượt qua kiểm tra — automation
   không phải và không được trở thành đường leo thang quyền

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-AUT-07/NL-01 | Người chạy dưới danh nghĩa rời project hoặc bị hạ quyền sau khi quy tắc đã tạo | Quy tắc tiếp tục chạy dưới danh nghĩa người đó nhưng hành động bị từ chối đúng theo quyền hiện tại (đã giảm) của họ — không tự nâng cấp, không tự dừng quy tắc; quản trị viên project được cảnh báo để đổi người chạy dưới danh nghĩa |
| UC-AUT-07/NL-02 | Người chạy dưới danh nghĩa bị vô hiệu hoá hoàn toàn (rời workspace) | Quy tắc tự động chuyển sang trạng thái tắt (UC-AUT-10), báo rõ lý do, không âm thầm chạy với quyền rỗng |

### Hậu điều kiện

Không có hành động nào của bất kỳ quy tắc nào từng thực hiện vượt quá quyền của
người mà quy tắc chạy dưới danh nghĩa — đây là Definition of Done của cả phase.

### Ảnh hưởng tới đồng bộ

Không áp dụng riêng — đây là quy tắc kiểm tra quyền áp cho mọi lần chạy, không
phải một thao tác ghi dữ liệu. Khi NL-02 tắt quy tắc, việc tắt đó phát delta
theo cơ chế ở UC-AUT-10.

---

## UC-AUT-08 — Chống vòng lặp và giới hạn số lần chạy

**Requirement:** FR-AUT-08
**Actor:** hệ thống (không có giao diện riêng)
**Tiền điều kiện:** không có

### Luồng chính

1. Hành động của một quy tắc có thể phát ra domain event khớp điều kiện kích
   hoạt của một quy tắc khác (kể cả chính nó) — hệ thống giới hạn **độ sâu**
   chuỗi kích hoạt liên tiếp trong một lần xử lý ban đầu
2. Hệ thống giới hạn **số lần chạy** của một quy tắc trong một khoảng thời
   gian, độc lập với độ sâu chuỗi

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-AUT-08/NL-01 | Vượt giới hạn độ sâu chuỗi kích hoạt (quy tắc A kích hoạt B, B kích hoạt A…) | Dừng chuỗi tại điểm vượt giới hạn, ghi rõ vào nhật ký chạy của quy tắc bị dừng là "dừng do vượt giới hạn vòng lặp", **không làm sập hệ thống** (Definition of Done của phase) |
| UC-AUT-08/NL-02 | Vượt giới hạn số lần chạy trong khoảng thời gian | Bỏ qua các lần kích hoạt tiếp theo cho tới khi qua khoảng thời gian đó, ghi vào nhật ký chạy, cảnh báo cho người quản trị quy tắc |

> **Chưa chốt:** tài liệu hiện có (`roadmap.md` Phase 14) nêu rõ cần "cả giới
> hạn độ sâu lẫn giới hạn số lần chạy trong một khoảng thời gian" nhưng chưa
> chốt con số cụ thể (độ sâu tối đa, số lần tối đa, độ dài khoảng thời gian).
> Để lại cho lúc thiết kế chi tiết, dựa trên đo đạc thực tế.

### Hậu điều kiện

Chuỗi kích hoạt liên tiếp dừng lại ở đúng giới hạn độ sâu hoặc số lần chạy;
không có quy tắc nào chạy vô hạn.

### Ảnh hưởng tới đồng bộ

Không áp dụng riêng — giới hạn chỉ chặn việc **đánh giá** kích hoạt tiếp theo,
không tự nó phát delta; nhật ký chạy được ghi theo cơ chế ở UC-AUT-09.

---

## UC-AUT-09 — Nhật ký chạy đủ chi tiết để tự gỡ lỗi

**Requirement:** FR-AUT-07
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** không có

### Luồng chính

1. Mỗi lần một quy tắc chạy (dù có hành động nào được thực hiện hay không),
   hệ thống ghi một bản ghi nhật ký chạy: thời điểm, sự kiện kích hoạt, kết
   quả từng điều kiện lọc, kết quả từng hành động (thực hiện / bỏ qua kèm lý
   do / lỗi kèm lý do)
2. Xem lại lịch sử chạy của một quy tắc, lọc theo kết quả (thành công, có hành
   động bị bỏ qua, dừng do vòng lặp)

### Hậu điều kiện

Người quản trị quy tắc tự xác định được lý do một lần chạy không như mong đợi
mà không cần xem log hệ thống cấp vận hành — đây là Definition of Done của
phase.

### Ảnh hưởng tới đồng bộ

Bản ghi nhật ký chạy nằm trong sync scope `proj:{projectId}`; mỗi lần chạy phát
một delta thêm mới, để trang xem lịch sử cập nhật theo thời gian thực.

---

## UC-AUT-10 — Bật tắt và phạm vi áp dụng của quy tắc

**Requirement:** FR-AUT-09
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** quy tắc đã tồn tại (UC-AUT-01)

### Luồng chính

1. Bật hoặc tắt một quy tắc bất cứ lúc nào; quy tắc tắt không tiêu thụ sự
   kiện kích hoạt, không chạy theo lịch, không hiện trong danh sách chạy thủ
   công
2. Đặt phạm vi áp dụng: toàn project, hoặc giới hạn theo loại issue/component

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-AUT-10/NT-01 | Tắt một quy tắc đang có lần chạy dở dang (nhiều hành động tuần tự) | Lần chạy dở dang tiếp tục hoàn tất; chỉ các lần kích hoạt **mới** sau thời điểm tắt bị bỏ qua |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-AUT-10/NL-01 | Không có quyền quản trị project | Không hiển thị chức năng bật/tắt hoặc đổi phạm vi |

### Hậu điều kiện

Trạng thái bật/tắt và phạm vi áp dụng của quy tắc phản ánh đúng lựa chọn cuối
cùng của người quản trị.

### Ảnh hưởng tới đồng bộ

Đổi trạng thái bật/tắt hoặc phạm vi áp dụng phát một delta cho quy tắc trong
scope `proj:{projectId}`; client cập nhật ngay danh sách quy tắc đang hoạt động.

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-AUT-01 | Điều kiện lọc không thoả thì dừng quy tắc tại đó, không báo lỗi |
| QT-AUT-02 | Quy tắc tiêu thụ domain event qua outbox, phải chống trùng theo `(consumer, event_id)` giống mọi consumer khác |
| QT-AUT-03 | Điều kiện lọc dùng chung tầng dịch điều kiện sang SQL với truy vấn động, không viết lại riêng |
| QT-AUT-04 | Hành động thực hiện qua đúng command handler của module sở hữu dữ liệu, không có đường ghi tắt |
| QT-AUT-05 | Giá trị động trong hành động phân giải tại thời điểm thực thi, không lưu cứng trước |
| QT-AUT-06 | Mọi hành động của quy tắc kiểm tra quyền theo người chạy dưới danh nghĩa, không có identity hệ thống vượt qua kiểm tra |
| QT-AUT-07 | Người chạy dưới danh nghĩa bị vô hiệu hoá hoàn toàn thì quy tắc tự tắt, không âm thầm chạy với quyền rỗng |
| QT-AUT-08 | Vượt giới hạn độ sâu chuỗi kích hoạt hoặc số lần chạy thì dừng có kiểm soát, không làm sập hệ thống |
| QT-AUT-09 | Mỗi lần chạy quy tắc đều ghi nhật ký đủ chi tiết để tự gỡ lỗi, kể cả khi không hành động nào được thực hiện |
| QT-AUT-10 | Tắt quy tắc không huỷ lần chạy dở dang, chỉ chặn các lần kích hoạt mới |

## Yêu cầu phi chức năng liên quan

`NFR-17` consumer sự kiện của automation phải chống trùng · `NFR-07` điều kiện
lọc phải ghép ở tầng SQL, không lọc sau · `NFR-01` chạy quy tắc không chặn luồng
xử lý sự kiện chính, xử lý bất đồng bộ qua outbox
