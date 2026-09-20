# UC-VER — Version & Release

Quản lý phiên bản phát hành. Khác với Epic ở roadmap (uc-12-roadmap.md), version
**có ngày riêng** (FR-VER-01) — không cần suy ra từ issue con — vì bản chất
version là một mốc phát hành do người quản trị đặt trước, không phải một khái
niệm tổng hợp.

**Phase:** 12 · **Feature:** KJ-VER-01 → KJ-VER-06
**Liên quan:** [uc-04-project.md](uc-04-project.md) · [uc-05-issue.md](uc-05-issue.md) · [uc-07-workflow.md](uc-07-workflow.md) · [roadmap.md — Phase 12](../roadmap.md)

---

## UC-VER-01 — Tạo và quản lý version

**Requirement:** FR-VER-01
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** không có

### Luồng chính

1. Mở trang version của project
2. Tạo version với tên, mô tả, ngày bắt đầu, ngày phát hành (FR-VER-01) — cả hai
   ngày đều tuỳ chọn, không bắt buộc phải có để tạo version
3. Sửa thông tin version, hoặc đổi thứ tự hiển thị (kéo thả)

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-VER-01/NT-01 | Xoá version đang được gán cho issue | Cảnh báo kèm số lượng issue bị ảnh hưởng, cho chọn: bỏ gán khỏi các issue đó, hoặc chuyển sang version khác — cùng cách UC-PRJ-04 xử lý xoá component |
| UC-VER-01/NT-02 | Tạo/sửa version khi mất kết nối | Vào hàng đợi bền cục bộ, hiển thị trạng thái "đang chờ đồng bộ"; áp dụng lạc quan lên danh sách version hiển thị |
| UC-VER-01/NT-03 | Gửi lại cùng một lần tạo version với cùng khoá chống trùng | Không tạo bản ghi version thứ hai — server trả lại kết quả của lần tạo đầu |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-VER-01/NL-01 | Ngày phát hành trước ngày bắt đầu | Từ chối lưu, báo lỗi tại chỗ |
| UC-VER-01/NL-02 | Không có quyền quản trị project | Không hiển thị chức năng tạo/sửa/xoá version |

### Hậu điều kiện

Version tồn tại ở cấp project, chưa gán cho issue nào — gán là việc của UC-VER-02.

### Ảnh hưởng tới đồng bộ

Version thuộc sync scope `proj:{projectId}`. Tạo/sửa/xoá version phát delta cho
chính bản ghi version; xoá kèm bỏ gán (NT-01) phát thêm delta cho từng issue bị
ảnh hưởng trong cùng đợt cập nhật.

---

## UC-VER-02 — Gán version cho issue

**Requirement:** FR-VER-02
**Actor:** thành viên có quyền sửa issue
**Tiền điều kiện:** project có ít nhất một version (UC-VER-01)

### Luồng chính

1. Trên một issue, gán **version bị ảnh hưởng** (affects version) và/hoặc
   **version sẽ sửa** (fix version) — hai trường độc lập, mỗi trường cho phép
   chọn **nhiều** version cùng lúc (một lỗi có thể ảnh hưởng nhiều bản phát
   hành cũ, và được lên kế hoạch sửa ở nhiều bản phát hành tới)
2. Hai trường này là trường hệ thống mới của issue kể từ Phase 12 (FR-VER-02)
   — trước phase này issue chưa có hai trường này, cùng cách "còn lại"/"đã
   dùng" là trường hệ thống mới thêm ở Phase 11 (uc-13-time.md)

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-VER-02/NT-01 | Gán version khi mất kết nối | Vào hàng đợi bền cục bộ như mọi thay đổi trường issue khác (UC-ISS-03/NT-01 áp dụng tương tự) |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-VER-02/NL-01 | Gán version đã lưu trữ (UC-VER-06) cho issue | Chặn ở giao diện chọn — version lưu trữ không hiện trong danh sách có thể gán mới, nhưng issue đã gán từ trước vẫn giữ nguyên tham chiếu |
| UC-VER-02/NL-02 | Không có quyền sửa issue | Trường version hiển thị ở chế độ chỉ đọc |

### Hậu điều kiện

Issue mang tham chiếu tới version được gán ở affects version và/hoặc fix version.

### Ảnh hưởng tới đồng bộ

Thay đổi version của issue phát delta như mọi trường hệ thống khác, cùng cơ chế
nhật ký thay đổi đã có từ UC-ISS-14.

---

## UC-VER-03 — Trang release với tiến độ

**Requirement:** FR-VER-03
**Actor:** thành viên có quyền xem project
**Tiền điều kiện:** không có

### Luồng chính

1. Mở trang release của một version, xem toàn bộ issue có **fix version** là
   version đó
2. Hiển thị tiến độ: số issue ở trạng thái thuộc nhóm "đã xong" (UC-WKF-01)
   trên tổng số issue, dạng thanh phần trăm
3. Danh sách issue chưa xong hiển thị riêng, nổi bật hơn issue đã xong

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-VER-03/NT-01 | Version chưa có issue nào gán fix version | Trang release hiện tiến độ 0%, không có gì trong danh sách chưa xong |
| UC-VER-03/NT-02 | Project dùng nhiều workflow theo loại issue (workflow scheme, UC-WKF-06) | Tiến độ tính "đã xong" theo đúng nhóm trạng thái của workflow tương ứng từng issue, không giả định một workflow chung |

### Hậu điều kiện

Không có — đây là thao tác chỉ đọc, không đổi trạng thái hệ thống.

### Ảnh hưởng tới đồng bộ

Không áp dụng — trang release đọc trực tiếp từ store cục bộ theo sync scope
`proj:{projectId}` đã có, không cần request hay scope riêng.

---

## UC-VER-04 — Cảnh báo khi phát hành còn issue chưa xong

**Requirement:** FR-VER-04
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** version chưa ở trạng thái đã phát hành

### Luồng chính

1. Yêu cầu phát hành (release) một version → hệ thống liệt kê mọi issue có fix
   version là version này nhưng **chưa** ở trạng thái thuộc nhóm "đã xong"
2. Hiển thị cảnh báo rõ số lượng issue chưa xong, **không chặn** — cho phép
   tiếp tục phát hành nếu người dùng xác nhận
3. Xác nhận → version chuyển sang trạng thái **đã phát hành**, ghi lại ngày
   phát hành thực tế (có thể khác ngày phát hành dự kiến đã đặt ở UC-VER-01)

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-VER-04/NT-01 | Người dùng huỷ giữa chừng sau khi thấy cảnh báo | Version giữ nguyên trạng thái chưa phát hành, không có thay đổi nào được ghi |
| UC-VER-04/NT-02 | Issue chưa xong vẫn còn sau khi version đã phát hành | Cho phép tồn tại — không có ràng buộc issue phải chuyển version hay đóng lại; đây là quyết định của người quản trị, hệ thống chỉ cảnh báo chứ không áp đặt |
| UC-VER-04/NT-03 | Gửi lại yêu cầu phát hành với cùng khoá chống trùng (ví dụ bấm xác nhận hai lần do mạng chậm) | Không phát hành lần thứ hai — server trả lại trạng thái đã phát hành từ lần xác nhận đầu, không ghi đè ngày phát hành thực tế |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-VER-04/NL-01 | Không có quyền quản trị project | Không hiển thị chức năng phát hành |

### Hậu điều kiện

Version đã phát hành có một ngày phát hành thực tế cố định, tách biệt với ngày
phát hành dự kiến.

### Ảnh hưởng tới đồng bộ

Đổi trạng thái phát hành phát một delta cho version trong sync scope
`proj:{projectId}`; trang release và các view liệt kê version cập nhật ngay.

---

## UC-VER-05 — Sinh ghi chú phát hành

**Requirement:** FR-VER-05
**Actor:** thành viên có quyền xem project
**Tiền điều kiện:** version đang xét có ít nhất một issue gán fix version

### Luồng chính

1. Sinh ghi chú phát hành (release notes) từ danh sách issue có fix version là
   version đã phát hành, **nhóm theo loại issue** (Story, Task, Bug…)
2. Xuất ra dạng văn bản có định dạng, sao chép được hoặc tải về

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-VER-05/NT-01 | Issue không có mô tả hoặc mô tả rỗng | Vẫn liệt kê issue trong ghi chú, chỉ hiện tiêu đề và mã issue, không có dòng mô tả |
| UC-VER-05/NT-02 | Issue bị giới hạn người xem (ví dụ do quyền project) sau khi ghi chú đã sinh | Không ảnh hưởng bản ghi chú đã sinh trước đó — ghi chú là một bản xuất tĩnh tại thời điểm sinh, không phải khung nhìn động |

> **Chưa chốt:** tài liệu hiện có (`functional.md` FR-VER-05, mức ưu tiên
> SHOULD) chưa nói định dạng xuất cụ thể (Markdown, HTML, hay cả hai) hay có
> tuỳ biến mẫu (template) được không. Để lại cho lúc thiết kế chi tiết.

### Hậu điều kiện

Không có — sinh ghi chú là một bản xuất tĩnh, không ghi lại trạng thái nào trong
hệ thống.

### Ảnh hưởng tới đồng bộ

Không áp dụng — ghi chú dựng từ dữ liệu cục bộ tại thời điểm yêu cầu, không lưu
lại và không phát delta.

---

## UC-VER-06 — Lưu trữ version

**Requirement:** FR-VER-06
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** version cần lưu trữ/khôi phục đã tồn tại (UC-VER-01)

### Luồng chính

1. Lưu trữ (archive) một version, đã phát hành hoặc chưa
2. Version lưu trữ không còn hiện trong danh sách chọn khi gán version mới cho
   issue (xem UC-VER-02), nhưng vẫn hiện trên issue đã gán từ trước và trong
   trang release của chính nó
3. Khôi phục version đã lưu trữ về trạng thái hoạt động bình thường

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-VER-06/NT-01 | Lưu trữ version đang có issue chưa xong | Cho phép trực tiếp, không cảnh báo như UC-VER-04 — lưu trữ chỉ ẩn khỏi danh sách chọn, không phải một dạng "đóng" version |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-VER-06/NL-01 | Không có quyền quản trị project | Không hiển thị chức năng lưu trữ/khôi phục |

### Hậu điều kiện

Version chuyển sang trạng thái lưu trữ hoặc trở lại hoạt động bình thường;
tham chiếu trên issue đã gán không đổi.

### Ảnh hưởng tới đồng bộ

Đổi trạng thái lưu trữ phát một delta cho version trong sync scope
`proj:{projectId}`; client cập nhật ngay danh sách chọn version khi gán mới.

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-VER-01 | Ngày phát hành của version không được trước ngày bắt đầu |
| QT-VER-02 | Xoá version đang được gán yêu cầu xử lý các issue liên quan trước, cùng cách UC-PRJ-04 xử lý component |
| QT-VER-03 | Affects version và fix version là hai trường độc lập, mỗi trường cho phép gán nhiều version |
| QT-VER-04 | Tiến độ release tính theo nhóm trạng thái "đã xong" của workflow đang áp dụng cho từng issue, không giả định một workflow chung |
| QT-VER-05 | Phát hành version còn issue chưa xong chỉ cảnh báo, không chặn |
| QT-VER-06 | Version đã phát hành có ngày phát hành thực tế, tách biệt với ngày phát hành dự kiến |
| QT-VER-07 | Version lưu trữ không hiện trong danh sách gán mới, nhưng vẫn giữ nguyên trên issue đã gán và trong trang release của nó |

## Yêu cầu phi chức năng liên quan

`NFR-01` sửa/gán version phản hồi tức thì trước khi server xác nhận · `NFR-20`
trang release không rò rỉ dữ liệu ngoài quyền xem project
