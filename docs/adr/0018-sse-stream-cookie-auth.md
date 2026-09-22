# ADR-0018: Luồng SSE xác thực bằng một cookie riêng, giới hạn ở endpoint luồng đồng bộ

- **Trạng thái:** Accepted
- **Ngày:** 2026-09-23
- **Liên quan:** [ADR-0006](0006-sse-over-websocket.md), [ADR-0009](0009-magic-link-only.md), [identity-and-permission.md](../04-system-design/identity-and-permission.md), [frontend.md](../04-system-design/frontend.md#xác-thực-phía-client), [sync-engine.md](../04-system-design/sync-engine.md#xác-thực-luồng-sse)

## Bối cảnh

[ADR-0006](0006-sse-over-websocket.md) chọn SSE vì trình duyệt tự nối lại và tự
gửi `Last-Event-ID`, và ghi rằng xác thực "đi tự nhiên qua cookie hoặc header".

Nửa sau không đúng với cách client của Kaiju được thiết kế:

- `EventSource` của trình duyệt **không cho đặt header**, nên không gửi được
  `Authorization: Bearer …`
- Token truy cập chỉ nằm trong bộ nhớ của SharedWorker, không nằm trong cookie
  ([frontend.md](../04-system-design/frontend.md#xác-thực-phía-client))
- Token làm mới nằm trong cookie nhưng sống lâu và chỉ dành cho endpoint làm mới;
  dùng nó để mở luồng là mở rộng phạm vi của thứ nhạy cảm nhất trong phiên

Vậy phải chọn một cách xác thực riêng cho luồng SSE.

## Quyết định

Luồng SSE xác thực bằng **một cookie riêng**:

| Thuộc tính | Giá trị |
|---|---|
| Thuộc tính cookie | `HttpOnly`, `Secure`, `SameSite=Strict`, `Path` giới hạn ở endpoint luồng đồng bộ |
| Nội dung | Một token cùng định dạng và cùng claims cơ bản với token truy cập, **loại token là `stream`** |
| Thời hạn | Ngang token truy cập |
| Nơi phát | Endpoint làm mới token, đặt cookie này cùng lúc trả token truy cập mới |
| Nơi chấp nhận | **Chỉ** endpoint luồng đồng bộ. Mọi endpoint khác từ chối token loại `stream` |

Hành vi:

- Server chỉ kiểm tra cookie **lúc mở kết nối**. Kết nối đang mở không bị cắt khi
  cookie hết hạn
- Phiên bị thu hồi hoặc đăng xuất thì server chủ động đóng mọi kết nối của phiên
  đó, qua kênh Redis của account
- Nối lại tự động bị từ chối vì cookie hết hạn thì `EventSource` dừng hẳn. Engine
  làm mới token (nhận luôn cookie mới) rồi mở kết nối mới, truyền cursor lấy từ
  IndexedDB qua tham số `cursor`
- Server lấy vị trí từ header `Last-Event-ID` nếu có, nếu không thì từ tham số `cursor`
- Frontend và API phục vụ **cùng một origin** qua máy chủ trung gian

## Lý do

- **Giữ được lý do chọn SSE.** Trường hợp mất kết nối hay gặp nhất — mạng chập
  chờn, server khởi động lại, máy thức dậy sau khi ngủ — vẫn do trình duyệt tự
  nối lại và tự gửi vị trí, vì cookie vẫn còn hạn. Chỉ trường hợp cookie hết hạn
  mới phải mở lại thủ công, và engine vốn đã cần đường mở lại thủ công đó
  (đổi account, sau `revoked`, sau khi nâng phiên bản)
- **JavaScript không chạm tới token.** Cookie `HttpOnly` giữ nguyên tinh thần của
  việc không lưu token vào lưu trữ trình duyệt
- **Phạm vi hẹp nhất có thể.** `Path` giới hạn nơi trình duyệt gửi cookie, còn loại
  token `stream` giới hạn nơi server chấp nhận nó. Lộ cookie này chỉ cho phép
  **đọc** luồng đồng bộ trong thời gian ngắn, không cho phép ghi gì
- **Rủi ro CSRF gần như bằng không.** Endpoint chỉ là GET, không đổi trạng thái;
  `SameSite=Strict` chặn trang khác gửi kèm cookie; CORS chặn trang khác đọc luồng
- **Không phải thêm claim nào.** Token loại `stream` dùng đúng tập claims cơ bản
  đã có, chỉ khác giá trị "loại token" — không đụng tới hợp đồng token ở
  [identity-and-permission.md](../04-system-design/identity-and-permission.md#token-truy-cập-chứa-gì)

## Hệ quả

- Có **hai** dạng xác thực song song: token truy cập trong header cho mọi request
  thường, và cookie loại `stream` cho luồng đồng bộ. Tầng xác thực phải phân biệt
  loại token theo endpoint, và có test chứng minh token `stream` bị từ chối ở
  endpoint thường
- Endpoint làm mới token có thêm trách nhiệm đặt cookie `stream`; đăng xuất phải
  xoá nó
- Cursor có thể xuất hiện trên query string khi mở lại thủ công. Cursor không phải
  bí mật — nó chỉ là vị trí, và server luôn tính lại quyền — nhưng không được ghi
  nó vào nhật ký ở mức chi tiết cao một cách vô ích
- Việc đóng kết nối khi phiên bị thu hồi **bắt buộc** phải làm, vì server không
  kiểm tra lại cookie trên kết nối đang mở
- Frontend và API không được tách sang hai origin khác nhau mà không xem lại quyết
  định này

## Phương án đã loại

**Đọc SSE bằng `fetch` để gắn header `Authorization`.** Gắn được token trong bộ
nhớ, nhưng mất việc trình duyệt tự nối lại và tự gửi `Last-Event-ID` — đúng lý do
ADR-0006 chọn SSE. Mọi lần mất kết nối đều phải qua logic nối lại tự viết.

**Vé dùng một lần trên query string.** Vé nằm trong URL nên lộ trong nhật ký của
máy chủ trung gian. Tệ hơn, trình duyệt tự nối lại bằng đúng URL cũ, tức là với
một vé đã dùng, nên **mọi** lần nối lại tự động đều thất bại.

**Dùng luôn cookie của token làm mới.** Mở rộng phạm vi của token sống lâu nhất
và nhạy cảm nhất sang một kết nối mở liên tục. Không đáng.

**Đặt token truy cập vào cookie cho mọi request.** Đổi toàn bộ mô hình xác thực
chỉ để giải quyết một endpoint, và đưa rủi ro CSRF vào mọi endpoint ghi.
