# UC-SRC — Search & Query

Truy vấn dữ liệu theo cách người dùng muốn. Đây là phase nhạy cảm nhất về phân
quyền trong toàn roadmap: truy vấn do người dùng tự viết, nên điều kiện phân
quyền **phải được ghép vào lúc dựng SQL**, không được lọc lại sau khi có kết
quả — sai một lần ở đây là rò rỉ dữ liệu giữa các project hoặc workspace.

**Phase:** 7 · **Feature:** KJ-SRC-01 → KJ-SRC-10
**Liên quan:** [uc-05-issue.md](uc-05-issue.md) · [uc-08-field.md](uc-08-field.md) · [data-access-and-tenancy.md](../../04-system-design/data-access-and-tenancy.md) · [ADR-0002](../../adr/0002-postgres-only.md) · [roadmap.md — Phase 7](../roadmap.md)

---

## UC-SRC-01 — Bộ phân tích cú pháp ngôn ngữ truy vấn

**Requirement:** FR-SRC-01
**Actor:** thành viên có quyền xem project
**Tiền điều kiện:** không có

### Luồng chính

1. Người dùng gõ một biểu thức truy vấn dạng văn bản (trường, toán tử, giá
   trị, kết hợp AND/OR, ngoặc)
2. Bộ phân tích cú pháp dựng cây cú pháp từ biểu thức
3. Biểu thức hợp lệ → sẵn sàng cho UC-SRC-02 dựng SQL

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-SRC-01/NL-01 | Cú pháp sai | Báo lỗi **chỉ rõ vị trí ký tự sai** trong chuỗi truy vấn, không chỉ nói chung chung "cú pháp không hợp lệ" |
| UC-SRC-01/NL-02 | Tham chiếu một trường không tồn tại hoặc không thuộc project đang xem | Báo lỗi tại vị trí tên trường, không phải lỗi cú pháp chung |
| UC-SRC-01/NL-03 | Toán tử không phù hợp với kiểu trường (ví dụ so sánh lớn hơn trên trường chọn một) | Báo lỗi tại vị trí toán tử |

### Hậu điều kiện

Tồn tại một cây cú pháp đã qua kiểm tra kiểu, chưa chạm tới cơ sở dữ liệu.

### Ảnh hưởng tới đồng bộ

Không áp dụng — phân tích cú pháp chạy phía server cho một request, không đổi
dữ liệu cục bộ nào.

---

## UC-SRC-02 — Dựng SQL động từ cây cú pháp

**Requirement:** FR-SRC-01
**Actor:** hệ thống (không có giao diện riêng — hệ quả của UC-SRC-01)
**Tiền điều kiện:** có cây cú pháp hợp lệ

### Luồng chính

1. Cây cú pháp được dịch sang SQL động qua **jOOQ**, đúng tầng đọc động đã
   dùng cho board, backlog, báo cáo (xem [data-access-and-tenancy.md](../../04-system-design/data-access-and-tenancy.md))
2. SQL sinh ra tham số hoá đầy đủ — giá trị người dùng nhập không bao giờ nối
   chuỗi trực tiếp vào câu lệnh

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-SRC-02/NL-01 | Cây cú pháp cố tình phức tạp để gây tải nặng (nhiều điều kiện lồng nhau) | Giới hạn độ sâu và số điều kiện tối đa ở tầng phân tích cú pháp, từ chối trước khi dựng SQL |

### Hậu điều kiện

Không có nhánh nào trong hệ thống dùng truy vấn do người dùng viết mà bỏ qua
jOOQ để tự nối chuỗi SQL — đây là điều kiện an toàn bắt buộc của cả phase.

### Ảnh hưởng tới đồng bộ

Không áp dụng — dựng SQL là một bước server-side trong một request đọc.

---

## UC-SRC-03 — Hàm dựng sẵn trong truy vấn

**Requirement:** FR-SRC-02
**Actor:** thành viên có quyền xem project
**Tiền điều kiện:** Có cây cú pháp hợp lệ chứa ít nhất một hàm dựng sẵn (UC-SRC-01).

### Luồng chính

1. Truy vấn dùng được các hàm dựng sẵn liên quan thời gian và người dùng hiện
   tại (ví dụ "issue của tôi", "cập nhật trong 7 ngày qua", "sprint hiện tại")
2. Hàm được phân giải thành giá trị cụ thể **tại thời điểm chạy truy vấn**,
   không lưu cứng giá trị đã phân giải vào bộ lọc đã lưu (xem UC-SRC-08)

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-SRC-03/NL-01 | Dùng hàm phụ thuộc ngữ cảnh không có (ví dụ "sprint hiện tại" ở project chưa bật Sprint) | Báo lỗi tại vị trí hàm, không trả về kết quả rỗng âm thầm |

### Hậu điều kiện

Hàm dựng sẵn trong truy vấn được phân giải thành giá trị cụ thể tại thời điểm
chạy; không giá trị nào bị lưu cứng lại.

### Ảnh hưởng tới đồng bộ

Không áp dụng — phân giải hàm chạy trong một request đọc.

---

## UC-SRC-04 — Truy vấn trên trường tuỳ biến

**Requirement:** FR-SRC-03
**Actor:** thành viên có quyền xem project
**Tiền điều kiện:** project có ít nhất một trường tuỳ biến (Phase 6)

### Luồng chính

1. Trường tuỳ biến xuất hiện trong danh sách trường có thể truy vấn, cùng
   cách với trường hệ thống — không có cú pháp riêng cho trường tuỳ biến
2. Điều kiện trên trường tuỳ biến được dịch sang SQL qua jOOQ, đọc từ cùng
   đường dữ liệu mà UC-FLD-08 đã chuẩn bị ở Phase 6

### Hậu điều kiện

Không có trạng thái nào đổi — đây là một đường đọc. Kết quả trả về phản ánh
đúng giá trị trường tuỳ biến tại thời điểm truy vấn.

### Chốt điểm chưa chốt ở UC-FLD-08

[uc-08-field.md](uc-08-field.md#uc-fld-08--trường-tuỳ-biến-dùng-được-trong-bộ-lọc-và-báo-cáo)
để lại câu hỏi về cách đánh chỉ mục cho lọc trường tuỳ biến ở quy mô lớn.
[ADR-0002](../../adr/0002-postgres-only.md) đã trả lời phần lưu trữ: trường
tuỳ biến đi qua `JSONB` kèm **GIN index**, và tài liệu đó nêu rõ GIN index xử
lý được "truy vấn theo giá trị field" — tức là điều kiện lọc kiểu bằng, chứa,
tồn tại giá trị. Đây là cơ chế chỉ mục dùng cho UC-SRC-04.

> **Chưa chốt:** GIN index trên `JSONB` phù hợp cho lọc theo giá trị, nhưng
> không tối ưu cho **sắp xếp** hoặc so sánh khoảng (lớn hơn/nhỏ hơn) trên
> trường tuỳ biến kiểu số hoặc ngày ở quy mô hàng chục nghìn issue trở lên.
> Tài liệu hiện có chưa nói cách xử lý riêng cho trường hợp này (ví dụ index
> biểu thức riêng theo từng trường hay chấp nhận sắp xếp chậm hơn). Để lại cho
> lúc thực hiện Phase 7 đo đạc thực tế rồi quyết định, không đoán trước ở đây.

### Ảnh hưởng tới đồng bộ

Không áp dụng — truy vấn trên trường tuỳ biến là một đường đọc server-side.

---

## UC-SRC-05 — Ghép điều kiện phân quyền vào truy vấn

**Requirement:** FR-SRC-09
**Actor:** hệ thống (không có giao diện riêng — áp dụng cho mọi truy vấn của UC-SRC-01..04, UC-SRC-07, UC-SRC-10)
**Tiền điều kiện:** Có một câu truy vấn sắp được chạy, dù từ ngôn ngữ truy vấn
hay từ giao diện lọc cơ bản.

### Luồng chính

1. Trước khi chạy bất kỳ truy vấn nào do người dùng viết hay giao diện lọc cơ
   bản sinh ra, hệ thống ghép thêm điều kiện phân quyền (project người dùng có
   quyền xem, giới hạn hiển thị bình luận theo UC-COL-03, RLS theo workspace)
   **vào cùng câu lệnh SQL**, ở tầng dựng truy vấn
2. Không có bước "lọc lại sau khi có kết quả" ở tầng ứng dụng hay ở client

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-SRC-05/NT-01 | Truy vấn không tham chiếu project nào tường minh | Vẫn tự động giới hạn theo danh sách project người dùng có quyền xem, không trả toàn bộ workspace |

### Hậu điều kiện

Kết quả trả về **chỉ** chứa dữ liệu người dùng có quyền xem — đây là Definition
of Done của cả phase, kiểm chứng bằng bộ test riêng cho từng loại truy vấn.

### Ảnh hưởng tới đồng bộ

Không áp dụng — ghép điều kiện phân quyền là một bước server-side trong request
đọc, không phát delta.

---

## UC-SRC-06 — Tìm kiếm toàn văn và đồng bộ chỉ mục

**Requirement:** FR-SRC-04
**Actor:** thành viên có quyền xem project
**Tiền điều kiện:** không có

### Luồng chính

1. Tìm kiếm toàn văn trên tiêu đề, mô tả, và nội dung bình luận
2. Chỉ mục tìm kiếm được cập nhật **bất đồng bộ**, qua domain event và tiến
   trình chuyển tiếp outbox (KJ-EVT-03) — không cập nhật chỉ mục trong cùng
   transaction với thay đổi nghiệp vụ

### Cơ chế chỉ mục

[ADR-0002](../../adr/0002-postgres-only.md) chỉ để ngỏ khả năng xem xét một
index phụ (ví dụ Elasticsearch) cho tìm kiếm "ở phase sau", nhưng **không**
coi đó là quyết định đã chốt, và invariant #5 của
[CLAUDE.md](../../../CLAUDE.md#architecture) — "không có datastore nào khác ngoài
PostgreSQL" — vẫn có hiệu lực cho tới khi có một ADR mới thay thế nó. Vì vậy
Phase 7 dùng **tìm kiếm toàn văn có sẵn của PostgreSQL** (`tsvector` kèm GIN
index) làm chỉ mục, không thêm Elasticsearch hay bất kỳ datastore nào khác.

> **Chưa chốt:** nếu tìm kiếm toàn văn của PostgreSQL không đủ chất lượng xếp
> hạng hoặc không đủ nhanh khi đo đạc thực tế, việc thêm một index phụ ngoài
> Postgres là thay đổi vượt ra ngoài phạm vi use case này — nó đòi hỏi một ADR
> mới thay thế hoặc bổ sung cho ADR-0002 và invariant #5, chứ không phải một
> quyết định âm thầm ở tầng use case.

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-SRC-06/NT-01 | Sự kiện cập nhật chỉ mục bị xử lý lại (retry của relay worker) | Ghi đè idempotent theo id bản ghi, không tạo bản trùng trong chỉ mục |
| UC-SRC-06/NT-02 | Tìm kiếm trong khoảng thời gian chỉ mục **chưa kịp cập nhật** sau một thay đổi | Chấp nhận độ trễ ngắn — tìm kiếm toàn văn không có cam kết tức thời như sync scope thông thường |

### Hậu điều kiện

Chỉ mục toàn văn phản ánh đúng nội dung mới nhất, có thể trễ một khoảng ngắn
sau khi outbox chuyển tiếp sự kiện.

### Ảnh hưởng tới đồng bộ

Không áp dụng — kết quả tìm kiếm là một đường đọc server-side theo request, không
qua sync scope hay client store cục bộ.

---

## UC-SRC-07 — Giao diện lọc cơ bản chuyển đổi hai chiều

**Requirement:** FR-SRC-05
**Actor:** thành viên có quyền xem project
**Tiền điều kiện:** Không có.

### Luồng chính

1. Xây dựng điều kiện lọc bằng giao diện chọn trường — chọn toán tử — nhập
   giá trị, không cần biết cú pháp truy vấn văn bản
2. Chuyển sang xem dạng truy vấn văn bản bất cứ lúc nào; sửa văn bản rồi
   chuyển lại giao diện lọc cũng dựng đúng lại các điều kiện đã chọn

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-SRC-07/NT-01 | Truy vấn văn bản dùng cấu trúc giao diện lọc cơ bản không biểu diễn được (ví dụ lồng OR trong AND phức tạp) | Vẫn cho xem và chạy ở dạng văn bản, nhưng giao diện lọc cơ bản báo rõ "không thể hiển thị đầy đủ ở chế độ cơ bản" thay vì hiển thị sai lệch |

### Hậu điều kiện

Chuyển đổi hai chiều giữa hai chế độ không làm mất thông tin của điều kiện đã
đặt — đây là Definition of Done riêng của use case này.

### Ảnh hưởng tới đồng bộ

Không áp dụng — chuyển đổi qua lại xảy ra hoàn toàn trên client, chưa chạy truy vấn.

---

## UC-SRC-08 — Lưu và chia sẻ bộ lọc

**Requirement:** FR-SRC-06
**Actor:** thành viên có quyền xem project
**Tiền điều kiện:** Có một truy vấn hợp lệ sẵn sàng lưu (UC-SRC-01).

### Luồng chính

1. Lưu một truy vấn thành bộ lọc có tên, thuộc về người tạo
2. Chia sẻ bộ lọc: riêng tư, chia sẻ với project, hoặc chia sẻ với một nhóm cụ
   thể
3. Bộ lọc lưu **cú pháp truy vấn**, không lưu kết quả đã phân giải — hàm dựng
   sẵn (UC-SRC-03) được phân giải lại mỗi lần chạy

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-SRC-08/NT-01 | Người dùng khác chạy bộ lọc đã chia sẻ | Kết quả vẫn đi qua UC-SRC-05 theo quyền của **người đang chạy**, không theo quyền của người tạo bộ lọc |
| UC-SRC-08/NT-02 | Người tạo bộ lọc rời project | Bộ lọc chia sẻ vẫn tồn tại, người khác vẫn chạy được; bộ lọc riêng tư không ai khác thấy được |
| UC-SRC-08/NT-03 | Lưu bộ lọc khi mất kết nối | Thao tác vào hàng đợi bền cục bộ; gửi lại khi có mạng theo cơ chế hàng đợi chung của sync engine |
| UC-SRC-08/NT-04 | Gửi lại yêu cầu lưu bộ lọc với cùng khoá chống trùng | Không tạo bộ lọc thứ hai — server nhận diện qua idempotency key |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-SRC-08/NL-01 | Xoá bộ lọc đang được board dùng làm nguồn (KJ-BRD-01, Phase 8) | Ngoài phạm vi phase này — ghi nhận để Phase 8 xử lý khi triển khai board |

### Hậu điều kiện

Bộ lọc tồn tại với đúng phạm vi chia sẻ đã chọn; người xem đúng phạm vi đó thấy
được nó khi chọn bộ lọc đã lưu.

### Ảnh hưởng tới đồng bộ

Bộ lọc đã lưu là dữ liệu cấu hình, phát delta trên scope `proj:{projectId}` khi
chia sẻ với project hoặc nhóm; bộ lọc riêng tư chỉ đồng bộ về client của người tạo.

---

## UC-SRC-09 — Xuất kết quả tìm kiếm

**Requirement:** FR-SRC-07
**Actor:** thành viên có quyền xem project
**Tiền điều kiện:** Có một truy vấn đã chạy và có kết quả (UC-SRC-01, UC-SRC-05).

### Luồng chính

1. Xuất kết quả của một truy vấn ra tệp (CSV)
2. Xuất chỉ chứa các trường đang hiển thị trong bảng kết quả tại thời điểm xuất

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-SRC-09/NL-01 | Kết quả quá lớn để xuất trong một request | Giới hạn số dòng mỗi lần xuất, báo rõ khi vượt giới hạn |

> **Chưa chốt:** tài liệu hiện có chưa nói cơ chế xuất chạy đồng bộ trong
> request hay chạy nền rồi gửi liên kết tải về khi vượt một ngưỡng nhất định.
> Để lại quyết định này cho lúc thiết kế chi tiết, dựa trên ngưỡng đo được
> thực tế.

### Hậu điều kiện

Tệp CSV chứa đúng các dòng và cột đang hiển thị tại thời điểm xuất.

### Ảnh hưởng tới đồng bộ

Không áp dụng — xuất tệp là hành động một lần, không đổi dữ liệu client giữ.

---

## UC-SRC-10 — Tìm kiếm nhanh toàn cục

**Requirement:** FR-SRC-08
**Actor:** thành viên
**Tiền điều kiện:** không có

### Luồng chính

1. Gõ từ khoá vào ô tìm kiếm nhanh, có sẵn ở mọi màn hình
2. Kết quả gộp từ nhiều loại (issue, project, thành viên) hiện ngay khi gõ,
   dùng cùng chỉ mục tìm kiếm toàn văn của UC-SRC-06
3. Chọn một kết quả để đi thẳng tới đó

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-SRC-10/NL-01 | Từ khoá khớp dữ liệu người dùng không có quyền xem | Không hiện trong kết quả — đi qua cùng UC-SRC-05, không có đường tắt nào bỏ qua ghép điều kiện phân quyền |

### Hậu điều kiện

Không có — đây là thao tác đọc, không đổi trạng thái hệ thống.

### Ảnh hưởng tới đồng bộ

Không áp dụng — tìm kiếm nhanh là một request đọc theo từ khoá, không phát delta.

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-SRC-01 | Lỗi cú pháp truy vấn phải chỉ rõ vị trí sai trong chuỗi, không chỉ báo lỗi chung |
| QT-SRC-02 | Mọi truy vấn do người dùng viết đều dịch sang SQL qua jOOQ, tham số hoá đầy đủ, không tự nối chuỗi SQL |
| QT-SRC-03 | Điều kiện phân quyền được ghép vào lúc dựng SQL, không lọc lại sau khi có kết quả |
| QT-SRC-04 | Trường tuỳ biến truy vấn được bằng cú pháp giống hệt trường hệ thống |
| QT-SRC-05 | Chỉ mục tìm kiếm toàn văn dùng PostgreSQL (`tsvector` + GIN), không thêm datastore khác, trừ khi có ADR mới thay thế ADR-0002 và invariant #5 |
| QT-SRC-06 | Cập nhật chỉ mục tìm kiếm là bất đồng bộ qua outbox, phải chống trùng theo id bản ghi |
| QT-SRC-07 | Chuyển đổi giữa giao diện lọc cơ bản và truy vấn văn bản không được mất thông tin |
| QT-SRC-08 | Bộ lọc đã lưu lưu cú pháp truy vấn, không lưu giá trị đã phân giải của hàm dựng sẵn |
| QT-SRC-09 | Bộ lọc chia sẻ chạy theo quyền của người đang chạy, không theo quyền của người tạo |

## Yêu cầu phi chức năng liên quan

`NFR-07` lọc quyền phải ở tầng SQL · `NFR-20` không rò rỉ dữ liệu giữa
workspace/project · `NFR-01` phản hồi tức thì khi gõ ở tìm kiếm nhanh và giao
diện lọc cơ bản
