# UC-INT — Integration & Public API

Mở hệ thống ra bên ngoài. Token API tuân đúng hợp đồng token truy cập đã chốt từ
Phase 1 ([identity-and-permission.md — token truy cập chứa gì](../../04-system-design/identity-and-permission.md#token-truy-cập-chứa-gì)):
**không mang quyền**, chỉ thêm một loại token mới và một danh sách phạm vi để
lọc bớt, còn mặt nạ quyền thật vẫn tra lại phía server theo member ở mỗi
request — đúng invariant #26 và #27 của
[CLAUDE.md](../../../CLAUDE.md#architecture). Webhook đi ra là một **bên tiêu thụ
domain event** giống mọi consumer khác từ Phase 0
([events-and-outbox.md — bên tiêu thụ dự kiến](../../04-system-design/events-and-outbox.md#bên-tiêu-thụ-dự-kiến)),
và là đúng hành động "gọi webhook (Phase 16)" đã được dự liệu trước ở
[uc-16-automation.md — UC-AUT-04](uc-16-automation.md#uc-aut-04--các-loại-hành-động).

**Phase:** 16 · **Feature:** KJ-INT-01 → KJ-INT-10
**Liên quan:** [uc-01-auth.md](uc-01-auth.md) · [uc-05-issue.md](uc-05-issue.md) · [uc-09-search.md](uc-09-search.md) · [uc-16-automation.md](uc-16-automation.md) · [identity-and-permission.md](../../04-system-design/identity-and-permission.md) · [events-and-outbox.md](../../04-system-design/events-and-outbox.md) · [roadmap.md — Phase 16](../roadmap.md)

---

## UC-INT-01 — REST API công khai có phiên bản

**Requirement:** FR-INT-01
**Actor:** hệ thống hoặc dịch vụ bên ngoài, xác thực bằng token API (UC-INT-03)
**Tiền điều kiện:** không có

### Luồng chính

1. API công khai lộ lại các nghiệp vụ đã có (issue, comment, board, search…)
   qua REST, đi qua **đúng command/query handler** mà giao diện web đã dùng —
   không có một tầng nghiệp vụ song song riêng cho API công khai
2. Đường dẫn API mang số phiên bản (ví dụ `/api/v1/...`); một phiên bản đã phát
   hành không đổi hành vi gây phá vỡ (breaking change) — thay đổi phá vỡ đi
   kèm phiên bản mới, phiên bản cũ tiếp tục hoạt động trong thời gian chuyển tiếp

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-INT-01/NT-01 | Gọi một endpoint ghi dữ liệu (mutation) hai lần với cùng khoá chống trùng | Không tạo hiệu ứng hai lần — API công khai mang cùng yêu cầu idempotency key với mutation từ giao diện web (invariant 19), không có ngoại lệ riêng cho bên gọi ngoài |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-INT-01/NL-01 | Request không có token hoặc token không hợp lệ | Từ chối ở cùng tầng xác thực dùng cho token truy cập thông thường, không có đường bỏ qua riêng cho API |
| UC-INT-01/NL-02 | Request vượt giới hạn tần suất theo token | Từ chối, trả về thời điểm được thử lại |

### Hậu điều kiện

Không có hành động nghiệp vụ nào chỉ tồn tại qua API công khai mà không đi qua
handler đã có — API công khai là một **lối vào khác** của cùng logic, không phải
một luồng logic khác.

### Ảnh hưởng tới đồng bộ

Không áp dụng riêng — vì API công khai đi qua đúng command/query handler mà
giao diện web dùng (QT-INT-01), nó phát đúng delta mà use case gốc của dữ liệu
đó phát, y hệt cơ chế đã mô tả cho automation ở
[uc-16-automation.md — UC-AUT-04](uc-16-automation.md#uc-aut-04--các-loại-hành-động).

---

## UC-INT-02 — Tài liệu OpenAPI

**Requirement:** FR-INT-01
**Actor:** người phát triển tích hợp bên ngoài
**Tiền điều kiện:** không có

### Luồng chính

1. Tài liệu OpenAPI được sinh từ chính định nghĩa route/handler, không viết tay
   riêng một bản dễ lệch với API thực tế
2. Tài liệu bao gồm ví dụ request/response và mô tả từng phạm vi quyền (scope)
   mà một thao tác yêu cầu

### Hậu điều kiện

Tài liệu OpenAPI luôn khớp với API đang chạy tại đúng phiên bản đó — đây là
Definition of Done của phase ("API công khai có tài liệu đầy đủ và phiên bản hoá").

### Ảnh hưởng tới đồng bộ

Không áp dụng — tài liệu là nội dung tĩnh sinh ra từ route/handler, không phải
dữ liệu client giữ cục bộ.

---

## UC-INT-03 — Token có phạm vi quyền

**Requirement:** FR-INT-02
**Actor:** thành viên tạo token
**Tiền điều kiện:** không có

### Luồng chính

1. Tạo một token API: đặt tên gợi nhớ, chọn **phạm vi (scope)** — tập hành động
   được phép dùng token này (ví dụ chỉ đọc issue, hoặc đọc và ghi issue, không
   được quản trị workspace)
2. Token API cùng hợp đồng nội dung với token truy cập thông thường — mang
   `account`, loại token, thời điểm hết hạn, **không mang quyền hay danh sách
   workspace** — phạm vi chỉ là một điều kiện lọc thêm, kiểm tra **cùng lúc**
   với việc tra mặt nạ quyền thật của member ở mỗi request, không thay thế
   bước đó
3. Token API hoạt động cho tới khi hết hạn hoặc bị thu hồi thủ công
   (UC-INT-03/NT-01)

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-INT-03/NT-01 | Thu hồi token | Vô hiệu ngay, cùng cơ chế thu hồi phiên đã có ở [uc-01-auth.md — UC-AUT-06](uc-01-auth.md#uc-auth-06--quản-lý-phiên-đăng-nhập) |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-INT-03/NL-01 | Request dùng token có phạm vi cho phép hành động, nhưng member tạo token **không còn đủ quyền thực tế** cho hành động đó (bị hạ quyền, rời project sau khi tạo token) | Từ chối — mặt nạ quyền tra lại theo member hiện tại ở mỗi request, phạm vi token chỉ có thể **thu hẹp thêm**, không bao giờ mở rộng vượt quyền hiện có của người tạo, đúng Definition of Done "token có phạm vi quyền không vượt quá quyền của người tạo ra nó" |
| UC-INT-03/NL-02 | Người tạo token rời khỏi workspace hoàn toàn | Token mất hiệu lực — không còn member nào để tra mặt nạ quyền |

### Hậu điều kiện

Một token API không bao giờ cho phép nhiều hơn những gì người tạo ra nó được
phép làm tại thời điểm request, bất kể phạm vi đã chọn lúc tạo token rộng đến
đâu.

### Ảnh hưởng tới đồng bộ

Danh sách token của một thành viên là dữ liệu quản trị, không phải dữ liệu
nghiệp vụ đồng bộ qua sync scope — trang quản lý token đọc trực tiếp qua API,
không cần store cục bộ hay hoạt động offline.

> **Chưa chốt:** tài liệu hiện có (`functional.md` FR-INT-02) xác nhận token có
> phạm vi quyền, tạo và thu hồi được, nhưng chưa nói cơ chế lưu trữ cụ thể (băm
> giống token làm mới, hay một cơ chế riêng), thời hạn mặc định, hay danh sách
> phạm vi chi tiết (theo từng quyền bit hay theo nhóm chức năng thô). Để lại
> cho lúc thiết kế chi tiết, dựa trên danh mục quyền đã có ở
> [identity-and-permission.md](../../04-system-design/identity-and-permission.md).

---

## UC-INT-04 — Đăng ký webhook đi ra

**Requirement:** FR-INT-03
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** không có

### Luồng chính

1. Đăng ký một webhook: URL đích, danh sách loại sự kiện muốn nhận (issue tạo
   mới, đổi trạng thái, bình luận thêm…)
2. Webhook là một **bên tiêu thụ domain event qua outbox**, cùng cơ chế mọi
   consumer khác đã dùng từ Phase 0 — không có đường phát riêng bỏ qua outbox

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-INT-04/NT-01 | Xoá webhook đang có lần gửi dở dang | Các lần gửi đã xếp hàng tiếp tục hoàn tất hoặc hết lượt thử lại theo UC-INT-05, không huỷ ngang |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-INT-04/NL-01 | Không có quyền quản trị project | Không hiển thị chức năng đăng ký/sửa/xoá webhook |

### Hậu điều kiện

Webhook tồn tại với URL đích và danh sách loại sự kiện đã đăng ký, sẵn sàng
nhận domain event qua outbox.

### Ảnh hưởng tới đồng bộ

Cấu hình webhook là dữ liệu quản trị của project, nằm trong sync scope
`proj:{projectId}`; đăng ký/sửa/xoá webhook phát delta cho chính cấu hình đó.
Việc gửi webhook thật sự không phát delta — xem UC-INT-05.

---

## UC-INT-05 — Thử lại, nhật ký gửi và chữ ký cho webhook

**Requirement:** FR-INT-03
**Actor:** hệ thống (không có giao diện riêng — hệ quả của UC-INT-04) · thành viên có quyền quản trị project (xem nhật ký)
**Tiền điều kiện:** webhook đã đăng ký (UC-INT-04)

### Luồng chính

1. Gửi webhook kèm **chữ ký** (HMAC trên nội dung, dùng khoá bí mật riêng của
   từng webhook) để bên nhận xác minh request thật sự đến từ Kaiju
2. Gửi thất bại (bên nhận lỗi hoặc không phản hồi) → thử lại theo giãn cách
   tăng dần, tới một số lần tối đa
3. Ghi nhật ký gửi: thời điểm, mã trạng thái phản hồi, số lần thử — xem lại được
   theo từng webhook

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-INT-05/NT-01 | Sự kiện được relay worker gửi lại (delivery ít nhất một lần ở tầng outbox) | Bên tiêu thụ webhook chống trùng theo `(consumer, event_id)` giống mọi consumer khác, không gửi trùng ra ngoài vì lý do nội bộ |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-INT-05/NL-01 | Webhook thất bại toàn bộ số lần thử | Đánh dấu lần gửi đó là thất bại vĩnh viễn trong nhật ký, **không ảnh hưởng** tới nghiệp vụ đã xảy ra (issue đã tạo, trạng thái đã đổi vẫn giữ nguyên) — đúng Definition of Done "webhook thất bại không ảnh hưởng tới luồng nghiệp vụ" |

### Hậu điều kiện

Nhật ký gửi phản ánh đúng kết quả cuối cùng (thành công, hoặc thất bại vĩnh
viễn sau khi hết lượt thử lại); dữ liệu nghiệp vụ nguồn không bị ảnh hưởng bởi
kết quả gửi webhook.

### Ảnh hưởng tới đồng bộ

Gửi webhook là tác vụ nền thuần tuý, không phát delta nào tới sync scope của
client — nó tiêu thụ domain event nội bộ, không tạo ra thay đổi dữ liệu nghiệp
vụ nào cần đồng bộ ngược lại.

---

## UC-INT-06 — Nhận diện mã issue trong commit và nhánh

**Requirement:** FR-INT-04
**Actor:** hệ thống (không có giao diện riêng — kích hoạt bởi sự kiện từ hệ thống quản lý mã nguồn bên ngoài)
**Tiền điều kiện:** đã kết nối một kho mã nguồn (Git provider)

### Luồng chính

1. Hệ thống quét tên nhánh, thông điệp commit, và tiêu đề pull request tìm mã
   issue (định dạng `KEY-số`, xem [uc-05-issue.md — UC-ISS-02](uc-05-issue.md#uc-iss-02--sinh-mã-issue-an-toàn-khi-tạo-đồng-thời))
2. Mã issue khớp → liên kết commit/nhánh/pull request đó với issue tương ứng,
   dữ liệu này thuộc bảng thông tin phát triển của issue (UC-INT-07)

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-INT-06/NT-01 | Một commit khớp nhiều mã issue | Liên kết với toàn bộ issue khớp được, không chỉ mã đầu tiên tìm thấy |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-INT-06/NL-01 | Mã issue khớp cú pháp nhưng issue đã bị xoá mềm hoặc thuộc project không còn kết nối | Không tạo liên kết, không báo lỗi cho commit — im lặng bỏ qua vì đây là dữ liệu suy luận, không phải một thao tác người dùng chủ động |

### Hậu điều kiện

Liên kết commit/nhánh/pull request với issue tồn tại trong bảng thông tin phát
triển của issue (UC-INT-07).

### Ảnh hưởng tới đồng bộ

Liên kết mới là dữ liệu thuộc issue, phát delta trong sync scope
`proj:{projectId}` như mọi thay đổi khác của issue.

---

## UC-INT-07 — Bảng thông tin phát triển trên issue

**Requirement:** FR-INT-05
**Actor:** thành viên có quyền xem project
**Tiền điều kiện:** issue có ít nhất một liên kết commit/nhánh/pull request (UC-INT-06)

### Luồng chính

1. Trên một issue, xem danh sách commit, nhánh, và pull request đã liên kết
   qua UC-INT-06 — trạng thái pull request (mở, đã duyệt, đã merge) hiển thị
   trực tiếp, cập nhật khi có sự kiện mới từ kho mã nguồn

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-INT-07/NT-01 | Người xem không có quyền xem kho mã nguồn liên kết (quyền quản lý ở phía Git provider) | Vẫn hiện tên nhánh/commit đã liên kết ở mức tối thiểu (đây là metadata đã lưu ở Kaiju), nhưng không cấp quyền xem nội dung mã nguồn — Kaiju không phải nơi cấp quyền đó |

### Hậu điều kiện

Không có — đây là thao tác chỉ đọc. Cập nhật trạng thái pull request là hệ quả
của sự kiện mới từ UC-INT-06, không phải của việc xem.

### Ảnh hưởng tới đồng bộ

Bảng thông tin phát triển đọc trực tiếp từ dữ liệu issue trong sync scope
`proj:{projectId}` đã có (UC-INT-06) — không có scope hay request riêng.

---

## UC-INT-08 — Lệnh trong commit

**Requirement:** FR-INT-06
**Actor:** thành viên viết commit trên kho mã nguồn đã kết nối
**Tiền điều kiện:** commit chứa mã issue hợp lệ (UC-INT-06)

### Luồng chính

1. Thông điệp commit chứa lệnh dạng đặc biệt (ví dụ `KEY-123 #time 2h`,
   `KEY-123 #close`) bên cạnh mã issue
2. Hệ thống diễn giải lệnh: ghi nhật ký công việc
   ([uc-13-time.md — UC-TIM-02](uc-13-time.md#uc-tim-02--nhật-ký-công-việc-theo-ngày))
   hoặc thực hiện bước chuyển trạng thái — bước chuyển vẫn đi qua đúng luồng
   UC-WKF-02..05 ở [uc-07-workflow.md](uc-07-workflow.md), không ghi thẳng
   trạng thái

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-INT-08/NL-01 | Lệnh yêu cầu bước chuyển không hợp lệ từ trạng thái hiện tại của issue | Bỏ qua lệnh đó, ghi cảnh báo vào bảng thông tin phát triển (UC-INT-07), không chặn commit đã đẩy lên (commit đã xảy ra ở kho mã nguồn, không thể huỷ ngược) |
| UC-INT-08/NL-02 | Người viết commit không có quyền thực hiện bước chuyển hoặc ghi nhật ký công việc trên issue đó | Bỏ qua lệnh, ghi rõ lý do thiếu quyền — cùng nguyên tắc UC-AUT-04 áp dụng cho hành động của automation: không có identity nào (kể cả tới từ tích hợp Git) bỏ qua kiểm tra quyền |

### Hậu điều kiện

Lệnh đã thực hiện để lại đúng trạng thái mà thao tác thủ công tương ứng
(UC-TIM-02 hoặc UC-WKF-02..05) sẽ để lại; lệnh bị bỏ qua không đổi gì.

### Ảnh hưởng tới đồng bộ

Không áp dụng riêng — lệnh thực thi đi qua đúng handler của UC-TIM-02 hoặc
UC-WKF-02..05, phát đúng delta mà use case đó đã mô tả.

> **Chưa chốt:** tài liệu hiện có (`functional.md` FR-INT-06, mức ưu tiên
> SHOULD) chưa liệt kê đầy đủ cú pháp lệnh hỗ trợ ngoài hai ví dụ ghi thời gian
> và chuyển trạng thái. Để lại danh sách lệnh đầy đủ cho lúc thiết kế chi tiết.

---

## UC-INT-09 — Thông báo sang công cụ chat

**Requirement:** FR-INT-07
**Actor:** thành viên có quyền quản trị project
**Tiền điều kiện:** không có

### Luồng chính

1. Kết nối một kênh Slack hoặc Discord với một project
2. Chọn loại sự kiện muốn thông báo sang kênh chat — cơ chế gửi dùng lại đúng
   nền tảng webhook đi ra đã có ở UC-INT-04/UC-INT-05, chỉ khác định dạng nội
   dung theo yêu cầu của từng nền tảng chat, không phải một đường gửi riêng

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-INT-09/NL-01 | Kênh chat đã kết nối bị xoá hoặc mất quyền truy cập phía nền tảng chat | Lần gửi tiếp theo thất bại và đi qua đúng luồng thử lại/ghi nhật ký của UC-INT-05, không có xử lý đặc biệt riêng cho loại webhook này |
| UC-INT-09/NL-02 | Không có quyền quản trị project | Không hiển thị chức năng kết nối kênh chat |

### Hậu điều kiện

Kết nối kênh chat và danh sách loại sự kiện muốn thông báo tồn tại, dùng chung
hạ tầng webhook đã có ở UC-INT-04.

### Ảnh hưởng tới đồng bộ

Cấu hình kết nối kênh chat phát delta như một webhook thông thường (UC-INT-04);
việc gửi thông báo không phát delta, cùng cơ chế UC-INT-05.

---

## UC-INT-10 — Đăng nhập một lần và cấp phát tài khoản tự động

**Requirement:** FR-INT-08
**Actor:** người dùng thuộc một tổ chức có nhà cung cấp danh tính (identity provider) ngoài
**Tiền điều kiện:** workspace đã cấu hình một nhà cung cấp SAML/OIDC

### Luồng chính

1. Người dùng đăng nhập qua nhà cung cấp danh tính bên ngoài (SAML hoặc OIDC)
   thay vì magic link
2. Xác thực thành công lần đầu → tự động tạo tài khoản, gắn `member` vào
   workspace đã cấu hình nhà cung cấp đó — không cần lời mời thủ công trước
3. Từ sau lần đầu, đăng nhập qua nhà cung cấp này đi thẳng vào workspace, không
   qua magic link

### Luồng thay thế

| ID | Trường hợp | Xử lý |
|---|---|---|
| UC-INT-10/NT-01 | Email từ nhà cung cấp danh tính đã có tài khoản tạo qua magic link trước đó | Gộp vào tài khoản hiện có theo email khớp, không tạo tài khoản trùng |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-INT-10/NL-01 | Nhà cung cấp danh tính trả về lỗi hoặc bị từ chối | Báo lỗi, không tự động rơi về magic link như một phương án thay thế âm thầm — người dùng phải được thông báo rõ đăng nhập SSO thất bại |

### Hậu điều kiện

Tài khoản tồn tại và có phiên đăng nhập hợp lệ, gắn `member` vào workspace đã
cấu hình nhà cung cấp — cùng trạng thái cuối mà magic link để lại (UC-AUTH-01).

### Ảnh hưởng tới đồng bộ

Không áp dụng riêng — đăng nhập thành công dẫn tới bootstrap như mọi phiên đăng
nhập khác (UC-AUTH-01); SSO chỉ thay phương thức xác thực, không thay cơ chế
đồng bộ sau đó.

> **Chưa chốt:** tài liệu hiện có (`functional.md` FR-INT-08, mức ưu tiên
> COULD — mức thấp nhất) chưa nói quan hệ giữa SSO và nguyên tắc "không có mật
> khẩu, magic link là phương thức xác thực duy nhất" đã chốt ở
> [ADR-0009](../../adr/0009-magic-link-only.md). Use case này đọc SSO như một
> **phương thức xác thực bổ sung** cho workspace có cấu hình, không thay thế
> magic link ở nơi khác — nhưng đây là một mở rộng của ADR-0009 chưa được ADR
> đó xác nhận tường minh. Nên viết một ADR mới hoặc bổ sung ADR-0009 khi thực
> sự triển khai UC-INT-10, vì đây là quyết định khó đảo ngược và ảnh hưởng cả
> backend lẫn frontend (đúng tiêu chí "khi nào viết ADR mới" của CLAUDE.md).

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-INT-01 | API công khai đi qua đúng command/query handler đã có, không có tầng nghiệp vụ song song riêng |
| QT-INT-02 | Tài liệu OpenAPI sinh từ định nghĩa route/handler thực tế, không viết tay riêng |
| QT-INT-03 | Token API không mang quyền hay danh sách workspace; phạm vi chỉ là điều kiện lọc thêm, mặt nạ quyền thật vẫn tra lại theo member ở mỗi request |
| QT-INT-04 | Token API không bao giờ cho phép vượt quá quyền hiện tại của người tạo ra nó |
| QT-INT-05 | Webhook đi ra là một consumer domain event qua outbox, phải chống trùng theo `(consumer, event_id)` giống mọi consumer khác |
| QT-INT-06 | Webhook thất bại toàn bộ số lần thử không ảnh hưởng tới dữ liệu nghiệp vụ đã xảy ra |
| QT-INT-07 | Lệnh trong commit vẫn kiểm tra quyền của người viết commit, không có identity nào bỏ qua kiểm tra quyền |
| QT-INT-08 | Thông báo sang công cụ chat dùng lại nền tảng webhook đi ra, không phải một đường gửi riêng |
| QT-INT-09 | Đăng nhập SSO không tự động rơi về magic link khi thất bại |

## Yêu cầu phi chức năng liên quan

`NFR-25` token không mang quyền · `NFR-07` phân quyền luôn tra lại phía server
theo request, kể cả request từ token API · `NFR-17` mọi consumer sự kiện
(bao gồm webhook) phải chống trùng
