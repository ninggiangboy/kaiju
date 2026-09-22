# ADR-0017: shadcn/ui làm nền giao diện, TanStack cho phần headless, TanStack Query chỉ cho dữ liệu ngoài đồng bộ

- **Trạng thái:** Accepted
- **Ngày:** 2026-09-23
- **Liên quan:** [ADR-0007](0007-build-own-sync-engine.md), [ADR-0008](0008-nextjs-as-spa-shell.md), [frontend.md](../04-system-design/frontend.md), [sync-engine.md](../04-system-design/sync-engine.md), [05-ux-ui-design](../05-ux-ui-design/)

## Bối cảnh

[frontend.md](../04-system-design/frontend.md#thư-viện) để ngỏ thư viện component
giao diện, chờ phần UX/UI design. Các thư viện còn lại (Dexie, Zustand, dnd-kit,
Tiptap, TanStack Virtual) đã chốt.

Kaiju là ứng dụng dày đặc thao tác bàn phím, bảng nhiều nghìn dòng, hộp thoại,
menu lệnh và kéo thả. Nó cần component có trợ năng tốt, chủ động được hoàn toàn
về giao diện, hỗ trợ chế độ tối, và không đi kèm một hệ thống lấy dữ liệu riêng
tranh chỗ với sync engine.

Có một rủi ro cụ thể: TanStack Query là lựa chọn mặc định cho gần như mọi dự án
React, nhưng frontend.md đã **cấm thư viện cache theo khoá truy vấn cho dữ liệu
nghiệp vụ**. Muốn có TanStack trong stack thì phải vạch ranh giới rõ, nếu không nó
sẽ lan vào dữ liệu nghiệp vụ theo thói quen.

## Quyết định

| Việc | Chọn |
|---|---|
| Component giao diện | **shadcn/ui** — mã nguồn component chép vào repo, dựng trên primitive trợ năng của Radix |
| Tạo kiểu | **Tailwind CSS**; token thiết kế là biến CSS theo quy ước theme của shadcn |
| Bảng | **TanStack Table**, ở chế độ sắp xếp, lọc và phân trang thủ công |
| Danh sách dài | **TanStack Virtual** (giữ nguyên, đã chốt từ trước) |
| Form | **TanStack Form** |
| Lời gọi server không thuộc đồng bộ | **TanStack Query**, trong phạm vi hẹp nêu dưới |
| Routing | **Giữ Next.js** — TanStack Router/Start vẫn bị loại theo [ADR-0008](0008-nextjs-as-spa-shell.md) |

### Phạm vi của TanStack Query

**Được dùng** cho dữ liệu **không có sync scope**:

- Tìm kiếm và gợi ý chạy ở server
- Báo cáo và số liệu tính ở server
- Dữ liệu của account toàn cục: danh sách phiên đăng nhập, cài đặt cá nhân
- Các bước của luồng đăng nhập chạy phía client, tải tệp lên, quản lý token API

**Không bao giờ** dùng cho:

- Đọc bất kỳ thực thể nào có sync scope — đọc qua `useLocalQuery`/`useLocalEntity`
- Thay đổi bất kỳ thực thể nào có sync scope — kể cả khi màn hình đó đang hiển
  thị dữ liệu lấy từ TanStack Query, thay đổi vẫn đi qua mutator của sync engine
- Được sync engine ghi vào cache của nó, hay ngược lại

Kiểm soát bằng công cụ: `@tanstack/react-query` chỉ được import trong thư mục
`remote/` (ở `src/remote/` cho phần thiết lập chung, và `src/features/<feature>/remote/`
cho lời gọi của từng feature). Luật kiểm tra mã nguồn chặn import ở mọi chỗ khác.

## Lý do

- **shadcn/ui là mã của dự án, không phải thư viện phụ thuộc.** Component nằm
  trong `src/ui/` và sửa được tận gốc. Một ứng dụng có hệ thống giao diện riêng
  sẽ sớm cần những thứ mà thư viện đóng gói không cho chỉnh.
- **Trợ năng có sẵn.** Menu, hộp thoại, combobox, tooltip trên Radix đã xử lý
  focus, bàn phím và ARIA — đúng những chỗ ứng dụng kiểu Jira dùng nhiều nhất và
  tự viết thì hay sai.
- **Không có runtime tạo kiểu.** Tailwind sinh CSS lúc build, không tốn gì ở
  luồng giao diện — quan trọng khi board và backlog phải render lại liên tục theo
  delta.
- **Token theme bằng biến CSS** là chỗ tự nhiên để đặt design system của
  [05-ux-ui-design](../05-ux-ui-design/), gồm cả chế độ tối.
- **TanStack Table + Virtual** đều headless, ghép với component shadcn và với dữ
  liệu từ truy vấn cục bộ mà không áp đặt nguồn dữ liệu.
- **TanStack Form** có kiểu dữ liệu chặt, không gắn với cách gửi dữ liệu — nộp
  form chỉ là gọi một mutator.
- **TanStack Query vẫn có chỗ thật.** Một số dữ liệu vốn chỉ sống ở server; tự
  viết cache, thử lại và khử trùng request cho chúng là làm lại đúng thứ TanStack
  Query làm tốt.

## Hệ quả

- Hai đường dữ liệu song song ở frontend: sync engine cho dữ liệu nghiệp vụ,
  TanStack Query cho phần còn lại. Ranh giới **phải** được chặn bằng luật kiểm tra
  mã nguồn, không chỉ bằng tài liệu.
- Tên hook của sync engine cố ý khác tên hook của TanStack Query (`useLocalQuery`,
  `useLocalEntity`, `useMutator` thay vì `useQuery`, `useEntity`, `useMutation`),
  để đọc một dòng code là biết dữ liệu đến từ đâu.
- Hàm lấy dữ liệu của TanStack Query **không tự gắn token**: nó gọi qua hàm `fetch`
  ủy quyền của sync engine, vì token chỉ nằm trong engine
  ([frontend.md](../04-system-design/frontend.md#xác-thực-phía-client)).
- Màn hình dùng TanStack Query **không thuộc luồng chính**, nên được phép có trạng
  thái chờ. Màn hình luồng chính vẫn không có ô xoay chờ.
- TanStack Table không tự sắp xếp hay lọc dữ liệu nghiệp vụ trên luồng giao
  diện; việc đó thuộc về truy vấn cục bộ chạy trong engine.
- Component shadcn là mã của dự án, nên **cập nhật là việc thủ công**: không có
  bản nâng cấp tự động từ upstream. Chấp nhận có chủ đích.
- Tailwind là phụ thuộc bắt buộc; mọi component mới viết theo cùng quy ước.

## Phương án đã loại

**MUI, Mantine, Chakra, Ant Design.** Mang theo ngôn ngữ thiết kế riêng và phải
ghi đè để có giao diện riêng. Một số dùng runtime tạo kiểu, tốn chi phí khi render
lại liên tục. Nâng cấp phiên bản lớn dễ phá giao diện đã tuỳ chỉnh.

**Radix hoặc primitive headless thuần, không dùng shadcn.** Cùng nền tảng nhưng
phải tự dựng toàn bộ lớp giao diện. shadcn cho sẵn điểm xuất phát mà vẫn là mã
của dự án.

**TanStack Query cho cả dữ liệu nghiệp vụ**, với cache do sync engine đẩy vào.
Cache của nó tổ chức theo khoá truy vấn, nên cùng một issue nằm ở nhiều mục và
phải vô hiệu hoá bằng tay — đúng lý do frontend.md đã loại loại thư viện này. Nó
còn tạo bản sao thứ hai của dữ liệu cục bộ, và chạy trên luồng giao diện thay vì
trong engine.

**TanStack Router hoặc TanStack Start thay Next.js.** Đã loại ở
[ADR-0008](0008-nextjs-as-spa-shell.md); quyết định này không mở lại.

**react-hook-form**, lựa chọn mặc định trong ví dụ của shadcn. Hoạt động tốt,
nhưng TanStack Form cho kiểu dữ liệu chặt hơn và đồng bộ với phần còn lại của
stack. Đây là lựa chọn cục bộ, đổi lại được nếu có lý do.
