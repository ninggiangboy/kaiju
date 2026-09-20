# UC-TIM — Time tracking

Theo dõi thời gian làm việc trên issue. Trường "ước lượng" đã có từ Phase 3
(FR-ISS-04, UC-ISS-01) trở thành **ước lượng ban đầu** — một trong ba giá trị
thời gian của phase này; hai giá trị còn lại (còn lại, đã dùng) là trường hệ
thống mới, và "đã dùng" luôn tổng hợp từ nhật ký công việc thay vì nhập tay.

**Phase:** 11 · **Feature:** KJ-TIM-01 → KJ-TIM-06
**Liên quan:** [uc-05-issue.md](uc-05-issue.md) · [uc-09-search.md](uc-09-search.md) · [data-access-and-tenancy.md](../../04-system-design/data-access-and-tenancy.md) · [roadmap.md — Phase 11](../roadmap.md)

---

## UC-TIM-01 — Ba giá trị thời gian trên issue

**Requirement:** FR-TIM-01
**Actor:** thành viên có quyền sửa issue
**Tiền điều kiện:** không có

### Luồng chính

1. Issue có ba giá trị thời gian: **ước lượng ban đầu** (trường đã có từ
   UC-ISS-01, nhập tay khi tạo hoặc sửa issue), **còn lại** (nhập tay hoặc tự
   điều chỉnh — xem UC-TIM-04), và **đã dùng** (chỉ đọc, luôn bằng tổng các bản
   ghi công việc hiện có của issue — xem UC-TIM-02)
2. Cả ba giá trị hiển thị cạnh nhau trên issue, cùng thanh tiến độ trực quan
   (đã dùng / ước lượng ban đầu)

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-TIM-01/NT-01 | Issue chưa từng đặt ước lượng ban đầu | "Còn lại" và "đã dùng" vẫn hoạt động bình thường — ba giá trị độc lập, không giá trị nào bắt buộc phải có giá trị kia |
| UC-TIM-01/NT-02 | Loại issue là Epic | Vẫn có ba giá trị thời gian như issue thường; **không tự tổng hợp** từ issue con — đó là việc của báo cáo (UC-TIM-06), không phải một trường tổng hợp tự động như ngày ở roadmap (UC-RDM-02) |

### Hậu điều kiện

"Đã dùng" không bao giờ lệch với tổng thực tế của nhật ký công việc — không có
đường nào ghi trực tiếp vào "đã dùng" ngoài việc ghi/sửa/xoá bản ghi công việc.

### Ảnh hưởng tới đồng bộ

Ba giá trị thời gian là trường của issue, nằm trong sync scope `proj:{projectId}`
như mọi trường khác của issue (UC-ISS-03) — không có scope riêng.

---

## UC-TIM-02 — Nhật ký công việc theo ngày

**Requirement:** FR-TIM-02
**Actor:** thành viên có quyền sửa issue
**Tiền điều kiện:** đang xem một issue

### Luồng chính

1. Ghi một bản ghi công việc: ngày làm việc, số giờ, mô tả ngắn (tuỳ chọn)
2. Bản ghi công việc là một **aggregate riêng**, tham chiếu issue bằng id —
   không nằm trong aggregate `Issue`, cùng cách bình luận được thiết kế ở
   [uc-06-collaboration.md — UC-COL-01](uc-06-collaboration.md#uc-col-01--bình-luận-và-lịch-sử-sửa)
3. Ghi xong → "đã dùng" của issue tính lại ngay (UC-TIM-01), xuất hiện trong
   dòng hoạt động (UC-COL-05)

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-TIM-02/NT-01 | Ngày làm việc trong tương lai | Cho phép — một số đội ghi log trước cho công việc đã lên lịch chắc chắn, hệ thống không tự phán đoán là sai |
| UC-TIM-02/NT-02 | Ghi log khi mất kết nối | Bản ghi vào hàng đợi bền cục bộ, hiển thị trạng thái "đang chờ đồng bộ"; "đã dùng" tính tạm trên client và xác nhận lại khi server phản hồi |
| UC-TIM-02/NT-03 | Gửi lại cùng một lần ghi log (ví dụ do mất kết nối giữa chừng) với cùng khoá chống trùng | Không tạo bản ghi công việc thứ hai — server nhận diện qua idempotency key và trả lại kết quả của lần ghi đầu |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-TIM-02/NL-01 | Số giờ ghi âm hoặc bằng không | Từ chối lưu, báo lỗi tại chỗ |
| UC-TIM-02/NL-02 | Ghi log trên issue đã xoá mềm (UC-ISS-04) | Chặn |
| UC-TIM-02/NL-03 | Không có quyền sửa issue | Không hiển thị chức năng ghi log |

### Hậu điều kiện

Bản ghi công việc mới tồn tại, tham chiếu issue bằng id. "Đã dùng" của issue
được tính lại và phản ánh bản ghi vừa thêm.

### Ảnh hưởng tới đồng bộ

Bản ghi công việc thuộc sync scope `proj:{projectId}`. Ghi log phát hai delta
trong cùng một đợt: bản ghi công việc mới và giá trị "đã dùng" mới của issue —
xem UC-TIM-03 cho lý do gộp chung một đợt.

---

## UC-TIM-03 — Sửa và xoá bản ghi công việc

**Requirement:** FR-TIM-02
**Actor:** người tạo bản ghi công việc, hoặc thành viên có quyền quản trị project
**Tiền điều kiện:** bản ghi công việc cần sửa/xoá đã tồn tại (UC-TIM-02)

### Luồng chính

1. Sửa số giờ, ngày, hoặc mô tả của một bản ghi công việc đã ghi
2. Xoá một bản ghi công việc
3. Sau mỗi lần sửa hoặc xoá, "đã dùng" của issue được **tính lại từ đầu** —
   quét tổng toàn bộ bản ghi hiện có của issue, không cộng/trừ số gia tăng vào
   một biến đếm lưu sẵn, để không bao giờ lệch (Definition of Done của phase)

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-TIM-03/NT-01 | Hai người sửa hai bản ghi khác nhau của cùng issue gần như đồng thời | Cả hai đều ghi thành công; "đã dùng" tính lại đúng ở lần tính cuối cùng, vì mỗi lần tính đều quét toàn bộ, không phụ thuộc thứ tự |
| UC-TIM-03/NT-02 | Sửa hoặc xoá bản ghi khi mất kết nối | Vào hàng đợi bền cục bộ như UC-TIM-02/NT-02; "đã dùng" hiển thị tạm, tính lại chính thức khi server xác nhận |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-TIM-03/NL-01 | Người không phải chủ bản ghi, không có quyền quản trị project, cố sửa/xoá | Chặn |

### Hậu điều kiện

Bản ghi công việc phản ánh đúng lần sửa cuối, hoặc không còn tồn tại nếu bị xoá.
"Đã dùng" của issue khớp với tổng các bản ghi còn lại.

### Ảnh hưởng tới đồng bộ

Bản ghi công việc và "đã dùng" cùng nằm trong sync scope `proj:{projectId}`;
sửa hoặc xoá một bản ghi phát delta cho cả bản ghi đó lẫn giá trị "đã dùng" mới
của issue trong cùng một đợt cập nhật, để client không bao giờ thấy trạng thái
hai giá trị lệch nhau giữa hai lần render.

---

## UC-TIM-04 — Tự điều chỉnh thời gian còn lại

**Requirement:** FR-TIM-03
**Actor:** thành viên có quyền sửa issue
**Tiền điều kiện:** không có

### Luồng chính

1. Khi ghi một bản ghi công việc mới (UC-TIM-02), hệ thống mặc định **trừ số
   giờ vừa ghi khỏi "còn lại"**
2. Tại thời điểm ghi log, người dùng có thể chọn thay vì trừ tự động: tự nhập
   giá trị "còn lại" mới, hoặc giữ nguyên "còn lại" không đổi

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-TIM-04/NT-01 | Trừ tự động làm "còn lại" xuống dưới không | Cho phép xuống âm — hiển thị cảnh báo trực quan "vượt ước lượng", không chặn ghi log |
| UC-TIM-04/NT-02 | Xoá một bản ghi công việc đã từng trừ vào "còn lại" (UC-TIM-03) | **Không** tự động cộng lại số giờ đó vào "còn lại" — chỉ "đã dùng" được tính lại tự động; "còn lại" là giá trị người dùng chủ động quản lý, xoá log không suy ngược lại ý định điều chỉnh trước đó |

### Hậu điều kiện

"Còn lại" phản ánh đúng lựa chọn của người dùng tại thời điểm ghi log: trừ tự
động, giá trị nhập tay, hoặc giữ nguyên.

### Ảnh hưởng tới đồng bộ

"Còn lại" là một trường của issue, đi theo cùng delta issue trong sync scope
`proj:{projectId}` — không phát delta riêng.

---

## UC-TIM-05 — Đơn vị thời gian cấu hình được

**Requirement:** FR-TIM-04
**Actor:** thành viên có quyền quản trị workspace
**Tiền điều kiện:** không có

### Luồng chính

1. Đặt số giờ làm việc mỗi ngày và số ngày làm việc mỗi tuần ở cấp workspace
2. Mọi giá trị thời gian (ước lượng, còn lại, đã dùng, bản ghi công việc) lưu
   trữ nội bộ theo đơn vị chuẩn (phút), chỉ **hiển thị** quy đổi sang ngày/tuần
   theo cấu hình này — đổi cấu hình không viết lại dữ liệu đã lưu
3. Nhập liệu chấp nhận cả hai dạng (ví dụ "2d 4h" hoặc số phút), quy đổi về đơn
   vị chuẩn khi lưu

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-TIM-05/NT-01 | Đổi cấu hình giờ/ngày sau khi đã có dữ liệu | Dữ liệu cũ hiển thị lại theo cách quy đổi mới ngay, không cần tính toán lại hay di trú dữ liệu vì giá trị gốc luôn ở đơn vị chuẩn |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-TIM-05/NL-01 | Không phải quản trị viên workspace | Không hiển thị chức năng này |

### Hậu điều kiện

Cấu hình giờ/ngày mới của workspace có hiệu lực cho mọi hiển thị tiếp theo.

### Ảnh hưởng tới đồng bộ

Cấu hình nằm trong scope `ws:{workspaceId}` (UC-WSP-08). Đổi cấu hình phát một
delta duy nhất; client tính lại cách hiển thị tại chỗ, không cần tải lại dữ
liệu thời gian.

---

## UC-TIM-06 — Báo cáo thời gian theo nhiều chiều

**Requirement:** FR-TIM-05
**Actor:** thành viên có quyền xem project
**Tiền điều kiện:** không có

### Luồng chính

1. Báo cáo tổng hợp thời gian đã dùng theo người ghi log, theo project, theo
   khoảng thời gian tuỳ chọn — dựng qua jOOQ, cùng tầng đọc động đã dùng ở
   [uc-09-search.md](uc-09-search.md)
2. Xem chi tiết từng bản ghi công việc trong một khoảng đã lọc

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-TIM-06/NT-01 | Thành viên thường xem báo cáo | Chỉ thấy tổng hợp và chi tiết log của **chính mình**, không thấy của người khác |
| UC-TIM-06/NT-02 | Quản trị viên project xem báo cáo | Thấy log của toàn bộ thành viên trong project, đi qua đúng điều kiện phân quyền ghép ở tầng dựng SQL (QT-TIM-03, [uc-09-search.md](uc-09-search.md#uc-src-05--ghép-điều-kiện-phân-quyền-vào-truy-vấn)), không lọc lại sau khi có kết quả |

### Hậu điều kiện

Không có — đây là thao tác chỉ đọc, không đổi trạng thái hệ thống.

### Ảnh hưởng tới đồng bộ

Không áp dụng — báo cáo dựng động qua truy vấn jOOQ theo yêu cầu, không phải dữ
liệu giữ trong store cục bộ hay phát qua sync scope.

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-TIM-01 | "Đã dùng" luôn bằng tổng các bản ghi công việc hiện có của issue, không có đường ghi trực tiếp nào khác |
| QT-TIM-02 | Mỗi lần sửa hoặc xoá bản ghi công việc, "đã dùng" được tính lại từ đầu bằng cách quét toàn bộ, không cộng/trừ gia tăng |
| QT-TIM-03 | Bản ghi công việc là aggregate riêng, tham chiếu issue bằng id, không nằm trong aggregate Issue |
| QT-TIM-04 | Số giờ ghi log phải lớn hơn không |
| QT-TIM-05 | Chỉ chủ bản ghi công việc hoặc quản trị viên project được sửa/xoá bản ghi đó |
| QT-TIM-06 | Trừ tự động vào "còn lại" khi ghi log là mặc định, có thể ghi đè bằng giá trị nhập tay hoặc giữ nguyên tại thời điểm ghi |
| QT-TIM-07 | Xoá một bản ghi công việc không tự động cộng lại số giờ đã trừ vào "còn lại" |
| QT-TIM-08 | Mọi giá trị thời gian lưu trữ theo đơn vị chuẩn (phút); đơn vị hiển thị chỉ là quy đổi tại thời điểm xem |
| QT-TIM-09 | Thành viên thường chỉ xem được báo cáo và log thời gian của chính mình; quản trị viên project xem được toàn bộ |

## Yêu cầu phi chức năng liên quan

`NFR-01` ghi log và sửa/xoá phản hồi tức thì trước khi server xác nhận ·
`NFR-07` báo cáo thời gian phải ghép điều kiện phân quyền ở tầng SQL, không lọc
sau · `NFR-11` báo cáo chịu được khối lượng log lớn mà không chậm
