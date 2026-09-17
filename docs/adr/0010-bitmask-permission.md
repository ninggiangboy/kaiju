# ADR-0010: Phân quyền bằng bitmask hai cấp

- **Trạng thái:** Accepted
- **Ngày:** 2026-09-17
- **Liên quan:** [ADR-0011](0011-account-vs-member.md), [ADR-0012](0012-shared-schema-tenancy-rls.md), [identity-and-permission.md](../04-system-design/identity-and-permission.md)

## Bối cảnh

Kaiju cần mô hình phân quyền chi tiết ở hai cấp: cấp workspace (mời thành viên,
tạo project, quản trị) và cấp project (xem, sửa, xoá, transition issue, quản trị
workflow). Việc kiểm tra quyền xảy ra ở gần như mọi request, và còn phải dùng để
**lọc danh sách** — ví dụ chỉ trả về những project mà người dùng được xem.

## Quyết định

Mỗi quyền là **một bit**. Role là một mask. Quyền hiệu lực của một member là phép
`OR` giữa mask cấp workspace, mask cấp project và mask đến từ các group.

Kiểm tra quyền là phép `AND` bit, và **đẩy được xuống SQL** để lọc danh sách
trong một truy vấn duy nhất.

Bên cạnh đó có một tầng mỏng **permission condition** chạy sau khi mask đã cho
phép, dùng cho các quyền phụ thuộc dữ liệu (`REPORTER_ONLY`, `ASSIGNEE_ONLY`,
`PROJECT_LEAD`). Chỗ nối cho tầng này được thiết kế ngay từ Phase 1, dù chưa
implement condition nào.

## Lý do

- Kiểm tra quyền cực rẻ, và quan trọng hơn là **lọc được ngay trong SQL**, tránh
  phải tải dữ liệu về rồi lọc ở tầng ứng dụng.
- Mask là một giá trị đơn, dễ cache trong Redis và dễ nhét vào một truy vấn.
- Mô hình role dễ hiểu với người dùng cuối, trong khi vẫn cho phép tạo role tuỳ biến.

## Hệ quả

- **Bitmask không biểu diễn được quyền phụ thuộc dữ liệu.** "Chỉ sửa issue mình
  tạo" không phải là một bit. Đây là giới hạn đã biết và là lý do phải có tầng
  permission condition — **nếu không thiết kế chỗ nối từ đầu thì sau này phải sửa
  mọi chỗ gọi kiểm tra quyền.**
- Số lượng quyền bị chặn bởi độ rộng của kiểu dữ liệu. Một `bigint` chỉ an toàn
  cho 63 quyền, trong khi riêng Jira đã có hơn 40 và Kaiju cần cả quyền cấp
  workspace lẫn cấp project. **Phải thiết kế cho trường hợp vượt 64 bit ngay từ
  đầu** (mảng nhiều phần, hoặc kiểu bit chuỗi), vì đổi về sau kéo theo sửa mọi
  truy vấn đã viết.
- Vị trí bit là một phần hợp đồng dữ liệu: **không bao giờ được đổi ý nghĩa hay
  tái sử dụng một bit đã cấp**. Quyền bị bỏ thì để trống vị trí đó.
- Mask hiệu lực phải được cache và **invalidate tường minh** khi role hoặc
  membership đổi, kèm phát sự kiện để client purge dữ liệu cục bộ.
- Đọc mask thô khi debug rất khó chịu; cần công cụ giải mã mask thành danh sách
  tên quyền, và log nên ghi tên quyền thay vì số.

## Phương án đã loại

**Bảng `role_permission` quan hệ thông thường.** Dễ đọc và không giới hạn số
lượng quyền, nhưng mỗi lần kiểm tra là một join, và việc lọc danh sách theo quyền
trở thành truy vấn phức tạp hoặc phải lọc ở tầng ứng dụng.

**ACL theo từng bản ghi.** Linh hoạt nhất nhưng khối lượng dữ liệu bùng nổ và
hiệu năng kém. Kaiju không cần quyền tới mức từng issue riêng lẻ ở giai đoạn này.

**Engine kiểu policy (OPA, Cedar).** Mạnh và biểu đạt tốt, nhưng thêm một thành
phần hạ tầng và một ngôn ngữ nữa phải học, trong khi phần lớn nhu cầu chỉ là
kiểm tra quyền phẳng.
