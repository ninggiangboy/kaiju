# ADR-0012: Multi-tenancy shared-schema kèm Row Level Security

- **Trạng thái:** Accepted
- **Ngày:** 2026-09-17
- **Liên quan:** [ADR-0002](0002-postgres-only.md), [ADR-0011](0011-account-vs-member.md), [data-access-and-tenancy.md](../04-system-design/data-access-and-tenancy.md)

## Bối cảnh

Workspace là đơn vị tenancy của Kaiju, và hệ thống có đăng ký mở nên số lượng
workspace không bị chặn. Rò rỉ dữ liệu giữa hai workspace là loại lỗi nghiêm
trọng nhất có thể xảy ra, và chỉ cần một câu truy vấn quên điều kiện lọc.

## Quyết định

**Shared schema**: mọi bảng nghiệp vụ nằm chung một schema và mang cột
`workspace_id`, kể cả khi đã có `project_id` — denormalize có chủ đích để mọi
truy vấn lọc được tenant ngay tại bảng đó.

Phòng thủ **hai lớp**:

1. Tầng ứng dụng: một `WorkspaceContext` được thiết lập từ request, và mọi
   repository bắt buộc nhận `workspaceId`
2. Tầng database: **Row Level Security** trên mọi bảng nghiệp vụ, với biến phiên
   được đặt ở đầu mỗi transaction

Shard key của toàn hệ thống là `workspace_id`, nhưng **chưa shard thật**.

## Lý do

- Shared schema giữ migration ở một lần chạy duy nhất, join được thoải mái, và
  backup chung — phù hợp với mô hình đăng ký mở, nơi số tenant lớn và phần lớn là
  tenant nhỏ.
- **RLS được bật ngay từ đầu vì chi phí lúc này gần như bằng không**, trong khi
  thêm vào sau khi đã có hàng trăm bảng vừa mệt vừa dễ sót. Một câu truy vấn quên
  điều kiện lọc là rò rỉ dữ liệu xuyên khách hàng; đây là chỗ đáng trả giá cho
  lưới an toàn.
- Giữ `workspace_id` ở mọi bảng đồng thời chuẩn bị sẵn cho việc shard mà không
  phải đổi mô hình.

## Hệ quả

- **Mọi bảng nghiệp vụ bắt buộc có `workspace_id`.** Không có ngoại lệ, kể cả các
  bảng nối.
- Mỗi transaction phải đặt biến phiên chứa workspace hiện tại trước khi chạy truy
  vấn; cần một cơ chế móc vào vòng đời transaction của Spring, và mọi luồng chạy
  nền (relay worker, scheduler) cũng phải đặt biến này.
- RLS có chi phí hiệu năng nhỏ trên mỗi truy vấn, và làm kế hoạch thực thi khó
  đọc hơn khi cần tối ưu.
- Một số thao tác quản trị cần chạy với vai trò bỏ qua RLS; vai trò đó phải được
  giới hạn chặt và không dùng cho đường request thông thường.
- **Không bảng nghiệp vụ nào được có khoá ngoại tới bảng toàn cục** ngoài
  `workspace`, để bảo toàn khả năng shard — xem [ADR-0011](0011-account-vs-member.md).
- Cần một bộ test chuyên bắt rò rỉ xuyên workspace, chạy trên mọi endpoint.
- Tenant lớn và tenant nhỏ dùng chung tài nguyên; một workspace hoạt động mạnh có
  thể ảnh hưởng hiệu năng của workspace khác. Đây là lý do giữ sẵn khả năng shard.

## Phương án đã loại

**Schema cho mỗi tenant.** Cách ly tốt hơn, nhưng số lần chạy migration nhân theo
số workspace, connection pool phình vì phải đổi `search_path`, và bản thân
`search_path` là một chỗ dễ rò. Không phù hợp với đăng ký mở.

**Database cho mỗi tenant.** Cách ly mạnh nhất, hoàn toàn không phù hợp khi ai
cũng có thể tạo workspace miễn phí.

**Chỉ lọc ở tầng ứng dụng, không dùng RLS.** Đơn giản và nhanh hơn một chút,
nhưng bỏ đi lưới an toàn cho đúng loại lỗi nghiêm trọng nhất. Kỷ luật của con
người không phải là biện pháp kiểm soát đủ tốt cho việc này.
