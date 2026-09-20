# UC-BLK — Bulk & Import/Export

Thao tác trên khối lượng lớn và di chuyển dữ liệu. Không có đường ghi dữ liệu
tắt nào riêng cho bulk: mỗi thay đổi trong một thao tác hàng loạt vẫn đi qua
đúng command handler và đúng bước kiểm tra quyền của module sở hữu dữ liệu đó,
đúng invariant #29 của [CLAUDE.md](../../../CLAUDE.md#architecture) — cùng nguyên
tắc đã áp dụng cho automation ở [uc-16-automation.md — UC-AUT-04](uc-16-automation.md#uc-aut-04--các-loại-hành-động).
Chuyển đổi hàng loạt khi đổi workflow đã có luồng riêng ở
[uc-07-workflow.md — UC-WKF-08](uc-07-workflow.md#uc-wkf-08--chuyển-đổi-issue-đang-tồn-tại-khi-đổi-workflow)
và không được định nghĩa lại ở đây.

**Phase:** 15 · **Feature:** KJ-BLK-01 → KJ-BLK-07
**Liên quan:** [uc-05-issue.md](uc-05-issue.md) · [uc-07-workflow.md](uc-07-workflow.md) · [uc-09-search.md](uc-09-search.md) · [uc-16-automation.md](uc-16-automation.md) · [roadmap.md — Phase 15](../roadmap.md)

---

## UC-BLK-01 — Thao tác hàng loạt với xem trước và xác nhận

**Requirement:** FR-BLK-01
**Actor:** thành viên có quyền tương ứng với từng issue trong tập đã chọn
**Tiền điều kiện:** có một tập issue đã chọn (từ bảng, board, hoặc kết quả truy vấn của [uc-09-search.md](uc-09-search.md))

### Luồng chính

1. Chọn một thao tác hàng loạt: sửa trường, chuyển trạng thái, di chuyển sang
   project khác, xoá mềm, hoặc theo dõi/bỏ theo dõi — áp dụng cho toàn bộ tập
   issue đã chọn
2. Hệ thống hiển thị **bản xem trước**: với từng issue, thao tác sẽ thành công
   hay bị chặn (ví dụ thiếu quyền, thiếu bước chuyển hợp lệ), kèm lý do cho
   từng issue bị chặn
3. Xác nhận → hệ thống thực hiện thao tác cho **từng issue một lệnh riêng**,
   qua đúng command handler và đúng bước kiểm tra quyền của module sở hữu dữ
   liệu đó (issue, workflow…) — không có một lệnh "ghi hàng loạt" bỏ qua tầng
   đó

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-BLK-01/NT-01 | Một số issue trong tập không thoả điều kiện (thiếu quyền, không có bước chuyển hợp lệ…) | Bản xem trước báo rõ **trước khi xác nhận**; người dùng chọn tiếp tục với phần issue hợp lệ hoặc huỷ toàn bộ, không có chế độ "cố làm hết rồi báo lỗi sau" |
| UC-BLK-01/NT-02 | Gửi lại xác nhận cùng một thao tác hàng loạt với cùng khoá chống trùng (ví dụ do mất kết nối giữa chừng) | Mỗi lệnh con (một issue) mang khoá chống trùng riêng theo id issue, nên phần đã chạy không chạy lại lần hai — chỉ phần chưa chạy được tiếp tục |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-BLK-01/NL-01 | Xác nhận xong, một issue thất bại vì trạng thái đã đổi giữa lúc xem trước và lúc xác nhận (đua với thao tác khác) | Issue đó báo lỗi riêng trong kết quả cuối, các issue khác trong tập không bị ảnh hưởng — mỗi issue là một lệnh độc lập, không có giao dịch chung cho cả tập |

### Hậu điều kiện

Kết quả cuối liệt kê rõ issue nào thành công, issue nào thất bại kèm lý do —
không có trạng thái "một phần đã đổi, không rõ đổi tới đâu".

### Ảnh hưởng tới đồng bộ

Không có delta "bulk" riêng — mỗi issue thành công phát đúng delta của thao tác
đó (đổi trường như UC-ISS-03, chuyển trạng thái như UC-WKF-02…), xem cơ chế chia
lô ở UC-BLK-02.

---

## UC-BLK-02 — Chia lô và chống làm ngập luồng đồng bộ

**Actor:** hệ thống (không có giao diện riêng — áp dụng cho mọi lần chạy của UC-BLK-01)
**Tiền điều kiện:** không có

### Luồng chính

1. Một thao tác hàng loạt trên nhiều issue chạy theo **lô nhỏ** tuần tự, không
   phát hết delta cùng lúc cho client
2. Khi số lượng issue bị ảnh hưởng vượt một ngưỡng, hệ thống **gộp** các delta
   riêng lẻ thành một tín hiệu "tải lại scope" thay vì phát từng delta một,
   cùng nguyên tắc chia lô đã dùng ở
   [uc-07-workflow.md — UC-WKF-08](uc-07-workflow.md#uc-wkf-08--chuyển-đổi-issue-đang-tồn-tại-khi-đổi-workflow)

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-BLK-02/NL-01 | Thao tác hàng loạt bị dừng giữa chừng (mất kết nối, người dùng huỷ) | Các lô đã chạy giữ nguyên kết quả, không hoàn tác — mỗi lô là các lệnh độc lập đã hoàn tất (xem UC-BLK-01); phần chưa chạy không thực hiện |

### Hậu điều kiện

Số lô đã chạy được ghi rõ, tách biệt phần đã áp dụng và phần chưa chạy —
tương ứng đúng NL-01 khi dừng giữa chừng.

### Ảnh hưởng tới đồng bộ

Không có một loại delta "bulk" riêng — mỗi issue vẫn phát đúng delta bình
thường của thao tác đó; điểm khác biệt duy nhất là gộp thành tín hiệu tải lại
scope khi số lượng vượt ngưỡng, để client không phải xử lý hàng nghìn delta
liên tiếp.

> **Chưa chốt:** tài liệu hiện có (`roadmap.md` Phase 15) nêu rủi ro cần "cơ
> chế gộp delta hoặc buộc client tải lại scope" nhưng chưa chốt ngưỡng cụ thể
> (số issue mỗi lô, số lô trước khi chuyển sang gộp). Để lại cho lúc thiết kế
> chi tiết, dựa trên đo đạc thực tế.

---

## UC-BLK-03 — Nhập từ CSV với ánh xạ cột

**Requirement:** FR-BLK-02
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** không có

### Luồng chính

1. Tải lên tệp CSV
2. Ánh xạ từng cột trong CSV sang một trường của issue (hệ thống hoặc tuỳ
   biến — xem [uc-08-field.md](uc-08-field.md)); cột không ánh xạ bị bỏ qua
3. Xem trước một số dòng đầu theo ánh xạ đã chọn trước khi chạy thử

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-BLK-03/NL-01 | Cột CSV không khớp kiểu trường đã ánh xạ (ví dụ văn bản vào trường số) | Đánh dấu ngay ở bước xem trước, không chờ tới lúc chạy thử |
| UC-BLK-03/NL-02 | Tệp CSV rỗng hoặc không có dòng dữ liệu | Từ chối, báo lỗi tại chỗ |
| UC-BLK-03/NL-03 | Không có quyền quản trị project | Không hiển thị chức năng nhập CSV |

### Hậu điều kiện

Ánh xạ cột → trường được lưu tạm cho bước chạy thử (UC-BLK-04); chưa có issue
nào được tạo.

### Ảnh hưởng tới đồng bộ

Không áp dụng — ánh xạ cột là bước chuẩn bị cục bộ, chưa ghi dữ liệu nào cần
phát delta.

---

## UC-BLK-04 — Chạy thử và báo lỗi theo từng dòng

**Requirement:** FR-BLK-02
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** đã ánh xạ cột (UC-BLK-03)

### Luồng chính

1. Chạy thử (dry run): kiểm tra hợp lệ từng dòng theo đúng quy tắc kiểm tra
   hợp lệ trường mà UC-ISS-01/UC-FLD-03 đã dùng cho tạo issue thường, **không
   ghi dữ liệu**
2. Báo lỗi theo từng dòng: dòng nào hợp lệ, dòng nào lỗi kèm lý do cụ thể
3. Xác nhận nhập → chỉ tạo issue cho các dòng hợp lệ; nếu người dùng chọn "chỉ
   nhập khi toàn bộ hợp lệ", một dòng lỗi thì **không tạo issue nào**

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-BLK-04/NL-01 | Nhập thất bại giữa chừng (mất kết nối khi đang ghi các dòng hợp lệ) | Không để lại dữ liệu nửa vời — chạy theo lô có thể chạy lại an toàn, idempotent theo dòng (đánh dấu dòng đã tạo issue thành công để không tạo trùng khi chạy lại), cùng nguyên tắc UC-WKF-08 |
| UC-BLK-04/NL-02 | Dòng CSV tham chiếu người được gán hoặc component không tồn tại trong project | Báo lỗi dòng đó ở bước chạy thử, không tự tạo mới người hoặc component để khớp |

### Hậu điều kiện

Nhập dữ liệu thất bại giữa chừng không để lại dữ liệu nửa vời — đây là
Definition of Done của phase.

### Ảnh hưởng tới đồng bộ

Mỗi issue tạo thành công phát đúng delta tạo issue (UC-ISS-01) trong sync scope
`proj:{projectId}`, chạy theo cơ chế chia lô của UC-BLK-02 khi số dòng lớn.

---

## UC-BLK-05 — Nhập từ các công cụ khác

**Requirement:** FR-BLK-03
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** không có

### Luồng chính

1. Nhập dữ liệu trực tiếp từ Jira, Trello, hoặc GitHub Issues, không cần
   người dùng tự xuất CSV trước
2. Dữ liệu từ nguồn ngoài được ánh xạ sang mô hình issue của Kaiju rồi đi qua
   **cùng luồng chạy thử và báo lỗi theo dòng** đã có ở UC-BLK-04, không phải
   một luồng nhập riêng

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-BLK-05/NT-01 | Trường của nguồn ngoài không có tương đương trong mô hình issue của Kaiju | Bỏ qua trường đó ở bản nhập, báo rõ danh sách trường bị bỏ qua trước khi xác nhận |

> **Chưa chốt:** tài liệu hiện có (`functional.md` FR-BLK-03, mức ưu tiên
> SHOULD) chỉ nêu ba nguồn (Jira, Trello, GitHub Issues) chứ chưa nói cơ chế
> kết nối (API trực tiếp có xác thực OAuth, hay yêu cầu người dùng xuất file
> từ công cụ nguồn rồi tải lên). Để lại cho lúc thiết kế chi tiết.

### Hậu điều kiện

Dữ liệu từ nguồn ngoài đã ánh xạ sang mô hình issue của Kaiju, sẵn sàng cho
bước chạy thử của UC-BLK-04 — chưa có issue nào được tạo.

### Ảnh hưởng tới đồng bộ

Không áp dụng riêng — đi qua đúng luồng UC-BLK-04, phát delta theo cơ chế đã mô
tả ở đó.

---

## UC-BLK-06 — Xuất dữ liệu project

**Requirement:** FR-BLK-04
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** không có

### Luồng chính

1. Xuất **toàn bộ dữ liệu của một project** (FR-BLK-04): mọi issue với toàn bộ
   trường (hệ thống và tuỳ biến), bình luận, nhật ký thay đổi, liên kết —
   khác với [uc-09-search.md — UC-SRC-09](uc-09-search.md#uc-src-09--xuất-kết-quả-tìm-kiếm),
   vốn chỉ xuất các trường đang hiển thị của **một truy vấn đã lọc**, không
   phải toàn bộ dữ liệu project
2. Xuất chạy nền, gửi liên kết tải về khi hoàn tất — không giữ request mở chờ
   xuất xong như UC-SRC-09 vẫn có thể làm ở quy mô nhỏ

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-BLK-06/NT-01 | Project có khối lượng dữ liệu rất lớn khiến xuất chạy lâu | Vẫn chạy nền tới khi xong, không có giới hạn thời gian cứng như một request đồng bộ; người dùng có thể rời trang và quay lại tải khi có liên kết |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-BLK-06/NL-01 | Không có quyền quản trị project | Không hiển thị chức năng xuất dữ liệu |

### Hậu điều kiện

Một tệp xuất tồn tại, chứa đúng bản chụp dữ liệu project tại thời điểm bắt đầu
xuất.

### Ảnh hưởng tới đồng bộ

Không áp dụng — xuất là thao tác chỉ đọc, tệp xuất không phải dữ liệu client
giữ cục bộ và không phát delta; liên kết tải về được gửi qua thông báo, không
qua sync scope.

---

## UC-BLK-07 — Sao lưu và khôi phục cấp workspace

**Requirement:** FR-BLK-05
**Actor:** chủ sở hữu workspace
**Tiền điều kiện:** không có

### Luồng chính

1. Sao lưu toàn bộ dữ liệu của một workspace (mọi project, thành viên, cấu
   hình) thành một bản xuất duy nhất
2. Khôi phục từ một bản sao lưu vào một workspace **mới** (không ghi đè
   workspace đang có dữ liệu) — cùng nguyên tắc thận trọng đã dùng cho các
   thao tác không thể đảo ngược khác trong hệ thống

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-BLK-07/NL-01 | Khôi phục một bản sao lưu vào workspace đang có dữ liệu | Chặn — chỉ khôi phục vào workspace mới, tránh ghi đè âm thầm dữ liệu đang hoạt động |
| UC-BLK-07/NL-02 | Không phải chủ sở hữu workspace | Không hiển thị chức năng sao lưu/khôi phục |

> **Chưa chốt:** tài liệu hiện có (`functional.md` FR-BLK-05, mức ưu tiên
> SHOULD) chưa nói định dạng bản sao lưu, có mã hoá không, hay giới hạn tần
> suất sao lưu. Để lại cho lúc thiết kế chi tiết.

### Hậu điều kiện

Sao lưu tạo ra một bản xuất độc lập; khôi phục tạo ra một workspace mới với
đúng dữ liệu của bản sao lưu, workspace nguồn không bị ảnh hưởng.

### Ảnh hưởng tới đồng bộ

Sao lưu không phát delta — thao tác chỉ đọc. Khôi phục tạo workspace mới thì đi
theo đúng luồng bootstrap của UC-WSP-01: client đăng ký scope workspace mới và
tải toàn bộ dữ liệu từ đầu, không có cơ chế đồng bộ riêng cho khôi phục.

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-BLK-01 | Mỗi issue trong một thao tác hàng loạt là một lệnh độc lập, qua đúng command handler và đúng kiểm tra quyền — không có đường ghi tắt bỏ qua handler |
| QT-BLK-02 | Bản xem trước báo rõ issue nào sẽ bị chặn **trước khi** xác nhận, không có chế độ "cố làm hết rồi báo lỗi sau" |
| QT-BLK-03 | Thao tác hàng loạt chạy theo lô, gộp delta hoặc buộc tải lại scope khi vượt ngưỡng, để không làm ngập luồng đồng bộ của client |
| QT-BLK-04 | Nhập CSV/nguồn ngoài luôn qua bước chạy thử báo lỗi theo dòng, chạy lại an toàn (idempotent theo dòng), không để lại dữ liệu nửa vời |
| QT-BLK-05 | Nhập từ nguồn ngoài dùng chung luồng chạy thử/báo lỗi với nhập CSV, không phải một luồng nhập riêng |
| QT-BLK-06 | Xuất toàn bộ dữ liệu project (UC-BLK-06) khác phạm vi với xuất kết quả truy vấn (UC-SRC-09) — không gộp chung hai luồng |
| QT-BLK-07 | Khôi phục bản sao lưu workspace chỉ tạo workspace mới, không ghi đè workspace đang có dữ liệu |

## Yêu cầu phi chức năng liên quan

`NFR-01` bản xem trước và kết quả bulk phản hồi tức thì trước khi hoàn tất
toàn bộ · `NFR-07` mỗi lệnh trong thao tác hàng loạt vẫn kiểm tra quyền ở tầng
handler · `NFR-11` thao tác hàng loạt trên hàng nghìn issue không làm treo hệ
thống và không làm ngập luồng đồng bộ của client
