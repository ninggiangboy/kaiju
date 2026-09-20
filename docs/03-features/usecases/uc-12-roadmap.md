# UC-RDM — Roadmap & Timeline

Nhìn kế hoạch theo trục thời gian, ở cấp Epic. Roadmap không lưu ngày riêng —
nó tổng hợp ngày từ issue con (Phase 3) và dùng lại loại liên kết "chặn" đã có
từ UC-ISS-08 để suy ra phụ thuộc giữa các Epic, không phát minh mô hình dữ liệu
mới.

**Phase:** 10 · **Feature:** KJ-RDM-01 → KJ-RDM-06
**Liên quan:** [uc-05-issue.md](uc-05-issue.md) · [uc-11-sprint.md](uc-11-sprint.md) · [events-and-outbox.md](../../04-system-design/events-and-outbox.md) · [roadmap.md — Phase 10](../roadmap.md)

---

## UC-RDM-01 — Trục thời gian hiển thị Epic

**Actor:** thành viên có quyền xem project
**Tiền điều kiện:** project có ít nhất một Epic (UC-ISS-07)

### Luồng chính

1. Xem danh sách Epic của project dưới dạng thanh trên trục thời gian, mỗi
   thanh trải từ ngày bắt đầu tới ngày kết thúc suy ra được của Epic đó
   (xem UC-RDM-02)
2. Epic chưa suy ra được đủ ngày (xem ngoại lệ) vẫn hiện trong danh sách, ở một
   khu vực riêng ngoài trục thời gian chính, không bị ẩn đi

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Epic chưa có issue con nào | Không có ngày để suy ra — hiện trong khu vực "chưa lên kế hoạch", không vẽ trên trục |
| Epic có issue con nhưng không issue con nào có hạn hoàn thành | Không có ngày để suy ra — cùng xử lý như trên |

---

## UC-RDM-02 — Tổng hợp ngày từ issue con qua sự kiện

**Actor:** hệ thống (không có giao diện riêng — hệ quả của UC-RDM-01)
**Tiền điều kiện:** không có

### Luồng chính

1. Ngày kết thúc của một Epic là **hạn hoàn thành xa nhất** trong số hạn hoàn
   thành của các issue con trực tiếp (UC-ISS-07) — issue hệ thống chỉ có
   trường "hạn hoàn thành" (FR-ISS-04), không có trường "ngày bắt đầu" riêng
2. Ngày bắt đầu của một Epic là **thời điểm tạo** của issue con sớm nhất trong
   số issue con có hạn hoàn thành — dùng thời điểm tạo vì không có trường ngày
   bắt đầu ở issue để tổng hợp từ đó
3. Mỗi khi một issue con đổi hạn hoàn thành, được tạo mới, bị xoá mềm, hoặc đổi
   Epic cha, module `issue` phát domain event; roadmap **nghe sự kiện đó và
   tính lại** ngày của Epic liên quan — không đọc trực tiếp bảng của module
   `issue` (đúng luật biên giới module)

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Issue con bị xoá mềm (UC-ISS-04) | Không tính vào tổng hợp ngày của Epic; ngày của Epic tính lại như thể issue đó chưa từng tồn tại |
| Issue con chuyển sang Epic khác (UC-ISS-11/UC-ISS-12 loại thao tác tương tự) | Cả Epic cũ và Epic mới đều được tính lại ngày |
| Sự kiện được relay worker gửi lại (delivery ít nhất một lần) | Tính lại ngày là phép toán idempotent theo bản chất (luôn quét lại toàn bộ issue con hiện có của Epic), không cần cơ chế chống trùng riêng |

> **Chưa chốt:** tài liệu hiện có (`functional.md` FR-ISS-04, `uc-05-issue.md`
> UC-ISS-01) không định nghĩa trường "ngày bắt đầu" cho issue — chỉ có "hạn
> hoàn thành". Use case này chọn dùng thời điểm tạo issue làm ngày bắt đầu suy
> ra vì đó là dữ liệu duy nhất luôn có sẵn, nhưng đây là một lựa chọn hợp lý
> chứ không phải điều đã được chốt ở tài liệu nguồn nào. Nếu sau này Phase 6
> hoặc một phase khác thêm trường "ngày bắt đầu" cho issue, roadmap nên đổi
> sang dùng trường đó thay vì thời điểm tạo.

### Ảnh hưởng tới đồng bộ

Ngày tổng hợp của Epic không phải là trường lưu cố định đồng bộ như trường hệ
thống khác — nó được tính lại phía server khi nghe sự kiện, rồi phát delta của
riêng nó (Epic đổi ngày) vào sync scope `proj:{projectId}`, tương tự cách
`activity` phát dòng hoạt động từ sự kiện của module khác (xem
[uc-06-collaboration.md — UC-COL-05](uc-06-collaboration.md#uc-col-05--dòng-hoạt-động)).

---

## UC-RDM-03 — Phụ thuộc giữa các Epic

**Actor:** thành viên có quyền sửa issue
**Tiền điều kiện:** có ít nhất hai Epic

### Luồng chính

1. Roadmap hiển thị đường nối giữa hai Epic khi tồn tại liên kết loại "chặn"
   (UC-ISS-08) giữa một issue thuộc Epic này và một issue thuộc Epic kia —
   không có loại liên kết riêng "phụ thuộc Epic", dùng lại nguyên loại liên
   kết đã có ở Phase 3
2. Tạo liên kết "chặn" trực tiếp giữa hai Epic ngay trên roadmap, tương đương
   tạo liên kết ở màn hình issue (UC-ISS-08)

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Nhiều cặp issue con giữa hai Epic cùng có liên kết "chặn" | Roadmap chỉ vẽ **một** đường nối giữa hai Epic, không vẽ lặp cho từng cặp issue |
| Epic tự chặn chính nó qua một chuỗi issue con | Xem UC-RDM-04 |

---

## UC-RDM-04 — Phát hiện phụ thuộc vòng và xung đột lịch

**Actor:** hệ thống (không có giao diện riêng) và thành viên có quyền sửa issue

### Luồng chính

1. Khi một liên kết "chặn" mới được tạo (trực tiếp giữa Epic hoặc giữa hai
   issue con thuộc hai Epic khác nhau), hệ thống kiểm tra đồ thị phụ thuộc
   giữa các Epic bị ảnh hưởng
2. Phát hiện vòng (Epic A chặn Epic B, B chặn A, trực tiếp hoặc qua chuỗi
   nhiều Epic) → từ chối tạo liên kết, báo rõ chuỗi gây vòng
3. Phát hiện xung đột lịch (Epic bị chặn có ngày bắt đầu suy ra sớm hơn ngày
   kết thúc suy ra của Epic chặn nó) → **không chặn** việc tạo liên kết, chỉ
   cảnh báo trực quan trên roadmap — lịch là hệ quả suy ra từ issue con, không
   phải ràng buộc cứng phải sửa ngay

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Vòng phụ thuộc hình thành gián tiếp qua đổi Epic cha của một issue con (không qua thao tác tạo liên kết) | Kiểm tra chạy lại mỗi khi đồ thị phụ thuộc Epic có thể đổi — kể cả khi nguyên nhân là đổi Epic cha, không chỉ khi tạo liên kết mới |
| Xung đột lịch tự hết do issue con đổi hạn hoàn thành | Cảnh báo tự biến mất ở lần tính lại ngày tiếp theo (UC-RDM-02), không cần thao tác thủ công để xoá cảnh báo |

### Hậu điều kiện

Không tồn tại vòng phụ thuộc giữa các Epic sau khi một liên kết được chấp
nhận — đây là Definition of Done của phase.

---

## UC-RDM-05 — Kéo đổi ngày và thu phóng

**Actor:** thành viên có quyền sửa issue

### Luồng chính

1. Thu phóng trục thời gian theo tuần, tháng, hoặc quý
2. Kéo một đầu thanh Epic để đổi ngày — vì ngày Epic là suy ra từ issue con
   (UC-RDM-02), kéo đổi ngày Epic là **đổi hạn hoàn thành của issue con** tương
   ứng (issue con có hạn hoàn thành xa nhất khi kéo đầu kết thúc), không có một
   trường "ngày Epic" độc lập để ghi trực tiếp

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Kéo đầu bắt đầu của thanh Epic | Không có trường "ngày bắt đầu" issue để ghi (xem ghi chú Chưa chốt ở UC-RDM-02) — **không hỗ trợ** kéo đầu bắt đầu ở phase này, chỉ đầu kết thúc kéo được |
| Kéo đầu kết thúc khi Epic có nhiều issue con cùng mang hạn hoàn thành xa nhất | Đổi hạn hoàn thành của **tất cả** issue con đang giữ giá trị xa nhất đó theo cùng độ dịch chuyển |
| Kéo tạo xung đột lịch với Epic phụ thuộc | Vẫn cho phép (giống UC-RDM-04), chỉ cảnh báo |

### Ảnh hưởng tới đồng bộ

Kéo đổi ngày phát đúng delta thay đổi hạn hoàn thành của issue (cùng cơ chế
UC-ISS-03/UC-ISS-14), không phải một loại delta "roadmap" riêng; ngày mới của
Epic hiển thị trên roadmap tới sau, khi UC-RDM-02 tính lại từ sự kiện.

---

## UC-RDM-06 — Lọc, chia sẻ và xuất ảnh roadmap

**Actor:** thành viên có quyền xem project

### Luồng chính

1. Lọc roadmap theo Epic, theo trạng thái, theo người được gán của issue con
2. Chia sẻ trạng thái lọc hiện tại bằng liên kết (tham số nằm trên URL, không
   cần lưu thành một đối tượng riêng như bộ lọc đã lưu ở UC-SRC-08)
3. Xuất ảnh tĩnh (PNG) của khung nhìn roadmap đang xem

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Người mở liên kết chia sẻ không có quyền xem project | Chặn ở cùng tầng kiểm tra quyền thông thường, không lộ dữ liệu qua tham số URL |

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-01 | Roadmap không lưu ngày riêng cho Epic — luôn tổng hợp từ hạn hoàn thành của issue con hiện có |
| QT-02 | Roadmap tính lại ngày Epic qua domain event từ module `issue`, không tự đọc bảng của module `issue` |
| QT-03 | Phụ thuộc giữa Epic dùng lại loại liên kết "chặn" đã có từ Phase 3, không có loại liên kết riêng cho Epic |
| QT-04 | Không cho phép tạo liên kết tạo thành vòng phụ thuộc giữa các Epic |
| QT-05 | Xung đột lịch giữa Epic phụ thuộc chỉ cảnh báo, không chặn thao tác |
| QT-06 | Kéo đổi ngày trên roadmap là ghi trực tiếp vào hạn hoàn thành của issue con, không có trường ngày Epic độc lập |
| QT-07 | Liên kết chia sẻ roadmap vẫn phải qua đúng kiểm tra quyền xem project, không lộ dữ liệu qua tham số URL |

## Yêu cầu phi chức năng liên quan

`NFR-17` consumer sự kiện tính lại ngày Epic phải chống trùng hoặc idempotent
theo bản chất · `NFR-01` kéo đổi ngày phản hồi tức thì trước khi server xác
nhận · `NFR-20` liên kết chia sẻ không rò rỉ dữ liệu ngoài quyền xem project
