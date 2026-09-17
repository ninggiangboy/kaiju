# Chiến lược kiểm thử

Hai nhóm test quan trọng nhất của dự án này không phải test nghiệp vụ thông
thường, mà là test **bắt rò rỉ dữ liệu giữa các tenant** và test **sync engine
trong điều kiện xấu**. Cả hai đều kiểm chứng những thứ không thể sửa dễ dàng nếu
sai.

**Liên quan:** [backend-modules.md](backend-modules.md) · [data-access-and-tenancy.md](data-access-and-tenancy.md) · [events-and-outbox.md](events-and-outbox.md) · [realtime-and-sync.md](realtime-and-sync.md)

---

## Các tầng

| Tầng | Phạm vi | Chạy trên |
|---|---|---|
| Unit — domain | Quy tắc nghiệp vụ trong `domain`, không có Spring | Bộ nhớ, rất nhanh |
| Integration — module | Một module với cơ sở dữ liệu thật | PostgreSQL trong container |
| Kiểm tra biên giới | Đồ thị phụ thuộc giữa các module | Không cần cơ sở dữ liệu |
| Bất biến cơ sở dữ liệu | Siêu dữ liệu của schema | PostgreSQL trong container |
| Tenancy | Rò rỉ dữ liệu xuyên workspace | PostgreSQL trong container |
| Sự kiện | Chuyển tiếp, chống trùng, thử lại, thư chết | PostgreSQL trong container |
| Sync engine — server | Cấp số thứ tự, catch-up, bootstrap, phân quyền scope | PostgreSQL trong container |
| Sync engine — client | Offline, nối lại, hoàn tác, rebase, đa tab | Môi trường giả lập trình duyệt |
| Đầu cuối | Các luồng chính | Trình duyệt thật |

**Kiểm thử tích hợp chạy trên PostgreSQL thật, không dùng bản giả lập trong bộ
nhớ.** Bảo mật mức dòng, khoá dòng có bỏ qua, cơ chế thông báo và phân vùng đều
không giả lập được — mà đó chính là những thứ cần kiểm chứng nhất.

---

## Kiểm tra biên giới module

Một test duy nhất kiểm tra toàn bộ đồ thị phụ thuộc và **làm hỏng build** khi có
vi phạm: import package nội bộ của module khác, hoặc phụ thuộc vòng.

Không có test này thì ba luật biên giới chỉ là lời khuyên, và trong một monolith
không có ranh giới mạng ép buộc, lời khuyên sẽ bị bỏ qua trong vài tháng.

---

## Bất biến cơ sở dữ liệu

Nhóm test quét siêu dữ liệu của schema và báo lỗi khi vi phạm:

| Kiểm tra | Lý do |
|---|---|
| Mọi bảng nghiệp vụ có cột định danh workspace | Điều kiện để cách ly tenant hoạt động |
| Mọi bảng nghiệp vụ bật bảo mật mức dòng | Lớp phòng thủ thứ hai |
| Không có khoá ngoại từ bảng nghiệp vụ tới bảng thuộc vùng toàn cục | Điều kiện để phân mảnh về sau |
| Không có bảng nào tham chiếu tới bảng danh tính toàn cục ngoài các bảng được phép | Giữ đúng mô hình hai tầng |

Đây là cách rẻ nhất để enforce các bất biến mà nếu vi phạm thì **không sửa được**
sau khi đã có dữ liệu.

---

## Migration

Ứng dụng không tự chạy migration ([CON-68](../02-requirement/constraints.md)), nên
migration là một đối tượng kiểm thử riêng chứ không phải thứ được chạy ké lúc dựng
môi trường test.

| Kịch bản | Kết quả mong đợi |
|---|---|
| Chạy toàn bộ chiều đi lên trên cơ sở dữ liệu trắng | Schema đúng, thoả mọi bất biến ở mục trên |
| Changeset không khai báo phần lùi | Build hỏng, không phải cảnh báo ([CON-74](../02-requirement/constraints.md)) |
| Lên rồi xuống rồi lên lại | Về đúng schema ban đầu, không sót đối tượng nào |
| Lùi về một phiên bản ở giữa | Dừng đúng chỗ, không lùi quá tay |
| Chạy chiều đi lên mới trên cơ sở dữ liệu đang có phiên bản ứng dụng cũ chạy | Ứng dụng cũ vẫn chạy đúng — điều kiện để quay lui an toàn |
| Chạy hai lần liên tiếp | Lần thứ hai không làm gì |

Phần lùi **chưa từng chạy thử là phần lùi không tồn tại**: nó chỉ được cần tới
đúng lúc có sự cố, và đó là lúc tệ nhất để phát hiện nó sai.

---

## Tenancy

Chạy trên **mọi endpoint**, không phải trên một vài endpoint tiêu biểu:

| Kịch bản | Kết quả mong đợi |
|---|---|
| Dùng thông tin xác thực của workspace A gọi tới tài nguyên của workspace B | Bị từ chối, và thông báo lỗi không tiết lộ tài nguyên đó có tồn tại hay không |
| Truy vấn danh sách khi thuộc nhiều workspace | Chỉ trả về dữ liệu của workspace hiện tại |
| Tiến trình nền xử lý sự kiện | Đặt đúng ngữ cảnh workspace trước khi truy vấn |
| Tác vụ theo lịch chạy cho mọi workspace | Không rò rỉ dữ liệu giữa các vòng lặp |
| Quên đặt ngữ cảnh workspace | Truy vấn trả về rỗng hoặc báo lỗi, **không** trả về dữ liệu của workspace khác |

Kịch bản cuối cùng là kịch bản kiểm chứng rằng lớp phòng thủ thứ hai thật sự hoạt
động. Nếu nó trả về dữ liệu thì bảo mật mức dòng đang không được áp dụng.

---

## Sự kiện và outbox

| Kịch bản | Kết quả mong đợi |
|---|---|
| Giao dịch nghiệp vụ thất bại | Không có sự kiện nào được ghi |
| Tiến trình chết sau khi dispatch, trước khi đánh dấu hoàn tất | Sự kiện được xử lý lại và bên tiêu thụ không tạo tác dụng phụ lần hai |
| Cùng một sự kiện được giao hai lần | Bên tiêu thụ chống trùng đúng |
| Bên tiêu thụ lỗi tạm thời | Thử lại với khoảng chờ tăng dần |
| Bên tiêu thụ lỗi liên tục | Chuyển vào khu vực thư chết, không chặn các sự kiện khác |
| Nhiều tiến trình chuyển tiếp chạy song song | Không sự kiện nào bị xử lý hai lần bởi hai tiến trình |
| Nhiều sự kiện của cùng một aggregate | Được xử lý đúng thứ tự |
| Phát lại từ khu vực thư chết | Cho kết quả đúng |

**Test chống trùng là bắt buộc cho mọi bên tiêu thụ**, không phải cho một bên
tiêu thụ tiêu biểu. Đây là ràng buộc khó nhất của kiến trúc hướng sự kiện và là
nguồn gốc của những lỗi khó chịu nhất.

---

## Sync engine — phía server

| Kịch bản | Kết quả mong đợi |
|---|---|
| Nhiều thao tác ghi đồng thời trên một scope | Số thứ tự tăng đơn điệu, không có lỗ hổng |
| Bắt kịp từ một vị trí cũ | Nhận đúng và đủ các thay đổi còn thiếu |
| Bắt kịp từ vị trí quá cũ | Nhận lệnh tải lại trạng thái đầy đủ |
| Ảnh chụp trạng thái và số thứ tự đi kèm | Thuộc cùng một thời điểm, không lệch |
| Người dùng không có quyền với một scope | Không nhận được delta nào của scope đó |
| Quyền bị thu hồi khi kết nối đang mở | Nhận sự kiện thu hồi ngay |
| Nhiều instance phục vụ đồng bộ | Client nối tới instance nào cũng nhận đủ delta |

---

## Sync engine — phía client

Đây là nhóm test hay bị bỏ qua nhất và cũng là nhóm phát hiện nhiều lỗi nhất.

| Kịch bản | Kết quả mong đợi |
|---|---|
| Mở ứng dụng khi chưa có dữ liệu cục bộ | Tải trạng thái đầy đủ rồi hiển thị |
| Mở ứng dụng khi đã có dữ liệu cục bộ | Hiển thị **ngay**, không chờ mạng |
| Mất kết nối giữa lúc nhận delta | Nối lại và không bỏ sót delta nào |
| Thao tác khi offline, tải lại trang, có mạng lại | Mutation vẫn được gửi đi |
| Mutation bị từ chối | Hoàn tác đúng, các mutation khác không bị ảnh hưởng |
| Delta tới trong lúc có mutation chưa xác nhận | Rebase đúng, thay đổi cục bộ không mất |
| Nhiều mutation trên cùng một thực thể | Áp đúng thứ tự |
| Thu hồi quyền | Dữ liệu cục bộ của scope bị xoá sạch, mutation đang chờ bị huỷ |
| Nhiều tab | Chỉ một kết nối, mọi tab nhất quán |
| Tab chủ bị đóng | Tab khác nhận vai trò, không mất kết nối lâu |
| Lưu trữ cục bộ bị trình duyệt xoá | Ứng dụng tải lại từ đầu, không hỏng |
| Khởi động lại server | Client tự nối lại và bắt kịp |

---

## Kiểm thử đầu cuối

Giữ ở số lượng nhỏ, chỉ cho các luồng thật sự quan trọng, vì chúng chậm và dễ gãy:

- Đăng nhập bằng magic link, gồm cả nhánh nhập mã 6 số
- Mời một người chưa có tài khoản cho tới lúc họ vào được workspace
- Tạo project và tạo issue đầu tiên
- Hai tab: thay đổi ở tab này hiện ra ở tab kia
- Mất mạng: thao tác vẫn được, và được gửi đi khi có mạng lại

---

## Quy ước

| Quy ước | |
|---|---|
| Đặt tên test | Mô tả hành vi, không mô tả tên hàm được gọi |
| Dữ liệu test | Tạo bằng hàm dựng sẵn cho từng aggregate, không dùng tệp cố định dùng chung |
| Cách ly | Mỗi test tự dựng dữ liệu của mình, không phụ thuộc thứ tự chạy |
| Cơ sở dữ liệu | Một container dùng chung, mỗi test một workspace riêng — đồng thời là bài kiểm tra cách ly tenant thật |
| Thời gian | Không dùng thời gian thực trong test; tiêm đồng hồ giả |
| Ngẫu nhiên | Không dùng giá trị ngẫu nhiên không kiểm soát được |

---

## Thứ được coi là xong

Theo nguyên tắc làm từng tính năng một nhưng đầy đủ, một feature chỉ được đánh
dấu hoàn thành khi:

- Luồng chính có test
- **Các nhánh ngoại lệ nêu trong use case đều có test**
- Phân quyền có test, gồm cả trường hợp không đủ quyền
- Cách ly tenant có test
- Nếu feature sinh sự kiện: có test chống trùng
- Nếu feature ảnh hưởng dữ liệu client: có test đồng bộ

Thiếu bất kỳ mục nào thì trạng thái vẫn là `IN_PROGRESS`, không phải `DONE`.
