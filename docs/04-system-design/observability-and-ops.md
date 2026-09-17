# Khả năng quan sát và vận hành

Nội dung của `infra/`, cách cấu hình theo vai trò ứng dụng, và những chỉ số phải
đo được để biết hệ thống có đang khoẻ hay không.

**Liên quan:** [infrastructure.md](infrastructure.md) · [architecture.md](architecture.md) · [events-and-outbox.md](events-and-outbox.md) · [realtime-and-sync.md](realtime-and-sync.md) · [non-functional.md](../02-requirement/non-functional.md)

---

## Nội dung `infra/`

```
infra/
├── docker-compose.yml         # môi trường phát triển
├── docker/
│   ├── backend.Dockerfile
│   └── frontend.Dockerfile
├── proxy/                     # cấu hình máy chủ trung gian
├── scripts/                   # khởi tạo, dữ liệu mẫu, tiện ích vận hành
└── env/                       # tệp biến môi trường mẫu — không chứa bí mật thật
```

### Môi trường phát triển

| Dịch vụ | Vai trò |
|---|---|
| PostgreSQL | Nguồn sự thật |
| Redis | Cache, phát tán, khoá |
| Bộ bắt email | Nhận mọi email gửi ra và hiển thị trên giao diện web. **Bắt buộc** vì đăng nhập phụ thuộc hoàn toàn vào email |
| Máy chủ trung gian | Tuỳ chọn, dùng khi cần kiểm chứng hành vi đệm của luồng đồng bộ |

Chạy một lệnh là có đủ môi trường. Backend và frontend chạy ngoài Docker khi phát
triển, để giữ vòng lặp sửa và chạy lại nhanh.

### Dữ liệu mẫu

Script tạo dữ liệu mẫu nằm ở `infra/scripts/`, **không** nằm trong migration.
Migration định nghĩa cấu trúc; dữ liệu mẫu là tiện ích phát triển và phải xoá
sạch, tạo lại được bất cứ lúc nào.

---

## Cấu hình theo vai trò

| Cấu hình | `api` | `realtime` | `worker` | `scheduler` |
|---|---|---|---|---|
| Tầng web nghiệp vụ | Có | Có | Không | Không |
| Kích thước connection pool | Lớn | Nhỏ | Vừa | Rất nhỏ |
| Tiến trình chuyển tiếp sự kiện | Không | Không | Có | Không |
| Lắng nghe thông báo từ cơ sở dữ liệu | Không | Không | Có (kết nối riêng ngoài pool) | Không |
| Đăng ký nhận phát tán từ Redis | Không | Có | Không | Không |
| Tác vụ theo lịch | Không | Không | Không | Có |
| Khoá chống chạy trùng | Không | Không | Không | Có |

**Tổng số kết nối tới PostgreSQL phải được tính thủ công**: số instance nhân với
kích thước pool của từng vai trò, cộng lại, so với giới hạn của PostgreSQL. Đây
là thứ hay bị quên cho tới khi scale rồi mới thấy lỗi hết kết nối.

### Biến môi trường và bí mật

| Quy ước | |
|---|---|
| Không bí mật nào nằm trong repository | `infra/env/` chỉ chứa tệp mẫu với giá trị giả |
| Cấu hình đọc từ biến môi trường | Không sinh tệp cấu hình lúc triển khai |
| Thiếu biến bắt buộc thì ứng dụng dừng ngay lúc khởi động | Chết sớm còn hơn chạy sai âm thầm |
| Bí mật không bao giờ được ghi vào nhật ký | Kể cả ở mức gỡ lỗi |

---

## Nhật ký

Nhật ký có cấu trúc, mỗi dòng là một bản ghi máy đọc được. Trường bắt buộc: thời
điểm, mức độ, vai trò ứng dụng, định danh tương quan, định danh workspace, định
danh người thực hiện, thông điệp.

### Định danh tương quan

**Một định danh duy nhất phải đi hết vòng đời của một thao tác:**

```
request HTTP → command handler → bản ghi sự kiện → tiến trình chuyển tiếp
→ bên tiêu thụ → phát tán → luồng đồng bộ
```

Đây là điều kiện để trả lời được câu hỏi "vì sao người dùng này không nhận được
thông báo" mà không phải đoán. Định danh được gắn vào siêu dữ liệu của sự kiện để
nó vượt qua ranh giới bất đồng bộ.

### Không được ghi vào nhật ký

Token, mật khẩu, mã đăng nhập, nội dung email, nội dung bình luận, tệp đính kèm.
Với mặt nạ quyền thì ghi **tên quyền**, không ghi giá trị số — con số không đọc
được bằng mắt và vô dụng khi điều tra.

---

## Chỉ số

### Ba chỉ số sống còn

| Chỉ số | Nói lên điều gì | Bất thường nghĩa là |
|---|---|---|
| Độ trễ hàng đợi sự kiện | Khoảng cách từ lúc sự kiện được ghi tới lúc được xử lý | Thông báo chậm, chỉ mục cũ, automation không chạy |
| Số kết nối đồng bộ đang mở | Bao nhiêu client đang kết nối | Sụt đột ngột nghĩa là có gì đó đang đóng kết nối hàng loạt |
| Độ trễ đồng bộ của client | Khoảng cách giữa vị trí của client và vị trí mới nhất của scope | Client đang tụt lại, thay đổi không tới nơi |

### Các chỉ số khác

Kích thước khu vực thư chết, tỉ lệ thử lại, số lần bootstrap lại, thời gian phản
hồi theo endpoint, sử dụng connection pool, tỉ lệ trúng cache quyền, thời gian
chờ khoá khi cấp số thứ tự, thời gian gửi email.

### Cảnh báo

| Điều kiện | Mức độ |
|---|---|
| Có bản ghi mới trong khu vực thư chết | Xem ngay |
| Độ trễ hàng đợi sự kiện vượt ngưỡng | Xem ngay |
| Không gửi được email | Xem ngay — đăng nhập phụ thuộc vào nó |
| Kết nối đồng bộ sụt đột ngột | Xem ngay |
| Sử dụng connection pool gần mức tối đa | Cảnh báo sớm |

---

## Kiểm tra sức khoẻ

Mỗi vai trò có điểm kiểm tra riêng **phản ánh đúng việc nó làm**:

| Vai trò | Khoẻ nghĩa là |
|---|---|
| `api` | Kết nối được cơ sở dữ liệu, migration đã chạy xong |
| `realtime` | Kết nối được cơ sở dữ liệu và Redis, đang đăng ký nhận phát tán |
| `worker` | Kết nối được cơ sở dữ liệu, tiến trình chuyển tiếp đang chạy, độ trễ hàng đợi dưới ngưỡng |
| `scheduler` | Kết nối được cơ sở dữ liệu, giữ được khoá hoặc đang chờ khoá |

Một điểm kiểm tra chỉ trả về "còn sống" cho mọi vai trò là vô dụng: `worker` vẫn
đang chạy nhưng hàng đợi tồn đọng một giờ thì nó **không** khoẻ.

---

## Yêu cầu với máy chủ trung gian

| Yêu cầu | Hệ quả nếu thiếu |
|---|---|
| Tắt đệm cho đường dẫn của luồng đồng bộ | Delta bị giữ lại, triệu chứng là "realtime không chạy" và **không có lỗi nào** |
| Thời gian chờ nhàn rỗi dài hơn chu kỳ nhịp tim | Kết nối bị đóng liên tục |
| Bật HTTP/2 | Giới hạn số kết nối trên mỗi nguồn |
| Giới hạn kích thước tệp tải lên | Nếu không, tải lên tệp lớn bị từ chối với thông báo khó hiểu |

Mục đầu tiên là lỗi vận hành phổ biến nhất của kiến trúc này và đáng được ghi
ngay ở đầu tài liệu triển khai.

---

## Triển khai

Thay thế cuốn chiếu theo từng vai trò. Client mất kết nối đồng bộ vài giây rồi tự
nối lại và bắt kịp, nên không mất thay đổi nào.

Hai ràng buộc:

- Migration phải **tương thích ngược** trong thời gian có hai phiên bản chạy song song
- Thay đổi phá vỡ cấu trúc dữ liệu phải chia làm ba bước qua ba lần phát hành:
  thêm cái mới → chuyển dữ liệu và chuyển code → xoá cái cũ

### Thứ tự triển khai

`worker` và `scheduler` trước, `api` và `realtime` sau. Lý do: tiến trình nền
phải hiểu được định dạng sự kiện mới trước khi có ai sinh ra chúng.

---

## Sao lưu và giữ dữ liệu

| Việc | Ghi chú |
|---|---|
| Sao lưu PostgreSQL định kỳ | Có khôi phục theo thời điểm |
| **Thử khôi phục thật sự** | Sao lưu chưa từng thử khôi phục thì chưa phải sao lưu |
| Không sao lưu Redis | Theo định nghĩa, mất Redis không mất dữ liệu |
| Tệp đính kèm | Sao lưu riêng, cùng chu kỳ với cơ sở dữ liệu |
| Dọn bảng chuyển tiếp sự kiện | Giữ ngắn; khu vực thư chết giữ lâu hơn hẳn |
| Dọn nhật ký thay đổi | Giữ đủ lâu để client vắng mặt nhiều ngày còn bắt kịp |
| Dọn nhật ký kiểm toán | Giữ lâu nhất trong các loại |
