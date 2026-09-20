# UC-AUTH — Đăng nhập và phiên làm việc

Kaiju chỉ có một phương thức xác thực: magic link. Cùng một luồng phục vụ cả đăng
ký lẫn đăng nhập.

**Phase:** 1 · **Feature:** KJ-IDN-01 → KJ-IDN-11
**Liên quan:** [ADR-0009](../../adr/0009-magic-link-only.md) · [identity-and-permission.md](../../04-system-design/identity-and-permission.md) · [uc-03-member-invite.md](uc-03-member-invite.md)

---

## UC-AUTH-01 — Yêu cầu liên kết đăng nhập

**Actor:** bất kỳ ai, không cần đăng nhập
**Tiền điều kiện:** không có

### Luồng chính

1. Người dùng mở trang đăng nhập và nhập địa chỉ email
2. Hệ thống kiểm tra định dạng email
3. Hệ thống sinh một token ngẫu nhiên và một mã 6 số, lưu **bản băm** của cả hai,
   gắn với một định danh yêu cầu đại diện cho thiết bị đang dùng
4. Hệ thống vô hiệu mọi token chưa dùng của cùng email
5. Hệ thống xếp email vào hàng chờ gửi
6. Giao diện chuyển sang màn hình chờ, **hiển thị ô nhập mã 6 số**, và nêu rõ
   email đã được gửi tới địa chỉ nào

### Luồng thay thế

| Nhánh | Xử lý |
|---|---|
| Email chưa có tài khoản | **Vẫn gửi bình thường.** Tài khoản được tạo ở bước xác thực |
| Người dùng bấm gửi lại | Chờ hết khoảng đếm ngược rồi mới cho gửi; token cũ bị vô hiệu |
| Người dùng đã đăng nhập | Chuyển thẳng vào ứng dụng |

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Email sai định dạng | Báo lỗi tại chỗ, không gửi request |
| Vượt giới hạn tần suất theo email | **Vẫn trả về thành công** nhưng không gửi thêm email (QT-03) |
| Vượt giới hạn tần suất theo địa chỉ IP | Yêu cầu xác minh bổ sung trước khi tiếp tục |
| Không gửi được email | Ghi nhật ký và cảnh báo vận hành; người dùng thấy màn hình chờ bình thường, có nút gửi lại |

### Hậu điều kiện

Tồn tại một token còn hiệu lực gắn với email và định danh yêu cầu. Chưa có phiên
đăng nhập nào được tạo.

---

## UC-AUTH-02 — Xác thực bằng liên kết

**Actor:** người nhận email
**Tiền điều kiện:** có token còn hiệu lực

### Luồng chính

1. Người dùng bấm liên kết trong email
2. Hệ thống băm token và tra cứu
3. Hệ thống kiểm tra: còn hiệu lực, chưa dùng, và **định danh yêu cầu khớp với
   thiết bị hiện tại**
4. Nếu email chưa có tài khoản thì tạo tài khoản với email đã xác thực sẵn
5. Đánh dấu token đã dùng
6. Cấp phiên đăng nhập: token truy cập ngắn hạn và token làm mới
7. Điều hướng theo trạng thái người dùng (xem bảng dưới)

| Trạng thái người dùng | Điều hướng tới |
|---|---|
| Tài khoản mới | Onboarding (UC-AUTH-05) |
| Có một workspace | Vào thẳng workspace đó |
| Có nhiều workspace | Workspace truy cập gần nhất |
| Không thuộc workspace nào | Màn hình tạo workspace |
| Có lời mời đang chờ | Màn hình xem lời mời |

### Luồng thay thế

| Nhánh | Xử lý |
|---|---|
| **Mở ở thiết bị khác thiết bị đã yêu cầu** | Không tự đăng nhập. Hiển thị màn hình yêu cầu nhập mã 6 số (UC-AUTH-03). Đây là biện pháp chống việc bị lừa chuyển tiếp email (QT-05) |
| Người dùng đã đăng nhập bằng chính email đó | Đánh dấu token đã dùng, chuyển thẳng vào ứng dụng |
| Người dùng đang đăng nhập bằng email **khác** | Hỏi rõ: tiếp tục với tài khoản hiện tại, hay đăng xuất và đăng nhập bằng email trong liên kết |

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Token không tồn tại | Trang lỗi chung, kèm nút yêu cầu liên kết mới. **Không** tiết lộ lý do cụ thể |
| Token hết hạn | Báo rõ là đã hết hạn, kèm nút gửi lại |
| Token đã dùng | Báo rõ là đã được sử dụng, kèm nút gửi lại |
| Tài khoản bị khoá | Báo tài khoản không truy cập được, kèm hướng liên hệ |

---

## UC-AUTH-03 — Xác thực bằng mã 6 số

**Actor:** người nhận email
**Tiền điều kiện:** đang ở màn hình chờ hoặc vừa mở liên kết ở thiết bị khác

### Luồng chính

1. Người dùng nhập mã 6 số từ email
2. Hệ thống kiểm tra mã theo **định danh yêu cầu của thiết bị hiện tại**
3. Từ đây giống UC-AUTH-02 từ bước 4

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Mã sai | Báo lỗi, cho thử lại, **đếm số lần sai** |
| Sai quá số lần cho phép | Vô hiệu token, bắt yêu cầu liên kết mới |
| Mã hết hạn | Báo rõ, kèm nút gửi lại |

### Vì sao nhánh này bắt buộc phải có

Người dùng thường mở hộp thư trên điện thoại trong khi đang đăng nhập trên máy
tính. Nếu chỉ có liên kết thì họ đăng nhập được trên điện thoại chứ không phải
trên thiết bị đang cần. Đây không phải tính năng phụ mà là điều kiện để luồng
đăng nhập dùng được trong thực tế.

---

## UC-AUTH-04 — Duy trì và làm mới phiên

**Actor:** người dùng đã đăng nhập

### Luồng chính

1. Sync engine giữ token truy cập trong bộ nhớ và đính kèm vào mọi request
2. Token sắp hết hạn thì tự đổi lấy token mới bằng token làm mới
3. Hệ thống **xoay vòng** token làm mới và cập nhật thời điểm truy cập của phiên

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Token làm mới hết hạn | Đăng xuất, giữ lại đường dẫn đang xem để quay lại sau khi đăng nhập |
| Token làm mới đã bị thu hồi | Đăng xuất ngay |
| **Phát hiện dùng lại token làm mới đã xoay vòng** | **Thu hồi toàn bộ phiên của tài khoản** và bắt đăng nhập lại — dấu hiệu token đã bị đánh cắp (QT-07) |

### Ảnh hưởng tới đồng bộ

Luồng đồng bộ đang mở phải dùng token mới ngay khi làm mới, nếu không nó sẽ bị
ngắt khi token cũ hết hạn.

---

## UC-AUTH-05 — Onboarding tài khoản mới

**Actor:** người vừa tạo tài khoản

### Luồng chính

1. Hệ thống hỏi tên hiển thị, điền sẵn phần trước ký hiệu `@` của email
2. Hệ thống hỏi tên workspace muốn tạo
3. Hệ thống sinh slug từ tên, cho phép sửa, kiểm tra trùng ngay khi gõ
4. Tạo workspace và tạo hồ sơ thành viên với vai trò chủ sở hữu
5. Vào workspace vừa tạo

### Luồng thay thế

| Nhánh | Xử lý |
|---|---|
| Đến từ một lời mời | **Bỏ qua bước tạo workspace**, vào thẳng workspace được mời (xem [uc-member-invite](uc-03-member-invite.md)) |
| Có lời mời đang chờ cho email này | Hiển thị danh sách lời mời trước, cho chọn chấp nhận hoặc tạo workspace mới |

### Vì sao hỏi tên workspace thay vì tự đặt

Tự đặt theo kiểu ghép tên người dùng thì đa số sẽ để nguyên, và sau này muốn đổi
slug lại vướng chuyện giữ đường dẫn cũ.

---

## UC-AUTH-06 — Quản lý phiên đăng nhập

**Actor:** người dùng đã đăng nhập

### Luồng chính

1. Người dùng mở trang bảo mật của tài khoản
2. Hệ thống hiển thị danh sách phiên: thiết bị, địa chỉ IP, lần truy cập gần
   nhất, và đánh dấu phiên hiện tại
3. Người dùng thu hồi một phiên hoặc toàn bộ phiên khác
4. Phiên bị thu hồi mất hiệu lực **ngay**, kể cả khi đang mở ứng dụng

### Ảnh hưởng tới đồng bộ

Thu hồi phiên phải đóng luồng đồng bộ của phiên đó. Client nhận biết là bị đăng
xuất và **xoá dữ liệu cục bộ** — nếu không, dữ liệu vẫn nằm lại trên thiết bị mà
người dùng vừa cố tình thu hồi quyền truy cập.

---

## UC-AUTH-07 — Đăng xuất

### Luồng chính

1. Người dùng chọn đăng xuất
2. Hệ thống thu hồi phiên hiện tại
3. Client **xoá toàn bộ dữ liệu cục bộ** và đóng luồng đồng bộ
4. Chuyển về trang đăng nhập

Bước 3 là bắt buộc. Với local-first, đăng xuất mà để lại dữ liệu trên máy là một
lỗi bảo mật, đặc biệt trên máy dùng chung.

---

## UC-AUTH-08 — Xoá tài khoản

**Actor:** chủ sở hữu tài khoản

### Luồng chính

1. Người dùng yêu cầu xoá tài khoản
2. Hệ thống cảnh báo hệ quả và yêu cầu xác nhận bằng cách gõ lại email
3. Hệ thống kiểm tra các workspace mà người này là chủ sở hữu **duy nhất**
4. Đánh dấu tài khoản đã xoá, thu hồi mọi phiên
5. Các hồ sơ thành viên ở mọi workspace chuyển sang vô hiệu và mất liên kết tới
   tài khoản; tên hiển thị được ẩn danh hoá
6. **Dữ liệu nghiệp vụ được giữ nguyên**: issue họ tạo, bình luận họ viết vẫn còn

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Là chủ sở hữu duy nhất của một workspace | Chặn, yêu cầu chuyển quyền sở hữu hoặc xoá workspace trước (QT-08) |

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-01 | Không có mật khẩu ở bất kỳ đâu trong hệ thống |
| QT-02 | Token chỉ lưu dưới dạng băm, dùng một lần, thời hạn khoảng mười phút |
| QT-03 | Hệ thống không bao giờ tiết lộ một email đã có tài khoản hay chưa |
| QT-04 | Dùng một token thì mọi token chưa dùng của cùng email bị vô hiệu |
| QT-05 | Mở liên kết ở thiết bị khác thiết bị đã yêu cầu thì bắt buộc nhập mã 6 số |
| QT-06 | Token truy cập chỉ mang danh tính, **không mang danh sách quyền** |
| QT-07 | Dùng lại token làm mới đã xoay vòng thì thu hồi toàn bộ phiên của tài khoản |
| QT-08 | Một workspace luôn phải có ít nhất một chủ sở hữu |
| QT-09 | Đăng xuất hoặc bị thu hồi phiên thì client phải xoá dữ liệu cục bộ |
| QT-10 | Email đăng nhập được gửi qua bảng chuyển tiếp, không gửi trực tiếp trong request |

## Yêu cầu phi chức năng liên quan

`NFR-23` token lưu dạng băm · `NFR-24` giới hạn tần suất · `NFR-25` token không
mang quyền · `NFR-26` nhật ký kiểm toán · `NFR-47` gửi email là thành phần quan trọng
