# UC-WSP — Workspace

Workspace là đơn vị tenancy của Kaiju. Một người tham gia nhiều workspace, và hồ
sơ của họ ở mỗi nơi là độc lập.

**Phase:** 1 · **Feature:** KJ-WSP-01 → KJ-WSP-03, KJ-WSP-12 → KJ-WSP-14, KJ-WSP-21
**Liên quan:** [ADR-0011](../../adr/0011-account-vs-member.md) · [ADR-0012](../../adr/0012-shared-schema-tenancy-rls.md) · [uc-03-member-invite.md](uc-03-member-invite.md) · [uc-04-project.md](uc-04-project.md)

---

## UC-WSP-01 — Tạo workspace

**Actor:** người dùng đã đăng nhập
**Tiền điều kiện:** không có — ai cũng tạo được, không giới hạn số lượng

### Luồng chính

1. Người dùng chọn tạo workspace mới
2. Nhập tên workspace
3. Hệ thống sinh slug từ tên và kiểm tra trùng ngay khi gõ; người dùng sửa được
4. Hệ thống tạo workspace và tạo hồ sơ thành viên cho người tạo với vai trò chủ sở hữu
5. Tên hiển thị của hồ sơ được **điền sẵn** từ thông tin mặc định của tài khoản
6. Vào workspace vừa tạo

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Slug đã tồn tại | Báo ngay khi gõ, gợi ý slug thay thế |
| Slug chứa ký tự không hợp lệ | Tự chuẩn hoá, hiển thị kết quả cho người dùng thấy |
| Slug trùng với từ khoá hệ thống | Từ chối, kèm danh sách từ bị cấm (QT-02) |

### Hậu điều kiện

Workspace tồn tại với đúng một thành viên là chủ sở hữu. Client đăng ký scope
workspace mới.

---

## UC-WSP-02 — Chuyển đổi giữa các workspace

**Actor:** thành viên của ít nhất hai workspace

### Luồng chính

1. Người dùng mở bộ chọn workspace
2. Hệ thống hiển thị danh sách workspace kèm vai trò của người dùng ở mỗi nơi
3. Chọn một workspace → chuyển ngay, **không phải đăng nhập lại**
4. Giao diện hiển thị ngay từ dữ liệu cục bộ nếu scope đó đã được đồng bộ

### Ảnh hưởng tới đồng bộ

Danh sách workspace nằm trong dữ liệu cục bộ nên bộ chọn hoạt động cả khi offline.
Scope workspace của mọi workspace người dùng thuộc về được giữ thường trực vì
chúng nhẹ; scope project chỉ đăng ký khi mở.

---

## UC-WSP-03 — Hồ sơ thành viên trong workspace

**Actor:** thành viên

### Luồng chính

1. Người dùng mở trang hồ sơ trong workspace hiện tại
2. Sửa tên hiển thị, avatar, múi giờ, ngôn ngữ, tuỳ chọn thông báo
3. Thay đổi chỉ áp dụng **cho workspace này**

### Luồng thay thế

| Nhánh | Xử lý |
|---|---|
| Muốn áp dụng cho mọi workspace | Nút tường minh "áp dụng cho tất cả", ghi vào **từng** workspace, không phải một tham chiếu chung |
| Sửa thông tin mặc định của tài khoản | Chỉ ảnh hưởng tới các hồ sơ **tạo mới sau này**, không lan sang hồ sơ đang có (QT-03) |

### Vì sao tách như vậy

Giữ mọi thao tác đọc nằm gọn trong một tenant là điều kiện để phân mảnh dữ liệu
về sau. Nếu hiển thị tên phải đọc từ vùng dữ liệu toàn cục thì mỗi lần hiển thị
một issue là một lần đọc xuyên vùng.

### Ảnh hưởng tới đồng bộ

Đổi tên hiển thị phát delta trên scope workspace. Mọi client đang mở workspace đó
cập nhật danh bạ thành viên, nên tên mới xuất hiện ngay ở mọi chỗ đang hiển thị
người này.

---

## UC-WSP-04 — Cấu hình workspace

**Actor:** thành viên có quyền quản trị

### Luồng chính

1. Mở trang cấu hình
2. Sửa tên, avatar, slug, và các tuỳ chọn mặc định của workspace
3. Lưu

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Đổi slug | Cảnh báo đường dẫn cũ sẽ không còn dùng được; yêu cầu xác nhận |
| Không đủ quyền | Trang cấu hình ở chế độ chỉ đọc, không phải báo lỗi sau khi bấm lưu |

---

## UC-WSP-05 — Rời workspace

**Actor:** thành viên

### Luồng chính

1. Người dùng chọn rời workspace
2. Hệ thống cảnh báo sẽ mất quyền truy cập
3. Xác nhận → hồ sơ thành viên chuyển sang vô hiệu, **không bị xoá**
4. Client **xoá dữ liệu cục bộ** của workspace đó và mọi project bên trong
5. Chuyển sang workspace khác, hoặc màn hình tạo workspace nếu không còn nơi nào

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Là chủ sở hữu duy nhất | Chặn, yêu cầu chuyển quyền sở hữu trước (QT-05) |
| Còn issue đang được gán | Cảnh báo kèm số lượng, cho phép tiếp tục — quản trị viên xử lý sau |

### Vì sao không xoá cứng hồ sơ

Issue người này tạo và bình luận họ viết vẫn tham chiếu tới hồ sơ. Xoá cứng là
làm vỡ toàn bộ lịch sử. Giao diện hiển thị họ kèm chú thích đã rời đi.

---

## UC-WSP-06 — Chuyển quyền sở hữu

**Actor:** chủ sở hữu

### Luồng chính

1. Chọn một thành viên đang hoạt động để chuyển quyền
2. Hệ thống yêu cầu xác nhận, nêu rõ hệ quả
3. Người được chọn thành chủ sở hữu; người chuyển trở thành quản trị viên
4. Cả hai nhận được thông báo

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Người được chọn đang ở trạng thái chờ chấp nhận lời mời | Chặn — chỉ chuyển cho thành viên đã hoạt động (QT-06) |
| Người được chọn đã bị vô hiệu | Không xuất hiện trong danh sách chọn |

---

## UC-WSP-07 — Xoá workspace

**Actor:** chủ sở hữu

### Luồng chính

1. Chọn xoá workspace
2. Hệ thống cảnh báo rõ: toàn bộ project và issue sẽ bị xoá
3. Yêu cầu gõ lại slug để xác nhận
4. Workspace chuyển sang trạng thái **đã xoá mềm**, kèm thời hạn ân hạn
5. Mọi thành viên mất quyền truy cập ngay; client xoá dữ liệu cục bộ
6. Hết thời hạn ân hạn, một tác vụ định kỳ xoá vĩnh viễn

### Luồng thay thế

| Nhánh | Xử lý |
|---|---|
| Khôi phục trong thời hạn ân hạn | Chủ sở hữu khôi phục được; thành viên lấy lại quyền và đồng bộ lại từ đầu |

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Gõ sai slug xác nhận | Không cho tiếp tục |
| Không phải chủ sở hữu | Không hiển thị chức năng này |

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-01 | Ai cũng tạo được workspace, không giới hạn số lượng |
| QT-02 | Slug duy nhất toàn hệ thống, không được trùng từ khoá hệ thống |
| QT-03 | Hồ sơ trong mỗi workspace là độc lập; sửa nơi này không lan sang nơi khác |
| QT-04 | Mọi dữ liệu nghiệp vụ thuộc về đúng một workspace và không bao giờ đi xuyên workspace |
| QT-05 | Workspace luôn phải có ít nhất một chủ sở hữu đang hoạt động |
| QT-06 | Chỉ chuyển quyền sở hữu cho thành viên đã hoạt động |
| QT-07 | Rời hoặc bị xoá khỏi workspace thì hồ sơ bị vô hiệu chứ không bị xoá cứng |
| QT-08 | Xoá workspace là xoá mềm kèm thời hạn ân hạn |
| QT-09 | Mất quyền truy cập thì client phải xoá dữ liệu cục bộ của workspace đó |

## Yêu cầu phi chức năng liên quan

`NFR-20` không rò rỉ giữa các workspace · `NFR-21` ràng buộc ở tầng cơ sở dữ liệu
· `NFR-22` thu hồi quyền có hiệu lực ngay · `NFR-42` múi giờ theo hồ sơ workspace
