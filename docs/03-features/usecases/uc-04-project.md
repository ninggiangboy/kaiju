# UC-PRJ — Project

Project là ranh giới tổ chức công việc bên trong workspace, và đồng thời là sync
scope thứ hai. Key của project là thứ sinh ra mã issue.

**Phase:** 2 · **Feature:** KJ-PRJ-01 → KJ-PRJ-12
**Liên quan:** [uc-02-workspace.md](uc-02-workspace.md) · [uc-03-member-invite.md](uc-03-member-invite.md) · [realtime-and-sync.md](../../04-system-design/realtime-and-sync.md)

---

## UC-PRJ-01 — Tạo project

**Requirement:** FR-PRJ-01, FR-PRJ-02, FR-PRJ-04
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

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-PRJ-01/NT-01 | Key đã tồn tại ở workspace khác | **Chấp nhận bình thường** — key chỉ duy nhất trong workspace (QT-PRJ-01) |
| UC-PRJ-01/NT-02 | Key sai định dạng | Tự chuẩn hoá về chữ hoa, loại ký tự không hợp lệ, hiển thị kết quả — không chặn tạo project |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-PRJ-01/NL-01 | Key đã tồn tại **trong workspace này** | Báo ngay khi gõ, gợi ý key thay thế |
| UC-PRJ-01/NL-02 | Key trùng từ khoá hệ thống | Từ chối kèm danh sách từ bị cấm |
| UC-PRJ-01/NL-03 | Không đủ quyền | Không hiển thị chức năng này |

### Hậu điều kiện

Project tồn tại với một thành viên. Sync scope mới được tạo; client của những
người có quyền thấy project trong danh sách ngay.

### Ảnh hưởng tới đồng bộ

Project mới phát delta trên scope workspace (danh sách project). Client của
người tạo đăng ký thêm scope `proj:{projectId}` và bootstrap ngay vì project
vừa mở; client của người khác chỉ thấy nó trong danh sách, chưa bootstrap.

---

## UC-PRJ-02 — Quản lý key

**Requirement:** FR-PRJ-03
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** không có

### Luồng chính

1. Mở cấu hình project, sửa key
2. Hệ thống cảnh báo: mã issue sẽ đổi, đường dẫn cũ vẫn hoạt động
3. Xác nhận → đổi key, **lưu key cũ vào lịch sử**
4. Mọi issue hiển thị theo key mới
5. Đường dẫn và mã issue theo key cũ **vẫn truy cập được**, chuyển hướng sang mã mới

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-PRJ-02/NL-01 | Key mới trùng key đang dùng của project khác | Từ chối |
| UC-PRJ-02/NL-02 | Key mới trùng key **cũ** của project khác | Từ chối — nếu không, mã issue lịch sử sẽ trỏ nhầm chỗ (QT-PRJ-02) |

### Ảnh hưởng tới đồng bộ

Đổi key làm thay đổi mã hiển thị của **mọi** issue trong project. Không phát delta
cho từng issue; thay vào đó phát một delta trên chính project và client tự tính
lại mã hiển thị từ key.

Đây là lý do mã issue nên được **tính từ key** ở phía client chứ không lưu sẵn
dạng chuỗi trong từng issue.

### Hậu điều kiện

Project mang key mới; key cũ nằm trong lịch sử và không cấp lại được cho project
khác (QT-PRJ-02).

---

## UC-PRJ-03 — Mức hiển thị và thành viên project

**Requirement:** FR-PRJ-05, FR-PRJ-06
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** không có

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

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-PRJ-03/NT-01 | Đổi từ mở sang chỉ người được mời | Cảnh báo số người sắp mất quyền, yêu cầu xác nhận, sau đó đổi bình thường |
| UC-PRJ-03/NT-02 | Thêm một người đang ở trạng thái chờ chấp nhận lời mời | Cho phép — gán việc được ngay |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-PRJ-03/NL-01 | Bớt người dẫn dắt project | Chặn, yêu cầu chọn người thay thế trước |

### Hậu điều kiện

Danh sách thành viên project phản ánh đúng người còn quyền truy cập; mức hiển
thị (nếu đổi) áp dụng ngay cho lần kiểm tra quyền kế tiếp.

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

**Requirement:** FR-PRJ-08
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** không có

### Luồng chính

1. Mở trang component
2. Tạo component với tên, mô tả, người phụ trách, người được gán mặc định
3. Sửa hoặc xoá component

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-PRJ-04/NT-01 | Xoá component đang được dùng | Cảnh báo kèm số lượng issue, cho chọn: bỏ gán, hoặc chuyển sang component khác |
| UC-PRJ-04/NT-02 | Người phụ trách rời workspace | Component giữ nguyên tham chiếu, giao diện hiển thị người đã rời đi |

### Hậu điều kiện

Component tồn tại với đúng người phụ trách và người được gán mặc định đã cấu
hình; issue đang dùng component bị xoá được gán lại hoặc bỏ gán theo lựa chọn.

### Ảnh hưởng tới đồng bộ

Component là dữ liệu trong scope project; thay đổi phát delta trên chính scope
đó, client của mọi thành viên đang mở project cập nhật ngay.

---

## UC-PRJ-05 — Danh sách project

**Requirement:** FR-PRJ-07
**Actor:** thành viên
**Tiền điều kiện:** không có

### Luồng chính

1. Mở danh sách project của workspace hiện tại
2. Hệ thống hiển thị project người dùng **có quyền xem**
3. Tìm kiếm, lọc theo loại và trạng thái lưu trữ, sắp xếp
4. Đánh dấu yêu thích; project yêu thích và project truy cập gần đây hiện lên đầu

### Hậu điều kiện

Danh sách project được đánh dấu yêu thích (nếu có thay đổi) phản ánh lựa chọn
mới nhất; không có dữ liệu nghiệp vụ nào khác thay đổi.

### Ảnh hưởng tới đồng bộ

Danh sách project nằm trong scope workspace nên hoạt động cả khi offline. Project
được đánh dấu yêu thích có scope giữ đồng bộ thường trực; các project khác chỉ
bootstrap khi mở lần đầu.

---

## UC-PRJ-06 — Lưu trữ, khôi phục và xoá project

**Requirement:** FR-PRJ-09
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** không có

### Luồng thay thế

**UC-PRJ-06/NT-01 — Lưu trữ**

1. Chọn lưu trữ project
2. Project ẩn khỏi danh sách mặc định, **dữ liệu vẫn đọc được**
3. Không tạo hoặc sửa issue được nữa
4. Khôi phục bất cứ lúc nào

**UC-PRJ-06/NT-02 — Xoá**

1. Chọn xoá project
2. Cảnh báo rõ, yêu cầu gõ lại key để xác nhận
3. Chuyển sang trạng thái đã xoá mềm, kèm thời hạn ân hạn
4. Client xoá dữ liệu cục bộ của scope project
5. Hết thời hạn, tác vụ định kỳ xoá vĩnh viễn

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-PRJ-06/NT-03 | Project có issue liên kết tới issue của project khác, đang xoá | Cảnh báo, các liên kết đó sẽ mất |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-PRJ-06/NL-01 | Gõ sai key xác nhận | Không cho tiếp tục |

### Hậu điều kiện

Sau lưu trữ: project ở chế độ chỉ đọc, vẫn còn trong danh sách (lọc theo trạng
thái). Sau xoá: project ở trạng thái đã xoá mềm trong thời hạn ân hạn, hoặc đã
xoá vĩnh viễn sau khi hết hạn.

### Ảnh hưởng tới đồng bộ

Lưu trữ phát delta cập nhật trạng thái trên scope project — client vẫn giữ dữ
liệu, chỉ chuyển UI sang chỉ đọc. Xoá phát sự kiện thu hồi cho scope
`proj:{projectId}`; client xoá toàn bộ dữ liệu cục bộ của project đó.

---

## UC-PRJ-07 — Permission scheme

**Requirement:** FR-PRJ-10
**Actor:** thành viên có quyền quản trị workspace
**Tiền điều kiện:** không có

### Luồng chính

1. Tạo permission scheme: ánh xạ vai trò trong project sang tập quyền
2. Gán scheme cho một hoặc nhiều project
3. Sửa scheme → áp dụng cho mọi project đang dùng nó

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-PRJ-07/NT-01 | Sửa scheme đang được nhiều project dùng | Cảnh báo kèm danh sách project bị ảnh hưởng, sau đó áp dụng bình thường |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-PRJ-07/NL-01 | Xoá scheme đang được dùng | Chặn, yêu cầu chuyển các project sang scheme khác trước |

### Hậu điều kiện

Scheme phản ánh ánh xạ vai trò → quyền mới nhất; mọi project gán scheme đó áp
dụng cùng ánh xạ.

### Ảnh hưởng tới đồng bộ

Sửa một scheme có thể đổi quyền của **rất nhiều người ở nhiều project cùng lúc**.
Phải xoá cache quyền và phát sự kiện thu hồi cho từng người ở từng scope bị ảnh
hưởng. Đây là thao tác có phạm vi ảnh hưởng rộng nhất trong Phase 2 và cần test riêng.

---

## UC-PRJ-08 — Nhật ký thay đổi cấp project

**Requirement:** FR-PRJ-11
**Actor:** thành viên có quyền xem project
**Tiền điều kiện:** project tồn tại và có ít nhất một thay đổi cấp project đã xảy ra (đổi tên, key, mô tả, mức hiển thị, lưu trữ, đổi permission scheme, v.v.)

### Luồng chính

1. Mở tab "Nhật ký" của project
2. Hệ thống liệt kê các thay đổi cấp project theo thời gian giảm dần: ai đổi,
   đổi trường nào, giá trị cũ → giá trị mới, khi nào
3. Người dùng lọc theo loại thay đổi hoặc theo người thực hiện

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-PRJ-08/NL-01 | Người xem không còn là thành viên project (ví dụ project ở mức hiển thị riêng tư) | Chặn, trả lỗi không đủ quyền |

### Hậu điều kiện

Không có trạng thái nào đổi — đây là một đường đọc.

### Ảnh hưởng tới đồng bộ

Không đổi dữ liệu client — UC này chỉ đọc. Bản thân các thay đổi cấp project
được ghi log tại đúng thời điểm xảy ra (như một phần của UC-PRJ-01 đến
UC-PRJ-07, UC-PRJ-09 tương ứng), không phải một hành động ghi riêng; nhật ký
này chỉ là một view đọc lại các log đó.

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-PRJ-01 | Key project duy nhất **trong workspace**, không duy nhất toàn hệ thống |
| QT-PRJ-02 | Key cũ được giữ trong lịch sử và không được cấp lại cho project khác |
| QT-PRJ-03 | Mã issue được tính từ key, không lưu sẵn dạng chuỗi trong issue |
| QT-PRJ-04 | Project luôn phải có một người dẫn dắt |
| QT-PRJ-05 | Khách chỉ thấy project được thêm đích danh |
| QT-PRJ-06 | Lưu trữ project giữ nguyên dữ liệu ở chế độ chỉ đọc; xoá project là xoá mềm kèm ân hạn |
| QT-PRJ-07 | Mọi thay đổi làm thu hẹp quyền phải phát sự kiện thu hồi cho **mọi** người bị ảnh hưởng |
| QT-PRJ-08 | Nhật ký thay đổi cấp project là bất biến sau khi ghi, kể cả bởi quản trị viên |

## Yêu cầu phi chức năng liên quan

`NFR-20` không rò rỉ giữa các workspace · `NFR-22` thu hồi quyền có hiệu lực ngay
· `NFR-07` lọc quyền ở tầng SQL
