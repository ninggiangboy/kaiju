# UC-INV — Thành viên và lời mời

Mời được cả người đã có tài khoản lẫn người chưa có. Ý tưởng then chốt làm mọi
thứ gọn lại: **token lời mời chính là một magic link** — người bấm được liên kết
trong hộp thư của họ đã chứng minh sở hữu email đó.

**Phase:** 1 · **Feature:** KJ-WSP-04 → KJ-WSP-11, KJ-WSP-15, KJ-WSP-20
**Liên quan:** [ADR-0009](../../adr/0009-magic-link-only.md) · [ADR-0011](../../adr/0011-account-vs-member.md) · [uc-auth.md](uc-auth.md) · [identity-and-permission.md](../../04-system-design/identity-and-permission.md)

---

## UC-INV-01 — Gửi lời mời

**Actor:** thành viên có quyền mời
**Tiền điều kiện:** đang ở trong một workspace

### Luồng chính

1. Mở trang thành viên, chọn mời người mới
2. Nhập một hoặc nhiều email, phân tách bằng dấu phẩy hoặc xuống dòng
3. Chọn vai trò áp dụng cho lô này; nếu là vai trò khách thì chọn luôn project
   được phép truy cập
4. Nhập lời nhắn tuỳ chọn
5. Hệ thống kiểm tra từng email và **báo lỗi theo từng dòng**, không chặn cả lô
6. Với mỗi email hợp lệ, hệ thống:
   - Tạo **hồ sơ thành viên ở trạng thái chờ**, chưa gắn tài khoản
   - Tạo lời mời với token lưu dạng băm, thời hạn khoảng một tuần
   - Xếp email vào hàng chờ gửi
7. Danh sách thành viên hiển thị ngay những người vừa mời, đánh dấu là đang chờ

### Vì sao tạo hồ sơ ngay lúc mời

Nhờ đó quản trị viên **gán issue, thêm vào project và cấp quyền cho người chưa
chấp nhận lời mời**. Khi họ chấp nhận thì chỉ cần gắn tài khoản vào hồ sơ đã có —
không có bước chuyển giao dữ liệu nào.

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Email sai định dạng | Đánh dấu dòng đó, các dòng khác vẫn được gửi |
| Email đã là thành viên đang hoạt động | Bỏ qua, báo "đã là thành viên" |
| Email đã có lời mời đang chờ | Bỏ qua, gợi ý dùng chức năng gửi lại |
| Email thuộc thành viên đã bị vô hiệu | **Kích hoạt lại** hồ sơ cũ thay vì tạo mới, giữ nguyên mọi tham chiếu lịch sử (QT-05) |
| Vượt giới hạn số lời mời | Chặn cả lô, báo rõ thời điểm được gửi tiếp (QT-08) |
| Không đủ quyền mời | Không hiển thị chức năng này |

### Ảnh hưởng tới đồng bộ

Hồ sơ mới phát delta trên scope workspace. Mọi client đang mở workspace thấy
người mới trong danh bạ ngay, **và gán việc cho họ được ngay**.

---

## UC-INV-02 — Chấp nhận lời mời

**Actor:** người nhận email
**Tiền điều kiện:** có lời mời còn hiệu lực

Đây là use case nhiều nhánh nhất của Phase 1. Mỗi nhánh phải có test riêng.

### Bảng nhánh xử lý

| # | Tình huống | Xử lý |
|---|---|---|
| 1 | **Chưa có tài khoản** | Tạo tài khoản với email đã xác thực sẵn (token lời mời chính là bằng chứng sở hữu email) → hỏi tên hiển thị → gắn tài khoản vào hồ sơ đã tạo sẵn → vào workspace. **Không bắt đăng ký riêng rồi mới mời lại** |
| 2 | **Đã có tài khoản, đang đăng nhập đúng email** | Hiển thị màn hình xác nhận nêu rõ ai mời, workspace nào, vai trò gì → chấp nhận hoặc từ chối |
| 3 | **Đã có tài khoản nhưng chưa đăng nhập** | Token lời mời đồng thời cấp phiên đăng nhập → sang nhánh 2 |
| 4 | **Đang đăng nhập bằng email khác** | Cảnh báo rõ ràng, cho chọn: đăng xuất rồi đăng nhập bằng email được mời, hoặc bỏ qua. **Không** cho gắn lời mời vào tài khoản đang đăng nhập (QT-06) |
| 5 | **Đã là thành viên đang hoạt động** | Đánh dấu lời mời đã dùng, chuyển thẳng vào workspace. **Không báo lỗi** |

### Luồng chính (nhánh 1 và 2)

1. Người dùng bấm liên kết trong email mời
2. Hệ thống băm token và tra cứu, kiểm tra còn hiệu lực và chưa dùng
3. Xác định nhánh theo bảng trên
4. Gắn tài khoản vào hồ sơ thành viên, chuyển hồ sơ sang trạng thái hoạt động,
   ghi thời điểm tham gia
5. Đánh dấu lời mời đã chấp nhận, ghi lại ai chấp nhận
6. Tạo bản ghi ánh xạ giữa tài khoản và workspace
7. Vào workspace

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Token không tồn tại | Trang lỗi chung kèm nút yêu cầu mời lại |
| Token hết hạn | Báo rõ, nút gửi yêu cầu tới quản trị viên của workspace |
| Lời mời đã bị thu hồi | Báo rõ lời mời không còn hiệu lực |
| Lời mời đã được dùng | Nếu người dùng đã là thành viên thì chuyển vào workspace; nếu không thì báo lỗi |
| Workspace đã bị xoá | Báo workspace không còn tồn tại |
| Tài khoản bị khoá | Báo tài khoản không truy cập được |

### Ảnh hưởng tới đồng bộ

Người chấp nhận đăng ký scope workspace và bootstrap. Các thành viên khác nhận
delta cập nhật trạng thái của người này từ chờ sang hoạt động.

---

## UC-INV-03 — Quản lý lời mời đang chờ

**Actor:** thành viên có quyền mời

### Luồng chính

1. Trang thành viên hiển thị mục lời mời đang chờ: email, vai trò, người mời,
   thời điểm gửi, thời điểm hết hạn
2. Có thể tìm kiếm và lọc

### Gửi lại

1. Chọn gửi lại một lời mời
2. Hệ thống **sinh token mới và vô hiệu token cũ**
3. Gửi email mới, làm mới thời hạn
4. Áp dụng giới hạn tần suất riêng cho việc gửi lại

### Thu hồi

1. Chọn thu hồi
2. Lời mời chuyển sang trạng thái đã thu hồi, token mất hiệu lực
3. Hồ sơ thành viên đang chờ bị **xoá** nếu chưa từng gắn tài khoản
4. Nếu hồ sơ đó đã được gán issue thì cảnh báo trước và cho chọn gán lại cho người khác

Điểm cuối là hệ quả trực tiếp của việc tạo hồ sơ ngay lúc mời — tiện lợi đổi lấy
một nhánh xử lý phải nhớ.

---

## UC-INV-04 — Đổi vai trò của thành viên

**Actor:** thành viên có quyền quản trị

### Luồng chính

1. Chọn một thành viên và chọn vai trò mới
2. Hệ thống cập nhật vai trò và **xoá cache quyền** của người đó
3. Phát sự kiện thay đổi quyền

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Hạ cấp chủ sở hữu cuối cùng | Chặn (QT-03) |
| Tự hạ cấp chính mình | Cảnh báo rõ hệ quả, yêu cầu xác nhận |
| Hạ từ thành viên xuống khách | Cảnh báo sẽ mất quyền truy cập nhiều project |

### Ảnh hưởng tới đồng bộ

Đây là chỗ dễ sai nhất của toàn bộ Phase 1.

- Quyền **mở rộng** → client đăng ký thêm scope và bootstrap phần mới
- Quyền **thu hẹp** → phát sự kiện thu hồi cho từng scope không còn quyền; client
  **xoá dữ liệu cục bộ của các scope đó** và huỷ mọi mutation đang chờ thuộc về chúng

Thiếu nhánh thứ hai thì người bị hạ quyền vẫn giữ nguyên dữ liệu trên máy và giao
diện vẫn hiển thị bình thường cho tới khi họ tải lại trang.

---

## UC-INV-05 — Xoá thành viên

**Actor:** thành viên có quyền quản trị

### Luồng chính

1. Chọn xoá một thành viên
2. Hệ thống **thống kê công việc đang thuộc về người đó**: issue được gán, issue
   đang theo dõi, vai trò dẫn dắt project hoặc component
3. Hiển thị tuỳ chọn gán lại hàng loạt cho người khác
4. Xác nhận → hồ sơ chuyển sang vô hiệu, **không bị xoá**
5. Xoá cache quyền, phát sự kiện thu hồi
6. Client của người bị xoá xoá toàn bộ dữ liệu cục bộ của workspace

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Là chủ sở hữu duy nhất | Chặn, yêu cầu chuyển quyền trước |
| Là người dẫn dắt của project hoặc component | Cảnh báo, yêu cầu chọn người thay thế |
| Là thành viên đang chờ chấp nhận | Xoá thẳng hồ sơ nếu chưa có tham chiếu nào |

### Vì sao bước 3 là bắt buộc

Thiếu nó, sau vài lần xoá thành viên sẽ có hàng trăm issue gán cho người không
còn trong workspace, và không ai biết để xử lý.

---

## UC-INV-06 — Group thành viên

**Actor:** thành viên có quyền quản trị

### Luồng chính

1. Tạo group với tên và mô tả
2. Thêm hoặc bớt thành viên
3. Gán quyền cho group ở cấp workspace hoặc cấp project
4. Quyền hiệu lực của một người là hợp của quyền cá nhân và quyền từ mọi group

### Ảnh hưởng tới đồng bộ

Đổi thành viên của group có thể làm thay đổi quyền của nhiều người cùng lúc. Phải
xoá cache và phát sự kiện thu hồi **cho từng người bị ảnh hưởng**, không chỉ cho
người thực hiện thao tác.

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-01 | Token lời mời chính là một magic link; không cần thêm bước xác thực email |
| QT-02 | Hồ sơ thành viên được tạo **ngay lúc mời**, ở trạng thái chờ |
| QT-03 | Workspace luôn phải có ít nhất một chủ sở hữu đang hoạt động |
| QT-04 | Xoá thành viên là vô hiệu hoá hồ sơ, không xoá cứng |
| QT-05 | Mời lại một email đã bị vô hiệu thì kích hoạt hồ sơ cũ, không tạo hồ sơ mới |
| QT-06 | Lời mời chỉ chấp nhận được bằng đúng email được mời |
| QT-07 | Token lời mời dùng một lần, lưu dạng băm, thời hạn khoảng một tuần |
| QT-08 | Số lời mời gửi ra bị giới hạn theo khoảng thời gian |
| QT-09 | Mọi thay đổi quyền phải xoá cache và phát sự kiện thu hồi cho người bị ảnh hưởng |
| QT-10 | Vai trò khách chỉ thấy project được mời đích danh và không thấy danh bạ thành viên |

## Yêu cầu phi chức năng liên quan

`NFR-22` thu hồi quyền có hiệu lực ngay · `NFR-23` token lưu dạng băm · `NFR-24`
giới hạn tần suất · `NFR-26` nhật ký kiểm toán cho thay đổi quyền
