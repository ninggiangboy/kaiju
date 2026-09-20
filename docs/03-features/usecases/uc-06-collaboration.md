# UC-COL — Collaboration

Làm việc cùng nhau trên issue, và hệ thống thông báo đầy đủ. Bình luận và đính
kèm thuộc module `issue` (chúng gắn trực tiếp vào issue); dòng hoạt động thuộc
module `activity`; thông báo thuộc module `notification`. Ba module này giao
tiếp với `issue` **chỉ qua domain event**, không truy vấn thẳng bảng của nhau.

**Phase:** 4 · **Feature:** KJ-COL-01 → KJ-COL-16
**Liên quan:** [uc-05-issue.md](uc-05-issue.md) · [backend-modules.md](../../04-system-design/backend-modules.md) · [events-and-outbox.md](../../04-system-design/events-and-outbox.md) · [roadmap.md — Phase 4](../roadmap.md)

---

## UC-COL-01 — Bình luận và lịch sử sửa

**Requirement:** FR-COL-01
**Actor:** thành viên có quyền bình luận trên issue
**Tiền điều kiện:** đang xem một issue

### Luồng chính

1. Soạn bình luận bằng trình soạn thảo rich text, tương tự mô tả issue
2. Gửi bình luận → hiện ngay trên giao diện, xuất hiện trong dòng hoạt động
3. Sửa bình luận của chính mình → bản cũ được giữ lại trong lịch sử chỉnh sửa,
   hiển thị nhãn "đã chỉnh sửa" kèm thời điểm
4. Xoá bình luận của chính mình → nội dung ẩn đi, vị trí trong luồng vẫn giữ

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-COL-01/NT-01 | Gửi bình luận lúc mất mạng | Vào hàng đợi bền cùng cơ chế mutation của UC-ISS-03, hiện trạng thái "đang gửi" cho tới khi server xác nhận |
| UC-COL-01/NT-02 | Client gửi lại cùng khoá chống trùng (timeout, hàng đợi bền gửi lại) | Server trả về bình luận đã tạo trước đó, không tạo bản ghi thứ hai |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-COL-01/NL-01 | Sửa hoặc xoá bình luận của người khác | Chặn, trừ khi có quyền quản trị bình luận |
| UC-COL-01/NL-02 | Sửa bình luận trên issue đã bị xoá mềm | Chặn |
| UC-COL-01/NL-03 | Bình luận rỗng sau khi xoá định dạng | Không cho gửi |

### Hậu điều kiện

Bình luận tồn tại là một aggregate riêng, tham chiếu tới issue bằng id — không
nằm trong aggregate `Issue`.

### Ảnh hưởng tới đồng bộ

Bình luận phát delta trên scope project của issue, cùng cơ chế trường-đã-đổi
như UC-ISS-03: chỉ trường thay đổi (nội dung, trạng thái ẩn) được gửi.

---

## UC-COL-02 — Nhắc tên và trả lời theo luồng

**Requirement:** FR-COL-02, FR-COL-03
**Actor:** thành viên có quyền bình luận
**Tiền điều kiện:** đang xem một issue

### Luồng chính

1. Gõ `@` trong bình luận, chọn một thành viên hoặc một group từ danh bạ workspace
2. Người/group được nhắc nhận thông báo (xem UC-COL-09)
3. Trả lời một bình luận cụ thể → bình luận mới hiển thị lồng dưới bình luận gốc

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-COL-02/NT-01 | Nhắc tên một người không có quyền xem issue (ví dụ do giới hạn người xem bình luận, UC-COL-03) | Vẫn cho nhắc trong nội dung, nhưng **không gửi thông báo** cho người không có quyền xem |
| UC-COL-02/NT-02 | Nhắc tên một group | Gửi thông báo cho **từng thành viên đang hoạt động** của group tại thời điểm gửi, không theo dõi thành viên gia nhập group sau đó |
| UC-COL-02/NT-03 | Trả lời một bình luận đã bị xoá | Cho phép — bình luận gốc hiển thị "bình luận đã bị xoá" |

### Hậu điều kiện

Bình luận mang danh sách người/group được nhắc; nếu là trả lời, liên kết tới
bình luận gốc tồn tại. Thông báo được tạo cho người có quyền xem (UC-COL-09).

### Ảnh hưởng tới đồng bộ

Danh sách người được nhắc và liên kết trả lời là trường của bình luận, đi theo
delta của chính bình luận đó trên scope project.

---

## UC-COL-03 — Giới hạn người xem bình luận

**Requirement:** FR-COL-04
**Actor:** thành viên có quyền bình luận
**Tiền điều kiện:** đang xem một issue

### Luồng chính

1. Khi soạn bình luận, chọn giới hạn người xem theo vai trò hoặc theo một group cụ thể
2. Bình luận chỉ hiển thị cho người thoả điều kiện đó, kể cả người có quyền xem
   issue nói chung

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-COL-03/NT-01 | Người xem không thoả điều kiện giới hạn | Không thấy bình luận trong dòng hoạt động, không thấy trong đếm số bình luận |
| UC-COL-03/NT-02 | Người bị giới hạn sau này được thêm vào group thoả điều kiện | Thấy được bình luận cũ, không hồi tố ẩn/hiện theo thời điểm gửi |

### Hậu điều kiện

Bình luận mang điều kiện giới hạn người xem; chỉ người thoả điều kiện đó thấy
được nó trong dòng hoạt động và trong đếm số bình luận.

### Ảnh hưởng tới đồng bộ

Bình luận có giới hạn người xem không được đẩy vào delta của những client không
thoả điều kiện — lọc ở tầng dựng truy vấn trước khi phát delta, không lọc sau ở
client. Cùng nguyên tắc với lọc quyền theo QT ở uc-04-project.

---

## UC-COL-04 — Biểu tượng cảm xúc

**Requirement:** FR-COL-05
**Actor:** thành viên có quyền xem issue
**Tiền điều kiện:** đang xem một issue

### Luồng chính

1. Thả một biểu tượng cảm xúc lên bình luận
2. Số lượng và danh sách người thả hiển thị cạnh bình luận
3. Bỏ biểu tượng đã thả

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-COL-04/NT-01 | Thả cùng một biểu tượng hai lần | Lần thứ hai bỏ biểu tượng đó thay vì thả thêm (toggle) |

### Hậu điều kiện

Danh sách biểu tượng cảm xúc trên bình luận phản ánh đúng người đã thả và loại
biểu tượng, tại thời điểm hiện tại.

### Ảnh hưởng tới đồng bộ

Biểu tượng cảm xúc là trường của bình luận, đi theo delta của chính bình luận
đó trên scope project.

---

## UC-COL-05 — Dòng hoạt động

**Requirement:** FR-COL-11
**Actor:** thành viên có quyền xem issue
**Tiền điều kiện:** đang xem một issue

### Luồng chính

1. Dòng hoạt động gộp: bình luận, thay đổi trường (nhật ký thay đổi từ
   [uc-05-issue](uc-05-issue.md)), và nhật ký công việc (phase sau)
2. Sắp xếp theo thời gian, lọc được theo loại nguồn
3. Mỗi nguồn phát tới `activity` module qua domain event của module gốc
   (`issue.field_changed`, `issue.commented`…) — `activity` **không** đọc bảng
   của `issue`

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-COL-05/NT-01 | Nhiều sự kiện xảy ra trong cùng một giây từ nhiều nguồn | Sắp xếp theo thời điểm sự kiện xảy ra ở nguồn, không theo thời điểm `activity` nhận được — vì delivery ít nhất một lần có thể tới lệch thứ tự |
| UC-COL-05/NT-02 | Sự kiện bị xử lý lại (retry của relay worker) | Không tạo dòng hoạt động trùng — `activity` chống trùng theo `(consumer, event_id)` |

### Hậu điều kiện

Mỗi sự kiện nguồn (bình luận, thay đổi trường…) có đúng một dòng tương ứng
trong dòng hoạt động, sắp xếp theo thời điểm xảy ra ở nguồn.

### Ảnh hưởng tới đồng bộ

Dòng hoạt động thuộc scope project của issue; mỗi dòng mới phát delta upsert
riêng, độc lập với module phát sinh sự kiện gốc.

---

## UC-COL-06 — Theo dõi và bình chọn

**Requirement:** FR-COL-09, FR-COL-10
**Actor:** thành viên có quyền xem issue
**Tiền điều kiện:** đang xem một issue

### Luồng chính

1. Người tạo issue và người bình luận **tự động** trở thành người theo dõi
2. Thêm hoặc bớt theo dõi thủ công bất cứ lúc nào
3. Bình chọn cho issue; số phiếu hiển thị, danh sách người bình chọn chỉ người có
   quyền quản trị project thấy được

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-COL-06/NT-01 | Tự bớt theo dõi issue mình vừa tạo | Cho phép — tự động theo dõi chỉ là giá trị khởi tạo, không ràng buộc |
| UC-COL-06/NT-02 | Bình chọn hai lần | Lần thứ hai bỏ phiếu thay vì cộng thêm (toggle, giống UC-COL-04) |

### Hậu điều kiện

Danh sách người theo dõi và số phiếu bình chọn của issue phản ánh trạng thái
mới nhất.

### Ảnh hưởng tới đồng bộ

Danh sách theo dõi và số phiếu là trường của issue, đi theo delta chung của
UC-ISS-03 trên scope project.

---

## UC-COL-07 — Đính kèm tệp

**Requirement:** FR-COL-06, FR-COL-08
**Actor:** thành viên có quyền sửa issue
**Tiền điều kiện:** đang xem một issue

### Luồng chính

1. Chọn hoặc kéo thả tệp vào issue
2. Client yêu cầu một **liên kết tải lên có chữ ký** từ server, tải trực tiếp lên
   kho lưu trữ đối tượng — tệp **không đi qua backend**
3. Server chỉ lưu siêu dữ liệu (tên, dung lượng, kiểu, người tải lên)
4. Xem trước ảnh và PDF ngay trong issue; tải về bằng liên kết tải xuống có chữ ký

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-COL-07/NT-01 | Tải về từ workspace khác (đoán URL) | Liên kết tải xuống có chữ ký và thời hạn ngắn; hết hạn thì phải xin lại, server kiểm tra quyền trước khi cấp |
| UC-COL-07/NT-02 | Xoá tệp đính kèm | Xoá siêu dữ liệu ngay; tệp vật lý dọn bởi tác vụ nền, không đồng bộ trong request xoá |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-COL-07/NL-01 | Tệp vượt giới hạn dung lượng | Từ chối cấp liên kết tải lên |
| UC-COL-07/NL-02 | Tệp bị điểm móc quét mã độc đánh dấu độc hại (chạy nền sau khi tải lên) | Ẩn tệp khỏi issue, đánh dấu "đã bị chặn", ghi nhật ký |

### Hậu điều kiện

Siêu dữ liệu đính kèm (tên, dung lượng, kiểu, người tải lên) tồn tại, tham chiếu
tới issue; tệp vật lý nằm trong kho lưu trữ đối tượng.

### Ảnh hưởng tới đồng bộ

Chỉ siêu dữ liệu đính kèm đi qua sync scope của project; nội dung tệp không bao
giờ nằm trong delta hay trong bản cục bộ của client.

---

## UC-COL-08 — Đính kèm trong bình luận

**Requirement:** FR-COL-07
**Actor:** thành viên có quyền bình luận
**Tiền điều kiện:** đang soạn một bình luận

### Luồng chính

1. Kéo thả hoặc chọn tệp ngay trong khung soạn bình luận
2. Tệp dùng lại đúng cơ chế tải lên có chữ ký của UC-COL-07, chỉ khác chỗ gắn
   (bình luận thay vì issue)

### Luồng thay thế / Ngoại lệ

Kế thừa toàn bộ các nhánh UC-COL-07/NT-01, NT-02, NL-01, NL-02.

### Hậu điều kiện

Siêu dữ liệu đính kèm tồn tại, tham chiếu tới bình luận thay vì tới issue trực
tiếp.

### Ảnh hưởng tới đồng bộ

Giống UC-COL-07: chỉ siêu dữ liệu đi qua sync scope của project, gắn vào delta
của bình luận chứa nó.

---

## UC-COL-09 — Thông báo trong ứng dụng

**Requirement:** FR-COL-12
**Actor:** thành viên nhận thông báo
**Tiền điều kiện:** không có

### Luồng chính

1. `notification` module lắng nghe domain event liên quan (được nhắc tên, được
   gán issue, issue mình theo dõi có bình luận mới, bước chuyển trạng thái…)
2. Tạo một thông báo trong trung tâm thông báo, tăng số chưa đọc
3. Đánh dấu đã đọc từng thông báo hoặc đánh dấu tất cả

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-COL-09/NT-01 | Cùng một sự kiện được relay worker gửi lại (delivery ít nhất một lần) | **Không tạo thông báo trùng** — chống trùng theo `(consumer, event_id)`, đúng CON-23 |
| UC-COL-09/NT-02 | Sự kiện tới nhưng người nhận đã mất quyền xem issue trước khi thông báo được tạo | Không tạo thông báo — kiểm tra lại quyền tại thời điểm xử lý, không tin vào quyền tại thời điểm sự kiện phát ra |

### Hậu điều kiện

Thông báo tồn tại trong trung tâm thông báo của người nhận, ở trạng thái chưa
đọc; số chưa đọc tăng tương ứng.

### Ảnh hưởng tới đồng bộ

Thông báo là một sync scope riêng theo từng member, không thuộc scope project —
một người rời project vẫn giữ thông báo cũ.

---

## UC-COL-10 — Thông báo email có gom nhóm

**Requirement:** FR-COL-13
**Actor:** thành viên nhận thông báo qua email
**Tiền điều kiện:** không có

### Luồng chính

1. Thay vì gửi một email cho mỗi sự kiện, hệ thống **gom nhóm** các thông báo
   phát sinh trong một khoảng thời gian ngắn thành một email
2. Email gửi qua bảng chuyển tiếp, cùng cơ chế outbox đã dùng cho email đăng nhập
   ở [uc-01-auth](uc-01-auth.md)

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-COL-10/NT-01 | Sự kiện được xử lý lại do relay worker retry | **Không gửi email trùng** — đây là rủi ro lớn nhất của phase, bắt buộc có test chống trùng riêng cho consumer gửi email |
| UC-COL-10/NT-02 | Người dùng đã đọc thông báo trong ứng dụng trước khi email gom nhóm được gửi | Vẫn gửi email theo lịch gom nhóm đã định, không huỷ giữa chừng — tránh thêm một điều kiện đua khác |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-COL-10/NL-01 | Không gửi được email (dịch vụ gửi thư lỗi) | Ghi nhật ký, cảnh báo vận hành, không chặn các thông báo trong ứng dụng khác |

### Hậu điều kiện

Email gom nhóm đã được xếp vào hàng chờ gửi (hoặc gửi thành công), chứa đúng
một lần cho mỗi thông báo phát sinh trong khoảng gom nhóm.

### Ảnh hưởng tới đồng bộ

Không áp dụng trực tiếp tới client — email đi qua bảng chuyển tiếp, không phải
một delta trên sync scope. Trạng thái đã đọc trong ứng dụng vẫn theo UC-COL-09.

---

## UC-COL-11 — Cấu hình thông báo theo project và cá nhân

**Requirement:** FR-COL-14, FR-COL-15
**Actor:** thành viên
**Tiền điều kiện:** không có

### Luồng chính

1. Quản trị viên project đặt cấu hình thông báo mặc định theo loại sự kiện, áp
   dụng cho project đó
2. Từng thành viên ghi đè cấu hình cho riêng mình (tắt bớt loại sự kiện muốn nhận)
3. Huỷ nhận thông báo qua email bằng liên kết huỷ nhận ngay trong email, không
   cần đăng nhập

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-COL-11/NT-01 | Cấu hình cá nhân xung đột với cấu hình mặc định của project | Cấu hình cá nhân luôn thắng |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-COL-11/NL-01 | Huỷ nhận qua liên kết trong email hết hạn hoặc đã dùng | Yêu cầu vào ứng dụng và đổi cấu hình từ trang thông báo |

### Hậu điều kiện

Cấu hình thông báo (mặc định của project hoặc ghi đè cá nhân) phản ánh lựa chọn
mới nhất; lần phát thông báo kế tiếp áp dụng cấu hình này.

### Ảnh hưởng tới đồng bộ

Cấu hình thông báo cá nhân thuộc dữ liệu riêng của người dùng, đồng bộ qua scope
workspace cùng hồ sơ thành viên; cấu hình mặc định của project thuộc scope
project.

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-COL-01 | Bình luận và đính kèm là aggregate riêng, tham chiếu issue bằng id, không nằm trong aggregate Issue |
| QT-COL-02 | Sửa bình luận giữ lại lịch sử; xoá bình luận là ẩn nội dung, không xoá vị trí trong luồng |
| QT-COL-03 | Bình luận có giới hạn người xem phải được lọc ở tầng dựng truy vấn, không lọc sau ở client |
| QT-COL-04 | Tệp đính kèm lưu ở kho lưu trữ đối tượng; cơ sở dữ liệu chỉ giữ siêu dữ liệu |
| QT-COL-05 | Upload và download tệp đi qua liên kết có chữ ký; tệp không bao giờ đi qua backend |
| QT-COL-06 | Mọi consumer của sự kiện (activity, notification) phải chống trùng theo `(consumer, event_id)` |
| QT-COL-07 | Thông báo email phải gom nhóm và không được gửi trùng khi sự kiện được xử lý lại |
| QT-COL-08 | Cấu hình thông báo cá nhân luôn ghi đè cấu hình mặc định của project |
| QT-COL-09 | Người tạo issue và người bình luận tự động theo dõi issue đó |

## Yêu cầu phi chức năng liên quan

`NFR-17` mọi consumer phải chống trùng vì delivery ít nhất một lần · `NFR-27`
giới hạn dung lượng tệp và điểm móc quét mã độc · `NFR-11` bảng chỉ ghi thêm
(activity) cần partition · `NFR-01` optimistic mutation cho bình luận
