# UC-COL — Collaboration

Làm việc cùng nhau trên issue, và hệ thống thông báo đầy đủ. Bình luận và đính
kèm thuộc module `issue` (chúng gắn trực tiếp vào issue); dòng hoạt động thuộc
module `activity`; thông báo thuộc module `notification`. Ba module này giao
tiếp với `issue` **chỉ qua domain event**, không truy vấn thẳng bảng của nhau.

**Phase:** 4 · **Feature:** KJ-COL-01 → KJ-COL-16
**Liên quan:** [uc-05-issue.md](uc-05-issue.md) · [backend-modules.md](../../04-system-design/backend-modules.md) · [events-and-outbox.md](../../04-system-design/events-and-outbox.md) · [roadmap.md — Phase 4](../roadmap.md)

---

## UC-COL-01 — Bình luận và lịch sử sửa

**Actor:** thành viên có quyền bình luận trên issue
**Tiền điều kiện:** đang xem một issue

### Luồng chính

1. Soạn bình luận bằng trình soạn thảo rich text, tương tự mô tả issue
2. Gửi bình luận → hiện ngay trên giao diện, xuất hiện trong dòng hoạt động
3. Sửa bình luận của chính mình → bản cũ được giữ lại trong lịch sử chỉnh sửa,
   hiển thị nhãn "đã chỉnh sửa" kèm thời điểm
4. Xoá bình luận của chính mình → nội dung ẩn đi, vị trí trong luồng vẫn giữ

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Sửa hoặc xoá bình luận của người khác | Chặn, trừ khi có quyền quản trị bình luận |
| Sửa bình luận trên issue đã bị xoá mềm | Chặn |
| Bình luận rỗng sau khi xoá định dạng | Không cho gửi |

### Hậu điều kiện

Bình luận tồn tại là một aggregate riêng, tham chiếu tới issue bằng id — không
nằm trong aggregate `Issue`.

---

## UC-COL-02 — Nhắc tên và trả lời theo luồng

**Actor:** thành viên có quyền bình luận

### Luồng chính

1. Gõ `@` trong bình luận, chọn một thành viên hoặc một group từ danh bạ workspace
2. Người/group được nhắc nhận thông báo (xem UC-COL-09)
3. Trả lời một bình luận cụ thể → bình luận mới hiển thị lồng dưới bình luận gốc

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Nhắc tên một người không có quyền xem issue (ví dụ do giới hạn người xem bình luận, UC-COL-03) | Vẫn cho nhắc trong nội dung, nhưng **không gửi thông báo** cho người không có quyền xem |
| Nhắc tên một group | Gửi thông báo cho **từng thành viên đang hoạt động** của group tại thời điểm gửi, không theo dõi thành viên gia nhập group sau đó |
| Trả lời một bình luận đã bị xoá | Cho phép — bình luận gốc hiển thị "bình luận đã bị xoá" |

---

## UC-COL-03 — Giới hạn người xem bình luận

**Actor:** thành viên có quyền bình luận

### Luồng chính

1. Khi soạn bình luận, chọn giới hạn người xem theo vai trò hoặc theo một group cụ thể
2. Bình luận chỉ hiển thị cho người thoả điều kiện đó, kể cả người có quyền xem
   issue nói chung

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Người xem không thoả điều kiện giới hạn | Không thấy bình luận trong dòng hoạt động, không thấy trong đếm số bình luận |
| Người bị giới hạn sau này được thêm vào group thoả điều kiện | Thấy được bình luận cũ, không hồi tố ẩn/hiện theo thời điểm gửi |

### Ảnh hưởng tới đồng bộ

Bình luận có giới hạn người xem không được đẩy vào delta của những client không
thoả điều kiện — lọc ở tầng dựng truy vấn trước khi phát delta, không lọc sau ở
client. Cùng nguyên tắc với lọc quyền theo QT ở uc-04-project.

---

## UC-COL-04 — Biểu tượng cảm xúc

**Actor:** thành viên có quyền xem issue

### Luồng chính

1. Thả một biểu tượng cảm xúc lên bình luận
2. Số lượng và danh sách người thả hiển thị cạnh bình luận
3. Bỏ biểu tượng đã thả

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Thả cùng một biểu tượng hai lần | Lần thứ hai bỏ biểu tượng đó thay vì thả thêm (toggle) |

---

## UC-COL-05 — Dòng hoạt động

**Actor:** thành viên có quyền xem issue

### Luồng chính

1. Dòng hoạt động gộp: bình luận, thay đổi trường (nhật ký thay đổi từ
   [uc-05-issue](uc-05-issue.md)), và nhật ký công việc (phase sau)
2. Sắp xếp theo thời gian, lọc được theo loại nguồn
3. Mỗi nguồn phát tới `activity` module qua domain event của module gốc
   (`issue.field_changed`, `issue.commented`…) — `activity` **không** đọc bảng
   của `issue`

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Nhiều sự kiện xảy ra trong cùng một giây từ nhiều nguồn | Sắp xếp theo thời điểm sự kiện xảy ra ở nguồn, không theo thời điểm `activity` nhận được — vì delivery ít nhất một lần có thể tới lệch thứ tự |
| Sự kiện bị xử lý lại (retry của relay worker) | Không tạo dòng hoạt động trùng — `activity` chống trùng theo `(consumer, event_id)` |

---

## UC-COL-06 — Theo dõi và bình chọn

**Actor:** thành viên có quyền xem issue

### Luồng chính

1. Người tạo issue và người bình luận **tự động** trở thành người theo dõi
2. Thêm hoặc bớt theo dõi thủ công bất cứ lúc nào
3. Bình chọn cho issue; số phiếu hiển thị, danh sách người bình chọn chỉ người có
   quyền quản trị project thấy được

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Tự bớt theo dõi issue mình vừa tạo | Cho phép — tự động theo dõi chỉ là giá trị khởi tạo, không ràng buộc |
| Bình chọn hai lần | Lần thứ hai bỏ phiếu thay vì cộng thêm (toggle, giống UC-COL-04) |

---

## UC-COL-07 — Đính kèm tệp

**Actor:** thành viên có quyền sửa issue

### Luồng chính

1. Chọn hoặc kéo thả tệp vào issue
2. Client yêu cầu một **liên kết tải lên có chữ ký** từ server, tải trực tiếp lên
   kho lưu trữ đối tượng — tệp **không đi qua backend**
3. Server chỉ lưu siêu dữ liệu (tên, dung lượng, kiểu, người tải lên)
4. Xem trước ảnh và PDF ngay trong issue; tải về bằng liên kết tải xuống có chữ ký

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Tệp vượt giới hạn dung lượng | Từ chối cấp liên kết tải lên |
| Tệp bị điểm móc quét mã độc đánh dấu độc hại (chạy nền sau khi tải lên) | Ẩn tệp khỏi issue, đánh dấu "đã bị chặn", ghi nhật ký |
| Tải về từ workspace khác (đoán URL) | Liên kết tải xuống có chữ ký và thời hạn ngắn; hết hạn thì phải xin lại, server kiểm tra quyền trước khi cấp |
| Xoá tệp đính kèm | Xoá siêu dữ liệu ngay; tệp vật lý dọn bởi tác vụ nền, không đồng bộ trong request xoá |

### Ảnh hưởng tới đồng bộ

Chỉ siêu dữ liệu đính kèm đi qua sync scope của project; nội dung tệp không bao
giờ nằm trong delta hay trong bản cục bộ của client.

---

## UC-COL-08 — Đính kèm trong bình luận

**Actor:** thành viên có quyền bình luận

### Luồng chính

1. Kéo thả hoặc chọn tệp ngay trong khung soạn bình luận
2. Tệp dùng lại đúng cơ chế tải lên có chữ ký của UC-COL-07, chỉ khác chỗ gắn
   (bình luận thay vì issue)

### Ngoại lệ

Kế thừa toàn bộ bảng ngoại lệ của UC-COL-07.

---

## UC-COL-09 — Thông báo trong ứng dụng

**Actor:** thành viên nhận thông báo

### Luồng chính

1. `notification` module lắng nghe domain event liên quan (được nhắc tên, được
   gán issue, issue mình theo dõi có bình luận mới, bước chuyển trạng thái…)
2. Tạo một thông báo trong trung tâm thông báo, tăng số chưa đọc
3. Đánh dấu đã đọc từng thông báo hoặc đánh dấu tất cả

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Cùng một sự kiện được relay worker gửi lại (delivery ít nhất một lần) | **Không tạo thông báo trùng** — chống trùng theo `(consumer, event_id)`, đúng CON-23 |
| Sự kiện tới nhưng người nhận đã mất quyền xem issue trước khi thông báo được tạo | Không tạo thông báo — kiểm tra lại quyền tại thời điểm xử lý, không tin vào quyền tại thời điểm sự kiện phát ra |

### Ảnh hưởng tới đồng bộ

Thông báo là một sync scope riêng theo từng member, không thuộc scope project —
một người rời project vẫn giữ thông báo cũ.

---

## UC-COL-10 — Thông báo email có gom nhóm

**Actor:** thành viên nhận thông báo qua email

### Luồng chính

1. Thay vì gửi một email cho mỗi sự kiện, hệ thống **gom nhóm** các thông báo
   phát sinh trong một khoảng thời gian ngắn thành một email
2. Email gửi qua bảng chuyển tiếp, cùng cơ chế outbox đã dùng cho email đăng nhập
   ở [uc-01-auth](uc-01-auth.md)

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Sự kiện được xử lý lại do relay worker retry | **Không gửi email trùng** — đây là rủi ro lớn nhất của phase, bắt buộc có test chống trùng riêng cho consumer gửi email |
| Người dùng đã đọc thông báo trong ứng dụng trước khi email gom nhóm được gửi | Vẫn gửi email theo lịch gom nhóm đã định, không huỷ giữa chừng — tránh thêm một điều kiện đua khác |
| Không gửi được email (dịch vụ gửi thư lỗi) | Ghi nhật ký, cảnh báo vận hành, không chặn các thông báo trong ứng dụng khác |

---

## UC-COL-11 — Cấu hình thông báo theo project và cá nhân

**Actor:** thành viên

### Luồng chính

1. Quản trị viên project đặt cấu hình thông báo mặc định theo loại sự kiện, áp
   dụng cho project đó
2. Từng thành viên ghi đè cấu hình cho riêng mình (tắt bớt loại sự kiện muốn nhận)
3. Huỷ nhận thông báo qua email bằng liên kết huỷ nhận ngay trong email, không
   cần đăng nhập

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Huỷ nhận qua liên kết trong email hết hạn hoặc đã dùng | Yêu cầu vào ứng dụng và đổi cấu hình từ trang thông báo |
| Cấu hình cá nhân xung đột với cấu hình mặc định của project | Cấu hình cá nhân luôn thắng |

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-01 | Bình luận và đính kèm là aggregate riêng, tham chiếu issue bằng id, không nằm trong aggregate Issue |
| QT-02 | Sửa bình luận giữ lại lịch sử; xoá bình luận là ẩn nội dung, không xoá vị trí trong luồng |
| QT-03 | Bình luận có giới hạn người xem phải được lọc ở tầng dựng truy vấn, không lọc sau ở client |
| QT-04 | Tệp đính kèm lưu ở kho lưu trữ đối tượng; cơ sở dữ liệu chỉ giữ siêu dữ liệu |
| QT-05 | Upload và download tệp đi qua liên kết có chữ ký; tệp không bao giờ đi qua backend |
| QT-06 | Mọi consumer của sự kiện (activity, notification) phải chống trùng theo `(consumer, event_id)` |
| QT-07 | Thông báo email phải gom nhóm và không được gửi trùng khi sự kiện được xử lý lại |
| QT-08 | Cấu hình thông báo cá nhân luôn ghi đè cấu hình mặc định của project |
| QT-09 | Người tạo issue và người bình luận tự động theo dõi issue đó |

## Yêu cầu phi chức năng liên quan

`NFR-17` mọi consumer phải chống trùng vì delivery ít nhất một lần · `NFR-27`
giới hạn dung lượng tệp và điểm móc quét mã độc · `NFR-11` bảng chỉ ghi thêm
(activity) cần partition · `NFR-01` optimistic mutation cho bình luận
