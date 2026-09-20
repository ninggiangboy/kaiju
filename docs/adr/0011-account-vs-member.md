# ADR-0011: Tách account toàn cục khỏi member theo workspace

- **Trạng thái:** Accepted
- **Ngày:** 2026-09-17
- **Liên quan:** [ADR-0009](0009-magic-link-only.md), [ADR-0012](0012-shared-schema-tenancy-rls.md), [Glossary](../glossary.md), [uc-03-member-invite.md](../03-features/usecases/uc-03-member-invite.md)

## Bối cảnh

Một người dùng có thể tham gia nhiều workspace, và thông tin của họ ở mỗi
workspace không nhất thiết giống nhau — tên hiển thị ở workspace công ty khác với
ở workspace cá nhân. Hai người chỉ được coi là cùng một người khi trùng email.

Câu hỏi: dữ liệu nghiệp vụ nên tham chiếu tới danh tính toàn cục, hay tới một hồ
sơ theo từng workspace?

## Quyết định

Tách làm hai khái niệm:

- **`account`** — danh tính toàn cục, định danh bằng email, chỉ giữ thông tin
  đăng nhập. Nằm ở vùng dữ liệu toàn cục.
- **`member`** — hồ sơ trong một workspace cụ thể: tên hiển thị, avatar,
  timezone, vai trò. Nằm ở vùng dữ liệu của workspace.

**Mọi bảng nghiệp vụ tham chiếu tới `member`, không bảng nào tham chiếu tới
`account`.** Các cột nối giữa hai vùng không khai báo khoá ngoại.

## Lý do

- **Khả năng shard.** Khi mọi tham chiếu tới con người đều trỏ tới `member`,
  toàn bộ khoá ngoại nằm gọn trong một workspace. Shard key là `workspace_id` và
  hệ thống có thể cắt theo đó bất cứ lúc nào. Nếu dữ liệu nghiệp vụ trỏ thẳng tới
  `account`, ta có một khoá ngoại xuyên shard vĩnh viễn — thứ **không sửa được**
  sau khi đã có dữ liệu.
- **Không bao giờ có tham chiếu mồ côi.** Người rời workspace chỉ bị vô hiệu hoá,
  dòng `member` vẫn còn, nên issue họ tạo từ lâu vẫn hiển thị đúng.
- **Gán việc cho người chưa có tài khoản.** `member` được tạo ngay lúc mời với
  trạng thái `INVITED`; admin gán issue và cấp quyền trước khi người đó chấp
  nhận. Khi chấp nhận chỉ cần gắn `account_id` vào, không có bước chuyển giao dữ liệu nào.
- **Hồ sơ độc lập thật sự** giữa các workspace, đúng với kỳ vọng của người dùng.

## Hệ quả

- **Truy vấn xuyên workspace trở nên đắt hơn.** Màn hình gộp công việc của tôi ở
  mọi workspace phải tra bảng ánh xạ để lấy các cặp (workspace, member) rồi truy
  vấn từng workspace và gộp kết quả. Đây là cái giá chính, và chấp nhận được vì
  số workspace của một người thường rất nhỏ — đồng thời đây **chính là** cách bắt
  buộc phải làm sau khi shard.
- Đổi tên hay avatar **không** tự lan sang workspace khác. Thông tin mặc định ở
  `account` chỉ dùng để điền sẵn khi tạo `member` mới; muốn áp dụng cho tất cả thì
  phải là một hành động tường minh ghi vào từng workspace. Giữ như vậy để mọi thao
  tác **đọc** đều nằm trong một tenant.
- Tuỳ chọn thông báo và timezone thuộc về `member`, không thuộc `account`.
- Access token chỉ mang danh tính `account`; thông tin `member` và quyền được
  resolve theo từng request và cache ở Redis — nếu nhét vào token thì không thu
  hồi được khi đuổi người khỏi workspace.
- Mention trong comment lưu `member`, nhờ đó client render được tên khi offline.
- Xoá `account` không làm vỡ dữ liệu nghiệp vụ: các `member` chuyển sang vô hiệu
  và mất liên kết tới account. Thuận lợi cho yêu cầu ẩn danh hoá.
- Cần một test tự động quét metadata của database để đảm bảo không ai vô tình
  thêm khoá ngoại tới bảng toàn cục.

## Phương án đã loại

**Dữ liệu nghiệp vụ tham chiếu thẳng tới `account`.** Đơn giản hơn và truy vấn
xuyên workspace dễ hơn, nhưng tạo khoá ngoại xuyên tenant vĩnh viễn, không gán
được việc cho người chưa đăng ký, và xoá account làm vỡ tham chiếu ở mọi workspace.

**Một `account` cho mỗi workspace, không có danh tính toàn cục.** Sẽ phải đăng
nhập lại cho từng workspace, đi ngược yêu cầu một tài khoản dùng nhiều workspace.

**Danh tính toàn cục kèm bảng hồ sơ phụ theo workspace, nhưng nghiệp vụ vẫn trỏ
tới account.** Có được hồ sơ độc lập nhưng vẫn giữ nguyên khoá ngoại xuyên shard
— tức là không giải quyết được lý do chính.
