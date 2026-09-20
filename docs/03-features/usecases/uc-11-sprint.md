# UC-SPR — Sprint & Scrum

Quy trình Scrum đầy đủ, xây trên nền board Kanban (Phase 8) và phân cấp issue
(Phase 3). Sprint không phải một loại board khác — nó là một **nguồn issue có
vòng đời** (tạo, bắt đầu, kết thúc) mà board của Phase 8 hiển thị, giống cách
board Kanban hiển thị kết quả của một bộ lọc đã lưu.

**Phase:** 9 · **Feature:** KJ-SPR-01 → KJ-SPR-09
**Liên quan:** [uc-05-issue.md](uc-05-issue.md) · [uc-10-board.md](uc-10-board.md) · [uc-04-project.md](uc-04-project.md) · [backend-modules.md](../../04-system-design/backend-modules.md) · [roadmap.md — Phase 9](../roadmap.md)

---

## UC-SPR-01 — Màn hình backlog kéo thả và gom nhóm theo epic

**Actor:** thành viên có quyền sửa issue
**Tiền điều kiện:** project thuộc loại có bật Sprint & Scrum (UC-PRJ-04)

### Luồng chính

1. Xem danh sách issue chưa thuộc sprint nào, dạng phẳng có thứ hạng — cùng cơ
   chế UC-ISS-09 (rank chuỗi) và cùng cách trình bày backlog đã có ở UC-BRD-08
2. Gom nhóm hiển thị theo Epic cha (UC-ISS-07); issue không có Epic gom vào
   nhóm "không có Epic"
3. Kéo thả để đổi thứ tự trong backlog, hoặc kéo issue vào một sprint cụ thể

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Kéo một Epic vào sprint | Chỉ Epic được gán vào sprint; issue con **không** tự động được gán theo — phải kéo riêng, vì issue con có thể thuộc sprint khác hoặc chưa lên kế hoạch |
| Project chưa bật Sprint & Scrum | Không có màn hình backlog dạng này — dùng backlog thường của board Kanban (UC-BRD-08) |

---

## UC-SPR-02 — Tạo sprint với mục tiêu và thời gian

**Actor:** thành viên có quyền quản trị project

### Luồng chính

1. Tạo sprint: tên, mục tiêu (văn bản ngắn), ngày bắt đầu, ngày kết thúc
2. Sprint ở trạng thái **chưa bắt đầu** cho tới khi thực hiện UC-SPR-03
3. Có thể tạo nhiều sprint chưa bắt đầu cùng lúc để lên kế hoạch trước

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Ngày kết thúc trước hoặc trùng ngày bắt đầu | Từ chối lưu, báo lỗi tại chỗ |
| Xoá sprint chưa bắt đầu | Cho phép trực tiếp — issue đã gán quay lại backlog |

---

## UC-SPR-03 — Bắt đầu sprint

**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** sprint ở trạng thái chưa bắt đầu, có ít nhất một issue

### Luồng chính

1. Xác nhận bắt đầu sprint → sprint chuyển sang trạng thái **đang chạy**
2. Từ thời điểm này, sprint có board riêng (UC-SPR-07) và được tính vào báo cáo
   burndown (UC-SPR-08)

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Sprint rỗng (không có issue nào) | Cảnh báo trước khi cho bắt đầu, không chặn cứng — một số đội cố ý bắt đầu rỗng rồi kéo issue vào sau |
| Bắt đầu một sprint khi đã có sprint khác đang chạy | Cho phép nếu project bật nhiều sprint song song (UC-SPR-05); nếu không bật thì chặn, yêu cầu kết thúc sprint đang chạy trước |

---

## UC-SPR-04 — Kết thúc sprint và xử lý issue chưa xong

**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** sprint đang chạy

### Luồng chính

1. Yêu cầu kết thúc sprint → hệ thống liệt kê mọi issue **chưa ở trạng thái
   thuộc nhóm "đã xong"** (UC-WKF-01) tại thời điểm kết thúc
2. Với từng issue chưa xong, chọn một trong ba hướng xử lý: chuyển vào backlog,
   chuyển sang một sprint khác đang hoặc sắp chạy, hoặc chuyển vào một sprint
   mới sẽ tạo tại chỗ
3. Xác nhận → sprint chuyển sang trạng thái **đã kết thúc** (đóng băng, không
   nhận thêm issue), báo cáo velocity của sprint được chốt tại thời điểm này

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Không chọn hướng xử lý cho một issue chưa xong | Chặn kết thúc sprint cho tới khi mọi issue chưa xong đều có hướng xử lý — đây là điều kiện "mọi lựa chọn phải đúng" nêu ở feature catalog |
| Issue chuyển trạng thái sang "đã xong" đúng lúc đang xử lý màn hình kết thúc sprint (đua với thao tác khác) | Tính lại danh sách issue chưa xong ngay trước khi xác nhận, không dùng danh sách đã hiển thị từ đầu phiên |

### Hậu điều kiện

Sprint đã kết thúc không còn nhận issue mới; số liệu velocity của sprint đó cố
định vĩnh viễn, không đổi theo thay đổi issue về sau (xem UC-SPR-08).

---

## UC-SPR-05 — Nhiều sprint song song

**Actor:** thành viên có quyền quản trị workspace

### Luồng chính

1. Bật tuỳ chọn cho phép nhiều sprint đang chạy đồng thời trong cùng một project
2. Mỗi issue chỉ thuộc **đúng một** sprint đang chạy tại một thời điểm, kể cả
   khi tính năng này được bật

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Tắt tính năng này khi đang có nhiều sprint chạy song song | Cho phép tắt; các sprint đang chạy tiếp tục chạy tới khi kết thúc, chỉ chặn **bắt đầu thêm** sprint mới trong lúc còn một sprint đang chạy |

---

## UC-SPR-06 — Story point và lập kế hoạch theo năng lực

**Actor:** thành viên có quyền sửa issue (ước lượng) · thành viên có quyền quản trị project (đặt năng lực)

### Luồng chính

1. Story point là **trường hệ thống của issue** (FR-ISS-04, đã có từ UC-ISS-01
   ở Phase 3) — module `sprint` không lưu một bản sao riêng, chỉ đọc qua API
   công khai của module `issue` khi lập kế hoạch và tính báo cáo
2. Khi lên kế hoạch sprint, đặt năng lực (capacity) cho từng thành viên trong
   sprint đó — theo story point hoặc theo giờ, tuỳ cấu hình project
3. Màn hình lập kế hoạch hiển thị tổng story point đã gán cho mỗi thành viên
   so với năng lực đã đặt, cảnh báo khi vượt

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Issue chưa có story point được kéo vào sprint | Cho phép — không bắt buộc ước lượng trước khi lên sprint, chỉ không tính vào tổng story point cho tới khi được ước lượng |
| Issue con (Sub-task) có story point riêng | Không cộng dồn vào story point của issue cha khi tính tổng sprint — mỗi issue tính theo story point của chính nó, tránh đếm hai lần |

> **Departure đã ghi nhận (2026-09-20):** khi viết use case này phát hiện
> [backend-modules.md](../../04-system-design/backend-modules.md) liệt kê
> "story point" trong cột khái niệm module `sprint` sở hữu, mâu thuẫn với
> `functional.md` (FR-ISS-04) và `uc-05-issue.md` (UC-ISS-01) — cả hai đã chốt
> từ Phase 3 rằng story point là trường hệ thống của issue, do module `issue`
> lưu trữ. Đã sửa `backend-modules.md` trong cùng đợt thay đổi này (kèm
> `> Changed` note tại đó) để module `issue` sở hữu story point; module
> `sprint` chỉ đọc qua API công khai của `issue`, đúng như luồng chính ở trên.

---

## UC-SPR-07 — Board của sprint hiện tại

**Actor:** thành viên có quyền xem project
**Tiền điều kiện:** có sprint đang chạy

### Luồng chính

1. Board của sprint dùng lại nguyên cơ chế board Kanban ở [uc-10-board.md](uc-10-board.md)
   (cột ánh xạ trạng thái, kéo thả qua workflow, WIP limit, làn ngang…) — khác
   biệt duy nhất là **nguồn issue**: thay vì một bộ lọc đã lưu tuỳ ý (UC-BRD-01),
   nguồn là "issue thuộc sprint đang chạy"
2. Nhiều sprint song song (UC-SPR-05) → mỗi sprint đang chạy có board riêng

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Kéo issue ra khỏi sprint ngay trên board (không qua màn hình backlog) | Cho phép — issue quay lại backlog, board sprint không còn hiển thị nó |

---

## UC-SPR-08 — Báo cáo burndown, burnup và velocity

**Actor:** thành viên có quyền xem project

### Luồng chính

1. Biểu đồ burndown và burnup: story point còn lại / đã hoàn thành theo từng
   ngày trong sprint, dựng từ nhật ký thay đổi có sẵn (UC-ISS-14) — không duy
   trì bảng thống kê song song, cùng nguyên tắc đã áp dụng ở UC-BRD-09
2. Velocity: tổng story point hoàn thành mỗi sprint đã kết thúc, so sánh giữa
   các sprint để ước tính năng lực trung bình

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Issue được thêm vào sprint sau khi sprint đã bắt đầu | Biểu đồ vẫn tính đúng — điểm phạm vi (scope) sprint được vẽ lại theo thời điểm issue thực sự vào sprint, không giả định toàn bộ issue có mặt từ ngày đầu |
| Issue bị bớt khỏi sprint đang chạy | Tương tự — phạm vi sprint giảm đúng tại thời điểm issue bị bớt ra, không tính issue đó vào phần "chưa xong" ở cuối sprint |
| Sprint đã kết thúc (UC-SPR-04) | Số liệu velocity của sprint đã kết thúc là **cố định**, không tính lại dù dữ liệu issue có đổi sau đó (ví dụ story point bị sửa lại sau khi sprint đóng) |

### Hậu điều kiện

Báo cáo đúng cả khi issue được thêm hoặc bớt giữa sprint — đây là Definition of
Done của phase.

---

## UC-SPR-09 — Báo cáo sprint và báo cáo epic

**Actor:** thành viên có quyền xem project

### Luồng chính

1. Báo cáo sprint: tổng kết một sprint đã kết thúc — issue hoàn thành, issue bị
   đẩy ra, velocity, dựa trên cùng dữ liệu đã chốt ở UC-SPR-08
2. Báo cáo epic: tiến độ một Epic tổng hợp từ toàn bộ issue con (UC-ISS-07),
   không giới hạn trong một sprint — một Epic có thể trải qua nhiều sprint

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Epic có issue con chưa gán sprint nào | Vẫn tính vào tổng số issue con của Epic, hiển thị riêng ở nhóm "chưa lên kế hoạch" |

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-01 | Kéo một Epic vào sprint không tự động kéo issue con theo |
| QT-02 | Ngày kết thúc sprint phải sau ngày bắt đầu |
| QT-03 | Không bắt đầu sprint mới khi đã có sprint đang chạy, trừ khi project bật nhiều sprint song song |
| QT-04 | Kết thúc sprint bắt buộc phải có hướng xử lý cho mọi issue chưa ở trạng thái nhóm "đã xong" |
| QT-05 | Mỗi issue chỉ thuộc đúng một sprint đang chạy tại một thời điểm |
| QT-06 | Story point là trường hệ thống của module `issue`; module `sprint` chỉ đọc qua API công khai, không lưu bản sao |
| QT-07 | Story point của issue con không cộng dồn vào issue cha khi tính tổng sprint |
| QT-08 | Board của sprint dùng chung cơ chế board Kanban, chỉ khác nguồn issue |
| QT-09 | Velocity của một sprint đã kết thúc là cố định, không tính lại theo thay đổi dữ liệu về sau |
| QT-10 | Burndown/burnup phải phản ánh đúng thay đổi phạm vi (thêm/bớt issue) trong lúc sprint đang chạy |

## Yêu cầu phi chức năng liên quan

`NFR-01` kéo thả trong backlog và board sprint phản hồi tức thì · `NFR-11`
báo cáo dựa trên nhật ký thay đổi phải chịu được lịch sử dài mà không chậm ·
`NFR-20` báo cáo và board sprint không rò rỉ dữ liệu ngoài quyền xem project
