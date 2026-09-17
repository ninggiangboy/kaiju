# 05 — UX/UI Design

**Trạng thái: ⬜ Chưa bắt đầu**

Phần này sẽ chứa thiết kế trải nghiệm và giao diện. Hiện chưa bắt đầu vì các
quyết định về kiến trúc và luồng nghiệp vụ được ưu tiên chốt trước.

**Liên quan:** [Brief](../01-brief/) · [Use cases](../03-features/usecases/) · [Frontend design](../04-system-design/frontend.md)

---

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
