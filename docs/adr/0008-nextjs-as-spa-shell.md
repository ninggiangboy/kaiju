# ADR-0008: Next.js dùng như SPA shell, không SSR dữ liệu nghiệp vụ

- **Trạng thái:** Accepted
- **Ngày:** 2026-09-17
- **Liên quan:** [ADR-0006](0006-sse-over-websocket.md), [ADR-0007](0007-build-own-sync-engine.md), [frontend.md](../04-system-design/frontend.md)

## Bối cảnh

Frontend dùng Next.js, và sản phẩm theo hướng local-first. Hai điều này kéo ngược
nhau: Next.js được thiết kế quanh server rendering và data fetching phía server,
còn local-first nghĩa là dữ liệu thật nằm trong IndexedDB trên máy người dùng và
server không biết gì về nó.

## Quyết định

Next.js được dùng như một **SPA framework có routing và build tool tốt**, không
phải như một framework full-stack.

| Vùng | Cách render |
|---|---|
| Landing, trang tài liệu, trang nhận magic link | SSR/SSG bình thường |
| Toàn bộ khu vực app | Client-only; server chỉ trả khung và skeleton |

**Cấm** dùng Server Action cho mutation nghiệp vụ, và **cấm** fetch dữ liệu
nghiệp vụ trong server component.

## Lý do

- SSR một màn hình mà dữ liệu thật đến từ store cục bộ chỉ tạo ra nhấp nháy nội
  dung sai, chậm hơn, và nhân đôi logic ở hai nơi.
- Mutation phải đi qua sync engine để có optimistic update, hàng đợi offline và
  rollback. Server Action bỏ qua toàn bộ cơ chế đó, và nếu được phép dùng thì sớm
  muộn sẽ có màn hình hoạt động khác hẳn phần còn lại của app.
- Next vẫn có giá trị thật ở phần landing, ở routing, ở build tool và ở trang
  nhận magic link — nơi server component là công cụ đúng.
- Ranh giới rõ ràng dễ tuân thủ hơn một quy tắc mơ hồ kiểu "hạn chế dùng SSR".

## Hệ quả

- Khu vực app có một layout gốc đánh dấu `"use client"`; mọi thứ bên dưới là client component.
- Không tận dụng được React Server Components cho phần nặng nhất của ứng dụng.
  Chấp nhận có chủ đích.
- SEO chỉ áp dụng cho landing và trang tài liệu, không áp dụng cho app. Đúng với
  bản chất sản phẩm.
- Cần một quy ước được ghi rõ và nhắc lại trong `CLAUDE.md`, vì thói quen mặc
  định khi làm Next là ngược lại. **Nếu thấy mình đang viết Server Action để sửa
  issue, tức là đã đi sai hướng.**
- `middleware.ts` chỉ kiểm tra sự tồn tại của cookie để điều hướng; việc xác thực
  token thuộc về backend.

## Phương án đã loại

**Dùng Next đúng bản chất full-stack** (Server Action, RSC data fetching). Sẽ phải
bỏ local-first. Không có đường ở giữa: hoặc dữ liệu nghiệp vụ nằm ở client và
client là nơi render, hoặc nằm ở server và server là nơi render.

**Vite + React Router thay cho Next.** Khớp hơn với mô hình SPA thuần, nhưng phải
tự dựng phần landing và mất hệ sinh thái routing/build sẵn có. Đã chọn Next ở cấp
stack, nên giữ Next và giới hạn phạm vi sử dụng của nó.

**Tanstack Start / Remix.** Cùng một mâu thuẫn với local-first, không giải quyết
được gì thêm.
