# UC-SYN — Sync engine

Đồng bộ dữ liệu là hạ tầng, nhưng hành vi client nhìn thấy do nó tạo ra —
hiển thị ngay khi mở app, hoàn tác khi server từ chối, làm việc được khi mất
mạng, xoá sạch dữ liệu khi bị thu hồi quyền — là luồng người dùng thật, và đều
là `MUST` trong `functional.md`. Các use case dưới đây đặc tả đúng những hành
vi đó; cơ chế nội bộ (giao thức SSE, cấp số thứ tự, phát tán qua Redis) đã có
trong [realtime-and-sync.md](../../04-system-design/realtime-and-sync.md) và
không lặp lại ở đây.

**Phase:** 0 · **Feature:** KJ-SYN-01 → KJ-SYN-21
**Liên quan:** [realtime-and-sync.md](../../04-system-design/realtime-and-sync.md) · [identity-and-permission.md](../../04-system-design/identity-and-permission.md) · [frontend.md](../../04-system-design/frontend.md) · [ADR-0006](../../adr/0006-sse-over-websocket.md) · [ADR-0007](../../adr/0007-build-own-sync-engine.md)

---

## UC-SYN-01 — Mở ứng dụng, hiển thị ngay từ bản sao cục bộ

**Requirement:** FR-SYN-01
**Actor:** người dùng đã đăng nhập, đã từng mở ứng dụng ít nhất một lần
**Tiền điều kiện:** bản sao cục bộ của ít nhất một scope đã tồn tại từ phiên trước

### Luồng chính

1. Mở ứng dụng
2. Giao diện đọc thẳng từ bản sao cục bộ (`ws:{workspaceId}`, `proj:{projectId}`
   đang mở/yêu thích) và hiển thị ngay, **không chờ mạng**
3. Song song, client mở kết nối SSE kèm cursor đã lưu để bắt kịp thay đổi mới
   (xem UC-SYN-06)

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-SYN-01/NT-01 | Không có mạng lúc mở ứng dụng | Giao diện vẫn hiển thị đầy đủ từ bản sao cục bộ; kết nối SSE thử lại theo khoảng chờ tăng dần |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-SYN-01/NL-01 | Chưa từng mở ứng dụng trên máy này (không có bản sao cục bộ) | Không có gì để hiển thị ngay; đi thẳng vào Bootstrap (UC-SYN-02), giao diện ở trạng thái tải |

### Hậu điều kiện

Giao diện hiển thị dữ liệu tại trạng thái đã lưu lần trước; kết nối SSE đang
mở hoặc đang thử mở.

### Ảnh hưởng tới đồng bộ

Không phát delta — đây là bước đọc cục bộ thuần tuý, xảy ra trước khi có phản
hồi nào từ server.

---

## UC-SYN-02 — Bootstrap lần đầu và khi vắng mặt quá lâu

**Requirement:** FR-SYN-10
**Actor:** hệ thống (chạy khi client thiếu dữ liệu của một scope)
**Tiền điều kiện:** client đăng ký một scope mà nó chưa có bản sao cục bộ, hoặc
cursor đã lưu cũ hơn thời hạn giữ nhật ký thay đổi của scope đó

### Luồng chính

1. Client mở kết nối kèm cursor (hoặc không có cursor nếu là lần đầu)
2. Server phát hiện scope cần bootstrap — thiếu dữ liệu hoặc cursor quá cũ —
   và trả về sự kiện `reset` cho scope đó
3. Client gọi endpoint bootstrap; server trả **ảnh chụp đầy đủ** của scope kèm
   số thứ tự tại đúng thời điểm chụp
4. Client thay thế toàn bộ dữ liệu cục bộ của scope bằng ảnh chụp, rồi tiếp
   tục nhận delta từ số thứ tự đó

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-SYN-02/NL-01 | Ảnh chụp và số thứ tự đi kèm không cùng một thời điểm (lỗi nhất quán phía server) | Không áp ảnh chụp; client giữ nguyên trạng thái cũ và thử bootstrap lại — đây là lỗi vận hành, không phải hành vi client tự xử lý bằng nghiệp vụ |

### Hậu điều kiện

Bản sao cục bộ của scope khớp chính xác với server tại số thứ tự vừa nhận;
không thay đổi nào bị lặp hoặc bị bỏ sót do lệch thời điểm chụp.

### Ảnh hưởng tới đồng bộ

Đây chính là hành vi cần đặc tả: client phát yêu cầu bootstrap trên scope bị
`reset`, nhận ảnh chụp, và tiếp tục ở chế độ Live (xem vòng đời client trong
realtime-and-sync.md). Không có scope nào bị bỏ dở giữa Bootstrap và Live.

---

## UC-SYN-03 — Áp lạc quan; hoàn tác kèm lý do khi server từ chối

**Requirement:** FR-SYN-02, FR-SYN-04
**Actor:** thành viên thực hiện một thao tác ghi bất kỳ (tạo, sửa, xoá)
**Tiền điều kiện:** đã đăng nhập, đang xem dữ liệu thuộc một scope đã đồng bộ

### Luồng chính

1. Người dùng thực hiện một thao tác ghi (ví dụ sửa một trường issue)
2. Thay đổi **áp ngay vào bản sao cục bộ và hiển thị lập tức**, trước khi
   server phản hồi
3. Client gửi mutation qua HTTP POST kèm khoá chống trùng (xem UC-SYN-04)
4. Server chấp nhận → client gỡ mutation khỏi hàng đợi, trạng thái hiển thị
   giữ nguyên (đã là trạng thái đúng)

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-SYN-03/NT-01 | Delta của người khác tới trong lúc còn mutation cục bộ chưa được server xác nhận | Rebase: áp delta vào tầng "đã xác nhận", áp lại các mutation chưa xác nhận lên trên; thay đổi cục bộ chưa mất — xem realtime-and-sync.md#hoà-giải-rebase |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-SYN-03/NL-01 | Server từ chối vì không đủ quyền | Hoàn tác thay đổi trên giao diện, báo rõ lý do |
| UC-SYN-03/NL-02 | Server từ chối vì vi phạm quy tắc nghiệp vụ (bước chuyển không hợp lệ, thiếu trường bắt buộc) | Hoàn tác, hiển thị lỗi cụ thể lấy từ server, không phải thông báo chung chung |
| UC-SYN-03/NL-03 | Server từ chối vì xung đột phiên bản | Áp trạng thái server, báo người dùng biết thay đổi của họ đã bị thay thế |
| UC-SYN-03/NL-04 | Server từ chối vì thực thể không còn tồn tại | Hoàn tác, xoá thực thể khỏi bản sao cục bộ |

### Hậu điều kiện

Trạng thái hiển thị khớp với trạng thái đã xác nhận cộng các mutation đang
chờ; không mutation nào bị bỏ qua âm thầm — bị từ chối luôn có thông báo.

### Ảnh hưởng tới đồng bộ

Mutation được chấp nhận sinh một bản ghi nhật ký thay đổi và một delta chỉ
chứa các trường đã đổi, phát trên scope tương ứng cho mọi client khác đang mở
scope đó (xem UC-SYN-05). Mutation bị từ chối không phát delta nào.

---

## UC-SYN-04 — Thao tác khi mất mạng, hàng đợi sống sót qua tải lại trang

**Requirement:** FR-SYN-03
**Actor:** thành viên đang mất kết nối mạng
**Tiền điều kiện:** không có

### Luồng chính

1. Người dùng thực hiện một thao tác ghi trong lúc không có mạng
2. Thay đổi áp ngay vào bản sao cục bộ như bình thường (UC-SYN-03)
3. Mutation xếp vào hàng đợi bền kèm khoá chống trùng, **không gửi được** vì
   không có kết nối
4. Người dùng đóng trình duyệt hoặc tải lại trang
5. Mở lại ứng dụng (có thể ngày hôm sau) — hàng đợi vẫn còn nguyên, thay đổi
   vẫn hiển thị trên giao diện
6. Có mạng trở lại → hàng đợi tự động gửi các mutation đang chờ, **tuần tự
   trong phạm vi một thực thể** để không tới server ngược thứ tự

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-SYN-04/NT-01 | Hai thay đổi liên tiếp lên cùng một thực thể trong lúc offline | Hàng đợi giữ đúng thứ tự tạo ra, gửi tuần tự khi có mạng lại — không thay đổi nào vượt lên trước |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-SYN-04/NL-01 | Một mutation trong hàng đợi bị server từ chối sau khi có mạng lại | Hoàn tác đúng mutation đó theo UC-SYN-03; các mutation khác trong hàng đợi không bị ảnh hưởng |

### Hậu điều kiện

Hàng đợi trống khi mọi mutation đã được server xác nhận hoặc từ chối; không
mutation nào bị mất do tải lại trang hay đóng trình duyệt.

### Ảnh hưởng tới đồng bộ

Không phát delta nào cho tới khi mutation thực sự được gửi và server xác
nhận — cho tới lúc đó thay đổi chỉ tồn tại cục bộ trên máy người thực hiện.

---

## UC-SYN-05 — Nhận thay đổi của người khác không cần tải lại

**Requirement:** FR-SYN-05
**Actor:** thành viên đang mở một scope mà người khác vừa thay đổi dữ liệu
**Tiền điều kiện:** đang có kết nối SSE mở (trạng thái Live)

### Luồng chính

1. Một thành viên khác thực hiện một thay đổi được chấp nhận
2. Server phát một delta trên scope tương ứng
3. Mọi client khác đang ở trạng thái Live cho scope đó nhận delta qua SSE
4. Client áp delta vào bản sao cục bộ; giao diện cập nhật ngay, không cần tải
   lại trang

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-SYN-05/NL-01 | Delta tới cho một thực thể không còn tồn tại cục bộ (đã bị xoá ở một luồng khác) | Bỏ qua delta đó một cách an toàn, không báo lỗi cho người dùng |

### Hậu điều kiện

Bản sao cục bộ của mọi client đang mở scope đó phản ánh đúng thay đổi mới,
trong vòng thời gian gần-thực (giới hạn bởi nhịp tim SSE, không phải polling).

### Ảnh hưởng tới đồng bộ

Đây chính là use case của delta trên scope: mỗi client đang Live cho scope đó
nhận đúng một bản delta, không nhiều hơn, không cần request riêng để "làm
mới".

---

## UC-SYN-06 — Nối lại sau khi mất kết nối, bắt kịp theo cursor, không sót

**Requirement:** FR-SYN-06
**Actor:** hệ thống (trình duyệt tự nối lại kết nối SSE)
**Tiền điều kiện:** client đã có cursor từ phiên kết nối trước

### Luồng chính

1. Kết nối SSE bị ngắt (mất mạng, server khởi động lại, máy tính ngủ)
2. Trình duyệt tự động nối lại, gửi kèm `Last-Event-ID` là cursor cuối cùng
   nhận được — toàn bộ logic này do trình duyệt xử lý, không phải code tự viết
3. Server giải mã cursor, phát lại đúng phần delta còn thiếu của từng scope
   trong cursor
4. Client áp các delta còn thiếu; trạng thái Live được khôi phục

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-SYN-06/NT-01 | Cursor vẫn còn hợp lệ (trong thời hạn giữ nhật ký thay đổi) | Server chỉ phát phần delta còn thiếu, không cần bootstrap lại |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-SYN-06/NL-01 | Cursor cũ hơn thời hạn giữ nhật ký thay đổi của một scope | Server trả `reset` cho scope đó; client bootstrap lại theo UC-SYN-02, các scope khác trong cùng cursor vẫn bắt kịp bình thường |

### Hậu điều kiện

Cursor của client khớp với vị trí mới nhất trên mọi scope đang đăng ký; không
delta nào giữa lúc mất kết nối và lúc nối lại bị bỏ sót.

### Ảnh hưởng tới đồng bộ

Không có delta nào bị mất do việc nối lại — đây là khẳng định nền tảng thứ ba
của cả sync engine (xem realtime-and-sync.md#mô-hình).

---

## UC-SYN-07 — Nhiều tab chia sẻ một kết nối và một bộ ghi cục bộ

**Requirement:** FR-SYN-07
**Actor:** người dùng mở nhiều tab của cùng ứng dụng
**Tiền điều kiện:** không có

### Luồng chính

1. Người dùng mở ứng dụng ở tab thứ hai trong khi tab đầu đang chạy
2. Cả hai tab chia sẻ **đúng một** kết nối SSE và **đúng một** bộ ghi cục bộ
   (SharedWorker, hoặc bầu tab chủ nếu trình duyệt không hỗ trợ)
3. Mutation từ bất kỳ tab nào đi qua cùng hàng đợi; delta nhận được áp vào
   cùng bản sao cục bộ, cả hai tab đọc ra dữ liệu giống nhau

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-SYN-07/NT-01 | Tab đang giữ vai trò chủ (SharedWorker không khả dụng) bị đóng | Một tab còn lại được bầu làm chủ mới, kết nối SSE và hàng đợi chuyển sang tab đó, không mất mutation đang chờ |

### Hậu điều kiện

Tất cả các tab đang mở hiển thị cùng một trạng thái dữ liệu; chỉ một kết nối
SSE và một hàng đợi mutation tồn tại cho cả trình duyệt.

### Ảnh hưởng tới đồng bộ

Không có delta "riêng cho từng tab" — bản sao cục bộ là tài nguyên dùng chung
trong trình duyệt, không phải theo tab.

---

## UC-SYN-08 — Hiển thị trạng thái kết nối và số thay đổi đang chờ

**Requirement:** FR-SYN-08
**Actor:** thành viên bất kỳ đang dùng ứng dụng
**Tiền điều kiện:** không có

### Luồng chính

1. Giao diện hiển thị trạng thái kết nối hiện tại: đang trực tuyến, đang thử
   nối lại, hoặc ngoại tuyến
2. Nếu hàng đợi mutation không rỗng, giao diện hiển thị số lượng thay đổi
   đang chờ gửi

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-SYN-08/NT-01 | Mất kết nối trong khi hàng đợi có mutation đang chờ | Hiển thị đồng thời trạng thái "ngoại tuyến" và số mutation đang chờ, không chỉ một trong hai |

### Hậu điều kiện

Trạng thái hiển thị luôn khớp với trạng thái kết nối thật và độ dài hàng đợi
thật tại thời điểm hiện tại.

### Ảnh hưởng tới đồng bộ

Không áp dụng — đây là hiển thị trạng thái nội bộ của client, không phát hay
nhận delta nào riêng cho việc này.

---

## UC-SYN-09 — Thu hồi quyền: xoá dữ liệu scope đó khỏi máy

**Requirement:** FR-SYN-09
**Actor:** hệ thống (chạy khi một hành động khác thu hẹp hoặc thu hồi quyền
của người dùng)
**Tiền điều kiện:** người dùng đang có dữ liệu cục bộ của scope bị ảnh hưởng

Đây là nơi **invariant 20** của `CLAUDE.md` được đặc tả lần đầu: *mọi thay đổi
thu hẹp quyền phải phát một sự kiện thu hồi, và client phải xoá dữ liệu cục bộ
của scope đó.* Các use case khác (đổi vai trò, đổi mức hiển thị project, xoá
thành viên, đổi workflow scheme, thu hẹp chia sẻ dashboard, …) **trỏ về đây**
thay vì lặp lại luồng, và chỉ nêu scope nào bị ảnh hưởng.

### Luồng chính

1. Một hành động khác (đổi vai trò, xoá khỏi project, rời/xoá workspace, thu
   hẹp mức hiển thị, …) làm quyền của một người dùng **thu hẹp** so với trước
2. Server ghi thay đổi, xoá cache quyền của người đó, và ghi sự kiện thu hồi
   cho đúng scope bị ảnh hưởng — trong cùng giao dịch với thay đổi quyền
3. Sự kiện thu hồi phát tán qua worker → instance `realtime` đang giữ kết nối
   của người đó
4. Client nhận sự kiện `revoked` cho scope đó qua SSE
5. Client **xoá toàn bộ dữ liệu cục bộ của scope**, **huỷ mọi mutation đang
   chờ thuộc scope đó**, và điều hướng ra khỏi màn hình đang mở nếu màn hình
   đó thuộc scope bị thu hồi

### Luồng thay thế

| ID | Nhánh | Xử lý |
|---|---|---|
| UC-SYN-09/NT-01 | Quyền bị thu hẹp nhưng không mất hoàn toàn (ví dụ đổi vai trò từ quản trị sang thành viên thường, vẫn còn xem được project) | Xử lý y hệt thu hồi hoàn toàn với đúng phần scope không còn được xem; phần vẫn được xem giữ nguyên, không xoá quá tay |

### Ngoại lệ

| ID | Trường hợp | Phản ứng |
|---|---|---|
| UC-SYN-09/NL-01 | Người dùng đang mất kết nối lúc quyền bị thu hồi | Sự kiện `revoked` không tới được lúc đó; khi nối lại, server tính lại danh sách scope được phép từ mặt nạ quyền hiện tại — scope không còn được phép sẽ không được phát lại, và client phải tự đối chiếu để dọn dữ liệu cũ khi cursor cho scope đó bị từ chối |

### Hậu điều kiện

Máy của người bị thu hồi không còn dữ liệu nào của scope đó; không mutation
nào thuộc scope đó còn treo trong hàng đợi; nếu màn hình đang mở thuộc scope
đó thì người dùng đã được điều hướng ra ngoài.

### Ảnh hưởng tới đồng bộ

Phát sự kiện `revoked` trên scope bị ảnh hưởng — khác với `delta`, sự kiện này
ra lệnh **xoá** thay vì áp thay đổi. Đây là sự kiện duy nhất trong giao thức
SSE có tác dụng xoá dữ liệu cục bộ thay vì cập nhật nó.

---

## Quy tắc nghiệp vụ

| # | Quy tắc |
|---|---|
| QT-SYN-01 | Giao diện không bao giờ chờ mạng để hiển thị nội dung đã có cục bộ |
| QT-SYN-02 | Bootstrap luôn thay thế toàn bộ dữ liệu cục bộ của scope, không hợp nhất từng phần với dữ liệu cũ |
| QT-SYN-03 | Ảnh chụp và số thứ tự kèm theo phải thuộc đúng cùng một thời điểm |
| QT-SYN-04 | Mọi thao tác ghi áp ngay vào giao diện trước khi có phản hồi từ server |
| QT-SYN-05 | Một mutation bị từ chối không bao giờ biến mất khỏi màn hình mà không có giải thích |
| QT-SYN-06 | Hàng đợi mutation phải sống sót qua việc tải lại trang và đóng trình duyệt |
| QT-SYN-07 | Hàng đợi xử lý tuần tự trong phạm vi một thực thể |
| QT-SYN-08 | Nhiều tab dùng chung một kết nối và một bộ ghi cục bộ, không mở kết nối riêng cho từng tab |
| QT-SYN-09 | Mọi thay đổi thu hẹp quyền phát đúng một sự kiện thu hồi cho đúng scope bị ảnh hưởng, trong cùng giao dịch với thay đổi quyền |
| QT-SYN-10 | Client xoá sạch dữ liệu cục bộ và huỷ mutation đang chờ của scope bị thu hồi, không giữ lại một phần |
| QT-SYN-11 | Quyền bị thu hẹp (không chỉ bị xoá hoàn toàn) xử lý theo đúng cơ chế thu hồi cho đúng phần scope không còn được xem |

## Yêu cầu phi chức năng liên quan

`NFR-20` không rò rỉ giữa các workspace · `NFR-22` thu hồi quyền có hiệu lực ngay
