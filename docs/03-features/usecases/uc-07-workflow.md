# UC-WKF — Workflow

Thay tập trạng thái cố định của Phase 3 (to-do / in-progress / done) bằng
workflow do người dùng định nghĩa. **Đây là phase rủi ro nhất của roadmap**, vì
nó thay một khái niệm đã được dùng khắp nơi kể từ Phase 3.

**Phase:** 5 · **Feature:** KJ-WKF-01 → KJ-WKF-11
**Liên quan:** [uc-05-issue.md](uc-05-issue.md) · [backend-modules.md](../../04-system-design/backend-modules.md) · [roadmap.md — Phase 5](../roadmap.md)

---

## UC-WKF-00 — Rà soát chỗ gắn cứng trạng thái cố định

**Actor:** đội phát triển (việc kỹ thuật, không có actor nghiệp vụ)
**Tiền điều kiện:** Không có — đây là việc kỹ thuật đầu phase, không có tiền điều
kiện nghiệp vụ.

### Luồng chính

1. Việc **đầu tiên** của phase, trước khi viết bất kỳ tính năng workflow nào: rà
   soát toàn bộ Phase 3–4 tìm mọi chỗ giả định trạng thái là một trong ba giá trị
   cố định (điều kiện hiển thị, quy tắc chuyển board ở phase sau, bộ lọc mặc định…)
2. Thay các chỗ đó bằng tra cứu theo **nhóm trạng thái** (chưa làm / đang làm /
   đã xong), là khái niệm sống sót qua việc chuyển sang workflow động

### Hậu điều kiện

Không còn nơi nào trong codebase so sánh trực tiếp với một trong ba giá trị
trạng thái cố định của Phase 3; mọi so sánh đi qua nhóm trạng thái hoặc qua
workflow. Đây là điều kiện tiên quyết để các UC còn lại của phase này an toàn.

### Ảnh hưởng tới đồng bộ

Không áp dụng — đây là việc rà soát code, không phát sinh thay đổi dữ liệu nào
client cần nhận.

---

## UC-WKF-01 — Trạng thái do người dùng định nghĩa và nhóm trạng thái

**Requirement:** FR-WKF-01
**Actor:** thành viên có quyền quản trị workspace
**Tiền điều kiện:** Đang ở cấp workspace.

### Luồng chính

1. Tạo trạng thái mới: tên, màu, thuộc về đúng một trong ba **nhóm trạng thái**
   cố định (chưa làm / đang làm / đã xong)
2. Trạng thái dùng chung ở cấp workspace, được tham chiếu bởi nhiều workflow

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-WKF-01/NT-01 | Đổi nhóm của một trạng thái đang có issue ở trạng thái đó | Cho phép — issue tự động tính lại theo nhóm mới, không cần chuyển đổi thủ công |
| UC-WKF-01/NT-02 | Tạo hoặc sửa trạng thái khi mất kết nối | Thao tác vào hàng đợi bền cục bộ, hiện trạng thái "đang chờ đồng bộ"; gửi lại khi có mạng theo cơ chế hàng đợi chung của sync engine |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-WKF-01/NL-01 | Xoá trạng thái đang được một workflow tham chiếu | Chặn, yêu cầu gỡ khỏi workflow trước |
| UC-WKF-01/NL-02 | Không đủ quyền quản trị workspace | Không hiển thị chức năng tạo/sửa trạng thái |

### Hậu điều kiện

Trạng thái mới tồn tại ở cấp workspace, sẵn sàng để các workflow tham chiếu.

### Ảnh hưởng tới đồng bộ

Trạng thái là dữ liệu cấu hình cấp workspace, phát delta trên scope
`ws:{workspaceId}`; mọi client đang mở workspace cập nhật ngay danh sách trạng
thái khả dụng.

---

## UC-WKF-02 — Workflow với các bước chuyển

**Requirement:** FR-WKF-02
**Actor:** thành viên có quyền quản trị workspace
**Tiền điều kiện:** Đã có ít nhất một trạng thái được định nghĩa (UC-WKF-01).

### Luồng chính

1. Tạo workflow: tập hợp trạng thái tham gia và các bước chuyển (transition)
   giữa chúng
2. Mỗi workflow có **bước chuyển khởi tạo** — trạng thái issue nhận khi vừa tạo
3. Có thể khai báo **bước chuyển toàn cục** (từ mọi trạng thái tới một trạng thái
   đích) và **bước chuyển về chính nó** (self-transition, để chạy hành động sau
   bước chuyển mà không đổi trạng thái)

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-WKF-02/NT-01 | Trạng thái không có bước chuyển đi ra (trừ trạng thái thuộc nhóm "đã xong") | Cảnh báo khi lưu — issue có thể bị kẹt vĩnh viễn ở trạng thái đó |
| UC-WKF-02/NT-02 | Gửi lại yêu cầu tạo workflow với cùng khoá chống trùng (ví dụ do mất kết nối ngay sau khi gửi) | Không tạo bản workflow thứ hai — server nhận diện qua idempotency key, trả về đúng bản đã tạo |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-WKF-02/NL-01 | Xoá bước chuyển đang là bước chuyển khởi tạo | Chặn, workflow luôn phải có đúng một bước chuyển khởi tạo |
| UC-WKF-02/NL-02 | Không đủ quyền quản trị workspace | Không hiển thị chức năng tạo/sửa workflow |

### Hậu điều kiện

Workflow tồn tại với tập trạng thái, bước chuyển, và đúng một bước chuyển khởi tạo.

### Ảnh hưởng tới đồng bộ

Workflow là cấu hình cấp workspace, phát delta trên scope `ws:{workspaceId}`.

---

## UC-WKF-03 — Điều kiện trên bước chuyển

**Requirement:** FR-WKF-03
**Actor:** thành viên có quyền quản trị workspace
**Tiền điều kiện:** Bước chuyển đã tồn tại trong workflow (UC-WKF-02).

### Luồng chính

1. Gắn điều kiện lên một bước chuyển: ai được phép thực hiện (theo vai trò, theo
   người báo cáo, theo người được gán…)
2. Khi thực hiện bước chuyển, hệ thống kiểm tra điều kiện **trước khi** cho thực
   hiện; không thoả thì bước chuyển không hiển thị trong danh sách lựa chọn

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-WKF-03/NL-01 | Người không thoả điều kiện gọi thẳng API bước chuyển | Từ chối ở tầng handler, không chỉ ẩn ở giao diện — kiểm tra quyền không bao giờ chỉ nằm ở client |
| UC-WKF-03/NL-02 | Điều kiện tham chiếu một vai trò đã bị xoá | Bước chuyển coi như không ai thoả điều kiện, cảnh báo khi quản trị viên mở lại workflow |
| UC-WKF-03/NL-03 | Không đủ quyền quản trị workspace để gắn điều kiện | Không hiển thị chức năng cấu hình điều kiện |

### Hậu điều kiện

Bước chuyển mang điều kiện; chỉ thành viên thoả điều kiện mới thấy và thực hiện được.

### Ảnh hưởng tới đồng bộ

Điều kiện thuộc cấu hình workflow, phát delta trên scope `ws:{workspaceId}`;
client ẩn/hiện bước chuyển trong danh sách lựa chọn dựa trên điều kiện đã đồng
bộ, nhưng quyền thực sự vẫn được server kiểm tra lại (invariant #27).

---

## UC-WKF-04 — Kiểm tra hợp lệ trên bước chuyển

**Requirement:** FR-WKF-04
**Actor:** thành viên thực hiện bước chuyển
**Tiền điều kiện:** Bước chuyển đã tồn tại (UC-WKF-02).

### Luồng chính

1. Bước chuyển khai báo trường bắt buộc phải có giá trị trước khi thực hiện được
   (ví dụ bắt buộc có người được gán trước khi chuyển sang "đang làm")
2. Thiếu trường bắt buộc → không cho thực hiện bước chuyển, báo rõ trường nào thiếu

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-WKF-04/NT-01 | Trường bắt buộc bị xoá khỏi cấu hình project sau khi workflow đã dùng nó | Bỏ qua kiểm tra trường đó, cảnh báo khi quản trị viên mở lại workflow |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-WKF-04/NL-01 | Không đủ quyền quản trị workspace để khai báo trường bắt buộc | Không hiển thị chức năng này |

### Hậu điều kiện

Bước chuyển mang danh sách trường bắt buộc; thực hiện bước chuyển mà thiếu
trường sẽ bị chặn.

### Ảnh hưởng tới đồng bộ

Cấu hình trường bắt buộc phát delta trên scope `ws:{workspaceId}`.

---

## UC-WKF-05 — Hành động sau bước chuyển và màn hình nhập liệu

**Requirement:** FR-WKF-05, FR-WKF-06
**Actor:** thành viên thực hiện bước chuyển
**Tiền điều kiện:** Bước chuyển đã tồn tại (UC-WKF-02); issue đang ở trạng thái
nguồn của bước chuyển đó.

### Luồng chính

1. Khai báo hành động chạy **sau khi** bước chuyển thành công: đặt kết quả xử lý
   (UC-WKF-08), tự gán người, phát domain event cho các module khác lắng nghe
2. Nếu bước chuyển cần nhập thêm dữ liệu (ví dụ bắt buộc chọn kết quả xử lý khi
   đóng issue), hệ thống hiện màn hình nhập liệu trước khi thực hiện

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-WKF-05/NT-01 | Người dùng huỷ màn hình nhập liệu giữa chừng | Bước chuyển không thực hiện, issue giữ nguyên trạng thái |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-WKF-05/NL-01 | Hành động sau bước chuyển thất bại (ví dụ gán một người không còn trong project) | **Toàn bộ bước chuyển bị rollback**, issue giữ nguyên trạng thái cũ, báo lỗi rõ |

### Hậu điều kiện

Issue chuyển sang trạng thái đích; hành động sau bước chuyển (đặt kết quả xử
lý, tự gán, phát event) đã chạy.

### Ảnh hưởng tới đồng bộ

Bước chuyển phát domain event `issue.transitioned`, không phải các module khác
tự suy ra từ thay đổi trường trạng thái — đúng nguyên tắc giao tiếp module chỉ
qua domain event.

---

## UC-WKF-06 — Workflow scheme ánh xạ theo loại issue

**Requirement:** FR-WKF-07
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** Đã có ít nhất một workflow được xuất bản (UC-WKF-02, UC-WKF-07).

### Luồng chính

1. Tạo workflow scheme: ánh xạ mỗi loại issue (Epic, Story, Task, Sub-task, Bug)
   sang một workflow
2. Gán scheme cho project; mọi issue trong project dùng workflow theo loại của nó

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-WKF-06/NT-01 | Loại issue chưa được ánh xạ trong scheme | Dùng workflow mặc định của scheme |
| UC-WKF-06/NT-02 | Sửa scheme đang được nhiều project dùng | Cảnh báo danh sách project bị ảnh hưởng, giống UC-PRJ-07 |
| UC-WKF-06/NT-03 | Scheme mới khiến một bước chuyển mà một số thành viên trước đó thấy được (theo điều kiện của UC-WKF-03) không còn tồn tại hoặc đổi điều kiện | Delta cấu hình workflow mới trên scope `proj:{projectId}` khiến client tính lại ngay danh sách bước chuyển hiển thị cho từng issue; đây không phải một sự kiện thu hồi quyền tài khoản (invariant #20 nói về mặt nạ quyền), nhưng hệ quả với người dùng giống nhau — hành động trước đó khả dụng nay không còn, nên phải phản ánh ngay, không đợi lần tải lại tiếp theo |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-WKF-06/NL-01 | Không đủ quyền quản trị project | Không hiển thị chức năng gán workflow scheme |

### Hậu điều kiện

Project dùng đúng workflow theo loại issue của scheme vừa gán.

### Ảnh hưởng tới đồng bộ

Scheme là cấu hình cấp project, phát delta trên scope `proj:{projectId}`; đổi
scheme đang dùng cho nhiều project phát delta cho từng project bị ảnh hưởng.

---

## UC-WKF-07 — Trình soạn workflow: bản nháp và xuất bản

**Requirement:** FR-WKF-08
**Actor:** thành viên có quyền quản trị workspace
**Tiền điều kiện:** Workflow đã tồn tại (UC-WKF-02).

### Luồng chính

1. Sửa workflow trong chế độ **bản nháp**; thay đổi ở bản nháp **không ảnh hưởng**
   tới issue đang chạy theo bản đã xuất bản
2. Xuất bản → bản nháp trở thành bản chính thức, áp dụng cho mọi issue dùng
   workflow này từ thời điểm xuất bản

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-WKF-07/NT-01 | Nhiều người sửa bản nháp cùng lúc | Ghi sau thắng ở mức trường, cùng nguyên tắc chung; không khoá độc quyền bản nháp |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-WKF-07/NL-01 | Xuất bản khi bản nháp gỡ một trạng thái đang có issue đứng ở đó | Chặn xuất bản trực tiếp, chuyển sang luồng UC-WKF-08 (cần ánh xạ chuyển đổi) |
| UC-WKF-07/NL-02 | Không đủ quyền quản trị workspace | Không hiển thị chức năng sửa/xuất bản workflow |

### Hậu điều kiện

Bản xuất bản mới thành bản chính thức; issue đang chạy áp dụng ngay theo bản mới.

### Ảnh hưởng tới đồng bộ

Bản nháp không phát delta cho tới khi xuất bản — chỉ bản chính thức mới đồng
bộ, trên scope `ws:{workspaceId}`.

---

## UC-WKF-08 — Chuyển đổi issue đang tồn tại khi đổi workflow

**Requirement:** FR-WKF-09
**Actor:** thành viên có quyền quản trị workspace
**Tiền điều kiện:** Xuất bản workflow (UC-WKF-07) làm mất ít nhất một trạng thái
đang có issue đứng ở đó.

### Luồng chính

1. Khi xuất bản một thay đổi workflow làm mất trạng thái đang có issue sử dụng,
   hệ thống yêu cầu **ánh xạ**: mỗi trạng thái bị gỡ chuyển issue đang đứng ở đó
   sang trạng thái nào trong workflow mới
2. Hiển thị **bản xem trước**: số issue bị ảnh hưởng theo từng ánh xạ
3. Xác nhận → chạy chuyển đổi hàng loạt, có **đường lùi**: giữ bản ghi ánh xạ đã
   dùng để hoàn tác nếu phát hiện sai ngay sau đó

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-WKF-08/NT-01 | Chuyển đổi hàng loạt thất bại giữa chừng (ví dụ mất kết nối) | Không để lại trạng thái nửa vời — chạy theo lô có thể chạy lại an toàn (idempotent theo issue) |
| UC-WKF-08/NT-02 | Project có hàng nghìn issue đang dùng workflow bị đổi | Không được làm mất hoặc sai trạng thái của issue nào — đây là điều kiện hoàn thành (Definition of Done) của cả phase |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-WKF-08/NL-01 | Không đủ quyền quản trị workspace | Không hiển thị chức năng chuyển đổi hàng loạt |

### Hậu điều kiện

Toàn bộ issue thuộc trạng thái bị gỡ đã chuyển sang trạng thái ánh xạ; bản ghi
ánh xạ được giữ lại cho đường lùi.

### Ảnh hưởng tới đồng bộ

Chuyển đổi hàng loạt phát nhiều delta cùng lúc; phải chia lô để không làm ngập
luồng đồng bộ, cùng cơ chế đã nêu ở UC-ISS-09 cho cân bằng lại thứ hạng.

---

## UC-WKF-09 — Quản lý kết quả xử lý

**Requirement:** FR-WKF-10
**Actor:** thành viên có quyền quản trị workspace
**Tiền điều kiện:** Không có — quản trị viên tạo danh mục kết quả xử lý bất cứ
lúc nào.

### Luồng chính

1. Định nghĩa danh mục kết quả xử lý dùng chung ở cấp workspace (ví dụ Done,
   Won't Fix, Duplicate, Cannot Reproduce)
2. Gắn việc đặt kết quả xử lý làm hành động sau bước chuyển (UC-WKF-05), thường ở
   bước chuyển vào nhóm trạng thái "đã xong"

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-WKF-09/NT-01 | Bước chuyển vào nhóm "đã xong" không gắn hành động đặt kết quả xử lý | Cho phép — kết quả xử lý là tuỳ chọn, không bắt buộc mọi workflow phải dùng |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-WKF-09/NL-01 | Xoá một kết quả xử lý đang được issue dùng | Chặn, yêu cầu gán lại các issue đó sang kết quả khác trước |
| UC-WKF-09/NL-02 | Không đủ quyền quản trị workspace | Không hiển thị chức năng quản lý danh mục kết quả xử lý |

### Hậu điều kiện

Danh mục kết quả xử lý sẵn sàng để gắn vào hành động sau bước chuyển.

### Ảnh hưởng tới đồng bộ

Danh mục là cấu hình cấp workspace, phát delta trên scope `ws:{workspaceId}`.

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-WKF-01 | Không còn nơi nào trong code so sánh trực tiếp với trạng thái cố định của Phase 3; mọi so sánh qua nhóm trạng thái hoặc qua workflow |
| QT-WKF-02 | Mỗi workflow có đúng một bước chuyển khởi tạo |
| QT-WKF-03 | Điều kiện trên bước chuyển được kiểm tra ở tầng handler, không chỉ ở giao diện |
| QT-WKF-04 | Hành động sau bước chuyển thất bại thì rollback toàn bộ bước chuyển |
| QT-WKF-05 | Sửa bản nháp workflow không ảnh hưởng issue đang chạy theo bản đã xuất bản |
| QT-WKF-06 | Xuất bản một workflow làm mất trạng thái đang dùng bắt buộc phải có ánh xạ chuyển đổi, kèm xem trước |
| QT-WKF-07 | Chuyển đổi hàng loạt khi đổi workflow không được làm mất hoặc sai trạng thái của bất kỳ issue nào |
| QT-WKF-08 | Bước chuyển phát domain event; module khác phản ứng qua event, không tự suy ra từ thay đổi trường |

## Yêu cầu phi chức năng liên quan

`NFR-19` thay đổi cấu trúc dữ liệu tương thích ngược trong triển khai cuốn chiếu
· `NFR-17` consumer sự kiện phải chống trùng · `NFR-01` phản hồi bước chuyển tức
thì trên giao diện trước khi server xác nhận
