# Môi trường

Bốn bậc môi trường, mỗi bậc thêm đúng một loại rủi ro so với bậc dưới. Tài liệu
này định nghĩa từng bậc dùng để làm gì, gồm những gì, và **điều gì chỉ bậc đó mới
phát hiện được**.

**Liên quan:** [infrastructure.md](infrastructure.md) · [observability-and-ops.md](observability-and-ops.md) · [ci-cd.md](ci-cd.md) · [architecture.md](architecture.md)

---

## Nguyên tắc: một artifact, bốn cấu hình

**Cùng một ảnh container chạy ở cả bốn bậc.** Khác nhau chỉ nằm ở biến môi trường
và ở việc bật vai trò ứng dụng nào.

Hệ quả bắt buộc: **không có nhánh code nào rẽ theo tên môi trường.** Không có
`if (env == "staging")`. Mỗi khác biệt giữa các bậc phải biểu diễn được bằng một
biến cấu hình có tên nói lên **tính chất** chứ không nói lên **nơi chốn** — ví dụ
`KAIJU_MAIL_TRANSPORT`, không phải `KAIJU_IS_PROD`.

Lý do: nhánh theo tên môi trường là loại code **không bao giờ được kiểm thử ở nơi
nó thật sự chạy**. Nhánh `staging` chỉ chạy ở staging, nhánh `prod` chỉ chạy ở
production, và không nơi nào chạy cả hai.

---

## Bốn bậc

| Bậc | Tên | Dùng để | Nơi chạy |
|---|---|---|---|
| 1 | `local-mini` | Viết code và chạy test. Vòng lặp sửa–chạy lại phải nhanh | Máy phát triển |
| 2 | `dev` | Kiểm thử **vận hành**: bộ gộp kết nối, quan sát hệ thống, máy chủ trung gian, bốn vai trò tách rời | Máy phát triển hoặc một máy dùng chung |
| 3 | `staging` | Bản sao của production trên **một máy chủ duy nhất**. Không còn dịch vụ giả lập nào | Một VPS |
| 4 | `production` | Chạy thật, nhiều instance, mở rộng theo từng vai trò | Nền tảng điều phối container |

### Cái gì chỉ bậc đó bắt được

Đây là lý do tồn tại của từng bậc. Bậc nào không bắt được thứ gì mà bậc dưới
không bắt được thì bậc đó thừa.

| Bậc | Chỉ nó bắt được |
|---|---|
| `local-mini` | Lỗi logic, lỗi migration, vi phạm biên giới module. Nói chung là mọi thứ **không** liên quan tới môi trường |
| `dev` | Vi phạm trạng thái phiên (`CON-62`), luồng đồng bộ bị đệm ở máy chủ trung gian, chuỗi lần vết bị đứt tại ranh giới bất đồng bộ, vai trò ứng dụng thiếu cấu hình khi chạy tách rời |
| `staging` | Hành vi của **dịch vụ thật**: thư đi vào hộp thư rác, liên kết có chữ ký của kho lưu trữ đối tượng, độ trễ thật của cơ sở dữ liệu không nằm cùng máy, TLS và tên miền thật |
| `production` | Nhiều instance cùng vai trò: tranh chấp khi cấp số thứ tự, khoá chống chạy trùng của tác vụ định kỳ, phát tán giữa nhiều instance realtime, triển khai cuốn chiếu |

> Bậc 2 là bậc duy nhất người phát triển **chủ động bật lên để thử vận hành**, rồi
> tắt đi. Nó không phải môi trường làm việc hằng ngày — đó là việc của bậc 1.

---

## Bậc 1 — `local-mini`

Mục tiêu duy nhất: **gõ một lệnh là có đủ thứ để `./gradlew bootRun` chạy được và
bộ test chạy được.**

| Dịch vụ | Vì sao ở bậc này |
|---|---|
| PostgreSQL | Nguồn sự thật, không thể thiếu |
| Máy chủ giao thức Redis | Phát tán và cache |
| Bộ bắt email | Đăng nhập phụ thuộc hoàn toàn vào email; thiếu nó thì không đăng nhập được |
| Lưu trữ đối tượng | Có sẵn từ đầu dù chỉ dùng từ Phase 4, vì thêm sau tốn công hơn là để đó |

**Backend và frontend chạy ngoài Docker.** Chạy trong container ở bậc này chỉ làm
chậm vòng lặp sửa–chạy lại mà không đổi lại được gì.

Cố tình **không có**: bộ gộp kết nối, hệ thống quan sát, máy chủ trung gian, tách
vai trò ứng dụng. Cả bốn thứ đó đều làm việc gỡ lỗi khó hơn, và không thứ nào bắt
được lỗi logic.

---

## Bậc 2 — `dev`

Bậc 1 cộng thêm mọi thứ thuộc về **vận hành**. Đây là nơi trả lời câu hỏi "cái này
có chạy được khi triển khai thật không", tách khỏi câu hỏi "cái này có đúng không".

| Thêm gì | Bắt được gì |
|---|---|
| Bộ gộp kết nối ở chế độ gộp theo giao dịch | Vi phạm `CON-62`. Đây là loại vi phạm **hoàn toàn im lặng** ở bậc 1 |
| Hệ thống quan sát gói sẵn | Chuỗi lần vết có đi hết bốn ranh giới bất đồng bộ không |
| Máy chủ trung gian | Luồng đồng bộ có bị đệm không — triệu chứng là "realtime không chạy" và **không có lỗi nào** |
| Bốn vai trò ứng dụng chạy tách rời trong container | Vai trò nào thiếu cấu hình, vai trò nào vô tình phụ thuộc vào thứ chỉ có ở `api` |

Điểm cuối đáng chú ý: ở bậc 1 mọi vai trò chạy chung một tiến trình, nên một
`worker` lỡ phụ thuộc vào bean chỉ có ở tầng web vẫn khởi động bình thường. Bậc 2
là nơi đầu tiên nó không khởi động được.

### Kết nối lắng nghe thông báo

`CON-25` nói kết nối lắng nghe thông báo phải đi thẳng tới cơ sở dữ liệu, không
qua bộ gộp. Bậc 2 là nơi **chứng minh** điều đó đã được viết đúng: nếu định tuyến
sai, tiến trình chuyển tiếp sự kiện sẽ lùi về quét định kỳ và độ trễ hàng đợi tăng
thấy rõ trên biểu đồ.

---

## Bậc 3 — `staging`

Toàn bộ trên **một máy chủ duy nhất**. Ứng dụng chạy trong container; mọi thứ có
trạng thái thì **không**.

| Thành phần | Ở staging là gì | Vì sao |
|---|---|---|
| Bốn vai trò ứng dụng | Container, mỗi vai trò một | Giống production, và đó là phần cần kiểm chứng |
| PostgreSQL | **Cài thẳng trên máy chủ** hoặc dịch vụ quản lý sẵn — không phải container | Hiệu năng vào ra và độ bền dữ liệu; container hoá cơ sở dữ liệu trên VPS chỉ thêm một tầng mà không đổi lại được gì |
| Máy chủ giao thức Redis | Cài thẳng trên máy chủ | Cùng lý do, nhẹ hơn |
| Gửi email | **Dịch vụ gửi thư giao dịch thật** | Bộ bắt email không bao giờ cho biết thư có vào được hộp thư đến hay không |
| Lưu trữ đối tượng | **Dịch vụ tương thích S3 thật** | Liên kết có chữ ký, chính sách truy cập và cấu hình chia sẻ nguồn gốc chỉ sai ở dịch vụ thật |
| Máy chủ trung gian | Container, có TLS và tên miền thật | |
| Quan sát hệ thống | Đích thu thập thật, không phải container gói sẵn | Container gói sẵn không bền dữ liệu; nhà phát hành nói rõ là không dành cho môi trường thật |

**Không còn dịch vụ tạm nào.** Đây là ranh giới định nghĩa bậc 3: mọi thứ chỉ tồn
tại để thuận tiện khi phát triển đều đã bị thay bằng hàng thật.

### Vì sao vẫn cần bậc 3 khi đã có bậc 4

Ba thứ chỉ hỏng ở lần chạm đầu tiên với dịch vụ thật, và không có bậc 3 thì lần
chạm đầu tiên đó xảy ra ở production:

1. **Xác thực tên miền gửi thư.** Cấu hình thiếu thì thư vào hộp thư rác, và triệu
   chứng người dùng thấy là "đăng nhập không hoạt động"
2. **Chính sách của kho lưu trữ đối tượng.** Liên kết có chữ ký hết hạn sai, hoặc
   cấu hình chia sẻ nguồn gốc chặn tải lên từ trình duyệt
3. **Chuỗi chứng chỉ và tên miền.** Luồng đồng bộ đi qua TLS thật và qua máy chủ
   trung gian thật lần đầu tiên

---

## Bậc 4 — `production`

Nền tảng điều phối container. Mỗi vai trò ứng dụng là một đối tượng triển khai
riêng, mở rộng độc lập.

| Vai trò | Số bản chạy | Mở rộng theo |
|---|---|---|
| `api` | Nhiều | Số request |
| `realtime` | Nhiều | Số kết nối đồng bộ đang mở |
| `worker` | Nhiều | Độ trễ hàng đợi sự kiện |
| `scheduler` | **Vẫn nhiều bản để sẵn sàng cao, nhưng chỉ một bản làm việc tại một thời điểm** | Không mở rộng — thêm bản chỉ để không chết |

### Những thứ chỉ xuất hiện ở bậc này

| Vấn đề | Cách xử lý |
|---|---|
| Nhiều `worker` cùng đọc bảng chuyển tiếp | Khoá dòng có bỏ qua dòng đã khoá, chia theo băm của định danh aggregate |
| Nhiều `scheduler` cùng chạy một tác vụ | Khoá phân tán |
| Nhiều `realtime` nhưng người dùng chỉ nối tới một | Phát tán qua Redis |
| Cấp số thứ tự đồng bộ từ nhiều tiến trình | Giao dịch với mức cô lập đủ mạnh |
| Migration chạy đồng thời từ nhiều bản | Chạy như một công việc riêng **trước** khi triển khai — giống hệt ba bậc dưới, chỉ khác là ở đây nó do pipeline gọi chứ không do người gọi |

> **Đã thay đổi (2026-09-17):** trước đây tài liệu này viết rằng ở bậc 1–3
> migration chạy lúc ứng dụng khởi động cũng chấp nhận được, chỉ bậc 4 là không.
> Bây giờ **không bậc nào chạy migration lúc khởi động**. Cách cũ khiến đường chạy
> ở bậc 4 gần như không bao giờ được diễn tập, và khiến không bậc nào điều khiển
> được chiều đi xuống. Xem [ADR-0013](../adr/0013-explicit-two-way-migration.md).

### Yêu cầu với đối tượng vào ra

Luồng đồng bộ chỉ hoạt động khi lớp vào ra được cấu hình đúng:

| Yêu cầu | Thiếu thì |
|---|---|
| Tắt đệm cho đường dẫn luồng đồng bộ | Delta bị giữ lại, không có lỗi nào |
| Thời gian chờ đọc dài hơn chu kỳ nhịp tim | Kết nối bị đóng liên tục |
| Gắn phiên theo kết nối cho vai trò `realtime` | Không bắt buộc, nhưng giảm số lần bootstrap lại |

### Thời gian tắt êm

Vai trò `realtime` giữ kết nối dài hạn, nên thời gian chờ tắt phải **dài hơn** chu
kỳ nhịp tim, để client kịp nhận tín hiệu đóng và nối lại chủ động thay vì phát
hiện ra bằng thời gian chờ.

---

## Migration

Cả bốn bậc gọi migration theo **cùng một cách**: vai trò `migrate` của chính ảnh
container đã có, chạy một lần rồi thoát. Khác nhau chỉ ở chỗ **ai gọi**.

| Bậc | Gọi bằng | Chiều đi xuống |
|---|---|---|
| `local-mini` | `make db-up`, `make db-down`, `make db-status` | Dùng thoải mái |
| `dev` | Cùng các lệnh đó, chạy trong mạng của bậc 2 | Dùng thoải mái |
| `staging` | Bước đầu tiên của script triển khai | Dè dặt |
| `production` | Công việc chạy trước khi triển khai trong pipeline | **Không** |

Không bậc nào chạy migration lúc ứng dụng khởi động, và không ứng dụng nào tự chạy
nó. Chi tiết công cụ, quy ước script và phần lùi nằm ở
[data-access-and-tenancy.md](data-access-and-tenancy.md#migration).

---

## Bảng so sánh

| | `local-mini` | `dev` | `staging` | `production` |
|---|---|---|---|---|
| Vai trò ứng dụng | Một tiến trình, tất cả vai trò | Bốn container | Bốn container | Bốn đối tượng triển khai, nhiều bản |
| PostgreSQL | Container | Container | Thật, ngoài container | Thật, dịch vụ quản lý sẵn |
| Redis | Container | Container | Thật, ngoài container | Thật |
| Bộ gộp kết nối | ❌ | ✅ | ✅ | Khi ngân sách kết nối chạm giới hạn |
| Email | Bộ bắt thư | Bộ bắt thư | **Dịch vụ thật** | **Dịch vụ thật** |
| Lưu trữ đối tượng | Container | Container | **Dịch vụ thật** | **Dịch vụ thật** |
| Máy chủ trung gian | ❌ | ✅ không TLS | ✅ TLS thật | Đối tượng vào ra của nền tảng |
| Quan sát hệ thống | ❌ | Container gói sẵn | Đích thu thập thật | Đích thu thập thật |
| Migration | Lệnh tường minh | Lệnh tường minh | Công việc riêng trước khi triển khai | Công việc riêng trước khi triển khai |
| Ai gọi migration | Người | Người | Script triển khai | Pipeline |
| Dữ liệu mẫu | ✅ | ✅ | ❌ | ❌ |
| Chạy migration lùi được | ✅ | ✅ | Dè dặt | ❌ — sửa tiến |

---

## Cấu hình

Mỗi bậc là một tập biến môi trường, không phải một tập tệp cấu hình.

| Quy ước | |
|---|---|
| Tệp mẫu nằm ở `infra/env/` | Chỉ giá trị giả, **không bí mật thật** |
| Bí mật thật không bao giờ vào repository | Bậc 3 lấy từ tệp trên máy chủ, bậc 4 lấy từ cơ chế bí mật của nền tảng |
| Thiếu biến bắt buộc thì dừng ngay lúc khởi động | Chết sớm còn hơn chạy sai âm thầm |
| Tên biến nói lên **tính chất**, không nói lên **nơi chốn** | `KAIJU_MAIL_TRANSPORT=smtp`, không phải `KAIJU_ENV=staging` |

### Vai trò ứng dụng được chọn thế nào

Bằng profile khi khởi động, không bằng ảnh container khác nhau. Một ảnh, bốn cách
chạy — xem [architecture.md](architecture.md).

---

## Chưa chốt

> **Chưa chốt:** nhà cung cấp cụ thể cho từng dịch vụ thật ở bậc 3 và 4 — dịch vụ
> gửi thư, kho lưu trữ đối tượng, đích thu thập tín hiệu quan sát, cơ sở dữ liệu
> quản lý sẵn. Quyết định khi dựng bậc 3 lần đầu. Nó không chặn việc gì vì cả bốn
> đều là giao thức chuẩn: SMTP, S3, chuẩn mở về quan sát, và giao thức của
> PostgreSQL.
