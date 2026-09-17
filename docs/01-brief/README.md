# 01 — Product Brief

Kaiju là một hệ quản lý dự án kiểu Jira, xây dựng theo hướng **local-first** và
**realtime**. Tài liệu này nêu vấn đề đang giải quyết, đối tượng, phạm vi, và
nguyên tắc phát triển chi phối mọi quyết định còn lại.

**Liên quan:** [Glossary](../glossary.md) · [Requirement](../02-requirement/) · [Roadmap](../03-features/roadmap.md) · [ADR](../adr/)

---

## Vấn đề

Các công cụ quản lý dự án phổ biến đều mạnh về tính năng nhưng chậm ở những thao
tác người ta làm hàng trăm lần mỗi ngày. Mở một issue, kéo một card sang cột
khác, lọc backlog — mỗi thao tác đều là một vòng đi về server, và người dùng ngồi
nhìn spinner. Khi mạng chập chờn thì công cụ gần như không dùng được, dù dữ liệu
cần thiết nhỏ và hoàn toàn có thể nằm sẵn trên máy.

Jira còn có một vấn đề thứ hai: độ phức tạp cấu hình. Scheme chồng scheme, và để
đổi một trường bắt buộc người ta phải đi qua bốn màn hình quản trị.

Kaiju không cố thay thế Jira ở quy mô doanh nghiệp. Nó là câu trả lời cho câu
hỏi: **nếu xây lại một công cụ như vậy với local-first và realtime là nền móng
chứ không phải tính năng đắp thêm, thì nó sẽ như thế nào?**

## Vì sao không dùng thẳng Jira

| Lý do | Diễn giải |
|---|---|
| Trải nghiệm | Mọi thao tác đi qua mạng; không có khái niệm làm việc offline |
| Kiểm soát | Không sửa được hành vi cốt lõi, không tự host được ở mức hợp lý |
| Mục đích học | Đây đồng thời là một dự án để làm tới nơi tới chốn các bài toán khó: sync engine, event-driven, multi-tenancy, phân quyền |

Lý do thứ ba là thật và cần nói rõ, vì nó giải thích nhiều lựa chọn kỹ thuật
trong dự án — chẳng hạn quyết định tự xây sync engine thay vì dùng thư viện
([ADR-0007](../adr/0007-build-own-sync-engine.md)).

## Đối tượng người dùng

**Chính:** đội phát triển phần mềm từ 3 đến 30 người, tự quản lý công việc của
mình, cần backlog, board, sprint và issue tracking đầy đủ.

**Phụ:** cá nhân hoặc nhóm nhỏ dùng như công cụ theo dõi công việc riêng.

**Không nhắm tới:** doanh nghiệp lớn cần SSO doanh nghiệp, audit tuân thủ, phân
quyền tới từng bản ghi, hay các quy trình phê duyệt phức tạp.

### Bối cảnh sử dụng

- Chủ yếu trên desktop, phiên làm việc dài, mở nhiều tab cùng lúc
- Nhiều người cùng thao tác trên một board và cần thấy thay đổi của nhau ngay
- Mạng không phải lúc nào cũng ổn định; mất kết nối vài phút không được làm gián
  đoạn công việc

## Mục tiêu sản phẩm

1. **Thao tác phản hồi tức thì.** Không có spinner ở luồng làm việc chính. Mọi
   thay đổi hiện ra ngay và đồng bộ phía sau.
2. **Dùng được khi offline.** Đọc, tạo và sửa vẫn hoạt động; thay đổi được gửi đi
   khi có mạng trở lại.
3. **Realtime thật.** Thay đổi của người khác xuất hiện trong vòng một giây mà
   không cần tải lại trang.
4. **Đầy đủ chứ không tối giản.** Mỗi tính năng làm tới nơi, kể cả các trường hợp
   biên, thay vì có nhiều tính năng dở dang.
5. **Cấu hình dễ hiểu.** Giữ khả năng tuỳ biến của Jira nhưng không bắt người
   dùng đi qua bốn lớp scheme để đổi một trường.

### Chỉ dấu thành công

Đây là dự án cá nhân nên các chỉ dấu mang tính định tính:

- Người dùng không nhận ra khi nào mình đang offline, cho tới lúc cần dữ liệu chưa tải
- Không có màn hình nào trong luồng chính hiển thị trạng thái chờ mạng
- Thêm một tính năng mới không buộc phải sửa lại tính năng đã có
- Một người mới đọc `docs/` là bắt tay implement được, không cần hỏi lại

## Phạm vi

### Sẽ làm

Quản lý issue đầy đủ (loại, phân cấp, liên kết, comment, attachment, watcher,
changelog), workflow cấu hình được, custom field, ngôn ngữ truy vấn kiểu JQL,
board Kanban và Scrum, sprint và báo cáo agile, roadmap, time tracking, version
và release, dashboard, automation engine, thao tác hàng loạt và import, REST API
công khai kèm webhook và tích hợp Git.

Chi tiết theo từng phase: [roadmap.md](../03-features/roadmap.md).

### Không làm

| Không làm | Vì sao |
|---|---|
| Service desk, SLA, cổng yêu cầu cho người ngoài | Là một sản phẩm khác, không phải một tính năng |
| Phân quyền tới từng issue riêng lẻ | Phức tạp lớn, nhu cầu nhỏ ở quy mô nhắm tới |
| Marketplace và hệ thống plugin của bên thứ ba | Chỉ có ý nghĩa khi đã có người dùng thật |
| Ứng dụng di động native | Web responsive là đủ cho bối cảnh sử dụng |
| Tài liệu kiểu wiki (Confluence) | Ngoài phạm vi |
| SSO doanh nghiệp, SCIM | Không thuộc đối tượng nhắm tới; để lại phase tích hợp |

### So với Jira

| | Jira | Kaiju |
|---|---|---|
| Đơn vị tổ chức | Organization → Site → Project | **Workspace → Project** (không có cấp tổ chức phía trên) |
| Xác thực | Mật khẩu, SSO, OAuth | **Chỉ magic link** ([ADR-0009](../adr/0009-magic-link-only.md)) |
| Trải nghiệm dữ liệu | Server-side, tải theo trang | **Local-first**, dữ liệu nằm trên máy người dùng |
| Realtime | Có giới hạn, nhiều chỗ phải tải lại | Đồng bộ toàn diện qua một sync engine duy nhất |
| Phân quyền | Permission scheme nhiều lớp | **Bitmask hai cấp** cộng permission condition |
| Service desk | Có | Không |
| Quy mô | Doanh nghiệp | Đội nhỏ và vừa |

## Nguyên tắc phát triển

**Làm từng tính năng một, nhưng mỗi tính năng phải đầy đủ.**

Không làm theo kiểu có mặt đủ mọi tính năng nhưng cái nào cũng sơ sài rồi bổ sung
dần. Một tính năng chỉ được coi là xong khi đã xử lý các trường hợp biên, phân
quyền, validation và giao diện — không chỉ luồng hạnh phúc.

Thứ tự các phase do **phụ thuộc kỹ thuật** quyết định, không do độ khó hay mức độ
hấp dẫn.

### Hệ quả đã chấp nhận

Nguyên tắc này có giá, và cái giá đó được chấp nhận một cách có ý thức:

| Hệ quả | Chi tiết |
|---|---|
| **Phase 0 rất nặng** | Nền tảng chiếm khoảng 30–40% công sức toàn dự án. Local-first và realtime là kiến trúc, không phải tính năng đắp thêm, nên không thể làm sau |
| **Lâu mới thấy màn hình đầu tiên** | Sẽ có một quãng dài chỉ có hạ tầng chạy được mà chưa có gì để nhìn |
| **Sản phẩm chưa dùng được toàn diện trong thời gian dài** | Đổi lại, phần đã làm thì không phải viết lại |
| **Một số tính năng phụ thuộc vòng** | Issue ↔ workflow, custom field ↔ screen, JQL ↔ custom field. Xử lý bằng cách chốt contract ở ranh giới phase, không bằng cách làm tạm rồi sửa |

Để giảm rủi ro mà không phá nguyên tắc, Phase 0 được kiểm chứng bằng một entity
nháp đi hết vòng đồng bộ trước khi bắt đầu Phase 1 — chi tiết ở
[roadmap.md](../03-features/roadmap.md).

## Định vị kỹ thuật

Ba đặc điểm dưới đây là **nền móng**, không phải tính năng. Chúng được quyết định
trước và mọi thứ khác xây trên chúng:

1. **Local-first** — dữ liệu nằm trên máy người dùng, giao diện đọc và ghi vào bản
   cục bộ trước ([ADR-0007](../adr/0007-build-own-sync-engine.md),
   [ADR-0008](../adr/0008-nextjs-as-spa-shell.md))
2. **Realtime qua một sync engine duy nhất** — mọi màn hình nhận thay đổi qua cùng
   một cơ chế, không có màn hình nào tự đi lấy dữ liệu theo cách riêng
   ([ADR-0006](../adr/0006-sse-over-websocket.md))
3. **Event-driven trong nội bộ** — module giao tiếp bất đồng bộ bằng domain event
   qua outbox, để thêm hành vi mới không phải sửa module cũ
   ([ADR-0005](../adr/0005-outbox-db-job.md))

Nếu về sau một yêu cầu nào đó mâu thuẫn với ba điều này, thứ phải nhượng bộ là
yêu cầu đó, không phải ba điều này.
