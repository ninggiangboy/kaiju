# UC-INT — Integration & Public API

Mở hệ thống ra bên ngoài. Token API tuân đúng hợp đồng token truy cập đã chốt từ
Phase 1 ([identity-and-permission.md — token truy cập chứa gì](../../04-system-design/identity-and-permission.md#token-truy-cập-chứa-gì)):
**không mang quyền**, chỉ thêm một loại token mới và một danh sách phạm vi để
lọc bớt, còn mặt nạ quyền thật vẫn tra lại phía server theo member ở mỗi
request — đúng invariant #26 và #27 của
[CLAUDE.md](../../../CLAUDE.md#kiến-trúc). Webhook đi ra là một **bên tiêu thụ
domain event** giống mọi consumer khác từ Phase 0
([events-and-outbox.md — bên tiêu thụ dự kiến](../../04-system-design/events-and-outbox.md#bên-tiêu-thụ-dự-kiến)),
và là đúng hành động "gọi webhook (Phase 16)" đã được dự liệu trước ở
[uc-16-automation.md — UC-AUT-04](uc-16-automation.md#uc-aut-04--các-loại-hành-động).

**Phase:** 16 · **Feature:** KJ-INT-01 → KJ-INT-10
**Liên quan:** [uc-01-auth.md](uc-01-auth.md) · [uc-05-issue.md](uc-05-issue.md) · [uc-09-search.md](uc-09-search.md) · [uc-16-automation.md](uc-16-automation.md) · [identity-and-permission.md](../../04-system-design/identity-and-permission.md) · [events-and-outbox.md](../../04-system-design/events-and-outbox.md) · [roadmap.md — Phase 16](../roadmap.md)

---

## UC-INT-01 — REST API công khai có phiên bản

**Actor:** hệ thống hoặc dịch vụ bên ngoài, xác thực bằng token API (UC-INT-03)
**Tiền điều kiện:** không có

### Luồng chính

1. API công khai lộ lại các nghiệp vụ đã có (issue, comment, board, search…)
   qua REST, đi qua **đúng command/query handler** mà giao diện web đã dùng —
   không có một tầng nghiệp vụ song song riêng cho API công khai
2. Đường dẫn API mang số phiên bản (ví dụ `/api/v1/...`); một phiên bản đã phát
   hành không đổi hành vi gây phá vỡ (breaking change) — thay đổi phá vỡ đi
   kèm phiên bản mới, phiên bản cũ tiếp tục hoạt động trong thời gian chuyển tiếp

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Request không có token hoặc token không hợp lệ | Từ chối ở cùng tầng xác thực dùng cho token truy cập thông thường, không có đường bỏ qua riêng cho API |
| Request vượt giới hạn tần suất theo token | Từ chối, trả về thời điểm được thử lại |

### Hậu điều kiện

Không có hành động nghiệp vụ nào chỉ tồn tại qua API công khai mà không đi qua
handler đã có — API công khai là một **lối vào khác** của cùng logic, không phải
một luồng logic khác.

---

## UC-INT-02 — Tài liệu OpenAPI

**Actor:** người phát triển tích hợp bên ngoài

### Luồng chính

1. Tài liệu OpenAPI được sinh từ chính định nghĩa route/handler, không viết tay
   riêng một bản dễ lệch với API thực tế
2. Tài liệu bao gồm ví dụ request/response và mô tả từng phạm vi quyền (scope)
   mà một thao tác yêu cầu

### Hậu điều kiện

Tài liệu OpenAPI luôn khớp với API đang chạy tại đúng phiên bản đó — đây là
Definition of Done của phase ("API công khai có tài liệu đầy đủ và phiên bản hoá").

---

## UC-INT-03 — Token có phạm vi quyền

**Actor:** thành viên tạo token

### Luồng chính

1. Tạo một token API: đặt tên gợi nhớ, chọn **phạm vi (scope)** — tập hành động
   được phép dùng token này (ví dụ chỉ đọc issue, hoặc đọc và ghi issue, không
   được quản trị workspace)
2. Token API cùng hợp đồng nội dung với token truy cập thông thường — mang
   `account`, loại token, thời điểm hết hạn, **không mang quyền hay danh sách
   workspace** — phạm vi chỉ là một điều kiện lọc thêm, kiểm tra **cùng lúc**
   với việc tra mặt nạ quyền thật của member ở mỗi request, không thay thế
   bước đó
3. Token API hoạt động cho tới khi hết hạn hoặc bị thu hồi thủ công (UC-INT-03
   luồng thay thế)

### Luồng thay thế

| Nhánh | Xử lý |
|---|---|
| Thu hồi token | Vô hiệu ngay, cùng cơ chế thu hồi phiên đã có ở [uc-01-auth.md — UC-AUT-06](uc-01-auth.md#uc-auth-06--quản-lý-phiên-đăng-nhập) |

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Request dùng token có phạm vi cho phép hành động, nhưng member tạo token **không còn đủ quyền thực tế** cho hành động đó (bị hạ quyền, rời project sau khi tạo token) | Từ chối — mặt nạ quyền tra lại theo member hiện tại ở mỗi request, phạm vi token chỉ có thể **thu hẹp thêm**, không bao giờ mở rộng vượt quyền hiện có của người tạo, đúng Definition of Done "token có phạm vi quyền không vượt quá quyền của người tạo ra nó" |
| Người tạo token rời khỏi workspace hoàn toàn | Token mất hiệu lực — không còn member nào để tra mặt nạ quyền |

### Hậu điều kiện

Một token API không bao giờ cho phép nhiều hơn những gì người tạo ra nó được
phép làm tại thời điểm request, bất kể phạm vi đã chọn lúc tạo token rộng đến
đâu.

> **Chưa chốt:** tài liệu hiện có (`functional.md` FR-INT-02) xác nhận token có
> phạm vi quyền, tạo và thu hồi được, nhưng chưa nói cơ chế lưu trữ cụ thể (băm
> giống token làm mới, hay một cơ chế riêng), thời hạn mặc định, hay danh sách
> phạm vi chi tiết (theo từng quyền bit hay theo nhóm chức năng thô). Để lại
> cho lúc thiết kế chi tiết, dựa trên danh mục quyền đã có ở
> [identity-and-permission.md](../../04-system-design/identity-and-permission.md).

---

## UC-INT-04 — Đăng ký webhook đi ra

**Actor:** thành viên có quyền quản trị project

### Luồng chính

1. Đăng ký một webhook: URL đích, danh sách loại sự kiện muốn nhận (issue tạo
   mới, đổi trạng thái, bình luận thêm…)
2. Webhook là một **bên tiêu thụ domain event qua outbox**, cùng cơ chế mọi
   consumer khác đã dùng từ Phase 0 — không có đường phát riêng bỏ qua outbox

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Xoá webhook đang có lần gửi dở dang | Các lần gửi đã xếp hàng tiếp tục hoàn tất hoặc hết lượt thử lại theo UC-INT-05, không huỷ ngang |

---

## UC-INT-05 — Thử lại, nhật ký gửi và chữ ký cho webhook

**Actor:** hệ thống (không có giao diện riêng — hệ quả của UC-INT-04) · thành viên có quyền quản trị project (xem nhật ký)

### Luồng chính

1. Gửi webhook kèm **chữ ký** (HMAC trên nội dung, dùng khoá bí mật riêng của
   từng webhook) để bên nhận xác minh request thật sự đến từ Kaiju
2. Gửi thất bại (bên nhận lỗi hoặc không phản hồi) → thử lại theo giãn cách
   tăng dần, tới một số lần tối đa
3. Ghi nhật ký gửi: thời điểm, mã trạng thái phản hồi, số lần thử — xem lại được
   theo từng webhook

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Webhook thất bại toàn bộ số lần thử | Đánh dấu lần gửi đó là thất bại vĩnh viễn trong nhật ký, **không ảnh hưởng** tới nghiệp vụ đã xảy ra (issue đã tạo, trạng thái đã đổi vẫn giữ nguyên) — đúng Definition of Done "webhook thất bại không ảnh hưởng tới luồng nghiệp vụ" |
| Sự kiện được relay worker gửi lại (delivery ít nhất một lần ở tầng outbox) | Bên tiêu thụ webhook chống trùng theo `(consumer, event_id)` giống mọi consumer khác, không gửi trùng ra ngoài vì lý do nội bộ |

### Ảnh hưởng tới đồng bộ

Gửi webhook là tác vụ nền thuần tuý, không phát delta nào tới sync scope của
client — nó tiêu thụ domain event nội bộ, không tạo ra thay đổi dữ liệu nghiệp
vụ nào cần đồng bộ ngược lại.

---

## UC-INT-06 — Nhận diện mã issue trong commit và nhánh

**Actor:** hệ thống (không có giao diện riêng — kích hoạt bởi sự kiện từ hệ thống quản lý mã nguồn bên ngoài)
**Tiền điều kiện:** đã kết nối một kho mã nguồn (Git provider)

### Luồng chính

1. Hệ thống quét tên nhánh, thông điệp commit, và tiêu đề pull request tìm mã
   issue (định dạng `KEY-số`, xem [uc-05-issue.md — UC-ISS-02](uc-05-issue.md#uc-iss-02--sinh-mã-issue-an-toàn-khi-tạo-đồng-thời))
2. Mã issue khớp → liên kết commit/nhánh/pull request đó với issue tương ứng,
   dữ liệu này thuộc bảng thông tin phát triển của issue (UC-INT-07)

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Mã issue khớp cú pháp nhưng issue đã bị xoá mềm hoặc thuộc project không còn kết nối | Không tạo liên kết, không báo lỗi cho commit — im lặng bỏ qua vì đây là dữ liệu suy luận, không phải một thao tác người dùng chủ động |
| Một commit khớp nhiều mã issue | Liên kết với toàn bộ issue khớp được, không chỉ mã đầu tiên tìm thấy |

---

## UC-INT-07 — Bảng thông tin phát triển trên issue

**Actor:** thành viên có quyền xem project

### Luồng chính

1. Trên một issue, xem danh sách commit, nhánh, và pull request đã liên kết
   qua UC-INT-06 — trạng thái pull request (mở, đã duyệt, đã merge) hiển thị
   trực tiếp, cập nhật khi có sự kiện mới từ kho mã nguồn

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Người xem không có quyền xem kho mã nguồn liên kết (quyền quản lý ở phía Git provider) | Vẫn hiện tên nhánh/commit đã liên kết ở mức tối thiểu (đây là metadata đã lưu ở Kaiju), nhưng không cấp quyền xem nội dung mã nguồn — Kaiju không phải nơi cấp quyền đó |

---

## UC-INT-08 — Lệnh trong commit

**Actor:** thành viên viết commit trên kho mã nguồn đã kết nối

### Luồng chính

1. Thông điệp commit chứa lệnh dạng đặc biệt (ví dụ `KEY-123 #time 2h`,
   `KEY-123 #close`) bên cạnh mã issue
2. Hệ thống diễn giải lệnh: ghi nhật ký công việc
   ([uc-13-time.md — UC-TIM-02](uc-13-time.md#uc-tim-02--nhật-ký-công-việc-theo-ngày))
   hoặc thực hiện bước chuyển trạng thái — bước chuyển vẫn đi qua đúng luồng
   UC-WKF-02..05 ở [uc-07-workflow.md](uc-07-workflow.md), không ghi thẳng
   trạng thái

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Lệnh yêu cầu bước chuyển không hợp lệ từ trạng thái hiện tại của issue | Bỏ qua lệnh đó, ghi cảnh báo vào bảng thông tin phát triển (UC-INT-07), không chặn commit đã đẩy lên (commit đã xảy ra ở kho mã nguồn, không thể huỷ ngược) |
| Người viết commit không có quyền thực hiện bước chuyển hoặc ghi nhật ký công việc trên issue đó | Bỏ qua lệnh, ghi rõ lý do thiếu quyền — cùng nguyên tắc UC-AUT-04 áp dụng cho hành động của automation: không có identity nào (kể cả tới từ tích hợp Git) bỏ qua kiểm tra quyền |

> **Chưa chốt:** tài liệu hiện có (`functional.md` FR-INT-06, mức ưu tiên
> SHOULD) chưa liệt kê đầy đủ cú pháp lệnh hỗ trợ ngoài hai ví dụ ghi thời gian
> và chuyển trạng thái. Để lại danh sách lệnh đầy đủ cho lúc thiết kế chi tiết.

---

## UC-INT-09 — Thông báo sang công cụ chat

**Actor:** thành viên có quyền quản trị project

### Luồng chính

1. Kết nối một kênh Slack hoặc Discord với một project
2. Chọn loại sự kiện muốn thông báo sang kênh chat — cơ chế gửi dùng lại đúng
   nền tảng webhook đi ra đã có ở UC-INT-04/UC-INT-05, chỉ khác định dạng nội
   dung theo yêu cầu của từng nền tảng chat, không phải một đường gửi riêng

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Kênh chat đã kết nối bị xoá hoặc mất quyền truy cập phía nền tảng chat | Lần gửi tiếp theo thất bại và đi qua đúng luồng thử lại/ghi nhật ký của UC-INT-05, không có xử lý đặc biệt riêng cho loại webhook này |

---

## UC-INT-10 — Đăng nhập một lần và cấp phát tài khoản tự động

**Actor:** người dùng thuộc một tổ chức có nhà cung cấp danh tính (identity provider) ngoài
**Tiền điều kiện:** workspace đã cấu hình một nhà cung cấp SAML/OIDC

### Luồng chính

1. Người dùng đăng nhập qua nhà cung cấp danh tính bên ngoài (SAML hoặc OIDC)
   thay vì magic link
2. Xác thực thành công lần đầu → tự động tạo tài khoản, gắn `member` vào
   workspace đã cấu hình nhà cung cấp đó — không cần lời mời thủ công trước
3. Từ sau lần đầu, đăng nhập qua nhà cung cấp này đi thẳng vào workspace, không
   qua magic link

### Ngoại lệ

| Trường hợp | Phản ứng |
|---|---|
| Email từ nhà cung cấp danh tính đã có tài khoản tạo qua magic link trước đó | Gộp vào tài khoản hiện có theo email khớp, không tạo tài khoản trùng |
| Nhà cung cấp danh tính trả về lỗi hoặc bị từ chối | Báo lỗi, không tự động rơi về magic link như một phương án thay thế âm thầm — người dùng phải được thông báo rõ đăng nhập SSO thất bại |

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
| QT-01 | API công khai đi qua đúng command/query handler đã có, không có tầng nghiệp vụ song song riêng |
| QT-02 | Tài liệu OpenAPI sinh từ định nghĩa route/handler thực tế, không viết tay riêng |
| QT-03 | Token API không mang quyền hay danh sách workspace; phạm vi chỉ là điều kiện lọc thêm, mặt nạ quyền thật vẫn tra lại theo member ở mỗi request |
| QT-04 | Token API không bao giờ cho phép vượt quá quyền hiện tại của người tạo ra nó |
| QT-05 | Webhook đi ra là một consumer domain event qua outbox, phải chống trùng theo `(consumer, event_id)` giống mọi consumer khác |
| QT-06 | Webhook thất bại toàn bộ số lần thử không ảnh hưởng tới dữ liệu nghiệp vụ đã xảy ra |
| QT-07 | Lệnh trong commit vẫn kiểm tra quyền của người viết commit, không có identity nào bỏ qua kiểm tra quyền |
| QT-08 | Thông báo sang công cụ chat dùng lại nền tảng webhook đi ra, không phải một đường gửi riêng |
| QT-09 | Đăng nhập SSO không tự động rơi về magic link khi thất bại |

## Yêu cầu phi chức năng liên quan

`NFR-25` token không mang quyền · `NFR-07` phân quyền luôn tra lại phía server
theo request, kể cả request từ token API · `NFR-17` mọi consumer sự kiện
(bao gồm webhook) phải chống trùng
