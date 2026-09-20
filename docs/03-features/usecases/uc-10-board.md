# UC-BRD — Board

Làm việc trực quan trên board Kanban. Board không lưu danh sách issue của
riêng nó — nó là một **lớp trình bày** trên trên bộ lọc đã lưu (UC-SRC-08) và
trên workflow (UC-WKF-01, UC-WKF-02) đã có từ các phase trước; phase này không
phát minh lại cơ chế lọc, thứ hạng hay chuyển trạng thái.

**Phase:** 8 · **Feature:** KJ-BRD-01 → KJ-BRD-10
**Liên quan:** [uc-05-issue.md](uc-05-issue.md) · [uc-07-workflow.md](uc-07-workflow.md) · [uc-09-search.md](uc-09-search.md) · [realtime-and-sync.md](../../04-system-design/realtime-and-sync.md) · [roadmap.md — Phase 8](../roadmap.md)

---

## UC-BRD-01 — Board gắn với bộ lọc

**Requirement:** FR-BRD-01
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** có ít nhất một bộ lọc đã lưu (UC-SRC-08)

### Luồng chính

1. Tạo board, chọn một bộ lọc đã lưu làm **nguồn issue** — board hiển thị đúng
   tập issue mà bộ lọc đó trả về, không có tập issue riêng
2. Bộ lọc nguồn chạy lại mỗi khi board tải hoặc khi có delta ảnh hưởng tới kết
   quả lọc; board không tự giữ một bản sao tĩnh của danh sách issue

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-BRD-01/NT-01 | Tạo board khi mất kết nối | Thao tác vào hàng đợi bền cục bộ; gửi lại khi có mạng theo cơ chế hàng đợi chung của sync engine |
| UC-BRD-01/NT-02 | Gửi lại yêu cầu tạo board với cùng khoá chống trùng | Không tạo board thứ hai — server nhận diện qua idempotency key |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-BRD-01/NL-01 | Bộ lọc nguồn của board bị xoá (tiếp nối ghi chú ở [uc-09-search.md — UC-SRC-08](uc-09-search.md#uc-src-08--lưu-và-chia-sẻ-bộ-lọc)) | **Chặn xoá bộ lọc** khi còn board tham chiếu nó, giống cách UC-WKF-01 chặn xoá trạng thái đang được workflow dùng; người dùng phải đổi board sang bộ lọc khác hoặc xoá board trước |
| UC-BRD-01/NL-02 | Người xem board không có quyền xem bộ lọc nguồn (bộ lọc riêng tư của người khác) | Board không hiển thị được, báo rõ lý do thay vì hiện trống |

### Hậu điều kiện

Board luôn phản ánh đúng kết quả hiện tại của bộ lọc nguồn; không có trạng thái
"board lệch với bộ lọc".

### Ảnh hưởng tới đồng bộ

Cấu hình board (bộ lọc nguồn, cột, làn, quy tắc tô màu — UC-BRD-01 đến UC-BRD-06)
là dữ liệu cấu hình cấp project, phát delta trên scope `proj:{projectId}`; danh
sách issue hiển thị trên board **không** có delta riêng — nó suy ra từ kết quả
bộ lọc nguồn chạy lại trên chính dữ liệu issue đã có trong scope đó (xem
UC-SRC-05).

---

## UC-BRD-02 — Cột ánh xạ nhiều trạng thái

**Requirement:** FR-BRD-02
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** Board đã tồn tại (UC-BRD-01); workflow áp dụng cho project
đã có trạng thái (UC-WKF-01).

### Luồng chính

1. Tạo cột, ánh xạ mỗi cột tới **một hoặc nhiều trạng thái** của workflow đang
   áp dụng cho project (không phải nhóm trạng thái cố định của Phase 3 — xem
   UC-WKF-01)
2. Một trạng thái chỉ thuộc đúng một cột tại một thời điểm
3. Thứ tự cột trên board là thứ tự làm việc theo quy ước, không ràng buộc bởi
   thứ tự bước chuyển trong workflow

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-BRD-02/NT-01 | Trạng thái mới được thêm vào workflow sau khi board đã cấu hình cột | Trạng thái chưa được ánh xạ vào cột nào — issue ở trạng thái đó không hiển thị trên board cho tới khi được ánh xạ, cảnh báo cho quản trị viên |
| UC-BRD-02/NT-02 | Project dùng nhiều workflow khác nhau theo loại issue (workflow scheme, UC-WKF-06) | Cấu hình cột phải ánh xạ đủ trạng thái của **mọi** workflow trong scheme đang hiển thị trên board, không chỉ một workflow |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-BRD-02/NL-01 | Xoá cột đang có issue | Yêu cầu chuyển các trạng thái đã ánh xạ sang cột khác trước |

### Hậu điều kiện

Mỗi trạng thái đang dùng thuộc về đúng một cột; cấu hình cột đủ để board hiển
thị mọi issue thuộc bộ lọc nguồn vào đúng cột tương ứng.

### Ảnh hưởng tới đồng bộ

Cấu hình cột phát delta trên scope `proj:{projectId}`, cùng cơ chế nêu ở
UC-BRD-01.

---

## UC-BRD-03 — Giới hạn số việc đang làm và cảnh báo

**Requirement:** FR-BRD-03
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** Cột đã tồn tại (UC-BRD-02).

### Luồng chính

1. Đặt giới hạn số issue tối đa cho một cột (WIP limit)
2. Vượt giới hạn → cột hiển thị cảnh báo trực quan, **không chặn** việc kéo
   thêm issue vào cột đó

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-BRD-03/NT-01 | Cột ánh xạ nhiều trạng thái (UC-BRD-02) | Giới hạn tính theo tổng issue của mọi trạng thái trong cột, không theo từng trạng thái riêng |

### Hậu điều kiện

Cột mang một giới hạn WIP; vượt giới hạn chỉ đổi cách hiển thị, không chặn thao tác.

### Ảnh hưởng tới đồng bộ

Giới hạn WIP phát delta trên scope `proj:{projectId}`, cùng cơ chế nêu ở
UC-BRD-01.

---

## UC-BRD-04 — Làn ngang theo nhiều tiêu chí

**Requirement:** FR-BRD-04
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** Board đã tồn tại (UC-BRD-01).

### Luồng chính

1. Chọn một trường làm tiêu chí chia làn ngang (epic, người được gán, trường
   tuỳ biến chọn một — dùng lại danh sách trường có thể lọc từ UC-SRC-04/UC-FLD-08)
2. Board hiển thị mỗi giá trị của trường đó thành một làn ngang riêng

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-BRD-04/NT-01 | Issue không có giá trị ở trường dùng chia làn | Gom vào làn "chưa phân loại" mặc định, không ẩn khỏi board |

### Hậu điều kiện

Board hiển thị các làn ngang theo giá trị của trường vừa chọn.

### Ảnh hưởng tới đồng bộ

Cấu hình chia làn phát delta trên scope `proj:{projectId}`, cùng cơ chế nêu ở
UC-BRD-01.

---

## UC-BRD-05 — Bộ lọc nhanh

**Requirement:** FR-BRD-05
**Actor:** thành viên có quyền xem project
**Tiền điều kiện:** Board đã tồn tại (UC-BRD-01).

### Luồng chính

1. Áp thêm điều kiện lọc tạm thời lên board đang xem (theo người được gán,
   theo nhãn…), không sửa bộ lọc nguồn đã lưu của board
2. Bộ lọc nhanh chỉ ảnh hưởng tới hiển thị của người đang xem, không lưu lại
   cho lần sau, không ảnh hưởng người khác đang xem cùng board

### Hậu điều kiện

Không có — bộ lọc nhanh mất đi khi rời board, không đổi cấu hình đã lưu nào.

### Ảnh hưởng tới đồng bộ

Không áp dụng — bộ lọc nhanh chỉ lọc lại dữ liệu đã có trên client, không gửi
request hay đổi dữ liệu cục bộ.

---

## UC-BRD-06 — Tuỳ biến thẻ và tô màu theo quy tắc

**Requirement:** FR-BRD-06
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** Board đã tồn tại (UC-BRD-01).

### Luồng chính

1. Chọn các trường hiển thị trên thẻ issue (bao gồm trường tuỳ biến)
2. Đặt quy tắc tô màu thẻ theo điều kiện trên một trường (ví dụ đỏ khi quá hạn)

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-BRD-06/NT-01 | Nhiều quy tắc tô màu cùng thoả cho một thẻ | Áp quy tắc **đầu tiên khớp** theo thứ tự đã cấu hình, không trộn màu |

### Hậu điều kiện

Thẻ issue trên board hiển thị đúng các trường đã chọn và màu theo quy tắc khớp
đầu tiên.

### Ảnh hưởng tới đồng bộ

Cấu hình thẻ và quy tắc tô màu phát delta trên scope `proj:{projectId}`, cùng
cơ chế nêu ở UC-BRD-01.

---

## UC-BRD-07 — Kéo thả cập nhật trạng thái và thứ hạng

**Requirement:** FR-BRD-07
**Actor:** thành viên có quyền sửa issue
**Tiền điều kiện:** Board đã có cột ánh xạ trạng thái (UC-BRD-02); issue đang
hiển thị trên board.

### Luồng chính

1. Kéo thẻ issue sang cột khác → cập nhật trạng thái issue sang một trạng thái
   thuộc cột đích; kéo trong cùng cột hoặc đổi làn → chỉ cập nhật thứ hạng
   và/hoặc trường chia làn, không đổi trạng thái
2. Đổi trạng thái khi kéo giữa hai cột đi qua **đúng luồng bước chuyển**
   (UC-WKF-02 đến UC-WKF-05): điều kiện, kiểm tra hợp lệ, hành động sau bước
   chuyển, màn hình nhập liệu nếu cần — kéo thả không phải một đường tắt bỏ
   qua workflow
3. Thứ hạng khi thả vào vị trí mới tính theo đúng cơ chế UC-ISS-09 (rank chuỗi,
   chèn vô hạn, cân bằng lại nền)
4. Giao diện cập nhật **ngay khi thả** (optimistic), không chờ server xác nhận

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-BRD-07/NT-01 | Cột đích ánh xạ nhiều trạng thái | Kéo vào cột chuyển issue sang trạng thái **đầu tiên** trong danh sách trạng thái ánh xạ của cột đó có bước chuyển hợp lệ từ trạng thái hiện tại; không có bước chuyển hợp lệ tới bất kỳ trạng thái nào trong cột → xem UC-BRD-07/NL-01 |
| UC-BRD-07/NT-02 | Bước chuyển cần màn hình nhập liệu (UC-WKF-05) | Thẻ giữ nguyên vị trí cũ cho tới khi màn hình nhập liệu được xác nhận; huỷ màn hình thì thẻ không di chuyển |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-BRD-07/NL-01 | Không có bước chuyển hợp lệ nào từ trạng thái hiện tại tới cột đích | Thẻ **bật lại vị trí cũ** ngay trên giao diện, báo rõ lý do — đây là ca hoàn tác nêu ở Definition of Done của Phase 8 |
| UC-BRD-07/NL-02 | Hành động sau bước chuyển thất bại ở server sau khi giao diện đã cập nhật lạc quan | Thẻ bật lại vị trí cũ, báo lỗi — cùng cơ chế rebase mutation chưa xác nhận (KJ-SYN-15) |
| UC-BRD-07/NL-03 | Hai người kéo cùng một thẻ tới hai cột khác nhau gần như đồng thời | Ai gửi request lên server trước thắng; người kia nhận lỗi xung đột, thẻ bật lại theo trạng thái mới nhất từ server, không âm thầm ghi đè |

### Hậu điều kiện

Issue đứng ở trạng thái và thứ hạng mới, đã đi qua đúng bước chuyển workflow;
không có trạng thái nửa vời nếu bước chuyển thất bại.

### Ảnh hưởng tới đồng bộ

Kéo thả phát đúng delta của UC-WKF-05 (đổi trạng thái, qua domain event
`issue.transitioned`) cộng với delta thứ hạng của UC-ISS-09; không có một loại
delta "board" riêng — client board chỉ là một cách hiển thị khác của cùng dữ
liệu issue trong sync scope `proj:{projectId}`.

---

## UC-BRD-08 — Backlog cho board Kanban

**Requirement:** FR-BRD-08
**Actor:** thành viên có quyền xem project
**Tiền điều kiện:** Board đã tồn tại (UC-BRD-01).

### Luồng chính

1. Xem danh sách issue thuộc bộ lọc nguồn của board nhưng **chưa vào** cột đầu
   tiên của workflow (chưa được kéo lên board), dạng danh sách phẳng có thứ hạng
2. Kéo từ backlog lên board — cùng cơ chế UC-BRD-07

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-BRD-08/NT-01 | Issue ở trạng thái đã thuộc một cột trên board | Không hiện trong backlog — backlog chỉ chứa issue thuộc bộ lọc nguồn nhưng ở ngoài mọi cột đã cấu hình |

### Hậu điều kiện

Không có — backlog chỉ là một cách hiển thị khác của cùng dữ liệu issue, kéo
lên board mới thực sự đổi trạng thái (UC-BRD-07).

### Ảnh hưởng tới đồng bộ

Không áp dụng riêng — backlog dùng chung delta của scope `proj:{projectId}` đã
nêu ở UC-BRD-01, không có delta backlog riêng.

---

## UC-BRD-09 — Biểu đồ dòng tích luỹ và biểu đồ kiểm soát

**Requirement:** FR-BRD-09
**Actor:** thành viên có quyền xem project
**Tiền điều kiện:** Board đã tồn tại với ít nhất một issue có lịch sử chuyển trạng thái.

### Luồng chính

1. Biểu đồ dòng tích luỹ: số issue theo mỗi cột, tính theo thời gian, dựng từ
   nhật ký thay đổi trạng thái (UC-ISS-14) của các issue thuộc bộ lọc nguồn
2. Biểu đồ kiểm soát: thời gian mỗi issue nằm trong một cột, từ cùng nguồn dữ
   liệu

### Hậu điều kiện

Biểu đồ chỉ dùng dữ liệu lịch sử đã có (nhật ký thay đổi), không cần một bảng
thống kê riêng được duy trì song song — tránh hai nguồn sự thật có thể lệch nhau.

> **Chưa chốt:** tài liệu hiện có chưa nói biểu đồ được tính trực tiếp từ nhật
> ký thay đổi mỗi lần xem (có thể chậm khi lịch sử dài) hay có một bước tổng
> hợp định kỳ chạy nền. Để lại cho lúc thiết kế chi tiết, dựa trên đo đạc thực
> tế về độ dài lịch sử điển hình.

### Ảnh hưởng tới đồng bộ

Không áp dụng — biểu đồ là một đường đọc tổng hợp từ nhật ký thay đổi đã đồng
bộ sẵn trong scope `proj:{projectId}`, không có delta riêng.

---

## UC-BRD-10 — Ảo hoá danh sách cho board lớn

**Actor:** thành viên có quyền xem project
**Tiền điều kiện:** Không có.

### Luồng chính

1. Board và backlog chỉ dựng DOM cho các thẻ đang nằm trong khung nhìn, cùng kỹ
   thuật ảo hoá đã dùng cho bảng issue (UC-ISS-13)
2. Board mượt với hàng nghìn issue trong một cột — đây là Definition of Done
   của phase

### Hậu điều kiện

Không có — ảo hoá là kỹ thuật hiển thị thuần client, không đổi dữ liệu nào.

### Ảnh hưởng tới đồng bộ

Không áp dụng — ảo hoá chỉ quyết định phần nào của dữ liệu đã đồng bộ được vẽ
lên DOM, không đổi cơ chế đồng bộ.

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-BRD-01 | Board không lưu danh sách issue riêng — luôn phản ánh kết quả hiện tại của bộ lọc nguồn |
| QT-BRD-02 | Không được xoá một bộ lọc đang được board dùng làm nguồn |
| QT-BRD-03 | Cột ánh xạ trạng thái của workflow, không ánh xạ nhóm trạng thái cố định của Phase 3 |
| QT-BRD-04 | Kéo thả đổi trạng thái phải đi qua đúng luồng bước chuyển của workflow, không có đường tắt |
| QT-BRD-05 | Kéo thả không có bước chuyển hợp lệ thì thẻ bật lại vị trí cũ, không âm thầm bỏ qua |
| QT-BRD-06 | Thứ hạng khi kéo thả trên board dùng đúng cơ chế rank chuỗi chung của UC-ISS-09 |
| QT-BRD-07 | Bộ lọc nhanh chỉ ảnh hưởng hiển thị cục bộ, không sửa bộ lọc nguồn đã lưu |
| QT-BRD-08 | Nhiều quy tắc tô màu thẻ cùng khớp thì áp quy tắc đầu tiên theo thứ tự cấu hình |
| QT-BRD-09 | Biểu đồ dòng tích luỹ và biểu đồ kiểm soát dựng từ nhật ký thay đổi có sẵn, không duy trì bảng thống kê song song riêng |

## Yêu cầu phi chức năng liên quan

`NFR-01` kéo thả phản hồi tức thì trước khi server xác nhận · `NFR-11` board
mượt ở quy mô hàng nghìn issue, cần ảo hoá danh sách · `NFR-20` không rò rỉ dữ
liệu giữa project khi hiển thị board dựa trên bộ lọc
