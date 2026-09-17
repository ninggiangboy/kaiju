# 03 — Features & Use cases

Danh mục toàn bộ feature của dự án kèm **trạng thái tiến độ**. Đây là **nơi duy
nhất** chứa trạng thái; roadmap và các tài liệu khác không lặp lại thông tin này.

**Liên quan:** [roadmap.md](roadmap.md) · [usecases/](usecases/) · [functional.md](../02-requirement/functional.md) · [System Design](../04-system-design/)

---

## Cách dùng

### Trạng thái

| Trạng thái | Nghĩa |
|---|---|
| `TODO` | Chưa bắt đầu |
| `IN_PROGRESS` | Đang làm, hoặc đã chạy được nhưng **chưa đầy đủ** |
| `DONE` | Đã đầy đủ theo [định nghĩa hoàn thành](../04-system-design/testing-strategy.md#thứ-được-coi-là-xong) |
| `BLOCKED` | Không làm tiếp được vì một phụ thuộc chưa xong; ghi rõ lý do ở cột ghi chú |
| `DEFERRED` | Đã quyết định hoãn sang phase sau; ghi rõ sang phase nào |

`DONE` chỉ được đặt khi feature đã xử lý các nhánh ngoại lệ, phân quyền, cách ly
tenant và đồng bộ — **không phải** khi luồng chính chạy được. Đây là điểm mấu
chốt của nguyên tắc làm từng tính năng một nhưng đầy đủ.

### Quy tắc cập nhật

- ID không bao giờ tái sử dụng. Feature bị bỏ thì giữ ID và chuyển sang `DEFERRED`
- Trước khi bắt đầu một feature, kiểm tra cột phụ thuộc — mọi ID trong đó phải `DONE`
- Thêm feature mới thì cấp ID kế tiếp trong nhóm, không chèn vào giữa

### Tiến độ

| Phase | Tên | Số feature | TODO | IN_PROGRESS | DONE |
|---|---|---|---|---|---|
| 0 | Nền tảng | 51 | 51 | 0 | 0 |
| 1 | Identity & Workspace | 32 | 32 | 0 | 0 |
| 2 | Project | 12 | 12 | 0 | 0 |
| 3 | Issue | 16 | 16 | 0 | 0 |
| 4 | Collaboration | 15 | 15 | 0 | 0 |
| 5 | Workflow | 11 | 11 | 0 | 0 |
| 6 | Custom field | 8 | 8 | 0 | 0 |
| 7 | Search | 10 | 10 | 0 | 0 |
| 8 | Board | 10 | 10 | 0 | 0 |
| 9 | Sprint | 9 | 9 | 0 | 0 |
| 10 | Roadmap | 6 | 6 | 0 | 0 |
| 11 | Time tracking | 6 | 6 | 0 | 0 |
| 12 | Version | 6 | 6 | 0 | 0 |
| 13 | Dashboard | 7 | 7 | 0 | 0 |
| 14 | Automation | 10 | 10 | 0 | 0 |
| 15 | Bulk & Import | 7 | 7 | 0 | 0 |
| 16 | Integration | 10 | 10 | 0 | 0 |
| | **Tổng** | **226** | **226** | **0** | **0** |

---

## Phase 0 — Nền tảng

### Platform

| ID | Feature | Phụ thuộc | Trạng thái | Ghi chú |
|---|---|---|---|---|
| KJ-PLT-01 | Gradle multi-module và cấu trúc bốn thư mục | | TODO | [backend-modules](../04-system-design/backend-modules.md) |
| KJ-PLT-02 | Bốn vai trò ứng dụng chọn bằng profile | KJ-PLT-01 | TODO | |
| KJ-PLT-03 | Cấu hình connection pool riêng theo vai trò | KJ-PLT-02 | TODO | Tính tổng số kết nối thủ công |
| KJ-PLT-04 | Kiểm tra biên giới module làm hỏng build | KJ-PLT-01 | TODO | Chỉ bắt được luật 1, xem ghi chú ở KJ-PLT-18 |
| KJ-PLT-05 | Cấu hình Spring Data JDBC và converter kiểu JSON | KJ-PLT-01 | TODO | Thiếu là mọi thao tác ghi lỗi kiểu |
| KJ-PLT-06 | Thiết lập jOOQ và bước sinh mã | KJ-PLT-05 | TODO | |
| KJ-PLT-07 | Flyway và quy ước migration | KJ-PLT-05 | TODO | |
| KJ-PLT-08 | Context workspace và biến phiên theo giao dịch | KJ-PLT-07 | TODO | Kể cả cho tiến trình nền |
| KJ-PLT-09 | Bảo mật mức dòng và tiện ích áp dụng | KJ-PLT-08 | TODO | |
| KJ-PLT-10 | Test bất biến schema quét siêu dữ liệu | KJ-PLT-09 | TODO | Bắt khoá ngoại vi phạm |
| KJ-PLT-11 | Trừu tượng hoá Redis: cache, khoá, giới hạn tần suất | KJ-PLT-01 | TODO | Mọi đường đọc có dự phòng |
| KJ-PLT-12 | Nhật ký có cấu trúc và định danh tương quan | KJ-PLT-01 | TODO | Phải vượt ranh giới bất đồng bộ |
| KJ-PLT-13 | Chỉ số và kiểm tra sức khoẻ theo vai trò | KJ-PLT-02 | TODO | |
| KJ-PLT-14 | Docker Compose môi trường phát triển kèm bộ bắt email | | TODO | Bắt buộc có bộ bắt email |
| KJ-PLT-15 | Dockerfile cho backend và frontend | KJ-PLT-01 | TODO | |
| KJ-PLT-16 | Cấu hình máy chủ trung gian đã tắt đệm cho SSE | KJ-PLT-14 | TODO | Lỗi vận hành phổ biến nhất |
| KJ-PLT-17 | Bộ khung kiểm thử với Testcontainers | KJ-PLT-07 | TODO | |
| KJ-PLT-18 | Enforce quyền sở hữu bảng theo module: tiền tố tên bảng và test quét | KJ-PLT-04, KJ-PLT-06 | TODO | Công cụ kiểm tra biên giới **không** bắt được luật này |
| KJ-PLT-19 | Test chặn thư viện bị cấm xuất hiện trên classpath | KJ-PLT-01 | TODO | Tránh có hai cơ chế chuyển tiếp sự kiện chạy song song |
| KJ-PLT-20 | Chốt phiên bản nền và khung package của toàn backend | | TODO | Làm trước KJ-PLT-01 |

### Events & Outbox

| ID | Feature | Phụ thuộc | Trạng thái | Ghi chú |
|---|---|---|---|---|
| KJ-EVT-01 | Định nghĩa domain event và cơ chế phiên bản | KJ-PLT-05 | TODO | Phiên bản có từ sự kiện đầu tiên |
| KJ-EVT-02 | Bảng chuyển tiếp, ghi trong cùng giao dịch | KJ-EVT-01 | TODO | |
| KJ-EVT-03 | Tiến trình chuyển tiếp với khoá dòng bỏ qua | KJ-EVT-02 | TODO | Nhiều instance song song |
| KJ-EVT-04 | Đánh thức bằng thông báo, có chu kỳ quét dự phòng | KJ-EVT-03 | TODO | Kết nối riêng ngoài pool |
| KJ-EVT-05 | Chia việc theo aggregate để giữ thứ tự | KJ-EVT-03 | TODO | |
| KJ-EVT-06 | Thử lại với khoảng chờ tăng dần | KJ-EVT-03 | TODO | |
| KJ-EVT-07 | Khu vực thư chết và công cụ phát lại | KJ-EVT-06 | TODO | Không được lược bớt |
| KJ-EVT-08 | Cơ chế chống trùng cho bên tiêu thụ | KJ-EVT-03 | TODO | Ràng buộc khó nhất |
| KJ-EVT-09 | Tác vụ dọn dữ liệu cũ của bảng chuyển tiếp | KJ-EVT-02 | TODO | |
| KJ-EVT-10 | Bộ test outbox đầy đủ | KJ-EVT-07, KJ-EVT-08 | TODO | Crash, thử lại, chống trùng, thứ tự |

### Sync engine

| ID | Feature | Phụ thuộc | Trạng thái | Ghi chú |
|---|---|---|---|---|
| KJ-SYN-01 | Nhật ký thay đổi và cấp số thứ tự theo scope | KJ-PLT-07 | TODO | Phương án bộ đếm theo scope |
| KJ-SYN-02 | Sinh patch bằng diff tường minh khi ghi | KJ-SYN-01, KJ-PLT-05 | TODO | Chỉ trường đã đổi |
| KJ-SYN-03 | Endpoint bắt kịp theo cursor | KJ-SYN-01 | TODO | |
| KJ-SYN-04 | Bootstrap với ảnh chụp nhất quán | KJ-SYN-03 | TODO | Ảnh chụp và số thứ tự cùng thời điểm |
| KJ-SYN-05 | Mã hoá và giải mã cursor đa scope | KJ-SYN-03 | TODO | Chuỗi mờ, client không diễn giải |
| KJ-SYN-06 | Luồng SSE với xác thực và nhịp tim | KJ-SYN-05 | TODO | |
| KJ-SYN-07 | Phân quyền scope khi mở kết nối | KJ-SYN-06 | TODO | Client không tự khai scope |
| KJ-SYN-08 | Phát tán giữa các instance qua Redis | KJ-SYN-06, KJ-EVT-03 | TODO | Gửi rồi quên, chấp nhận mất |
| KJ-SYN-09 | Sự kiện thu hồi scope | KJ-SYN-07 | TODO | |
| KJ-SYN-10 | SharedWorker và phương án bầu tab chủ | | TODO | Làm cả hai trong phase này |
| KJ-SYN-11 | Bản sao cục bộ chuẩn hoá theo thực thể | KJ-SYN-10 | TODO | Không tổ chức theo khoá truy vấn |
| KJ-SYN-12 | Tầng truy vấn phản ứng cho React | KJ-SYN-11 | TODO | |
| KJ-SYN-13 | Hàng đợi mutation bền | KJ-SYN-11 | TODO | Sống sót qua tải lại trang |
| KJ-SYN-14 | Áp lạc quan và hoàn tác | KJ-SYN-13 | TODO | |
| KJ-SYN-15 | Rebase mutation chưa được xác nhận | KJ-SYN-14 | TODO | Hai tầng trạng thái |
| KJ-SYN-16 | Endpoint mutation với khoá chống trùng | KJ-SYN-02 | TODO | |
| KJ-SYN-17 | Hiển thị trạng thái kết nối và mutation chờ | KJ-SYN-13 | TODO | |
| KJ-SYN-18 | Chính sách dọn dẹp lưu trữ cục bộ | KJ-SYN-11 | TODO | |
| KJ-SYN-19 | Tầng truyền tải nằm sau interface | KJ-SYN-06 | TODO | Để đổi sang WebSocket được |
| KJ-SYN-20 | Bộ test sync engine theo bảng kịch bản | KJ-SYN-15, KJ-SYN-09 | TODO | [testing-strategy](../04-system-design/testing-strategy.md) |
| KJ-SYN-21 | Thực thể nháp và bảy bước kiểm chứng nền tảng | KJ-SYN-20, KJ-EVT-10 | TODO | Cổng ra của Phase 0 |

---

## Phase 1 — Identity & Workspace

### Identity

| ID | Feature | Phụ thuộc | Trạng thái | Ghi chú |
|---|---|---|---|---|
| KJ-IDN-01 | Gửi magic link, giới hạn tần suất, chống dò email | KJ-PLT-11 | TODO | [uc-auth](usecases/uc-auth.md) |
| KJ-IDN-02 | Token lưu dạng băm, dùng một lần, có thời hạn, vô hiệu hàng loạt | KJ-IDN-01 | TODO | |
| KJ-IDN-03 | Mã 6 số kèm ràng buộc thiết bị | KJ-IDN-02 | TODO | Bắt buộc, không phải tuỳ chọn |
| KJ-IDN-04 | Xác thực và cấp phiên đăng nhập | KJ-IDN-03 | TODO | |
| KJ-IDN-05 | Token làm mới xoay vòng và phát hiện tái sử dụng | KJ-IDN-04 | TODO | Tái sử dụng thì thu hồi toàn bộ |
| KJ-IDN-06 | Danh sách phiên và thu hồi | KJ-IDN-05 | TODO | |
| KJ-IDN-07 | Onboarding tài khoản mới | KJ-IDN-04 | TODO | Hỏi tên hiển thị và tên workspace |
| KJ-IDN-08 | Hồ sơ mặc định của tài khoản | KJ-IDN-04 | TODO | Chỉ dùng để điền sẵn |
| KJ-IDN-09 | Xoá tài khoản kèm ẩn danh hoá | KJ-IDN-08 | TODO | Dữ liệu nghiệp vụ nguyên vẹn |
| KJ-IDN-10 | Nhật ký kiểm toán cho hành động bảo mật | KJ-IDN-04 | TODO | |
| KJ-IDN-11 | Gửi email qua bảng chuyển tiếp kèm mẫu thư | KJ-EVT-03 | TODO | Không gửi trực tiếp trong request |

### Workspace & Member

| ID | Feature | Phụ thuộc | Trạng thái | Ghi chú |
|---|---|---|---|---|
| KJ-WSP-01 | Tạo workspace và quản lý slug | KJ-IDN-07 | TODO | [uc-workspace](usecases/uc-workspace.md) |
| KJ-WSP-02 | Chuyển đổi giữa các workspace | KJ-WSP-01 | TODO | Không phải đăng nhập lại |
| KJ-WSP-03 | Hồ sơ thành viên riêng theo workspace | KJ-WSP-01 | TODO | Không lan sang workspace khác |
| KJ-WSP-04 | Mời nhiều email trong một lần | KJ-WSP-03, KJ-IDN-11 | TODO | [uc-member-invite](usecases/uc-member-invite.md) |
| KJ-WSP-05 | Chấp nhận lời mời, đầy đủ mọi nhánh | KJ-WSP-04 | TODO | Năm nhánh, mỗi nhánh một test |
| KJ-WSP-06 | Thành viên ở trạng thái chờ, gán việc trước khi chấp nhận | KJ-WSP-04 | TODO | |
| KJ-WSP-07 | Danh sách lời mời, gửi lại, thu hồi | KJ-WSP-04 | TODO | |
| KJ-WSP-08 | Bốn vai trò mặc định | KJ-WSP-16 | TODO | |
| KJ-WSP-09 | Vai trò khách với phạm vi hạn chế | KJ-WSP-08 | TODO | Bắt buộc có từ phase này |
| KJ-WSP-10 | Đổi vai trò của thành viên | KJ-WSP-08 | TODO | |
| KJ-WSP-11 | Xoá thành viên kèm gán lại công việc | KJ-WSP-10 | TODO | Tránh issue mồ côi |
| KJ-WSP-12 | Tự rời workspace | KJ-WSP-11 | TODO | |
| KJ-WSP-13 | Chuyển quyền sở hữu | KJ-WSP-10 | TODO | Luôn còn ít nhất một chủ sở hữu |
| KJ-WSP-14 | Xoá workspace mềm kèm ân hạn và khôi phục | KJ-WSP-13 | TODO | |
| KJ-WSP-15 | Group thành viên và cấp quyền theo group | KJ-WSP-16 | TODO | |
| KJ-WSP-16 | Mặt nạ bit hai cấp và tính quyền hiệu lực | KJ-PLT-05 | TODO | Dự phòng vượt 64 bit |
| KJ-WSP-17 | Cache quyền và xoá cache khi thay đổi | KJ-WSP-16, KJ-PLT-11 | TODO | Kèm phát sự kiện thu hồi |
| KJ-WSP-18 | Chỗ nối cho tầng permission condition | KJ-WSP-16 | TODO | Bắt buộc, dù chưa có điều kiện nào |
| KJ-WSP-19 | Scope workspace và danh bạ thành viên đồng bộ | KJ-SYN-07, KJ-WSP-03 | TODO | Ô chọn người chạy cục bộ |
| KJ-WSP-20 | Giới hạn số lời mời trong một khoảng thời gian | KJ-WSP-04 | TODO | Chống dùng để gửi thư rác |
| KJ-WSP-21 | Cấu hình workspace | KJ-WSP-01 | TODO | |

---

## Phase 2 — Project

| ID | Feature | Phụ thuộc | Trạng thái | Ghi chú |
|---|---|---|---|---|
| KJ-PRJ-01 | Tạo project với thông tin cơ bản | KJ-WSP-16 | TODO | [uc-project](usecases/uc-project.md) |
| KJ-PRJ-02 | Quy tắc và tính duy nhất của key trong workspace | KJ-PRJ-01 | TODO | Không duy nhất toàn cục |
| KJ-PRJ-03 | Đổi key và giữ liên kết cũ | KJ-PRJ-02 | TODO | Cần lưu lịch sử key |
| KJ-PRJ-04 | Loại project quyết định tính năng được bật | KJ-PRJ-01 | TODO | |
| KJ-PRJ-05 | Hai mức hiển thị của project | KJ-PRJ-01, KJ-WSP-09 | TODO | Nền cho vai trò khách |
| KJ-PRJ-06 | Thành viên và vai trò trong project | KJ-PRJ-01, KJ-WSP-16 | TODO | |
| KJ-PRJ-07 | Danh sách project, tìm kiếm, yêu thích, gần đây | KJ-PRJ-01 | TODO | |
| KJ-PRJ-08 | Component trong project | KJ-PRJ-01 | TODO | |
| KJ-PRJ-09 | Lưu trữ, khôi phục và xoá project | KJ-PRJ-01 | TODO | |
| KJ-PRJ-10 | Permission scheme dùng lại giữa nhiều project | KJ-PRJ-06 | TODO | |
| KJ-PRJ-11 | Nhật ký thay đổi cấp project | KJ-PRJ-01 | TODO | |
| KJ-PRJ-12 | Scope project cho sync engine | KJ-PRJ-01, KJ-SYN-07 | TODO | Đăng ký, bootstrap, thu hồi |

---

## Phase 3 — Issue

| ID | Feature | Phụ thuộc | Trạng thái | Ghi chú |
|---|---|---|---|---|
| KJ-ISS-01 | Tạo, xem, sửa issue | KJ-PRJ-12 | TODO | |
| KJ-ISS-02 | Xoá mềm và khôi phục | KJ-ISS-01 | TODO | |
| KJ-ISS-03 | Năm loại issue và cấu hình loại theo project | KJ-ISS-01 | TODO | |
| KJ-ISS-04 | Sinh mã issue an toàn khi tạo đồng thời | KJ-ISS-01, KJ-PRJ-02 | TODO | Test song song |
| KJ-ISS-05 | Đầy đủ trường hệ thống | KJ-ISS-01 | TODO | |
| KJ-ISS-06 | Mô tả định dạng phong phú kèm ảnh nhúng | KJ-ISS-05 | TODO | |
| KJ-ISS-07 | Phân cấp ba tầng có chống vòng lặp | KJ-ISS-03 | TODO | |
| KJ-ISS-08 | Liên kết hai chiều giữa issue | KJ-ISS-01 | TODO | |
| KJ-ISS-09 | Loại liên kết cấu hình được | KJ-ISS-08 | TODO | |
| KJ-ISS-10 | Thứ hạng cho phép chèn vô hạn | KJ-ISS-01 | TODO | Có cơ chế cân bằng lại |
| KJ-ISS-11 | Nhân bản issue | KJ-ISS-07, KJ-ISS-08 | TODO | |
| KJ-ISS-12 | Chuyển issue sang project khác | KJ-ISS-04 | TODO | Giữ nguyên lịch sử |
| KJ-ISS-13 | Chuyển đổi giữa task và sub-task | KJ-ISS-07 | TODO | |
| KJ-ISS-14 | Xem dạng bảng với cột cấu hình được | KJ-ISS-05 | TODO | |
| KJ-ISS-15 | Nhật ký thay đổi đầy đủ trên issue | KJ-ISS-05, KJ-SYN-02 | TODO | |
| KJ-ISS-16 | Tầng phân giải trường cho phép cắm trường động | KJ-ISS-05 | TODO | **Contract cho Phase 6** |

---

## Phase 4 — Collaboration

| ID | Feature | Phụ thuộc | Trạng thái | Ghi chú |
|---|---|---|---|---|
| KJ-COL-01 | Bình luận định dạng phong phú | KJ-ISS-01 | TODO | |
| KJ-COL-02 | Lịch sử chỉnh sửa bình luận | KJ-COL-01 | TODO | |
| KJ-COL-03 | Nhắc tên người và group | KJ-COL-01, KJ-WSP-19 | TODO | Hoạt động cục bộ |
| KJ-COL-04 | Trả lời theo luồng | KJ-COL-01 | TODO | |
| KJ-COL-05 | Giới hạn người xem bình luận | KJ-COL-01, KJ-WSP-16 | TODO | |
| KJ-COL-06 | Biểu tượng cảm xúc | KJ-COL-01 | TODO | |
| KJ-COL-07 | Đính kèm tệp, xem trước, tải về | KJ-ISS-01 | TODO | |
| KJ-COL-08 | Giới hạn dung lượng và điểm móc quét mã độc | KJ-COL-07 | TODO | |
| KJ-COL-09 | Đính kèm trong bình luận | KJ-COL-07, KJ-COL-01 | TODO | |
| KJ-COL-10 | Theo dõi issue | KJ-ISS-01 | TODO | |
| KJ-COL-11 | Bình chọn | KJ-ISS-01 | TODO | |
| KJ-COL-12 | Dòng hoạt động gộp và lọc được | KJ-ISS-15, KJ-COL-01 | TODO | |
| KJ-COL-13 | Thông báo trong ứng dụng | KJ-EVT-08 | TODO | Phải chống trùng |
| KJ-COL-14 | Thông báo email có gom nhóm | KJ-COL-13, KJ-IDN-11 | TODO | Rủi ro gửi trùng cao nhất |
| KJ-COL-15 | Cấu hình thông báo theo project và cá nhân | KJ-COL-14 | TODO | Tuỳ chọn thuộc hồ sơ workspace |

---

## Phase 5 — Workflow

| ID | Feature | Phụ thuộc | Trạng thái | Ghi chú |
|---|---|---|---|---|
| KJ-WKF-01 | Rà soát và gỡ mọi chỗ gắn cứng trạng thái cố định | KJ-ISS-05 | TODO | Việc đầu tiên của phase |
| KJ-WKF-02 | Trạng thái do người dùng định nghĩa và nhóm trạng thái | KJ-WKF-01 | TODO | |
| KJ-WKF-03 | Workflow với các bước chuyển | KJ-WKF-02 | TODO | |
| KJ-WKF-04 | Điều kiện trên bước chuyển | KJ-WKF-03, KJ-WSP-16 | TODO | |
| KJ-WKF-05 | Kiểm tra hợp lệ trên bước chuyển | KJ-WKF-03 | TODO | |
| KJ-WKF-06 | Hành động sau bước chuyển | KJ-WKF-03 | TODO | |
| KJ-WKF-07 | Màn hình nhập liệu khi chuyển trạng thái | KJ-WKF-05 | TODO | |
| KJ-WKF-08 | Workflow scheme ánh xạ theo loại issue | KJ-WKF-03, KJ-ISS-03 | TODO | |
| KJ-WKF-09 | Trình soạn workflow có bản nháp và xuất bản | KJ-WKF-03 | TODO | |
| KJ-WKF-10 | Chuyển đổi issue đang tồn tại khi đổi workflow | KJ-WKF-08 | TODO | Có xem trước và đường lùi |
| KJ-WKF-11 | Quản lý kết quả xử lý | KJ-WKF-06 | TODO | |

---

## Phase 6 — Custom field & Screen

| ID | Feature | Phụ thuộc | Trạng thái | Ghi chú |
|---|---|---|---|---|
| KJ-FLD-01 | Đầy đủ các kiểu trường | KJ-ISS-16 | TODO | Kiểm tra contract Phase 3 |
| KJ-FLD-02 | Cấu hình trường theo ngữ cảnh project và loại issue | KJ-FLD-01 | TODO | |
| KJ-FLD-03 | Bắt buộc, quy tắc hợp lệ, giá trị mặc định | KJ-FLD-02 | TODO | |
| KJ-FLD-04 | Màn hình và screen scheme cho ba thao tác | KJ-FLD-02 | TODO | |
| KJ-FLD-05 | Sắp xếp trường và chia tab | KJ-FLD-04 | TODO | |
| KJ-FLD-06 | Xử lý dữ liệu khi xoá hoặc đổi trường | KJ-FLD-02 | TODO | |
| KJ-FLD-07 | Trường tuỳ biến vào nhật ký thay đổi và delta | KJ-FLD-01, KJ-ISS-15 | TODO | Phải giống hệt trường hệ thống |
| KJ-FLD-08 | Trường tuỳ biến dùng được trong bộ lọc và báo cáo | KJ-FLD-01 | TODO | Chuẩn bị cho Phase 7 |

---

## Phase 7 — Search & Query

| ID | Feature | Phụ thuộc | Trạng thái | Ghi chú |
|---|---|---|---|---|
| KJ-SRC-01 | Bộ phân tích cú pháp ngôn ngữ truy vấn | KJ-ISS-05 | TODO | Lỗi phải chỉ rõ vị trí |
| KJ-SRC-02 | Dựng SQL động từ cây cú pháp | KJ-SRC-01, KJ-PLT-06 | TODO | |
| KJ-SRC-03 | Hàm dựng sẵn trong truy vấn | KJ-SRC-01 | TODO | |
| KJ-SRC-04 | Truy vấn trên trường tuỳ biến | KJ-SRC-02, KJ-FLD-08 | TODO | |
| KJ-SRC-05 | Ghép điều kiện phân quyền vào truy vấn | KJ-SRC-02, KJ-WSP-16 | TODO | Ghép lúc dựng SQL, không lọc sau |
| KJ-SRC-06 | Tìm kiếm toàn văn và đồng bộ chỉ mục | KJ-SRC-02, KJ-EVT-03 | TODO | |
| KJ-SRC-07 | Giao diện lọc cơ bản chuyển đổi hai chiều | KJ-SRC-01 | TODO | Không mất thông tin |
| KJ-SRC-08 | Lưu và chia sẻ bộ lọc | KJ-SRC-02 | TODO | |
| KJ-SRC-09 | Xuất kết quả tìm kiếm | KJ-SRC-02 | TODO | |
| KJ-SRC-10 | Tìm kiếm nhanh toàn cục | KJ-SRC-06 | TODO | |

---

## Phase 8 — Board

| ID | Feature | Phụ thuộc | Trạng thái | Ghi chú |
|---|---|---|---|---|
| KJ-BRD-01 | Board gắn với bộ lọc | KJ-SRC-08 | TODO | |
| KJ-BRD-02 | Cột ánh xạ nhiều trạng thái | KJ-BRD-01, KJ-WKF-02 | TODO | |
| KJ-BRD-03 | Giới hạn số việc đang làm và cảnh báo | KJ-BRD-02 | TODO | |
| KJ-BRD-04 | Làn ngang theo nhiều tiêu chí | KJ-BRD-01 | TODO | |
| KJ-BRD-05 | Bộ lọc nhanh | KJ-BRD-01 | TODO | |
| KJ-BRD-06 | Tuỳ biến thẻ và tô màu theo quy tắc | KJ-BRD-01 | TODO | |
| KJ-BRD-07 | Kéo thả cập nhật trạng thái và thứ hạng | KJ-BRD-02, KJ-ISS-10, KJ-SYN-14 | TODO | Hoàn tác khi bước chuyển bị từ chối |
| KJ-BRD-08 | Backlog cho board Kanban | KJ-BRD-01 | TODO | |
| KJ-BRD-09 | Biểu đồ dòng tích luỹ và biểu đồ kiểm soát | KJ-BRD-02 | TODO | |
| KJ-BRD-10 | Ảo hoá danh sách cho board lớn | KJ-BRD-01 | TODO | Hàng nghìn issue |

---

## Phase 9 — Sprint & Scrum

| ID | Feature | Phụ thuộc | Trạng thái | Ghi chú |
|---|---|---|---|---|
| KJ-SPR-01 | Màn hình backlog kéo thả và gom nhóm theo epic | KJ-BRD-08, KJ-ISS-07 | TODO | |
| KJ-SPR-02 | Tạo sprint với mục tiêu và thời gian | KJ-PRJ-04 | TODO | |
| KJ-SPR-03 | Bắt đầu sprint | KJ-SPR-02 | TODO | |
| KJ-SPR-04 | Kết thúc sprint và xử lý issue chưa xong | KJ-SPR-03 | TODO | Mọi lựa chọn phải đúng |
| KJ-SPR-05 | Nhiều sprint song song | KJ-SPR-03 | TODO | |
| KJ-SPR-06 | Story point và lập kế hoạch theo năng lực | KJ-SPR-01 | TODO | |
| KJ-SPR-07 | Board của sprint hiện tại | KJ-SPR-03, KJ-BRD-02 | TODO | |
| KJ-SPR-08 | Báo cáo burndown, burnup và velocity | KJ-SPR-04 | TODO | Đúng cả khi thêm bớt giữa sprint |
| KJ-SPR-09 | Báo cáo sprint và báo cáo epic | KJ-SPR-08 | TODO | |

---

## Phase 10 — Roadmap & Timeline

| ID | Feature | Phụ thuộc | Trạng thái | Ghi chú |
|---|---|---|---|---|
| KJ-RDM-01 | Trục thời gian hiển thị epic | KJ-ISS-07 | TODO | |
| KJ-RDM-02 | Tổng hợp ngày từ issue con qua sự kiện | KJ-RDM-01, KJ-EVT-03 | TODO | |
| KJ-RDM-03 | Phụ thuộc giữa các epic | KJ-RDM-01, KJ-ISS-08 | TODO | |
| KJ-RDM-04 | Phát hiện phụ thuộc vòng và xung đột lịch | KJ-RDM-03 | TODO | |
| KJ-RDM-05 | Kéo đổi ngày và thu phóng | KJ-RDM-01 | TODO | |
| KJ-RDM-06 | Lọc, chia sẻ và xuất ảnh roadmap | KJ-RDM-01 | TODO | |

---

## Phase 11 — Time tracking

| ID | Feature | Phụ thuộc | Trạng thái | Ghi chú |
|---|---|---|---|---|
| KJ-TIM-01 | Ba giá trị thời gian trên issue | KJ-ISS-05 | TODO | |
| KJ-TIM-02 | Nhật ký công việc theo ngày | KJ-TIM-01 | TODO | |
| KJ-TIM-03 | Sửa và xoá bản ghi công việc | KJ-TIM-02 | TODO | Tổng phải luôn khớp |
| KJ-TIM-04 | Tự điều chỉnh thời gian còn lại | KJ-TIM-02 | TODO | |
| KJ-TIM-05 | Đơn vị thời gian cấu hình được | KJ-TIM-01 | TODO | |
| KJ-TIM-06 | Báo cáo thời gian theo nhiều chiều | KJ-TIM-02 | TODO | |

---

## Phase 12 — Version & Release

| ID | Feature | Phụ thuộc | Trạng thái | Ghi chú |
|---|---|---|---|---|
| KJ-VER-01 | Tạo và quản lý version | KJ-PRJ-01 | TODO | |
| KJ-VER-02 | Gán version cho issue | KJ-VER-01, KJ-ISS-05 | TODO | |
| KJ-VER-03 | Trang release với tiến độ | KJ-VER-02 | TODO | |
| KJ-VER-04 | Cảnh báo khi phát hành còn issue chưa xong | KJ-VER-03 | TODO | |
| KJ-VER-05 | Sinh ghi chú phát hành | KJ-VER-03 | TODO | |
| KJ-VER-06 | Lưu trữ version | KJ-VER-01 | TODO | |

---

## Phase 13 — Dashboard & Report

| ID | Feature | Phụ thuộc | Trạng thái | Ghi chú |
|---|---|---|---|---|
| KJ-DSH-01 | Tạo dashboard với bố cục kéo thả | KJ-SRC-08 | TODO | |
| KJ-DSH-02 | Chia sẻ và đặt dashboard mặc định | KJ-DSH-01 | TODO | |
| KJ-DSH-03 | Gadget dựa trên bộ lọc | KJ-DSH-01 | TODO | |
| KJ-DSH-04 | Gadget biểu đồ và thống kê | KJ-DSH-03 | TODO | |
| KJ-DSH-05 | Gadget dòng hoạt động và ghi chú | KJ-DSH-01, KJ-COL-12 | TODO | |
| KJ-DSH-06 | Phân quyền theo người xem trên mọi gadget | KJ-DSH-02, KJ-SRC-05 | TODO | Không lộ dữ liệu của người tạo |
| KJ-DSH-07 | Các báo cáo dựng sẵn | KJ-SRC-02 | TODO | |

---

## Phase 14 — Automation

| ID | Feature | Phụ thuộc | Trạng thái | Ghi chú |
|---|---|---|---|---|
| KJ-AUT-01 | Mô hình quy tắc: kích hoạt, điều kiện, hành động | KJ-EVT-03 | TODO | |
| KJ-AUT-02 | Các loại điều kiện kích hoạt | KJ-AUT-01 | TODO | Gồm cả theo lịch và thủ công |
| KJ-AUT-03 | Các loại điều kiện lọc | KJ-AUT-01, KJ-SRC-02 | TODO | |
| KJ-AUT-04 | Các loại hành động | KJ-AUT-01, KJ-WKF-03 | TODO | |
| KJ-AUT-05 | Nhánh rẽ sang issue liên quan | KJ-AUT-04, KJ-ISS-07 | TODO | |
| KJ-AUT-06 | Giá trị động trong nội dung hành động | KJ-AUT-04 | TODO | |
| KJ-AUT-07 | Quy tắc chạy dưới danh nghĩa một người và tôn trọng quyền | KJ-AUT-04, KJ-WSP-16 | TODO | |
| KJ-AUT-08 | Chống vòng lặp và giới hạn số lần chạy | KJ-AUT-04 | TODO | Giới hạn cả độ sâu lẫn tần suất |
| KJ-AUT-09 | Nhật ký chạy đủ chi tiết để tự gỡ lỗi | KJ-AUT-04 | TODO | |
| KJ-AUT-10 | Bật tắt và phạm vi áp dụng của quy tắc | KJ-AUT-01 | TODO | |

---

## Phase 15 — Bulk & Import/Export

| ID | Feature | Phụ thuộc | Trạng thái | Ghi chú |
|---|---|---|---|---|
| KJ-BLK-01 | Thao tác hàng loạt với xem trước và xác nhận | KJ-SRC-02 | TODO | |
| KJ-BLK-02 | Chia lô và chống làm ngập luồng đồng bộ | KJ-BLK-01, KJ-SYN-08 | TODO | Gộp delta hoặc buộc tải lại scope |
| KJ-BLK-03 | Nhập từ CSV với ánh xạ cột | KJ-ISS-01 | TODO | |
| KJ-BLK-04 | Chạy thử và báo lỗi theo từng dòng | KJ-BLK-03 | TODO | Thất bại không để lại dữ liệu nửa vời |
| KJ-BLK-05 | Nhập từ các công cụ khác | KJ-BLK-03 | TODO | |
| KJ-BLK-06 | Xuất dữ liệu project | KJ-ISS-01 | TODO | |
| KJ-BLK-07 | Sao lưu và khôi phục cấp workspace | KJ-BLK-06 | TODO | |

---

## Phase 16 — Integration & Public API

| ID | Feature | Phụ thuộc | Trạng thái | Ghi chú |
|---|---|---|---|---|
| KJ-INT-01 | REST API công khai có phiên bản | KJ-ISS-01 | TODO | |
| KJ-INT-02 | Tài liệu OpenAPI | KJ-INT-01 | TODO | |
| KJ-INT-03 | Token có phạm vi quyền | KJ-INT-01, KJ-WSP-16 | TODO | Không vượt quyền người tạo |
| KJ-INT-04 | Đăng ký webhook đi ra | KJ-EVT-03 | TODO | |
| KJ-INT-05 | Thử lại, nhật ký gửi và chữ ký cho webhook | KJ-INT-04 | TODO | Thất bại không ảnh hưởng nghiệp vụ |
| KJ-INT-06 | Nhận diện mã issue trong commit và nhánh | KJ-ISS-04 | TODO | |
| KJ-INT-07 | Bảng thông tin phát triển trên issue | KJ-INT-06 | TODO | |
| KJ-INT-08 | Lệnh trong commit | KJ-INT-06, KJ-WKF-03 | TODO | |
| KJ-INT-09 | Thông báo sang công cụ chat | KJ-INT-04 | TODO | |
| KJ-INT-10 | Đăng nhập một lần và cấp phát tài khoản tự động | KJ-IDN-04 | TODO | |
