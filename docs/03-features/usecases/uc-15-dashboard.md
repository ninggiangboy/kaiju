# UC-DSH — Dashboard & Report

Tổng hợp và theo dõi trên một màn hình. Dashboard không có nguồn dữ liệu riêng
— mỗi gadget **truy vấn lại** đúng dữ liệu module sở hữu nó (issue qua tầng
truy vấn của [uc-09-search.md](uc-09-search.md), time qua
[uc-13-time.md](uc-13-time.md), hoạt động qua
[uc-06-collaboration.md — UC-COL-05](uc-06-collaboration.md#uc-col-05--dòng-hoạt-động))
theo **quyền của người đang xem**, không theo quyền của người tạo dashboard.

**Phase:** 13 · **Feature:** KJ-DSH-01 → KJ-DSH-07
**Liên quan:** [uc-09-search.md](uc-09-search.md) · [uc-06-collaboration.md](uc-06-collaboration.md) · [uc-13-time.md](uc-13-time.md) · [backend-modules.md](../../04-system-design/backend-modules.md) · [roadmap.md — Phase 13](../roadmap.md)

---

## UC-DSH-01 — Tạo dashboard với bố cục kéo thả

**Requirement:** FR-DSH-01
**Actor:** thành viên
**Tiền điều kiện:** không có

### Luồng chính

1. Tạo dashboard mới, đặt tên
2. Kéo thả để thêm, xoá, đổi kích thước và sắp xếp lại gadget trên lưới bố cục
3. Bố cục lưu theo từng dashboard, không theo từng người xem — mọi người xem
   cùng một dashboard thấy cùng bố cục

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-DSH-01/NT-01 | Kéo hai gadget chồng lên nhau | Gadget bị đẩy tự động sang vị trí trống gần nhất, không cho chồng |
| UC-DSH-01/NT-02 | Hai người sửa bố cục cùng một dashboard gần như đồng thời | Ghi sau thắng ở mức toàn bộ bố cục (không hợp nhất từng gadget) — vì bố cục thuộc về dashboard, không theo người xem (QT-DSH-01); người sửa sau có thể vô tình ghi đè thay đổi của người trước, chấp nhận được vì đây là tài liệu dùng chung, không phải dữ liệu nghiệp vụ có tranh chấp quyền sở hữu |
| UC-DSH-01/NT-03 | Sửa bố cục khi mất kết nối | Vào hàng đợi bền cục bộ, áp dụng lạc quan trên giao diện; đồng bộ lại khi có kết nối |

### Hậu điều kiện

Dashboard tồn tại, thuộc về người tạo, chưa chia sẻ cho ai khác — chia sẻ là
việc của UC-DSH-02.

### Ảnh hưởng tới đồng bộ

Dashboard và bố cục là dữ liệu có thực (khác với nội dung gadget, luôn truy vấn
lại — QT-DSH-03), nằm trong sync scope nơi nó được tạo: `proj:{projectId}` nếu
tạo trong ngữ cảnh project, `ws:{workspaceId}` nếu tạo ở cấp workspace. Tạo/sửa
bố cục phát delta cho scope đó.

---

## UC-DSH-02 — Chia sẻ và đặt dashboard mặc định

**Requirement:** FR-DSH-02
**Actor:** người tạo dashboard, hoặc thành viên có quyền quản trị workspace cho dashboard dùng chung cấp workspace
**Tiền điều kiện:** dashboard cần chia sẻ đã tồn tại (UC-DSH-01)

### Luồng chính

1. Chia sẻ dashboard: riêng tư, chia sẻ với một project, hoặc chia sẻ với toàn
   workspace — cùng ba mức chia sẻ đã dùng cho bộ lọc ở
   [uc-09-search.md — UC-SRC-08](uc-09-search.md#uc-src-08--lưu-và-chia-sẻ-bộ-lọc)
2. Đặt một dashboard đã chia sẻ làm mặc định cho toàn workspace hoặc cho một
   project — người vào lần đầu thấy ngay dashboard đó

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-DSH-02/NT-01 | Người tạo dashboard rời workspace | Dashboard đã chia sẻ vẫn tồn tại, người khác vẫn xem được; dashboard riêng tư không ai khác thấy được — cùng cách UC-SRC-08 xử lý bộ lọc khi người tạo rời project |
| UC-DSH-02/NT-02 | Thu hẹp mức chia sẻ (ví dụ từ toàn workspace về riêng tư) | Phát sự kiện thu hồi cho scope chứa dashboard đó; client của những người không còn xem được xoá dashboard khỏi dữ liệu cục bộ ngay, kể cả khi họ đang mở nó |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-DSH-02/NL-01 | Xoá dashboard đang được đặt làm mặc định | Chặn, yêu cầu đặt dashboard khác làm mặc định trước hoặc bỏ đặt mặc định |
| UC-DSH-02/NL-02 | Không phải người tạo, và không có quyền quản trị workspace cho dashboard cấp workspace | Không hiển thị chức năng chia sẻ/đặt mặc định |

### Hậu điều kiện

Dashboard có đúng một mức chia sẻ hiện hành; nếu được đặt mặc định, đó là
dashboard mặc định duy nhất của phạm vi đó (workspace hoặc project).

### Ảnh hưởng tới đồng bộ

Đổi mức chia sẻ hoặc đặt mặc định phát một delta cho dashboard trong scope chứa
nó (xem UC-DSH-01); client cập nhật ngay danh sách dashboard nhìn thấy được và
dashboard mặc định hiển thị khi vào lần đầu. Khi mức chia sẻ bị thu hẹp
(NT-02), đây là trường hợp thu hồi quyền theo invariant 20: người không còn
xem được nhận sự kiện thu hồi thay vì delta xoá thông thường.

---

## UC-DSH-03 — Gadget dựa trên bộ lọc

**Requirement:** FR-DSH-03, FR-DSH-04
**Actor:** thành viên có quyền chỉnh sửa dashboard
**Tiền điều kiện:** dashboard đích đã tồn tại (UC-DSH-01)

### Luồng chính

1. Thêm gadget hiển thị danh sách issue theo một bộ lọc đã lưu (UC-SRC-08),
   dạng bảng rút gọn
2. Gadget chạy lại truy vấn của bộ lọc mỗi lần dashboard tải hoặc tự làm mới —
   không giữ bản sao tĩnh, cùng nguyên tắc UC-BRD-01 áp dụng cho board

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-DSH-03/NL-01 | Bộ lọc nguồn của gadget bị xoá | Gadget hiện thông báo "bộ lọc nguồn không còn tồn tại" thay vì lỗi hoặc ẩn; **không chặn xoá bộ lọc** như board (UC-BRD-01) — dashboard chỉ tham chiếu lỏng, không giữ ràng buộc cứng như board |
| UC-DSH-03/NL-02 | Người xem không có quyền xem bộ lọc nguồn (bộ lọc riêng tư của người khác) | Gadget hiện thông báo không có quyền xem, không hiện dữ liệu |
| UC-DSH-03/NL-03 | Không có quyền chỉnh sửa dashboard | Không hiển thị chức năng thêm/sửa gadget, chỉ xem |

### Hậu điều kiện

Gadget tồn tại trên dashboard, tham chiếu tới bộ lọc nguồn bằng id — không sao
chép điều kiện lọc vào gadget.

### Ảnh hưởng tới đồng bộ

Cấu hình gadget (tham chiếu bộ lọc, vị trí trên lưới) là dữ liệu có thực, đi
theo delta của dashboard chứa nó (UC-DSH-01). Kết quả truy vấn hiển thị trong
gadget không lưu và không phát delta — luôn dựng lại theo QT-DSH-03.

---

## UC-DSH-04 — Gadget biểu đồ và thống kê

**Requirement:** FR-DSH-03, FR-DSH-04
**Actor:** thành viên có quyền chỉnh sửa dashboard
**Tiền điều kiện:** dashboard đích đã tồn tại (UC-DSH-01)

### Luồng chính

1. Thêm gadget biểu đồ (cột, tròn, đường) hoặc số liệu đơn (đếm issue, tổng
   story point, tổng thời gian đã dùng…), nguồn dữ liệu là một bộ lọc đã lưu
   hoặc một báo cáo dựng sẵn (UC-DSH-07)
2. Cấu hình trục/nhóm theo một trường (trạng thái, người được gán, trường tuỳ
   biến…), dùng lại danh sách trường có thể truy vấn từ UC-SRC-04

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-DSH-04/NL-01 | Trường dùng để nhóm bị xoá sau khi gadget đã cấu hình | Gadget hiện thông báo lỗi cấu hình, không hiển thị biểu đồ sai lệch |

### Hậu điều kiện

Gadget biểu đồ tồn tại trên dashboard với cấu hình nguồn dữ liệu và trục/nhóm
đã chọn.

### Ảnh hưởng tới đồng bộ

Cấu hình gadget đi theo delta của dashboard chứa nó (UC-DSH-01), cùng cơ chế
với UC-DSH-03. Dữ liệu biểu đồ hiển thị không lưu, luôn dựng lại khi tải.

---

## UC-DSH-05 — Gadget dòng hoạt động và ghi chú

**Requirement:** FR-DSH-03, FR-DSH-04
**Actor:** thành viên có quyền chỉnh sửa dashboard
**Tiền điều kiện:** dashboard đích đã tồn tại (UC-DSH-01)

### Luồng chính

1. Thêm gadget hiển thị dòng hoạt động gộp và lọc được (UC-COL-05), giới hạn
   theo project hoặc theo bộ lọc đã chọn cho gadget
2. Thêm gadget ghi chú văn bản tự do, không gắn với dữ liệu nghiệp vụ nào —
   dùng để chú thích cho dashboard

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-DSH-05/NL-01 | Gadget dòng hoạt động giới hạn theo project mà người xem không còn quyền xem | Gadget hiện thông báo không có quyền xem, không hiện dữ liệu hoạt động cũ |

### Hậu điều kiện

Gadget dòng hoạt động hoặc gadget ghi chú tồn tại trên dashboard. Nội dung ghi
chú là dữ liệu thực, khác với các gadget khác chỉ tham chiếu dữ liệu nơi khác.

### Ảnh hưởng tới đồng bộ

Cấu hình gadget dòng hoạt động đi theo delta của dashboard (UC-DSH-01), không
lưu lại nội dung dòng hoạt động. Nội dung gadget ghi chú **là** dữ liệu thực nên
cũng phát delta riêng khi sửa, cùng scope với dashboard chứa nó.

---

## UC-DSH-06 — Phân quyền theo người xem trên mọi gadget

**Actor:** hệ thống (không có giao diện riêng — áp dụng cho mọi gadget của UC-DSH-03..05, UC-DSH-07)
**Tiền điều kiện:** không có

### Luồng chính

1. Mỗi lần một gadget tải hoặc làm mới dữ liệu, truy vấn của nó đi qua đúng
   tầng ghép điều kiện phân quyền đã có ở
   [uc-09-search.md — UC-SRC-05](uc-09-search.md#uc-src-05--ghép-điều-kiện-phân-quyền-vào-truy-vấn):
   điều kiện phân quyền ghép **vào lúc dựng truy vấn**, theo quyền của **người
   đang xem dashboard**, không theo quyền của người tạo dashboard hay người
   cấu hình gadget
2. Dashboard không có một tầng phân quyền riêng của module `dashboard` — nó
   không tự đọc bảng của `issue`, `time`, `activity`; mỗi gadget gọi qua API
   công khai hoặc tầng truy vấn đã kiểm soát quyền của module sở hữu dữ liệu
   đó, đúng luật biên giới module (không tự nối chuỗi truy vấn bỏ qua tầng đó)

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-DSH-06/NT-01 | Dashboard chia sẻ cho người có quyền thấp hơn người tạo | Gadget chỉ hiện phần dữ liệu người xem có quyền, không hiện toàn bộ dữ liệu người tạo từng thấy khi cấu hình — đây là Definition of Done của cả phase |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-DSH-06/NL-01 | Người xem không có quyền xem bất kỳ phần nào của một gadget | Gadget hiện thông báo không có quyền xem thay vì gadget rỗng gây hiểu nhầm là không có dữ liệu |

### Hậu điều kiện

Không có gadget nào trên bất kỳ dashboard nào hiển thị dữ liệu vượt quá quyền
của người đang xem, bất kể ai tạo hay cấu hình dashboard đó.

### Ảnh hưởng tới đồng bộ

Không áp dụng — đây là quy tắc áp cho tầng truy vấn khi gadget tải hoặc làm
mới, không phải một thao tác ghi phát delta.

---

## UC-DSH-07 — Các báo cáo dựng sẵn

**Requirement:** FR-DSH-05
**Actor:** thành viên có quyền xem project
**Tiền điều kiện:** không có

### Luồng chính

1. Xem các báo cáo dựng sẵn cấp project: báo cáo sprint và epic
   ([uc-11-sprint.md — UC-SPR-09](uc-11-sprint.md#uc-spr-09--báo-cáo-sprint-và-báo-cáo-epic)),
   báo cáo thời gian
   ([uc-13-time.md — UC-TIM-06](uc-13-time.md#uc-tim-06--báo-cáo-thời-gian-theo-nhiều-chiều)),
   báo cáo release
   ([uc-14-version.md — UC-VER-03](uc-14-version.md#uc-ver-03--trang-release-với-tiến-độ))
2. Các báo cáo này không phải nội dung mới của phase — UC-DSH-07 là việc gom
   chúng vào một danh mục điều hướng chung, và cho phép ghim một báo cáo dựng
   sẵn làm gadget (UC-DSH-04) lên dashboard

### Hậu điều kiện

Không có báo cáo dựng sẵn nào tính toán lại logic đã có ở use case gốc của nó
— UC-DSH-07 chỉ điều hướng và ghim, không sao chép cách tính.

### Ảnh hưởng tới đồng bộ

Ghim một báo cáo dựng sẵn lên dashboard tạo ra một gadget — đi theo đúng cơ chế
đồng bộ đã mô tả ở UC-DSH-04, không có delta riêng cho UC-DSH-07.

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-DSH-01 | Bố cục dashboard thuộc về dashboard, không thuộc về từng người xem |
| QT-DSH-02 | Không xoá được dashboard đang được đặt làm mặc định |
| QT-DSH-03 | Gadget không giữ bản sao tĩnh dữ liệu — luôn truy vấn lại khi tải hoặc làm mới |
| QT-DSH-04 | Bộ lọc nguồn của gadget bị xoá thì gadget báo lỗi rõ, không chặn việc xoá bộ lọc như board |
| QT-DSH-05 | Mọi gadget đọc dữ liệu qua API công khai hoặc tầng truy vấn đã kiểm soát quyền của module sở hữu, không tự đọc bảng module khác |
| QT-DSH-06 | Điều kiện phân quyền của gadget ghép theo quyền của người đang xem, không theo quyền của người tạo hay người cấu hình dashboard |
| QT-DSH-07 | Báo cáo dựng sẵn không sao chép lại logic tính toán đã có ở use case gốc, chỉ điều hướng và ghim |

## Yêu cầu phi chức năng liên quan

`NFR-07` mọi gadget phải ghép điều kiện phân quyền ở tầng truy vấn, không lọc
sau · `NFR-20` không rò rỉ dữ liệu ngoài quyền xem của người đang xem, kể cả
khi dashboard được chia sẻ cho người có quyền thấp hơn người tạo · `NFR-11`
dashboard nhiều gadget vẫn tải được mà không chậm
