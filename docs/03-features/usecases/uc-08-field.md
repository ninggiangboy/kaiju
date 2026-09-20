# UC-FLD — Custom field & Screen

Người dùng tự định nghĩa trường và bố trí màn hình. Toàn bộ phase này là bài
kiểm tra cho **tầng phân giải trường** đã chốt ở Phase 3 (UC-ISS-15,
KJ-ISS-16): nếu tầng đó đủ tổng quát thì mọi use case dưới đây chỉ là cắm thêm
cấu hình, không sửa lại module `issue`.

**Phase:** 6 · **Feature:** KJ-FLD-01 → KJ-FLD-08
**Liên quan:** [uc-05-issue.md](uc-05-issue.md) · [backend-modules.md](../../04-system-design/backend-modules.md) · [data-access-and-tenancy.md](../../04-system-design/data-access-and-tenancy.md) · [roadmap.md — Phase 6](../roadmap.md)

---

## UC-FLD-01 — Đầy đủ các kiểu trường

**Requirement:** FR-FLD-01
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

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-FLD-01/NT-01 | Tạo trường khi mất kết nối | Thao tác vào hàng đợi bền cục bộ, hiện trạng thái "đang chờ đồng bộ"; gửi lại khi có mạng theo cơ chế hàng đợi chung của sync engine |
| UC-FLD-01/NT-02 | Gửi lại yêu cầu tạo trường với cùng khoá chống trùng | Không tạo trường thứ hai — server nhận diện qua idempotency key, trả về đúng trường đã tạo |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-FLD-01/NL-01 | Tên trường trùng tên trường hệ thống hoặc trường tuỳ biến khác trong cùng workspace | Từ chối, gợi ý tên khác |
| UC-FLD-01/NL-02 | Kiểu trường không nằm trong danh sách hỗ trợ | Không hiển thị trong lựa chọn — danh sách kiểu là đóng, không do người dùng tự định nghĩa kiểu mới |
| UC-FLD-01/NL-03 | Không đủ quyền quản trị workspace | Không hiển thị chức năng tạo trường tuỳ biến |

### Hậu điều kiện

Trường tồn tại nhưng **chưa gắn vào bất kỳ project hoặc loại issue nào** — gắn
là việc của UC-FLD-02.

### Ảnh hưởng tới đồng bộ

Định nghĩa trường là cấu hình cấp workspace, phát delta trên scope
`ws:{workspaceId}`.

---

## UC-FLD-02 — Cấu hình trường theo ngữ cảnh project và loại issue

**Requirement:** FR-FLD-02
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** Trường tuỳ biến đã tồn tại ở cấp workspace (UC-FLD-01).

### Luồng chính

1. Gắn một trường tuỳ biến vào một hoặc nhiều project
2. Trong mỗi project, chọn tiếp loại issue nào dùng trường này (Epic, Story,
   Task, Sub-task, Bug)
3. Cùng một trường có thể có cấu hình khác nhau ở hai project khác nhau —
   cấu hình (bắt buộc, giá trị mặc định, tuỳ chọn cho phép) gắn theo **cặp
   (project, loại issue)**, không gắn theo trường

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-FLD-02/NT-01 | Gỡ trường khỏi một loại issue đang có issue chứa dữ liệu ở trường đó | Cho phép — dữ liệu cũ vẫn còn, chỉ không hiển thị và không sửa được nữa qua giao diện thường; xử lý dữ liệu theo UC-FLD-06 |
| UC-FLD-02/NT-02 | Cùng một trường được gắn vào hai project với hai bộ tuỳ chọn khác nhau (trường chọn một/chọn nhiều) | Cho phép — danh sách tuỳ chọn cũng thuộc cấu hình theo (project, loại issue), không dùng chung |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-FLD-02/NL-01 | Không đủ quyền quản trị project | Không hiển thị chức năng gắn trường vào project |

### Hậu điều kiện

Trường xuất hiện (hoặc biến mất) khỏi màn hình tạo/sửa/xem của đúng những
(project, loại issue) vừa cấu hình.

### Ảnh hưởng tới đồng bộ

Cấu hình theo (project, loại issue) phát delta trên scope `proj:{projectId}`
của từng project bị ảnh hưởng.

---

## UC-FLD-03 — Bắt buộc, quy tắc hợp lệ, giá trị mặc định

**Requirement:** FR-FLD-03
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** Trường đã gắn vào cặp (project, loại issue) này (UC-FLD-02).

### Luồng chính

1. Với mỗi cặp (project, loại issue) đã gắn trường, đặt: bắt buộc hay không,
   giá trị mặc định, văn bản hướng dẫn
2. Với các kiểu có thể ràng buộc thêm (số, ngày, văn bản), đặt quy tắc hợp lệ
   (khoảng giá trị, độ dài, định dạng)
3. Khi tạo hoặc sửa issue, hệ thống kiểm tra các quy tắc này qua tầng phân
   giải trường — cùng cơ chế kiểm tra hợp lệ trường hệ thống đã dùng

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-FLD-03/NT-01 | Đặt bắt buộc cho một trường đang có issue để trống ở trường đó | Cho phép đặt — không hồi tố bắt buộc lên issue cũ, chỉ áp dụng từ lần sửa tiếp theo |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-FLD-03/NL-01 | Giá trị mặc định không thoả chính quy tắc hợp lệ vừa đặt (ví dụ mặc định ngoài khoảng số cho phép) | Từ chối lưu cấu hình, báo lỗi tại chỗ |
| UC-FLD-03/NL-02 | Không đủ quyền quản trị project | Không hiển thị chức năng này |

### Hậu điều kiện

Cấu hình bắt buộc/mặc định/quy tắc hợp lệ áp dụng cho các issue tạo hoặc sửa
**từ thời điểm này trở đi**.

### Ảnh hưởng tới đồng bộ

Cấu hình phát delta trên scope `proj:{projectId}`.

---

## UC-FLD-04 — Màn hình và screen scheme cho ba thao tác

**Requirement:** FR-FLD-04
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** Không có — screen scheme tạo độc lập, gắn trường vào màn
hình có thể làm sau.

### Luồng chính

1. Tạo màn hình (screen): một tập hợp trường sẽ hiển thị
2. Tạo screen scheme: ánh xạ một màn hình riêng cho từng thao tác trong ba
   thao tác — tạo, sửa, xem — có thể dùng chung một màn hình cho cả ba hoặc
   tách riêng
3. Gán scheme cho một loại issue trong một project

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-FLD-04/NT-01 | Một trường bắt buộc (UC-FLD-03) không có mặt trong màn hình tạo | Cảnh báo khi lưu screen — issue sẽ không thể tạo được vì không có chỗ nhập trường bắt buộc |
| UC-FLD-04/NT-02 | Sửa scheme đang được nhiều project dùng | Cảnh báo kèm danh sách project bị ảnh hưởng, cùng cách xử lý ở UC-PRJ-07 và UC-WKF-06 |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-FLD-04/NL-01 | Không đủ quyền quản trị project | Không hiển thị chức năng cấu hình màn hình/scheme |

### Hậu điều kiện

Loại issue trong project dùng đúng màn hình theo scheme vừa gán, cho cả ba
thao tác tạo/sửa/xem.

### Ảnh hưởng tới đồng bộ

Screen scheme là cấu hình cấp project, phát delta trên scope `proj:{projectId}`
của từng project bị ảnh hưởng.

---

## UC-FLD-05 — Sắp xếp trường và chia tab

**Requirement:** FR-FLD-05
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** Màn hình đã tồn tại (UC-FLD-04).

### Luồng chính

1. Trong một màn hình, kéo thả để đổi thứ tự hiển thị các trường
2. Nhóm các trường vào tab, đặt tên tab, đổi thứ tự tab

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-FLD-05/NT-01 | Hai quản trị viên sắp xếp trường/tab trên cùng màn hình gần như đồng thời | Ghi sau thắng ở mức cấu hình màn hình, cùng nguyên tắc ghi sau thắng chung của sync engine — không khoá độc quyền màn hình |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-FLD-05/NL-01 | Xoá một tab đang chứa trường | Yêu cầu chuyển các trường sang tab khác trước, hoặc chuyển hết về tab mặc định |
| UC-FLD-05/NL-02 | Không đủ quyền quản trị project | Không hiển thị chức năng sắp xếp trường/tab |

### Hậu điều kiện

Thứ tự trường và bố cục tab trên màn hình phản ánh đúng thay đổi vừa lưu.

### Ảnh hưởng tới đồng bộ

Bố cục màn hình phát delta trên scope `proj:{projectId}`.

---

## UC-FLD-06 — Xử lý dữ liệu khi xoá hoặc đổi trường

**Requirement:** FR-FLD-06
**Actor:** thành viên có quyền quản trị workspace
**Tiền điều kiện:** Trường tuỳ biến đã tồn tại (UC-FLD-01).

### Luồng chính

1. Xoá một trường tuỳ biến khỏi workspace
2. Hệ thống cảnh báo số issue đang có dữ liệu ở trường này, trên những project nào
3. Xác nhận → trường chuyển sang xoá mềm, dữ liệu cũ trong issue **vẫn còn**
   nhưng không hiển thị, không sửa được, không tính vào bộ lọc/báo cáo nữa
4. Đổi kiểu một trường đã có dữ liệu → **không hỗ trợ trực tiếp**; phải tạo
   trường mới rồi tự chuyển dữ liệu, vì không có phép chuyển đổi an toàn cho
   mọi cặp kiểu (ví dụ số → chọn một)

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-FLD-06/NT-01 | Khôi phục một trường vừa xoá mềm trong thời hạn ân hạn | Trường và mọi cấu hình (project, loại issue, màn hình) trở lại như trước khi xoá |
| UC-FLD-06/NT-02 | Hết thời hạn ân hạn | Tác vụ định kỳ xoá vĩnh viễn dữ liệu của trường ở mọi issue |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-FLD-06/NL-01 | Không đủ quyền quản trị workspace | Không hiển thị chức năng xoá/khôi phục trường |

### Hậu điều kiện

Không có issue nào bị hỏng bởi việc xoá hoặc đổi trường — đây là Definition of
Done của phase.

### Ảnh hưởng tới đồng bộ

Xoá mềm trường phát delta ẩn trường đó trên scope `ws:{workspaceId}`; client
ngừng hiển thị trường ở mọi issue đã đồng bộ, dữ liệu cục bộ cũ vẫn giữ cho tới
khi tác vụ xoá vĩnh viễn phát delta xoá thật.

---

## UC-FLD-07 — Trường tuỳ biến vào nhật ký thay đổi và delta

**Actor:** hệ thống (không có giao diện riêng — hệ quả của UC-FLD-01 đến UC-FLD-03)
**Tiền điều kiện:** Trường tuỳ biến đã gắn vào một issue có thể sửa (UC-FLD-02).

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

**Requirement:** FR-FLD-07
**Actor:** thành viên có quyền xem project
**Tiền điều kiện:** Trường tuỳ biến đã gắn vào project (UC-FLD-02).

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

### Ảnh hưởng tới đồng bộ

Không áp dụng — lọc/sắp xếp là một đường đọc server-side (jOOQ), không phát
sinh delta hay thay đổi dữ liệu cục bộ nào.

> **Chưa chốt:** tài liệu hiện có xác nhận đường đọc (jOOQ) và việc trường
> tuỳ biến phải dùng được trong bộ lọc, nhưng chưa mô tả cách đánh chỉ mục
> cho lọc/sắp xếp trên trường tuỳ biến ở quy mô lớn (ví dụ project hàng chục
> nghìn issue). Đây là quyết định của Phase 7 (ngôn ngữ truy vấn và chỉ mục),
> không phải của phase này.

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-FLD-01 | Trường tuỳ biến đi qua đúng tầng phân giải trường mà trường hệ thống dùng — không có đường xử lý riêng trong module `issue` |
| QT-FLD-02 | Cấu hình một trường (bắt buộc, mặc định, tuỳ chọn) gắn theo cặp (project, loại issue), không gắn theo trường |
| QT-FLD-03 | Đặt bắt buộc cho một trường không hồi tố lên issue đã có trước đó |
| QT-FLD-04 | Xoá trường là xoá mềm; dữ liệu cũ trong issue được giữ nguyên nhưng ẩn khỏi hiển thị, bộ lọc và báo cáo |
| QT-FLD-05 | Đổi kiểu một trường đã có dữ liệu không được hỗ trợ trực tiếp; phải tạo trường mới |
| QT-FLD-06 | Mỗi lần đổi giá trị trường tuỳ biến sinh đúng một dòng nhật ký thay đổi, cùng cơ chế trường hệ thống |
| QT-FLD-07 | Trường tuỳ biến dùng chung scope đồng bộ `proj:{projectId}`, không có scope riêng |
| QT-FLD-08 | Lọc và sắp xếp theo trường tuỳ biến đi qua jOOQ, không qua `JdbcClient` |

## Yêu cầu phi chức năng liên quan

`NFR-19` thay đổi cấu trúc dữ liệu tương thích ngược trong triển khai cuốn
chiếu · `NFR-01` optimistic mutation cho cấu hình trường và screen · `NFR-07`
lọc theo trường tuỳ biến vẫn phải đẩy điều kiện phân quyền xuống tầng SQL
