# ADR-0007: Tự xây sync engine thay vì dùng thư viện sync có sẵn

- **Trạng thái:** Accepted
- **Ngày:** 2026-09-17
- **Liên quan:** [ADR-0006](0006-sse-over-websocket.md), [ADR-0008](0008-nextjs-as-spa-shell.md), [ADR-0010](0010-bitmask-permission.md), [realtime-and-sync.md](../04-system-design/realtime-and-sync.md)

## Bối cảnh

Kaiju là local-first: client giữ dữ liệu trên máy, đọc và ghi cục bộ trước, đồng
bộ diễn ra phía sau. Cần một cơ chế đồng bộ hai chiều đầy đủ: bootstrap,
catch-up, live stream, optimistic mutation, rollback, rebase, và xử lý thu hồi quyền.

Có sẵn một số giải pháp: ElectricSQL, Zero, Triplit, PowerSync, Jazz.

## Quyết định

**Tự xây sync engine**, cả phía server (change log, cấp seq, SSE stream, phân
quyền theo scope) lẫn phía client (store trên IndexedDB, hàng đợi mutation,
catch-up, rebase).

## Lý do

- **Lý do quyết định là bảo mật.** Backend là Spring Boot với phân quyền bitmask
  hai cấp cộng permission condition theo dữ liệu. Các thư viện kể trên đồng bộ
  **thẳng từ Postgres xuống client**, đi vòng qua Spring. Nghĩa là toàn bộ logic
  phân quyền phải được **viết lại lần thứ hai** bằng cơ chế row filter của chúng,
  và giữ đồng bộ hai bản mãi mãi. Lệch một chỗ là rò rỉ dữ liệu.
- Sync engine là lõi trải nghiệm của sản phẩm, không phải chi tiết hạ tầng có thể
  thuê ngoài. Hiểu nó đến tận đáy là điều kiện để sửa được khi có sự cố.
- Phần lớn các giải pháp còn mới, ràng buộc kiến trúc mạnh, và đều giả định
  backend nằm trong hệ sinh thái JavaScript.
- Khớp với nguyên tắc phát triển của dự án: làm từng tính năng một nhưng đầy đủ.

## Hệ quả

- **Phase 0 phình to đáng kể** — ước tính chiếm 30–40% công sức của cả dự án.
  Phải chấp nhận một quãng dài trước khi nhìn thấy màn hình nghiệp vụ đầu tiên.
- Phải tự xử lý những ca khó và không được lược bớt: cursor đa scope, thu hồi
  quyền phải purge dữ liệu cục bộ, điều phối đa tab, rebase mutation chưa ack,
  bootstrap khi cursor quá cũ.
- Cần một bộ test riêng cho sync: mất kết nối giữa chừng, resume, purge khi bị
  thu hồi quyền, nhiều tab, restart server.
- Đổi lại, thay đổi protocol về sau là việc nội bộ, không phụ thuộc lộ trình của
  bên thứ ba.
- Xung đột dùng last-write-wins ở cấp field cho dữ liệu có cấu trúc. CRDT (Yjs)
  chỉ dành cho rich text và là một hệ thống riêng ở phase sau, không trộn vào đây.

## Phương án đã loại

**ElectricSQL.** Hợp với stack chỉ dùng Postgres, nhưng đồng bộ vòng qua backend,
buộc phải nhân bản logic phân quyền vào shape definition — rủi ro bảo mật không
chấp nhận được với mô hình quyền của Kaiju.

**Zero (Rocicorp).** Mô hình gần với thứ Kaiju cần nhất, nhưng còn mới, ràng buộc
kiến trúc mạnh và giả định backend JavaScript.

**Triplit / PowerSync / Jazz.** Đánh đổi giống nhau: nhanh lúc đầu, cứng về sau,
và đều phải nhân bản phân quyền.

**Không làm local-first, dùng REST cộng invalidation thông thường.** Đơn giản hơn
nhiều, nhưng bỏ đi chính đặc điểm định vị sản phẩm.
