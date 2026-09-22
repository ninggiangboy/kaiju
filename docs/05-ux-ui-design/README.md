# 05 — UX/UI Design

**Trạng thái: 🟨 Đang làm** — đã có bản thiết kế đầu tiên, xem [canvas](#bản-thiết-kế-canvas)

Phần này chứa thiết kế trải nghiệm và giao diện.

> **Changed (2026-09-23):** trước đây trạng thái là "⬜ Chưa bắt đầu", với lý do
> các quyết định về kiến trúc và luồng nghiệp vụ được ưu tiên chốt trước. Bản
> thiết kế đầu tiên đã được làm trên một canvas Claude Design và export vào
> [`canvas/`](canvas/canvas.json).

**Liên quan:** [Brief](../01-brief/) · [Use cases](../03-features/usecases/) · [Frontend design](../04-system-design/frontend.md)

---

## Bản thiết kế (canvas)

Nguồn gốc là canvas **"Kaiju — UI Design"** trên Claude Design
(`https://claude.ai/artifact/JcWbyXU4J3QD5sdMC254eQ`). Thư mục [`canvas/`](canvas/canvas.json)
là bản export các file nội dung của canvas đó:

| File | Nội dung |
|---|---|
| [`canvas/canvas.json`](canvas/canvas.json) | Chỉ mục: vị trí, kích thước, tiêu đề từng artboard, và các nhóm (ghi chú `title1`) gắn với use case / phase |
| [`canvas/ds/kaiju/tokens.json`](canvas/ds/kaiju/tokens.json) | Design token: màu, typography (Manrope / Space Grotesk / JetBrains Mono), spacing, radius, shadow |
| `canvas/*.dc.html` | Mỗi file là một màn hình hoặc một thành phần dùng chung (`Sidebar`, `ProjectSidebar`, `TopBar`, `AuthPanel`, được nhúng bằng `<dc-import>`) |

Các nhóm màn hình, theo `notes` trong `canvas.json`:

- Design system, component, pattern local-first và khung dùng chung — `Foundations`, `Components`, `Patterns`
- Đăng nhập & onboarding — UC-AUTH, UC-INV
- Workspace & member — UC-WSP, UC-INV
- Project — UC-PRJ
- Workflow (Phase 5), custom field & screen (Phase 6), search (Phase 7), board
  (Phase 8), sprint (Phase 9), roadmap (Phase 10), time tracking (Phase 11),
  version & release (Phase 12), dashboard (Phase 13), automation (Phase 14),
  bulk & import/export (Phase 15), integration & public API (Phase 16)

Về cách dùng các file này:

- File `.dc.html` là định dạng của Claude Design, không phải HTML chạy độc lập:
  dòng `<script src="./support.js">` trỏ tới runtime của canvas, runtime đó
  **không** nằm trong repo. Muốn xem hoặc sửa trực quan thì mở canvas gốc; bản
  trong repo dùng để đọc, review diff và làm nguồn tham chiếu khi implement.
- Canvas là nơi sửa chính. Sau khi sửa trên canvas, export lại vào `canvas/`
  để bản trong repo không bị lệch.
- Dữ liệu trong màn hình (tên người, số liệu, token mẫu) là dữ liệu minh hoạ.

> **Changed (2026-09-23):** lúc export, `tokens.json` chỉ có theme sáng. Theme tối
> (`dark`) đã được thêm cho mọi token màu, cùng tên token, với mọi cặp chữ/nền đạt
> tương phản AA (≥ 4.5:1). Theme tối mới chỉ có ở bản trong repo: canvas gốc và
> các màn hình `.dc.html` vẫn ghi màu sáng trực tiếp bằng hex, chưa đọc từ token.

> **Chưa chốt:** token vẫn viết dưới dạng hex, trong khi ràng buộc bên dưới yêu cầu
> token theme của shadcn/ui. Cần quyết định cách ánh xạ các token này sang biến CSS
> của shadcn (`--background`, `--primary`, …) cho cả hai theme.

## Sẽ chứa gì

- **Design system**: bảng màu, typography, spacing, component cơ bản, dark mode
- **Wireframe** theo màn hình: đăng nhập, onboarding, danh sách workspace, danh
  sách project, board, backlog, issue detail, settings
- **Luồng màn hình** (user flow) bám theo các use case đã viết
- **Trạng thái giao diện đặc thù của local-first**: hiển thị mutation đang chờ
  gửi, trạng thái offline, xung đột bị server từ chối, dữ liệu đang bootstrap
- **Empty state, loading state, error state** cho từng màn hình
- Quy ước keyboard shortcut
- Responsive: desktop là chính, tablet/mobile ở mức đọc và thao tác cơ bản

## Phụ thuộc vào

- [Use cases](../03-features/usecases/) — luồng nghiệp vụ phải chốt trước khi vẽ màn hình
- [04-system-design/frontend.md](../04-system-design/frontend.md) — ràng buộc kỹ
  thuật của local-first ảnh hưởng trực tiếp tới thiết kế: không có spinner chờ
  mạng ở luồng chính, mọi thao tác phản hồi tức thì, và cần chỗ hiển thị trạng
  thái đồng bộ

## Khi nào bắt đầu

Trước khi implement giao diện của **Phase 1** (identity và workspace). Không cần
chờ toàn bộ roadmap; thiết kế theo từng phase, đúng nguyên tắc làm đầy đủ từng
tính năng một.

## Ràng buộc đã chốt mà thiết kế phải tuân theo

| Ràng buộc | Vì sao |
|---|---|
| Thao tác của người dùng phải phản hồi **tức thì**, không có trạng thái chờ mạng ở luồng chính | Mọi mutation đều optimistic, xem [ADR-0007](../adr/0007-build-own-sync-engine.md) |
| Phải có chỗ hiển thị trạng thái đồng bộ và số mutation đang chờ | Người dùng cần biết việc của mình đã tới server hay chưa |
| App phải dùng được khi offline, kể cả tạo và sửa | Local-first, xem [ADR-0008](../adr/0008-nextjs-as-spa-shell.md) |
| Chỉ landing và trang nhận magic link được render phía server | Xem [ADR-0008](../adr/0008-nextjs-as-spa-shell.md) |
| Đăng nhập chỉ có một ô email, không có ô mật khẩu ở bất kỳ đâu | Xem [ADR-0009](../adr/0009-magic-link-only.md) |
| Design system viết dưới dạng **token theme của shadcn/ui** (biến CSS cho màu, bo góc, font; Tailwind cho spacing), có chế độ tối; component xuất phát từ bộ của shadcn | Thư viện component đã chốt trước phần này, xem [ADR-0017](../adr/0017-shadcn-and-tanstack-frontend-stack.md) |
