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

**Actor:** thành viên
**Tiền điều kiện:** không có

### Luồng chính

1. Tạo dashboard mới, đặt tên
2. Kéo thả để thêm, xoá, đổi kích thước và sắp xếp lại gadget trên lưới bố cục
3. Bố cục lưu theo từng dashboard, không theo từng người xem — mọi người xem
   cùng một dashboard thấy cùng bố cục

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Kéo hai gadget chồng lên nhau | Gadget bị đẩy tự động sang vị trí trống gần nhất, không cho chồng |

### Hậu điều kiện

Dashboard tồn tại, thuộc về người tạo, chưa chia sẻ cho ai khác — chia sẻ là
việc của UC-DSH-02.

---

## UC-DSH-02 — Chia sẻ và đặt dashboard mặc định

**Actor:** người tạo dashboard, hoặc thành viên có quyền quản trị workspace cho dashboard dùng chung cấp workspace

### Luồng chính

1. Chia sẻ dashboard: riêng tư, chia sẻ với một project, hoặc chia sẻ với toàn
   workspace — cùng ba mức chia sẻ đã dùng cho bộ lọc ở
   [uc-09-search.md — UC-SRC-08](uc-09-search.md#uc-src-08--lưu-và-chia-sẻ-bộ-lọc)
2. Đặt một dashboard đã chia sẻ làm mặc định cho toàn workspace hoặc cho một
   project — người vào lần đầu thấy ngay dashboard đó

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Người tạo dashboard rời workspace | Dashboard đã chia sẻ vẫn tồn tại, người khác vẫn xem được; dashboard riêng tư không ai khác thấy được — cùng cách UC-SRC-08 xử lý bộ lọc khi người tạo rời project |
| Xoá dashboard đang được đặt làm mặc định | Chặn, yêu cầu đặt dashboard khác làm mặc định trước hoặc bỏ đặt mặc định |

---

## UC-DSH-03 — Gadget dựa trên bộ lọc

**Actor:** thành viên có quyền chỉnh sửa dashboard

### Luồng chính

1. Thêm gadget hiển thị danh sách issue theo một bộ lọc đã lưu (UC-SRC-08),
   dạng bảng rút gọn
2. Gadget chạy lại truy vấn của bộ lọc mỗi lần dashboard tải hoặc tự làm mới —
   không giữ bản sao tĩnh, cùng nguyên tắc UC-BRD-01 áp dụng cho board

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Bộ lọc nguồn của gadget bị xoá | Gadget hiện thông báo "bộ lọc nguồn không còn tồn tại" thay vì lỗi hoặc ẩn; **không chặn xoá bộ lọc** như board (UC-BRD-01) — dashboard chỉ tham chiếu lỏng, không giữ ràng buộc cứng như board |
| Người xem không có quyền xem bộ lọc nguồn (bộ lọc riêng tư của người khác) | Gadget hiện thông báo không có quyền xem, không hiện dữ liệu |

---

## UC-DSH-04 — Gadget biểu đồ và thống kê

**Actor:** thành viên có quyền chỉnh sửa dashboard

### Luồng chính

1. Thêm gadget biểu đồ (cột, tròn, đường) hoặc số liệu đơn (đếm issue, tổng
   story point, tổng thời gian đã dùng…), nguồn dữ liệu là một bộ lọc đã lưu
   hoặc một báo cáo dựng sẵn (UC-DSH-07)
2. Cấu hình trục/nhóm theo một trường (trạng thái, người được gán, trường tuỳ
   biến…), dùng lại danh sách trường có thể truy vấn từ UC-SRC-04

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Trường dùng để nhóm bị xoá sau khi gadget đã cấu hình | Gadget hiện thông báo lỗi cấu hình, không hiển thị biểu đồ sai lệch |

---

## UC-DSH-05 — Gadget dòng hoạt động và ghi chú

**Actor:** thành viên có quyền chỉnh sửa dashboard

### Luồng chính

1. Thêm gadget hiển thị dòng hoạt động gộp và lọc được (UC-COL-05), giới hạn
   theo project hoặc theo bộ lọc đã chọn cho gadget
2. Thêm gadget ghi chú văn bản tự do, không gắn với dữ liệu nghiệp vụ nào —
   dùng để chú thích cho dashboard

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Gadget dòng hoạt động giới hạn theo project mà người xem không còn quyền xem | Gadget hiện thông báo không có quyền xem, không hiện dữ liệu hoạt động cũ |

---

## UC-DSH-06 — Phân quyền theo người xem trên mọi gadget

**Actor:** hệ thống (không có giao diện riêng — áp dụng cho mọi gadget của UC-DSH-03..05, UC-DSH-07)

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

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Dashboard chia sẻ cho người có quyền thấp hơn người tạo | Gadget chỉ hiện phần dữ liệu người xem có quyền, không hiện toàn bộ dữ liệu người tạo từng thấy khi cấu hình — đây là Definition of Done của cả phase |
| Người xem không có quyền xem bất kỳ phần nào của một gadget | Gadget hiện thông báo không có quyền xem thay vì gadget rỗng gây hiểu nhầm là không có dữ liệu |

### Hậu điều kiện

Không có gadget nào trên bất kỳ dashboard nào hiển thị dữ liệu vượt quá quyền
của người đang xem, bất kể ai tạo hay cấu hình dashboard đó.

---

## UC-DSH-07 — Các báo cáo dựng sẵn

**Actor:** thành viên có quyền xem project

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

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-01 | Bố cục dashboard thuộc về dashboard, không thuộc về từng người xem |
| QT-02 | Không xoá được dashboard đang được đặt làm mặc định |
| QT-03 | Gadget không giữ bản sao tĩnh dữ liệu — luôn truy vấn lại khi tải hoặc làm mới |
| QT-04 | Bộ lọc nguồn của gadget bị xoá thì gadget báo lỗi rõ, không chặn việc xoá bộ lọc như board |
| QT-05 | Mọi gadget đọc dữ liệu qua API công khai hoặc tầng truy vấn đã kiểm soát quyền của module sở hữu, không tự đọc bảng module khác |
| QT-06 | Điều kiện phân quyền của gadget ghép theo quyền của người đang xem, không theo quyền của người tạo hay người cấu hình dashboard |
| QT-07 | Báo cáo dựng sẵn không sao chép lại logic tính toán đã có ở use case gốc, chỉ điều hướng và ghim |

## Yêu cầu phi chức năng liên quan

`NFR-07` mọi gadget phải ghép điều kiện phân quyền ở tầng truy vấn, không lọc
sau · `NFR-20` không rò rỉ dữ liệu ngoài quyền xem của người đang xem, kể cả
khi dashboard được chia sẻ cho người có quyền thấp hơn người tạo · `NFR-11`
dashboard nhiều gadget vẫn tải được mà không chậm
