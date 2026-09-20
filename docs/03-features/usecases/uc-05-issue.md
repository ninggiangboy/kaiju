# UC-ISS — Issue

Issue là hạt nhân nghiệp vụ của Kaiju. Mô hình dữ liệu của phase này làm trọn một
lần: tách ra sau sẽ phải sửa lại schema. Trạng thái ở phase này là một tập **cố
định ba giá trị** (to-do / in-progress / done) — workflow động do người dùng định
nghĩa thuộc Phase 5, và đây là ngoại lệ duy nhất với nguyên tắc làm đầy đủ, được
chấp nhận vì hai tính năng phụ thuộc vòng nhau.

**Phase:** 3 · **Feature:** KJ-ISS-01 → KJ-ISS-16
**Liên quan:** [uc-04-project.md](uc-04-project.md) · [backend-modules.md](../../04-system-design/backend-modules.md) · [realtime-and-sync.md](../../04-system-design/realtime-and-sync.md) · [roadmap.md — Phase 3](../roadmap.md)

---

## UC-ISS-01 — Tạo issue

**Requirement:** FR-ISS-01, FR-ISS-04
**Actor:** thành viên có quyền tạo issue trong project
**Tiền điều kiện:** đang ở trong một project

### Luồng chính

1. Chọn tạo issue, chọn loại issue trong số loại **đã được bật cho project này**
2. Nhập tiêu đề, mô tả, và các trường hệ thống khác (độ ưu tiên, người được gán,
   người báo cáo, nhãn, component, hạn hoàn thành, ước lượng, story point)
3. Hệ thống sinh mã issue dạng `KEY-số`, lấy số tiếp theo trong project
4. Issue được tạo ở trạng thái mặc định của nhóm "chưa làm"
5. Người tạo tự động trở thành người theo dõi (xem [uc-06-collaboration](uc-06-collaboration.md))

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-ISS-01/NT-01 | Hai request tạo issue cùng lúc trong cùng project | Cả hai đều thành công, mỗi issue nhận **một số khác nhau, không trùng** — xem UC-ISS-02 |
| UC-ISS-01/NT-02 | Mất mạng ngay sau khi bấm tạo | Request vào **hàng đợi bền**, issue hiện ngay trên giao diện ở trạng thái "đang gửi"; hàng đợi sống sót qua tải lại trang và gửi lại khi có mạng |
| UC-ISS-01/NT-03 | Client gửi lại request tạo cùng khoá chống trùng (do timeout hoặc do hàng đợi bền gửi lại) | Server nhận ra khoá đã xử lý, trả về **issue đã tạo trước đó**, không tạo issue thứ hai |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-ISS-01/NL-01 | Loại issue chưa được bật cho project | Không hiển thị trong danh sách chọn |
| UC-ISS-01/NL-02 | Người báo cáo không còn hoạt động (đã rời workspace) | Không cho chọn làm người báo cáo của issue mới |
| UC-ISS-01/NL-03 | Người được gán không có quyền truy cập project | Từ chối gán, báo rõ lý do |
| UC-ISS-01/NL-04 | Không đủ quyền tạo issue | Không hiển thị chức năng này |

### Hậu điều kiện

Issue tồn tại với mã duy nhất trong project. Client của mọi người có quyền xem
project nhận được issue mới qua sync scope của project.

### Ảnh hưởng tới đồng bộ

Issue mới phát delta upsert trên scope `proj:{projectId}`. Người tạo trở thành
người theo dõi cũng nằm trong cùng delta đó, không phát riêng.

---

## UC-ISS-02 — Sinh mã issue an toàn khi tạo đồng thời

**Requirement:** FR-ISS-03
**Actor:** hệ thống (chạy trong mọi luồng tạo issue)
**Tiền điều kiện:** không có

### Luồng chính

1. Mỗi project giữ một bộ đếm số issue tiếp theo
2. Khi tạo issue, hệ thống lấy số kế tiếp và tăng bộ đếm **trong cùng giao dịch**
   với việc tạo issue
3. Mã hiển thị được **tính từ `key` của project cộng số này**, không lưu sẵn dạng
   chuỗi trong issue — giống nguyên tắc đã áp dụng cho key project ở UC-PRJ-02

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-ISS-02/NT-01 | Nhiều request tạo issue cùng lúc trong cùng project | Bộ đếm phải tuần tự hoá đúng, không có hai issue nào nhận cùng một số — kiểm chứng bằng **test song song** |
| UC-ISS-02/NT-02 | Giao dịch tạo issue bị rollback (ví dụ do ràng buộc khác thất bại) | Số đã lấy có thể bị bỏ trống (gap), điều này **chấp nhận được** — yêu cầu là không trùng, không phải không có khoảng trống |

### Hậu điều kiện

Bộ đếm số issue của project đã tăng đúng một lần cho mỗi issue tạo thành công;
không hai issue nào trong cùng project mang cùng số.

### Ảnh hưởng tới đồng bộ

Vì mã hiển thị được tính từ key chứ không lưu chuỗi, đổi key project (UC-PRJ-02)
không cần phát delta cho từng issue — client tự tính lại khi project đổi key.

---

## UC-ISS-03 — Xem và sửa issue

**Requirement:** FR-ISS-01, FR-ISS-04
**Actor:** thành viên có quyền xem/sửa issue
**Tiền điều kiện:** không có

### Luồng chính

1. Mở issue, xem đầy đủ trường hệ thống và mô tả
2. Sửa một hoặc nhiều trường
3. Thay đổi hiện ngay trên giao diện (optimistic), gửi lên server qua HTTP POST
   kèm khoá chống trùng
4. Server xác nhận hoặc từ chối; nếu từ chối, giao diện hoàn tác kèm lý do

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-ISS-03/NT-01 | Hai người sửa **cùng một trường** gần như đồng thời | Ghi sau thắng ở mức trường, theo nguyên tắc chung của sync engine |
| UC-ISS-03/NT-02 | Sửa trong lúc mất mạng | Mutation vào hàng đợi bền, giao diện hiện trạng thái "đang chờ gửi"; nhiều lần sửa liên tiếp trên cùng issue được gửi **tuần tự**, không ngược thứ tự |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-ISS-03/NL-01 | Không đủ quyền sửa | Trường hiển thị ở chế độ chỉ đọc |
| UC-ISS-03/NL-02 | Sửa một issue đã bị xoá mềm | Chặn, báo issue đã bị xoá |
| UC-ISS-03/NL-03 | Gán người không thuộc project (mức hiển thị hạn chế) | Từ chối, gợi ý thêm người đó vào project trước |

### Hậu điều kiện

Issue mang giá trị mới ở các trường đã sửa; một bản ghi nhật ký thay đổi tồn tại
cho mỗi trường đổi.

### Ảnh hưởng tới đồng bộ

Mỗi thay đổi trường sinh một bản ghi nhật ký thay đổi và một delta chỉ chứa
**các trường đã đổi**, không gửi cả issue.

---

## UC-ISS-04 — Xoá mềm và khôi phục

**Requirement:** FR-ISS-01
**Actor:** thành viên có quyền xoá issue
**Tiền điều kiện:** không có

### Luồng chính

1. Chọn xoá issue
2. Issue chuyển sang trạng thái đã xoá mềm, ẩn khỏi mọi danh sách và board mặc định
3. Có thể khôi phục từ danh sách issue đã xoá trong project

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-ISS-04/NT-01 | Issue có sub-task | Cảnh báo số sub-task sẽ bị xoá theo, yêu cầu xác nhận |
| UC-ISS-04/NT-02 | Issue đang được liên kết bởi issue khác | Cảnh báo, liên kết vẫn giữ nhưng hiển thị "issue đã xoá" ở đầu kia |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-ISS-04/NL-01 | Issue là epic đang chứa issue con | Chặn, yêu cầu bỏ liên kết hoặc xoá các issue con trước |

### Hậu điều kiện

Issue ở trạng thái đã xoá mềm, ẩn khỏi danh sách và board mặc định; dữ liệu vẫn
tồn tại trong cơ sở dữ liệu cho tới khi xoá vĩnh viễn.

### Ảnh hưởng tới đồng bộ

Client xoá issue khỏi mọi view cục bộ khi nhận delta xoá mềm, nhưng **không xoá
dữ liệu vĩnh viễn** — khôi phục chỉ cần một delta upsert lại.

---

## UC-ISS-05 — Năm loại issue và cấu hình theo project

**Requirement:** FR-ISS-02
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** không có

### Luồng chính

1. Năm loại cố định: Epic, Story, Task, Sub-task, Bug
2. Quản trị viên project chọn loại nào được bật cho project này
3. Loại đã bật xuất hiện trong danh sách chọn khi tạo issue (UC-ISS-01)

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-ISS-05/NT-01 | Tắt một loại đang có issue tồn tại | Cho phép — issue cũ vẫn giữ loại đó, chỉ ẩn khỏi lựa chọn tạo mới |
| UC-ISS-05/NT-02 | Tắt Epic hoặc Sub-task khi đang có phân cấp dùng loại đó | Cảnh báo rõ ảnh hưởng tới UC-ISS-07, vẫn cho tắt |

### Hậu điều kiện

Danh sách loại issue được bật cho project phản ánh lựa chọn mới nhất; issue đã
tạo bằng loại vừa tắt giữ nguyên loại đó.

### Ảnh hưởng tới đồng bộ

Cấu hình loại issue là dữ liệu của scope project; thay đổi phát delta trên
chính scope đó, client của mọi thành viên đang mở project cập nhật ngay.

---

## UC-ISS-06 — Mô tả định dạng phong phú

**Requirement:** FR-ISS-05
**Actor:** thành viên có quyền sửa issue
**Tiền điều kiện:** không có

### Luồng chính

1. Soạn mô tả bằng trình soạn thảo rich text
2. Dán hoặc kéo thả ảnh vào mô tả — ảnh được tải lên kho lưu trữ đối tượng và
   nhúng bằng đường dẫn, giống cơ chế đính kèm tệp ở [uc-06-collaboration](uc-06-collaboration.md)
3. Nội dung lưu ở định dạng có cấu trúc, không phải HTML thô

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-ISS-06/NT-01 | Xoá issue có ảnh nhúng trong mô tả | Ảnh vẫn còn ở kho lưu trữ cho tới khi issue bị xoá vĩnh viễn |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-ISS-06/NL-01 | Ảnh vượt giới hạn dung lượng | Từ chối, báo giới hạn |

### Hậu điều kiện

Mô tả lưu ở định dạng có cấu trúc kèm ảnh đã nhúng; ảnh nằm trong kho lưu trữ
đối tượng, được tham chiếu bằng đường dẫn từ nội dung mô tả.

### Ảnh hưởng tới đồng bộ

Nội dung mô tả là một trường của issue nên đi theo delta chung của UC-ISS-03;
đường dẫn ảnh nằm trong nội dung, không cần cơ chế đồng bộ riêng.

---

## UC-ISS-07 — Phân cấp ba tầng

**Requirement:** FR-ISS-06
**Actor:** thành viên có quyền sửa issue
**Tiền điều kiện:** không có

### Luồng chính

1. Gán một issue làm con của một Epic, hoặc một Sub-task làm con của một Task/Story
2. Hệ thống giới hạn đúng ba tầng: Epic → Story/Task/Bug → Sub-task
3. Issue cha hiển thị danh sách issue con; issue con hiển thị liên kết tới issue cha

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-ISS-07/NT-01 | Gán issue cha thuộc project khác | Cho phép — phân cấp không bị giới hạn trong một project, khác với sync scope (xem ghi chú dưới) |
| UC-ISS-07/NT-02 | Xoá issue cha | Issue con **không** bị xoá theo, chỉ mất liên kết cha |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-ISS-07/NL-01 | Gán issue cha tạo thành vòng lặp (A là con của B, B là con của A) | Từ chối, báo lỗi vòng lặp |
| UC-ISS-07/NL-02 | Gán quá ba tầng (ví dụ gán con cho một Sub-task) | Từ chối — Sub-task không có issue con |

### Hậu điều kiện

Liên kết cha-con tồn tại giữa hai issue, hiển thị ở cả hai chiều (danh sách
issue con ở issue cha, liên kết cha ở issue con).

### Ảnh hưởng tới đồng bộ

Vì issue cha và issue con có thể thuộc hai project khác nhau, client hiển thị
phân cấp phải tự ráp dữ liệu từ **hai sync scope**; không có scope riêng cho
"cây phân cấp".

---

## UC-ISS-08 — Liên kết hai chiều và loại liên kết cấu hình được

**Requirement:** FR-ISS-07, FR-ISS-08
**Actor:** thành viên có quyền sửa issue
**Tiền điều kiện:** không có

### Luồng chính

1. Tạo liên kết giữa hai issue, chọn loại liên kết (chặn, liên quan, trùng lặp,
   nhân bản, hoặc loại tự định nghĩa)
2. Liên kết hiện ở **cả hai issue**, mỗi bên hiển thị đúng tên chiều của mình
   (ví dụ "chặn" ở issue A hiện thành "bị chặn bởi" ở issue B)
3. Quản trị viên workspace định nghĩa loại liên kết mới, đặt tên hai chiều

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-ISS-08/NT-01 | Xoá một loại liên kết đang được dùng | Cảnh báo số liên kết bị ảnh hưởng, cho chọn: xoá liên kết hoặc chuyển sang loại khác |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-ISS-08/NL-01 | Tạo liên kết trùng (cùng cặp issue, cùng loại) | Từ chối, báo đã tồn tại |
| UC-ISS-08/NL-02 | Liên kết một issue với chính nó | Từ chối |

### Hậu điều kiện

Liên kết tồn tại giữa hai issue, mỗi bên hiển thị đúng tên chiều của loại liên
kết đã chọn.

### Ảnh hưởng tới đồng bộ

Liên kết là một trường của cả hai issue liên quan; tạo hoặc xoá liên kết phát
delta cho cả hai, có thể nằm ở hai scope project khác nhau.

---

## UC-ISS-09 — Thứ hạng cho phép chèn vô hạn

**Requirement:** FR-ISS-09
**Actor:** thành viên có quyền sắp xếp issue (board, backlog)
**Tiền điều kiện:** không có

### Luồng chính

1. Mỗi issue trong một danh sách sắp xếp được (board, backlog) mang một giá trị
   thứ hạng dạng chuỗi, so sánh được theo thứ tự từ điển
2. Kéo một issue tới vị trí mới → hệ thống tính thứ hạng nằm **giữa hai giá trị
   lân cận**, không cần đánh số lại các issue khác
3. Khi khoảng cách giữa hai giá trị lân cận cạn hết, hệ thống chạy cân bằng lại
   nền, đánh số cách đều

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-ISS-09/NT-01 | Kéo tới vị trí đầu hoặc cuối danh sách | Tính thứ hạng dựa trên một đầu mút, không cần hai giá trị lân cận |
| UC-ISS-09/NT-02 | Hai người kéo hai issue khác nhau vào cùng vị trí gần như đồng thời | Cả hai đều thành công, thứ tự cuối cùng theo ai gửi lên server trước |
| UC-ISS-09/NT-03 | Cân bằng lại đang chạy mà có thao tác kéo mới | Thao tác kéo mới chờ cân bằng lại hoàn tất rồi tính lại thứ hạng, không áp lên giá trị cũ |

### Hậu điều kiện

Issue vừa kéo mang giá trị thứ hạng mới, đặt đúng vị trí trong danh sách. Sau
cân bằng lại nền, các issue trong danh sách mang giá trị thứ hạng cách đều.

### Ảnh hưởng tới đồng bộ

Đổi thứ hạng chỉ phát delta cho **issue vừa kéo**, không phát cho các issue khác
trong danh sách — đây là lý do chọn cách đánh thứ hạng cho phép chèn vô hạn thay
vì số thứ tự nguyên liền kề. Cân bằng lại nền là ngoại lệ duy nhất phát nhiều
delta cùng lúc; phải chia lô để không làm ngập luồng đồng bộ (xem KJ-BLK-02 ở
phase sau cho cơ chế chung).

---

## UC-ISS-10 — Nhân bản issue

**Requirement:** FR-ISS-10
**Actor:** thành viên có quyền tạo issue
**Tiền điều kiện:** không có

### Luồng chính

1. Chọn nhân bản một issue
2. Chọn có nhân bản kèm sub-task và liên kết hay không
3. Hệ thống tạo issue mới với mã mới, sao chép các trường (trừ nhật ký thay đổi,
   bình luận, dòng hoạt động — những thứ đó không nhân bản)
4. Issue mới tự động liên kết "nhân bản của" với issue gốc

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-ISS-10/NT-01 | Nhân bản kèm sub-task nhưng một sub-task đã bị xoá mềm | Bỏ qua sub-task đã xoá, không nhân bản |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-ISS-10/NL-01 | Nhân bản issue đã xoá mềm | Chặn |

### Hậu điều kiện

Issue mới tồn tại với mã riêng, liên kết "nhân bản của" trỏ về issue gốc; issue
gốc không đổi.

### Ảnh hưởng tới đồng bộ

Giống UC-ISS-01: issue mới phát delta upsert trên scope project của nó.

---

## UC-ISS-11 — Chuyển issue sang project khác

**Requirement:** FR-ISS-11
**Actor:** thành viên có quyền quản trị cả project nguồn và project đích
**Tiền điều kiện:** không có

### Luồng chính

1. Chọn chuyển issue sang project khác
2. Hệ thống cảnh báo: mã issue sẽ đổi theo key của project đích
3. Xác nhận → issue nhận mã mới theo bộ đếm của project đích, **giữ nguyên toàn
   bộ lịch sử** (nhật ký thay đổi, bình luận, dòng hoạt động)
4. Đường dẫn theo mã cũ vẫn truy cập được, chuyển hướng sang mã mới — cùng cơ chế
   với đổi key ở UC-PRJ-02

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-ISS-11/NT-01 | Issue có sub-task | Sub-task chuyển theo cùng project đích |
| UC-ISS-11/NT-02 | Issue có liên kết tới issue khác trong project nguồn | Giữ nguyên liên kết — liên kết không bị ràng buộc trong một project |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-ISS-11/NL-01 | Project đích không bật loại issue tương ứng | Chặn, yêu cầu bật loại đó trước hoặc chuyển đổi loại |
| UC-ISS-11/NL-02 | Người thực hiện không có quyền ở project đích | Chặn |

### Hậu điều kiện

Issue mang mã mới theo key của project đích; toàn bộ lịch sử (nhật ký thay đổi,
bình luận, dòng hoạt động) vẫn còn nguyên, gắn với issue đó.

### Ảnh hưởng tới đồng bộ

Issue biến mất khỏi sync scope của project nguồn (delta xoá) và xuất hiện ở sync
scope của project đích (delta upsert), vì scope được tổ chức theo project.

---

## UC-ISS-12 — Chuyển đổi giữa Task và Sub-task

**Requirement:** FR-ISS-12
**Actor:** thành viên có quyền sửa issue
**Tiền điều kiện:** không có

### Luồng chính

1. Chuyển một Task thành Sub-task → phải chọn issue cha ngay lúc chuyển
2. Chuyển một Sub-task thành Task → issue mất liên kết cha, trở thành issue độc lập

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-ISS-12/NL-01 | Chuyển Task có sub-task riêng thành Sub-task | Chặn — vi phạm giới hạn ba tầng (UC-ISS-07) |
| UC-ISS-12/NL-02 | Chuyển Task thành Sub-task nhưng không chọn issue cha | Chặn, bắt buộc chọn |

### Hậu điều kiện

Issue mang loại mới (Task hoặc Sub-task), kèm hoặc không kèm liên kết cha đúng
theo hướng chuyển đổi.

### Ảnh hưởng tới đồng bộ

Đổi loại và liên kết cha là các trường của issue nên đi theo delta chung của
UC-ISS-03.

---

## UC-ISS-13 — Xem dạng bảng với cột cấu hình được

**Requirement:** FR-ISS-13
**Actor:** thành viên có quyền xem project
**Tiền điều kiện:** không có

### Luồng chính

1. Mở danh sách issue dạng bảng
2. Chọn cột hiển thị trong số các trường hệ thống
3. Sắp xếp và cuộn; danh sách lớn dùng ảo hoá để cuộn mượt

### Hậu điều kiện

Cột hiển thị đã chọn được ghi nhớ cho lần mở sau; không có dữ liệu nghiệp vụ
nào thay đổi.

### Ảnh hưởng tới đồng bộ

Bảng đọc trực tiếp từ store cục bộ theo sync scope của project — không cần
request riêng, kể cả khi offline.

---

## UC-ISS-14 — Nhật ký thay đổi đầy đủ

**Requirement:** FR-ISS-14
**Actor:** hệ thống (chạy trên mọi thay đổi trường)
**Tiền điều kiện:** không có

### Luồng chính

1. Mỗi lần một trường của issue đổi giá trị, hệ thống ghi một dòng nhật ký: ai,
   lúc nào, trường nào, từ giá trị gì sang giá trị gì
2. Dòng nhật ký hiển thị trong dòng hoạt động của issue (xem
   [uc-06-collaboration](uc-06-collaboration.md))

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-ISS-14/NT-01 | Thay đổi hàng loạt nhiều trường trong một request | Ghi một dòng nhật ký cho **mỗi trường** đổi, không gộp thành một dòng mơ hồ |
| UC-ISS-14/NT-02 | Giá trị cũ hoặc mới là một tham chiếu (người, component) đã bị xoá sau đó | Nhật ký vẫn giữ nguyên giá trị tại thời điểm đổi, không suy diễn lại |

### Hậu điều kiện

Một bản ghi nhật ký thay đổi tồn tại cho mỗi trường đã đổi giá trị, độc lập với
các bản ghi khác trong cùng request.

### Ảnh hưởng tới đồng bộ

Nhật ký thay đổi thuộc scope project của issue; hiển thị trong dòng hoạt động
đi theo cùng delta của thay đổi trường ở UC-ISS-03.

---

## UC-ISS-15 — Tầng phân giải trường

**Actor:** hệ thống (contract nội bộ, không có giao diện riêng ở phase này)
**Tiền điều kiện:** không có

> Đây là **hợp đồng phải chốt trong Phase 3**, để Phase 6 (custom field) cắm
> trường tuỳ biến vào đúng cơ chế đọc, ghi, kiểm tra hợp lệ và ghi nhật ký thay
> đổi này, thay vì phải viết lại toàn bộ tầng trường. Phase này **không** thiết
> kế kiểu trường tuỳ biến cụ thể — đó là phạm vi của
> [KJ-FLD](../README.md) ở Phase 6.

### Luồng chính

1. Trường hệ thống (tiêu đề, mô tả, độ ưu tiên, người được gán…) được đọc/ghi
   qua cùng một tầng phân giải trường, không hard-code riêng từng trường trong
   tầng đọc/ghi/validate/audit
2. Để kiểm chứng tầng này đủ tổng quát, phase này viết thử **một trường "giả tuỳ
   biến"** đi qua đúng tầng này

### Hậu điều kiện

Khi Phase 6 bắt đầu, thêm một kiểu trường mới là cắm vào tầng phân giải trường,
không sửa lại issue module.

### Ảnh hưởng tới đồng bộ

Không áp dụng — đây là một hợp đồng nội bộ giữa tầng đọc/ghi và issue module,
không phải một luồng người dùng phát delta.

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-ISS-01 | Mã issue được tính từ key của project, không lưu sẵn dạng chuỗi trong issue |
| QT-ISS-02 | Sinh số issue tiếp theo phải tuần tự hoá đúng khi tạo đồng thời; **không trùng**, gap chấp nhận được |
| QT-ISS-03 | Phân cấp giới hạn đúng ba tầng: Epic → Story/Task/Bug → Sub-task, không có vòng lặp |
| QT-ISS-04 | Xoá issue cha không xoá issue con, chỉ mất liên kết cha |
| QT-ISS-05 | Loại liên kết luôn có tên cho cả hai chiều |
| QT-ISS-06 | Thứ hạng dùng chuỗi cho phép chèn vô hạn; đổi thứ hạng chỉ phát delta cho issue vừa đổi |
| QT-ISS-07 | Chuyển project giữ nguyên toàn bộ lịch sử; mã cũ vẫn truy cập được |
| QT-ISS-08 | Mọi trường — hệ thống lẫn tuỳ biến sau này — đi qua cùng một tầng phân giải trường |
| QT-ISS-09 | Mỗi lần đổi giá trị một trường sinh đúng một dòng nhật ký thay đổi |

## Yêu cầu phi chức năng liên quan

`NFR-01` optimistic mutation · `NFR-06` board/backlog cuộn mượt với hàng nghìn
issue, cần ảo hoá · `NFR-11` bảng chỉ ghi thêm (nhật ký thay đổi) cần partition ·
`NFR-32` biên giới module được kiểm tra tự động
