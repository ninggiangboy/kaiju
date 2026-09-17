# Hạ tầng và thư viện phụ thuộc

Danh sách đầy đủ những thành phần hạ tầng hệ thống thật sự cần, khi nào cần, và
điều gì xảy ra khi từng thành phần chết. Kèm theo là các nhóm thư viện phụ thuộc
ở phía backend.

**Liên quan:** [architecture.md](architecture.md) · [observability-and-ops.md](observability-and-ops.md) · [backend-modules.md](backend-modules.md#phiên-bản-nền) · [ADR-0002](../adr/0002-postgres-only.md) · [ADR-0003](../adr/0003-redis-scope.md)

---

## Nguyên tắc

Mỗi thành phần hạ tầng là một thứ phải cài, cấu hình, giám sát, sao lưu, nâng cấp
và xử lý khi hỏng. Vì vậy:

1. **Chỉ thêm khi phase nào đó thật sự cần**, không thêm sẵn "cho chắc"
2. Mỗi thành phần phải trả lời được câu hỏi **"mất nó thì sao"**
3. Thành phần nào mất mà hệ thống **sai** dữ liệu thì phải được coi là trọng yếu,
   ngang với cơ sở dữ liệu

---

## Cần gì, khi nào

| Thành phần | Phase cần | Bắt buộc? |
|---|---|---|
| PostgreSQL | 0 | ✅ Nguồn sự thật |
| Máy chủ giao thức Redis | 0 | ✅ Phát tán realtime không thể thiếu |
| Máy chủ trung gian đã tắt đệm | 0 | ✅ Luồng đồng bộ không chạy nếu thiếu |
| Docker (môi trường phát triển và CI) | 0 | ✅ Kiểm thử tích hợp chạy trên cơ sở dữ liệu thật |
| Hệ thống gửi email | 1 | ✅ **Đăng nhập phụ thuộc hoàn toàn** |
| Lưu trữ đối tượng | 4 | ✅ Cho tệp đính kèm |
| Quét mã độc cho tệp tải lên | 4 | ⚠️ Có điểm móc từ phase 4; bật thật khi mở cho người ngoài |
| Hệ thống thu thập nhật ký và chỉ số | 0 ở mức tối thiểu, đầy đủ dần | ✅ |
| Máy chủ tìm kiếm riêng | Có thể **không bao giờ** | ❌ Chỉ khi tìm kiếm trên cơ sở dữ liệu không còn đủ |
| Message broker | Không | ❌ [ADR-0005](../adr/0005-outbox-db-job.md) |
| Kho dữ liệu thứ hai | Không | ❌ [ADR-0002](../adr/0002-postgres-only.md) |

---

## PostgreSQL

**Phiên bản: dòng 18.** Đây là dòng ổn định hiện hành; dòng 19 đã bị lùi lịch phát
hành và không nên là nơi bắt đầu một dự án.

### Tính năng của cơ sở dữ liệu mà kiến trúc phụ thuộc vào

Không phải "dùng cho tiện" mà là **phụ thuộc kiến trúc**: thiếu một trong số này
thì thiết kế phải đổi.

| Tính năng | Dùng ở đâu | Thay thế được không |
|---|---|---|
| Bảo mật ở mức dòng | Lớp phòng thủ thứ hai cho cách ly tenant | Không — [ADR-0012](../adr/0012-shared-schema-tenancy-rls.md) |
| Khoá dòng có bỏ qua dòng đã khoá | Nhiều tiến trình chuyển tiếp sự kiện chạy song song | Không, nếu không muốn dùng message broker |
| Cơ chế thông báo giữa các phiên | Đánh thức tiến trình chuyển tiếp | Có — lùi về quét định kỳ, đổi lại độ trễ cao hơn |
| Kiểu dữ liệu JSON có đánh chỉ mục | Trường tuỳ biến, payload sự kiện, patch đồng bộ | Không — [ADR-0002](../adr/0002-postgres-only.md) |
| Phân vùng bảng theo thời gian | Bảng chỉ ghi thêm: sự kiện, nhật ký thay đổi, hoạt động | Không ở quy mô dự kiến |
| Tìm kiếm toàn văn | Phase 7 | Có — máy chủ tìm kiếm riêng, nhưng chỉ khi cần |
| Giao dịch với mức cô lập đủ mạnh | Cấp số thứ tự đồng bộ | Không |

### Phần mở rộng cần bật

| Phần mở rộng | Dùng để | Phase |
|---|---|---|
| So sánh chuỗi không phân biệt hoa thường | Email và slug phải so sánh không phân biệt hoa thường | 1 |
| So khớp chuỗi gần đúng | Gợi ý khi tìm kiếm, tìm theo tên | 7 |

Không cần phần mở rộng sinh định danh: **định danh do ứng dụng sinh**, không do cơ
sở dữ liệu sinh — xem mục dưới.

### Định danh do client sinh

Đây là hệ quả trực tiếp của local-first, và cần chốt ở Phase 0.

Client tạo một issue khi đang offline phải có định danh **ngay lập tức** để tham
chiếu tới nó — gán nhãn, mở màn hình chi tiết, tạo liên kết. Chờ server cấp định
danh là phá vỡ toàn bộ mô hình.

| Quy tắc | |
|---|---|
| Định danh sinh ở **client**, kiểu định danh duy nhất có thành phần thời gian | Sắp xếp được theo thời gian tạo, không phân mảnh chỉ mục như định danh ngẫu nhiên thuần |
| Server **kiểm tra** định danh hợp lệ và chưa tồn tại, không tự sinh | Trùng định danh thì từ chối mutation như mọi trường hợp bị từ chối khác |
| Mã issue dạng `KEY-số` **vẫn do server cấp** | Nó phải liên tục trong project, không thể sinh ở client |

Nghĩa là một issue có **hai** định danh: định danh nội bộ do client sinh, và mã
hiển thị do server cấp khi mutation được chấp nhận.

### Ngân sách kết nối

Phải tính tay, và phải tính **trước khi** scale:

```
tổng kết nối = Σ (số instance của mỗi vai trò × kích thước pool của vai trò đó)
             + kết nối riêng cho việc lắng nghe thông báo
             + kết nối cho migration và công cụ vận hành
```

Con số này phải nhỏ hơn giới hạn của máy chủ cơ sở dữ liệu. Đây là thứ hay bị
quên cho tới khi thêm instance rồi mới thấy lỗi hết kết nối.

### Nếu về sau thêm bộ gộp kết nối

Chưa cần ở giai đoạn đầu, nhưng **phải biết trước** vì nó ảnh hưởng tới thiết kế:

| Cơ chế đang dùng | Ở chế độ gộp theo giao dịch |
|---|---|
| Biến phiên đặt trong phạm vi giao dịch cho bảo mật mức dòng | ✅ Hoạt động — vì nó là trạng thái của giao dịch, không phải của phiên |
| **Lắng nghe thông báo** | ❌ **Không hoạt động** — kết nối lắng nghe phải đi thẳng tới cơ sở dữ liệu, không qua bộ gộp |
| Gửi thông báo | ✅ Hoạt động |
| Khoá tư vấn ở mức phiên | ❌ Không hoạt động — phải dùng loại khoá ở mức giao dịch |
| Đặt biến ở mức phiên | ❌ Không hoạt động |

Hai hệ quả cần tuân thủ **ngay từ bây giờ**, vì sửa sau sẽ khó:

- Chỉ đặt biến phiên bằng cơ chế **phạm vi giao dịch**, không bao giờ ở phạm vi phiên
- Nếu cần khoá tư vấn thì dùng loại **gắn với giao dịch**

---

## Máy chủ giao thức Redis

Vai trò và ranh giới: [ADR-0003](../adr/0003-redis-scope.md). Ở đây chỉ bàn về lựa
chọn sản phẩm.

Hệ thống không phụ thuộc vào một sản phẩm cụ thể mà phụ thuộc vào **giao thức**.
Thư viện client phía Java hoạt động với mọi bản tương thích giao thức.

| Lựa chọn | Giấy phép | Ghi chú |
|---|---|---|
| **Valkey** (mặc định đề xuất) | BSD 3-Clause | Bản rẽ nhánh do một tổ chức phi lợi nhuận quản lý; đã là mặc định trên nhiều bản phân phối và dịch vụ đám mây |
| Redis dòng 8 | Đa giấy phép, có lựa chọn AGPLv3 | Cũng dùng tốt; AGPLv3 không gây vấn đề khi tự vận hành cho hệ thống của mình |

Đề xuất Valkey vì giấy phép đơn giản hơn và là mặc định ở phần lớn nơi. **Quyết
định này không đáng để tranh luận lâu** — hai bên tương thích giao thức, đổi qua
lại chỉ là đổi địa chỉ kết nối.

> ⚠️ Không dùng tính năng riêng của một sản phẩm. Chỉ dùng phần giao thức chung:
> cache, phát tán thông điệp, khoá, bộ đếm.

---

## Hệ thống gửi email

**Đây là thành phần trọng yếu, không phải tiện ích phụ.** Đăng nhập chỉ có magic
link ([ADR-0009](../adr/0009-magic-link-only.md)), nên email chết đồng nghĩa với
**không ai đăng nhập được**, kể cả người đã có tài khoản nhưng hết phiên.

| Môi trường | Dùng gì |
|---|---|
| Phát triển | Bộ bắt email chạy cục bộ, có giao diện web để xem thư |
| Thật | Dịch vụ gửi thư giao dịch chuyên dụng |

### Yêu cầu

| Yêu cầu | Vì sao |
|---|---|
| Cấu hình xác thực tên miền gửi đầy đủ | Thiếu thì thư vào hộp thư rác, và triệu chứng là "đăng nhập không hoạt động" |
| Tách luồng thư đăng nhập khỏi thư thông báo | Thông báo nhiều, dễ bị đánh dấu là thư rác; không được kéo theo thư đăng nhập |
| Xử lý thư bị trả lại và khiếu nại | Gửi mãi tới địa chỉ chết làm hỏng uy tín tên miền |
| Giám sát tỉ lệ gửi thành công | Đây là một trong những chỉ số cần cảnh báo ngay |
| Gửi qua bảng chuyển tiếp, không gửi trong request | Không mất thư khi tiến trình chết; xem [events-and-outbox.md](events-and-outbox.md) |

---

## Lưu trữ đối tượng

Cần từ Phase 4 cho tệp đính kèm.

| | |
|---|---|
| Loại | Dịch vụ tương thích giao thức S3 |
| Phát triển | Bản tự vận hành chạy trong Docker |
| Truy cập | Tải lên và tải xuống bằng liên kết có chữ ký và thời hạn, **không đi qua backend** |

### Vì sao không lưu tệp trong cơ sở dữ liệu

| Lý do | |
|---|---|
| Kích thước sao lưu | Tệp đính kèm sẽ chiếm phần lớn dung lượng sao lưu và làm thời gian khôi phục dài ra nhiều lần |
| Băng thông | Tải tệp qua backend chiếm kết nối cơ sở dữ liệu và bộ nhớ của tiến trình |
| Không phải việc của nó | Cơ sở dữ liệu đang là điểm chịu tải tập trung, không nên gánh thêm |

Cơ sở dữ liệu chỉ giữ **siêu dữ liệu** của tệp; nội dung nằm ở kho lưu trữ đối tượng.

### Cách ly tenant cho tệp

Đường dẫn của tệp phải mang định danh workspace, và liên kết có chữ ký phải được
cấp **sau khi kiểm tra quyền**. Một tệp đính kèm rò rỉ cũng nghiêm trọng như một
dòng dữ liệu rò rỉ.

---

## Máy chủ trung gian

Bắt buộc từ Phase 0 vì luồng đồng bộ không hoạt động đúng nếu thiếu cấu hình.

| Yêu cầu | Hệ quả nếu thiếu |
|---|---|
| Tắt đệm cho đường dẫn của luồng đồng bộ | Delta bị giữ lại; triệu chứng là "realtime không chạy" và **không có lỗi nào** |
| Thời gian chờ nhàn rỗi dài hơn chu kỳ nhịp tim | Kết nối bị đóng liên tục |
| Bật HTTP/2 | Giới hạn số kết nối trên mỗi nguồn |
| Giới hạn kích thước nội dung tải lên | Thông báo lỗi khó hiểu khi tải tệp lớn |
| Kết thúc TLS | |

---

## Quét mã độc

Yêu cầu [FR-COL-08](../02-requirement/functional.md). Thiết kế là một **điểm móc**
từ Phase 4: tệp mới tải lên ở trạng thái chờ quét, chỉ chuyển sang dùng được khi
quét xong.

Hiện thực thật có thể lùi lại, nhưng **điểm móc phải có từ đầu** — thêm một trạng
thái vào vòng đời của tệp đính kèm sau khi đã có dữ liệu là việc khó chịu.

---

## Tìm kiếm

Phase 7 dùng **tìm kiếm toàn văn có sẵn trong cơ sở dữ liệu**. Không thêm máy chủ
tìm kiếm riêng ở giai đoạn này.

Điều kiện xem xét thêm: có số đo cho thấy truy vấn tìm kiếm không đạt yêu cầu về
độ trễ, **hoặc** cần các tính năng mà cơ sở dữ liệu không làm được như xếp hạng
theo độ liên quan nâng cao hay tìm kiếm mờ quy mô lớn.

Nếu thêm thì nó là **chỉ mục phụ**, đồng bộ qua sự kiện, và **không bao giờ là
nguồn sự thật** — mất chỉ mục thì dựng lại được từ cơ sở dữ liệu.

---

## Quan sát hệ thống

| Thành phần | Mức tối thiểu ở Phase 0 | Đầy đủ dần |
|---|---|---|
| Nhật ký | Ghi có cấu trúc ra đầu ra chuẩn | Thu thập tập trung, tìm kiếm được |
| Chỉ số | Điểm cuối phơi bày chỉ số | Thu thập và vẽ biểu đồ, có cảnh báo |
| Lần vết | Định danh tương quan trong nhật ký | Lần vết phân tán đầy đủ |
| Kiểm tra sức khoẻ | Theo từng vai trò ứng dụng | |

Ba chỉ số sống còn và ngưỡng cảnh báo: [observability-and-ops.md](observability-and-ops.md#chỉ-số).

---

## Docker

Cần ở **hai** nơi, và nơi thứ hai hay bị quên:

| Nơi | Dùng để |
|---|---|
| Máy phát triển | Chạy toàn bộ phụ thuộc bằng một lệnh |
| **Máy chạy CI** | Kiểm thử tích hợp khởi động cơ sở dữ liệu thật trong container |

Kiểm thử tích hợp chạy trên cơ sở dữ liệu thật là một quyết định đã chốt
([testing-strategy.md](testing-strategy.md)), vì bảo mật mức dòng, phân vùng, khoá
dòng và cơ chế thông báo không giả lập được. Hệ quả là **môi trường CI bắt buộc
phải chạy được container**.

---

## Thư viện backend

Nhóm theo mục đích. Phiên bản cụ thể theo bộ quản lý phiên bản của framework nền,
xem [phiên bản nền](backend-modules.md#phiên-bản-nền).

| Nhóm | Gồm |
|---|---|
| Nền | Framework ứng dụng, tầng web, kiểm tra tính hợp lệ, xử lý JSON |
| Truy cập dữ liệu | Tầng ánh xạ theo aggregate, bộ dựng truy vấn động, trình điều khiển cơ sở dữ liệu, bộ gộp kết nối, công cụ migration |
| Bộ nhớ đệm và điều phối | Client cho máy chủ giao thức Redis, khoá phân tán cho tác vụ định kỳ |
| Bảo mật | Chuỗi bộ lọc xác thực, tiêu đề bảo mật, thư viện xử lý token |
| Kiểm tra biên giới | Nhân của công cụ kiểm tra module, và phần hỗ trợ kiểm thử |
| Quan sát | Thư viện đo chỉ số, xuất nhật ký có cấu trúc, lần vết |
| Email | Tầng gửi thư, hoặc bộ thư viện của nhà cung cấp |
| Lưu trữ đối tượng | Bộ thư viện tương thích giao thức S3 |
| Kiểm thử | Khung kiểm thử đơn vị, thư viện khởi động container, thư viện kiểm tra kiến trúc |

### Thư viện bị cấm

| Cấm | Vì sao |
|---|---|
| Mọi thư viện lưu trữ sự kiện của framework nền | Tạo ra cơ chế chuyển tiếp sự kiện thứ hai chạy song song — [events-and-outbox.md](events-and-outbox.md#ba-điều-cấm) |
| Thư viện externalize sự kiện ra message broker | Dự án không dùng broker |
| Thư viện ánh xạ quan hệ đối tượng dạng đầy đủ | [ADR-0004](../adr/0004-spring-data-jdbc.md) |
| Client của bất kỳ kho dữ liệu nào khác | [ADR-0002](../adr/0002-postgres-only.md) |

Có test kiểm tra classpath và báo lỗi khi phát hiện thư viện bị cấm
([KJ-PLT-19](../03-features/README.md)).

### Về tầng bảo mật

Dự án tự viết luồng xác thực (magic link) và tự viết phân quyền (mặt nạ bit),
nhưng **vẫn dùng tầng bảo mật có sẵn của framework** cho phần hạ tầng: chuỗi bộ
lọc, tiêu đề bảo mật, bảo vệ chống giả mạo request cho điểm cuối làm mới token.

Tự viết những phần đó không đổi lại được gì và dễ sai ở các chi tiết nhỏ.

---

## Thư viện frontend

Xem [frontend.md](frontend.md#thư-viện). Về hạ tầng, phía frontend chỉ cần môi
trường chạy JavaScript và một bộ quản lý gói — không cần dịch vụ nền nào.

---

## Mất thành phần này thì sao

Bảng này quyết định thứ tự ưu tiên khi có sự cố.

| Mất | Hậu quả | Mức độ |
|---|---|---|
| PostgreSQL | Hệ thống dừng hoàn toàn | 🔴 Trọng yếu |
| Hệ thống gửi email | **Không ai đăng nhập được**; người đang có phiên vẫn dùng bình thường | 🔴 Trọng yếu |
| Máy chủ giao thức Redis | Chậm đi; realtime lùi về mức bắt kịp khi client tự nối lại. **Không sai dữ liệu** | 🟡 Suy giảm |
| Máy chủ trung gian | Không truy cập được từ bên ngoài | 🔴 Trọng yếu |
| Lưu trữ đối tượng | Không tải lên hay tải xuống tệp được; phần còn lại hoạt động bình thường | 🟡 Suy giảm |
| Hệ thống quan sát | Mất khả năng nhìn thấy, ứng dụng vẫn chạy | 🟡 Suy giảm |
| Máy chủ tìm kiếm, nếu có | Tìm kiếm lùi về cơ sở dữ liệu hoặc ngừng hoạt động | 🟢 Cục bộ |

Điểm đáng chú ý: **hệ thống gửi email nằm cùng mức trọng yếu với cơ sở dữ liệu**.
Đây là hệ quả trực tiếp và đã được chấp nhận của việc chỉ dùng magic link, và nó
phải được phản ánh trong cách giám sát chứ không chỉ trong tài liệu.

---

## Cố tình chưa thêm

| Chưa thêm | Điều kiện xem xét |
|---|---|
| Message broker | Không dự kiến — [ADR-0005](../adr/0005-outbox-db-job.md) |
| Kho dữ liệu thứ hai | Không dự kiến — [ADR-0002](../adr/0002-postgres-only.md) |
| Bộ gộp kết nối cơ sở dữ liệu | Khi ngân sách kết nối chạm giới hạn; kèm theo các hệ quả đã nêu ở trên |
| Máy chủ tìm kiếm riêng | Khi có số đo chứng minh tìm kiếm trên cơ sở dữ liệu không đủ |
| Mạng phân phối nội dung | Khi tải tệp đính kèm trở thành vấn đề về độ trễ |
| Kho bí mật chuyên dụng | Khi có nhiều hơn một môi trường thật |
| Nền tảng điều phối container | Khi vận hành thủ công trở nên tốn thời gian hơn việc học nó |
