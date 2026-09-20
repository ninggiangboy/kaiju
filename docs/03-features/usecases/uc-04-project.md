# UC-PRJ — Project

Project là ranh giới tổ chức công việc bên trong workspace, và đồng thời là sync
scope thứ hai. Key của project là thứ sinh ra mã issue.

**Phase:** 2 · **Feature:** KJ-PRJ-01 → KJ-PRJ-12
**Liên quan:** [uc-02-workspace.md](uc-02-workspace.md) · [uc-03-member-invite.md](uc-03-member-invite.md) · [realtime-and-sync.md](../../04-system-design/realtime-and-sync.md)

---

## UC-PRJ-01 — Tạo project

**Actor:** thành viên có quyền tạo project
**Tiền điều kiện:** đang ở trong một workspace

### Luồng chính

1. Chọn tạo project mới
2. Nhập tên project
3. Hệ thống **đề xuất key** từ tên (viết hoa, lấy các chữ cái đầu), cho phép sửa
4. Kiểm tra key trùng ngay khi gõ, trong phạm vi workspace
5. Chọn loại project, quyết định tính năng nào được bật
6. Chọn mức hiển thị: mọi thành viên workspace, hoặc chỉ người được mời
7. Hệ thống tạo project, đặt người tạo làm người dẫn dắt và thành viên đầu tiên
8. Vào project vừa tạo

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Key đã tồn tại **trong workspace này** | Báo ngay khi gõ, gợi ý key thay thế |
| Key đã tồn tại ở workspace khác | **Chấp nhận bình thường** — key chỉ duy nhất trong workspace (QT-01) |
| Key sai định dạng | Tự chuẩn hoá về chữ hoa, loại ký tự không hợp lệ, hiển thị kết quả |
| Key trùng từ khoá hệ thống | Từ chối kèm danh sách từ bị cấm |
| Không đủ quyền | Không hiển thị chức năng này |

### Hậu điều kiện

Project tồn tại với một thành viên. Sync scope mới được tạo; client của những
người có quyền thấy project trong danh sách ngay.

---

## UC-PRJ-02 — Quản lý key

**Actor:** thành viên có quyền quản trị project

### Luồng chính

1. Mở cấu hình project, sửa key
2. Hệ thống cảnh báo: mã issue sẽ đổi, đường dẫn cũ vẫn hoạt động
3. Xác nhận → đổi key, **lưu key cũ vào lịch sử**
4. Mọi issue hiển thị theo key mới
5. Đường dẫn và mã issue theo key cũ **vẫn truy cập được**, chuyển hướng sang mã mới

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Key mới trùng key đang dùng của project khác | Từ chối |
| Key mới trùng key **cũ** của project khác | Từ chối — nếu không, mã issue lịch sử sẽ trỏ nhầm chỗ (QT-02) |

### Ảnh hưởng tới đồng bộ

Đổi key làm thay đổi mã hiển thị của **mọi** issue trong project. Không phát delta
cho từng issue; thay vào đó phát một delta trên chính project và client tự tính
lại mã hiển thị từ key.

Đây là lý do mã issue nên được **tính từ key** ở phía client chứ không lưu sẵn
dạng chuỗi trong từng issue.

---

## UC-PRJ-03 — Mức hiển thị và thành viên project

**Actor:** thành viên có quyền quản trị project

### Hai mức hiển thị

| Mức | Ai thấy |
|---|---|
| Mở trong workspace | Mọi thành viên workspace, trừ khách |
| Chỉ người được mời | Chỉ những người được thêm đích danh vào project |

### Luồng chính

1. Mở trang thành viên của project
2. Thêm thành viên từ danh bạ workspace, chọn vai trò trong project
3. Hoặc mời email mới — lời mời này vừa vào workspace vừa vào project (xem
   [uc-member-invite](uc-03-member-invite.md))
4. Bớt thành viên khỏi project

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Đổi từ mở sang chỉ người được mời | Cảnh báo số người sắp mất quyền, yêu cầu xác nhận |
| Bớt người dẫn dắt project | Chặn, yêu cầu chọn người thay thế trước |
| Thêm một người đang ở trạng thái chờ chấp nhận lời mời | Cho phép — gán việc được ngay |

### Ảnh hưởng tới đồng bộ

- Thêm thành viên → client của người đó đăng ký scope project và bootstrap
- Bớt thành viên → phát sự kiện thu hồi; client **xoá dữ liệu cục bộ của project**
  và huỷ mutation đang chờ thuộc project đó
- Đổi mức hiển thị từ mở sang hạn chế → phát thu hồi **cho mọi người không có tên
  trong danh sách**, không chỉ cho một người

Nhánh cuối là chỗ dễ bỏ sót nhất: một thao tác cấu hình duy nhất có thể thu hồi
quyền của hàng chục người cùng lúc.

---

## UC-PRJ-04 — Component

**Actor:** thành viên có quyền quản trị project

### Luồng chính

1. Mở trang component
2. Tạo component với tên, mô tả, người phụ trách, người được gán mặc định
3. Sửa hoặc xoá component

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Xoá component đang được dùng | Cảnh báo kèm số lượng issue, cho chọn: bỏ gán, hoặc chuyển sang component khác |
| Người phụ trách rời workspace | Component giữ nguyên tham chiếu, giao diện hiển thị người đã rời đi |

---

## UC-PRJ-05 — Danh sách project

**Actor:** thành viên

### Luồng chính

1. Mở danh sách project của workspace hiện tại
2. Hệ thống hiển thị project người dùng **có quyền xem**
3. Tìm kiếm, lọc theo loại và trạng thái lưu trữ, sắp xếp
4. Đánh dấu yêu thích; project yêu thích và project truy cập gần đây hiện lên đầu

### Ảnh hưởng tới đồng bộ

Danh sách project nằm trong scope workspace nên hoạt động cả khi offline. Project
được đánh dấu yêu thích có scope giữ đồng bộ thường trực; các project khác chỉ
bootstrap khi mở lần đầu.

---

## UC-PRJ-06 — Lưu trữ, khôi phục và xoá project

**Actor:** thành viên có quyền quản trị project

### Lưu trữ

1. Chọn lưu trữ project
2. Project ẩn khỏi danh sách mặc định, **dữ liệu vẫn đọc được**
3. Không tạo hoặc sửa issue được nữa
4. Khôi phục bất cứ lúc nào

### Xoá

1. Chọn xoá project
2. Cảnh báo rõ, yêu cầu gõ lại key để xác nhận
3. Chuyển sang trạng thái đã xoá mềm, kèm thời hạn ân hạn
4. Client xoá dữ liệu cục bộ của scope project
5. Hết thời hạn, tác vụ định kỳ xoá vĩnh viễn

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Gõ sai key xác nhận | Không cho tiếp tục |
| Project có issue liên kết tới issue của project khác | Cảnh báo, các liên kết đó sẽ mất |

---

## UC-PRJ-07 — Permission scheme

**Actor:** thành viên có quyền quản trị workspace

### Luồng chính

1. Tạo permission scheme: ánh xạ vai trò trong project sang tập quyền
2. Gán scheme cho một hoặc nhiều project
3. Sửa scheme → áp dụng cho mọi project đang dùng nó

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Sửa scheme đang được nhiều project dùng | Cảnh báo kèm danh sách project bị ảnh hưởng |
| Xoá scheme đang được dùng | Chặn, yêu cầu chuyển các project sang scheme khác trước |

### Ảnh hưởng tới đồng bộ

Sửa một scheme có thể đổi quyền của **rất nhiều người ở nhiều project cùng lúc**.
Phải xoá cache quyền và phát sự kiện thu hồi cho từng người ở từng scope bị ảnh
hưởng. Đây là thao tác có phạm vi ảnh hưởng rộng nhất trong Phase 2 và cần test riêng.

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-01 | Key project duy nhất **trong workspace**, không duy nhất toàn hệ thống |
| QT-02 | Key cũ được giữ trong lịch sử và không được cấp lại cho project khác |
| QT-03 | Mã issue được tính từ key, không lưu sẵn dạng chuỗi trong issue |
| QT-04 | Project luôn phải có một người dẫn dắt |
| QT-05 | Khách chỉ thấy project được thêm đích danh |
| QT-06 | Lưu trữ project giữ nguyên dữ liệu ở chế độ chỉ đọc; xoá project là xoá mềm kèm ân hạn |
| QT-07 | Mọi thay đổi làm thu hẹp quyền phải phát sự kiện thu hồi cho **mọi** người bị ảnh hưởng |

## Yêu cầu phi chức năng liên quan

`NFR-20` không rò rỉ giữa các workspace · `NFR-22` thu hồi quyền có hiệu lực ngay
· `NFR-07` lọc quyền ở tầng SQL
