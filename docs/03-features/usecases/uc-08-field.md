# UC-FLD — Custom field & Screen

Người dùng tự định nghĩa trường và bố trí màn hình. Toàn bộ phase này là bài
kiểm tra cho **tầng phân giải trường** đã chốt ở Phase 3 (UC-ISS-15,
KJ-ISS-16): nếu tầng đó đủ tổng quát thì mọi use case dưới đây chỉ là cắm thêm
cấu hình, không sửa lại module `issue`.

**Phase:** 6 · **Feature:** KJ-FLD-01 → KJ-FLD-08
**Liên quan:** [uc-05-issue.md](uc-05-issue.md) · [backend-modules.md](../../04-system-design/backend-modules.md) · [data-access-and-tenancy.md](../../04-system-design/data-access-and-tenancy.md) · [roadmap.md — Phase 6](../roadmap.md)

---

## UC-FLD-01 — Đầy đủ các kiểu trường

**Actor:** thành viên có quyền quản trị workspace
**Tiền điều kiện:** không có

### Luồng chính

1. Tạo trường tuỳ biến mới: đặt tên, chọn một trong các kiểu — văn bản ngắn,
   văn bản dài, số, ngày, ngày giờ, chọn một, chọn nhiều, hộp kiểm, nút chọn,
   chọn người, chọn nhiều người, nhãn, URL, chọn phân cấp
2. Trường được cắm vào **cùng tầng phân giải trường** mà trường hệ thống dùng
   (UC-ISS-15) — đọc, ghi, kiểm tra hợp lệ, ghi nhật ký thay đổi đi qua một
   cơ chế duy nhất, không viết riêng đường xử lý cho từng kiểu trường ở tầng
   issue
3. Trường tồn tại ở cấp workspace, dùng lại được giữa nhiều project

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Tên trường trùng tên trường hệ thống hoặc trường tuỳ biến khác trong cùng workspace | Từ chối, gợi ý tên khác |
| Kiểu trường không nằm trong danh sách hỗ trợ | Không hiển thị trong lựa chọn — danh sách kiểu là đóng, không do người dùng tự định nghĩa kiểu mới |

### Hậu điều kiện

Trường tồn tại nhưng **chưa gắn vào bất kỳ project hoặc loại issue nào** — gắn
là việc của UC-FLD-02.

---

## UC-FLD-02 — Cấu hình trường theo ngữ cảnh project và loại issue

**Actor:** thành viên có quyền quản trị project

### Luồng chính

1. Gắn một trường tuỳ biến vào một hoặc nhiều project
2. Trong mỗi project, chọn tiếp loại issue nào dùng trường này (Epic, Story,
   Task, Sub-task, Bug)
3. Cùng một trường có thể có cấu hình khác nhau ở hai project khác nhau —
   cấu hình (bắt buộc, giá trị mặc định, tuỳ chọn cho phép) gắn theo **cặp
   (project, loại issue)**, không gắn theo trường

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Gỡ trường khỏi một loại issue đang có issue chứa dữ liệu ở trường đó | Cho phép — dữ liệu cũ vẫn còn, chỉ không hiển thị và không sửa được nữa qua giao diện thường; xử lý dữ liệu theo UC-FLD-06 |
| Cùng một trường được gắn vào hai project với hai bộ tuỳ chọn khác nhau (trường chọn một/chọn nhiều) | Cho phép — danh sách tuỳ chọn cũng thuộc cấu hình theo (project, loại issue), không dùng chung |

---

## UC-FLD-03 — Bắt buộc, quy tắc hợp lệ, giá trị mặc định

**Actor:** thành viên có quyền quản trị project

### Luồng chính

1. Với mỗi cặp (project, loại issue) đã gắn trường, đặt: bắt buộc hay không,
   giá trị mặc định, văn bản hướng dẫn
2. Với các kiểu có thể ràng buộc thêm (số, ngày, văn bản), đặt quy tắc hợp lệ
   (khoảng giá trị, độ dài, định dạng)
3. Khi tạo hoặc sửa issue, hệ thống kiểm tra các quy tắc này qua tầng phân
   giải trường — cùng cơ chế kiểm tra hợp lệ trường hệ thống đã dùng

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Đặt bắt buộc cho một trường đang có issue để trống ở trường đó | Cho phép đặt — không hồi tố bắt buộc lên issue cũ, chỉ áp dụng từ lần sửa tiếp theo |
| Giá trị mặc định không thoả chính quy tắc hợp lệ vừa đặt (ví dụ mặc định ngoài khoảng số cho phép) | Từ chối lưu cấu hình, báo lỗi tại chỗ |

---

## UC-FLD-04 — Màn hình và screen scheme cho ba thao tác

**Actor:** thành viên có quyền quản trị project

### Luồng chính

1. Tạo màn hình (screen): một tập hợp trường sẽ hiển thị
2. Tạo screen scheme: ánh xạ một màn hình riêng cho từng thao tác trong ba
   thao tác — tạo, sửa, xem — có thể dùng chung một màn hình cho cả ba hoặc
   tách riêng
3. Gán scheme cho một loại issue trong một project

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Một trường bắt buộc (UC-FLD-03) không có mặt trong màn hình tạo | Cảnh báo khi lưu screen — issue sẽ không thể tạo được vì không có chỗ nhập trường bắt buộc |
| Sửa scheme đang được nhiều project dùng | Cảnh báo kèm danh sách project bị ảnh hưởng, cùng cách xử lý ở UC-PRJ-07 và UC-WKF-06 |

---

## UC-FLD-05 — Sắp xếp trường và chia tab

**Actor:** thành viên có quyền quản trị project

### Luồng chính

1. Trong một màn hình, kéo thả để đổi thứ tự hiển thị các trường
2. Nhóm các trường vào tab, đặt tên tab, đổi thứ tự tab

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Xoá một tab đang chứa trường | Yêu cầu chuyển các trường sang tab khác trước, hoặc chuyển hết về tab mặc định |

---

## UC-FLD-06 — Xử lý dữ liệu khi xoá hoặc đổi trường

**Actor:** thành viên có quyền quản trị workspace

### Luồng chính

1. Xoá một trường tuỳ biến khỏi workspace
2. Hệ thống cảnh báo số issue đang có dữ liệu ở trường này, trên những project nào
3. Xác nhận → trường chuyển sang xoá mềm, dữ liệu cũ trong issue **vẫn còn**
   nhưng không hiển thị, không sửa được, không tính vào bộ lọc/báo cáo nữa
4. Đổi kiểu một trường đã có dữ liệu → **không hỗ trợ trực tiếp**; phải tạo
   trường mới rồi tự chuyển dữ liệu, vì không có phép chuyển đổi an toàn cho
   mọi cặp kiểu (ví dụ số → chọn một)

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Khôi phục một trường vừa xoá mềm trong thời hạn ân hạn | Trường và mọi cấu hình (project, loại issue, màn hình) trở lại như trước khi xoá |
| Hết thời hạn ân hạn | Tác vụ định kỳ xoá vĩnh viễn dữ liệu của trường ở mọi issue |

### Hậu điều kiện

Không có issue nào bị hỏng bởi việc xoá hoặc đổi trường — đây là Definition of
Done của phase.

---

## UC-FLD-07 — Trường tuỳ biến vào nhật ký thay đổi và delta

**Actor:** hệ thống (không có giao diện riêng — hệ quả của UC-FLD-01 đến UC-FLD-03)

### Luồng chính

1. Mỗi lần giá trị một trường tuỳ biến đổi, tầng phân giải trường sinh **đúng
   một dòng nhật ký thay đổi**, giống hệt cách trường hệ thống sinh ở UC-ISS-14
2. Thay đổi trường tuỳ biến xuất hiện trong delta đồng bộ của scope project,
   cùng cơ chế delta của trường hệ thống — client không cần biết một trường là
   hệ thống hay tuỳ biến để hiển thị nhật ký hoặc để cập nhật cache cục bộ

### Hậu điều kiện

Đây chính là bài kiểm tra cho contract đã chốt ở Phase 3: nếu bước này cần
sửa module `issue` hoặc sửa cơ chế nhật ký thay đổi/đồng bộ, tầng phân giải
trường ở Phase 3 chưa đủ tổng quát và phải coi là một lỗi cần vá ngược, không
phải một ngoại lệ chấp nhận được ở đây.

### Ảnh hưởng tới đồng bộ

Không có scope hay cơ chế delta riêng cho trường tuỳ biến — nó dùng nguyên
scope `proj:{projectId}` đã có, chỉ khác payload chứa thêm trường tuỳ biến bên
cạnh trường hệ thống trong cùng một patch.

---

## UC-FLD-08 — Trường tuỳ biến dùng được trong bộ lọc và báo cáo

**Actor:** thành viên có quyền xem project

### Luồng chính

1. Trường tuỳ biến xuất hiện trong danh sách trường có thể lọc, giống trường
   hệ thống
2. Lọc và sắp xếp theo trường tuỳ biến đi qua **jOOQ** — đường đọc động dùng
   cho board, backlog, báo cáo — không qua `JdbcClient` vốn chỉ dành cho đọc
   với cấu trúc cố định

### Hậu điều kiện

Đây là điều kiện tiên quyết cho Phase 7 (Search & Query): ngôn ngữ truy vấn
của Phase 7 truy vấn được trường tuỳ biến chính vì trường tuỳ biến đã đi qua
đường đọc động này từ Phase 6, không phải xây lại ở Phase 7.

> **Chưa chốt:** tài liệu hiện có xác nhận đường đọc (jOOQ) và việc trường
> tuỳ biến phải dùng được trong bộ lọc, nhưng chưa mô tả cách đánh chỉ mục
> cho lọc/sắp xếp trên trường tuỳ biến ở quy mô lớn (ví dụ project hàng chục
> nghìn issue). Đây là quyết định của Phase 7 (ngôn ngữ truy vấn và chỉ mục),
> không phải của phase này.

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-01 | Trường tuỳ biến đi qua đúng tầng phân giải trường mà trường hệ thống dùng — không có đường xử lý riêng trong module `issue` |
| QT-02 | Cấu hình một trường (bắt buộc, mặc định, tuỳ chọn) gắn theo cặp (project, loại issue), không gắn theo trường |
| QT-03 | Đặt bắt buộc cho một trường không hồi tố lên issue đã có trước đó |
| QT-04 | Xoá trường là xoá mềm; dữ liệu cũ trong issue được giữ nguyên nhưng ẩn khỏi hiển thị, bộ lọc và báo cáo |
| QT-05 | Đổi kiểu một trường đã có dữ liệu không được hỗ trợ trực tiếp; phải tạo trường mới |
| QT-06 | Mỗi lần đổi giá trị trường tuỳ biến sinh đúng một dòng nhật ký thay đổi, cùng cơ chế trường hệ thống |
| QT-07 | Trường tuỳ biến dùng chung scope đồng bộ `proj:{projectId}`, không có scope riêng |
| QT-08 | Lọc và sắp xếp theo trường tuỳ biến đi qua jOOQ, không qua `JdbcClient` |

## Yêu cầu phi chức năng liên quan

`NFR-19` thay đổi cấu trúc dữ liệu tương thích ngược trong triển khai cuốn
chiếu · `NFR-01` optimistic mutation cho cấu hình trường và screen · `NFR-07`
lọc theo trường tuỳ biến vẫn phải đẩy điều kiện phân quyền xuống tầng SQL
