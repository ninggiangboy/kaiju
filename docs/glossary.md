# Glossary — từ điển thuật ngữ

Tài liệu này chốt cách gọi tên trong toàn dự án. Khi một thuật ngữ ở đây xuất
hiện trong tài liệu khác, nó mang đúng nghĩa được định nghĩa tại đây, không mang
nghĩa thông thường hay nghĩa của Jira.

**Liên quan:** [README](README.md) · [System Design](04-system-design/) · [ADR](adr/)

---

## Danh tính và tổ chức

### Account
Danh tính **toàn cục** của một con người trong hệ thống, định danh bằng email.
Một account đăng nhập một lần và truy cập được mọi workspace mà họ là thành viên.
Account chỉ giữ thông tin đăng nhập, không giữ thông tin hiển thị dùng trong công việc.

> ⚠️ **Dễ nhầm:** account **không** phải là "người dùng trong một dự án". Không
> có bảng nghiệp vụ nào tham chiếu tới account. Xem [ADR-0011](adr/0011-account-vs-member.md).

### Member
Hồ sơ của một con người **bên trong một workspace cụ thể**: tên hiển thị, avatar,
timezone, vai trò. Một account tham gia ba workspace thì có ba member khác nhau,
với tên hiển thị có thể khác nhau.

Mọi tham chiếu tới con người trong dữ liệu nghiệp vụ (reporter, assignee,
watcher, người mention, người log work) đều trỏ tới **member**, không trỏ tới account.

Một member có thể tồn tại **trước khi** người đó có account — đó là trạng thái
`INVITED`, cho phép gán việc cho người chưa đăng ký.

### Workspace
Đơn vị **tenancy** của hệ thống. Một workspace chứa nhiều project và nhiều
member. Mọi dữ liệu nghiệp vụ thuộc về đúng một workspace và không bao giờ đi
xuyên workspace.

Không có cấp tổ chức nào phía trên workspace.

### Project
Một dự án bên trong workspace, có `key` dùng để sinh mã issue (ví dụ `KJU-123`).
`key` là duy nhất **trong workspace**, không duy nhất toàn hệ thống.

> ⚠️ **Dễ nhầm:** workspace là ranh giới **cách ly dữ liệu**; project là ranh giới
> **tổ chức công việc**. Phân quyền tồn tại ở cả hai cấp.

### Role
Một tập quyền đặt tên sẵn, biểu diễn bằng một [mask](#mask--bitmask). Role tồn
tại ở cấp workspace (`OWNER`, `ADMIN`, `MEMBER`, `GUEST`) và ở cấp project.

---

## Phân quyền

### Mask / bitmask
Một số nguyên trong đó mỗi bit đại diện cho một quyền. Kiểm tra quyền là phép
`AND` bit, cực rẻ và đẩy được xuống SQL. Quyền hiệu lực của một member là phép
`OR` của mask cấp workspace và mask cấp project. Xem [ADR-0010](adr/0010-bitmask-permission.md).

### Permission condition
Tầng kiểm tra bổ sung chạy **sau** khi mask đã cho phép, dùng cho những quyền phụ
thuộc vào dữ liệu — ví dụ `REPORTER_ONLY` (chỉ sửa issue mình tạo). Bitmask không
biểu diễn được loại quyền này, nên cần một cơ chế riêng.

---

## Kiến trúc và module

### Module
Một **bounded context** trong backend: identity, workspace, project, issue,
workflow, field, board, sprint, search, activity, notification, automation. Mỗi
module sở hữu bảng dữ liệu của riêng mình và chỉ lộ ra ngoài qua package `public`.

### Aggregate
Một cụm entity được đọc và ghi như một khối, có một **aggregate root** làm điểm
vào duy nhất và chịu trách nhiệm giữ invariant bên trong khối đó. Trong Kaiju,
aggregate được giữ **nhỏ**: `Issue` là một aggregate, còn `Comment`, `Attachment`,
`Worklog`, `Sprint` là các aggregate riêng, tham chiếu bằng id.

### App role
Vai trò triển khai của cùng một artifact backend, chọn bằng Spring profile:
`api`, `realtime`, `worker`, `scheduler`. Cùng một codebase, cùng một image, khác
tập bean được kích hoạt và khác cách scale.

---

## Event và outbox

### Domain event
Một sự kiện đã xảy ra trong domain, đặt tên ở **thì quá khứ**
(`issue.transitioned`, `member.removed`). Là phương tiện giao tiếp bất đồng bộ
duy nhất giữa các module.

### Outbox
Bảng trong Postgres nhận domain event **trong cùng transaction** với thay đổi
nghiệp vụ, đảm bảo không bao giờ xảy ra tình trạng dữ liệu đã đổi mà event bị
mất. Một worker nền đọc bảng này và chuyển event tới các consumer.
Xem [ADR-0005](adr/0005-outbox-db-job.md).

> ⚠️ **Dễ nhầm:** outbox **không** phải hàng đợi công việc chung. Nó chỉ chuyển
> tiếp domain event; các job định kỳ do `scheduler` đảm nhiệm.

### Relay worker
Tiến trình đọc bảng outbox bằng `FOR UPDATE SKIP LOCKED` và dispatch event tới
consumer, kèm retry, backoff và dead letter.

### Idempotency
Tính chất "chạy lại không đổi kết quả". Vì outbox đảm bảo **at-least-once**, mỗi
consumer phải tự chống trùng, thường bằng một bảng ghi nhận cặp
`(consumer, event_id)` đã xử lý.

---

## Realtime và đồng bộ

### Sync scope (scope)
Đơn vị đăng ký nhận thay đổi của client. Có hai loại: `ws:{workspaceId}` (danh
sách project, member, role, setting) và `proj:{projectId}` (issue, comment,
sprint, board…). Scope cũng là ranh giới phân quyền của luồng đồng bộ.

### Change log
Dòng ghi nhận **mọi thay đổi** của một scope theo thứ tự, là nguồn để client bắt
kịp trạng thái sau khi mất kết nối.

### Seq
Số thứ tự đơn điệu tăng **trong phạm vi một scope**, gắn với mỗi bản ghi change
log. Client dùng seq để biết mình đang ở đâu.

> ⚠️ **Dễ nhầm:** seq là **theo scope**, không phải toàn cục. Hai scope khác nhau
> có seq độc lập và không so sánh được với nhau.

### Cursor
Vị trí đồng bộ của client trên **nhiều scope cùng lúc**, mã hoá thành một chuỗi
mờ (base64 của map `{scope: seq}`). Cursor được gửi qua trường `id` của SSE event
và quay lại server qua header `Last-Event-ID` khi client kết nối lại.

### Delta
Một bản ghi thay đổi gửi xuống client: scope, seq, entity, thao tác
(`upsert`/`delete`) và **patch** chỉ chứa các field đã đổi — không gửi cả entity.

### Bootstrap
Quá trình tải trạng thái đầy đủ của một scope khi client chưa có dữ liệu, hoặc
khi cursor quá cũ để catch-up bằng change log.

### Catch-up
Quá trình client nhận các delta còn thiếu kể từ cursor của mình, xảy ra ngay khi
kết nối hoặc kết nối lại, trước khi chuyển sang nhận live.

### Mutation
Một thay đổi do người dùng khởi xướng. Client áp ngay vào store cục bộ
(**optimistic**), đẩy vào hàng đợi bền, rồi gửi lên server bằng HTTP POST kèm
idempotency key. Server là nơi quyết định cuối cùng; client rollback nếu bị từ chối.

### Rebase
Việc áp lại các mutation chưa được server xác nhận lên trên trạng thái mới nhận
từ server, để giao diện luôn phản ánh cả sự thật của server lẫn ý định chưa gửi
xong của người dùng.

### Sync engine
Toàn bộ cơ chế đồng bộ hai đầu: phía server (change log, cấp seq, SSE stream,
phân quyền scope) và phía client (store trên IndexedDB, hàng đợi mutation,
catch-up, rebase). Xem [ADR-0007](adr/0007-build-own-sync-engine.md).

---

## Frontend

### Local-first
Nguyên tắc: dữ liệu người dùng cần được giữ **ngay trên máy họ**, giao diện đọc
và ghi vào bản cục bộ trước, đồng bộ với server diễn ra phía sau. Hệ quả là app
mở tức thì và vẫn dùng được khi mất mạng.

> ⚠️ **Dễ nhầm:** local-first **không** phải là cache. Cache có thể bỏ đi bất cứ
> lúc nào; bản cục bộ ở đây là nơi giao diện thực sự đọc và ghi.

### SPA shell
Cách Kaiju dùng Next.js: server chỉ trả khung trang cho khu vực app, còn dữ liệu
render từ store cục bộ. Chỉ landing và trang nhận magic link mới render phía server.
Xem [ADR-0008](adr/0008-nextjs-as-spa-shell.md).

---

## Xác thực

### Magic link
Phương thức xác thực **duy nhất** của Kaiju: người dùng nhập email, nhận một liên
kết dùng một lần kèm mã 6 số, và đăng nhập mà không cần mật khẩu. Cùng một luồng
phục vụ cả đăng ký lẫn đăng nhập. Xem [ADR-0009](adr/0009-magic-link-only.md).

### Invitation token
Token gửi kèm lời mời vào workspace. Về bản chất **chính là một magic link**:
người bấm được liên kết trong hộp thư đã chứng minh sở hữu email đó, nên không
cần thêm một bước xác thực nữa.
