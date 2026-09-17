# Yêu cầu phi chức năng

Các yêu cầu về chất lượng hệ thống. Khác với yêu cầu chức năng, phần lớn những
điều dưới đây **không thể bổ sung sau** mà phải nằm trong thiết kế ngay từ đầu.

**Liên quan:** [functional.md](functional.md) · [constraints.md](constraints.md) · [System Design](../04-system-design/) · [testing-strategy.md](../04-system-design/testing-strategy.md)

---

## Hiệu năng và cảm nhận

| ID | Yêu cầu | Ghi chú |
|---|---|---|
| NFR-01 | Thao tác của người dùng phải hiện kết quả trên giao diện **ngay lập tức**, không chờ mạng | Mọi mutation đều lạc quan; độ trễ mạng không nằm trong đường phản hồi |
| NFR-02 | Mở ứng dụng phải hiển thị nội dung từ dữ liệu cục bộ trước khi có bất kỳ phản hồi nào từ server | Đây là hệ quả trực tiếp của local-first |
| NFR-03 | Thay đổi của một người phải xuất hiện ở máy người khác trong khoảng một giây ở điều kiện mạng bình thường | Đường đi: ghi → outbox → phát tán → luồng đồng bộ |
| NFR-04 | Bắt kịp sau khi mất kết nối ngắn phải hoàn tất trong vài trăm mili giây | Chỉ gửi phần thay đổi, không gửi lại toàn bộ |
| NFR-05 | Tải lại trạng thái đầy đủ của một project cỡ trung bình phải hoàn tất trong vài giây | Áp dụng khi vắng mặt quá lâu |
| NFR-06 | Board và backlog phải cuộn mượt với hàng nghìn issue | Cần danh sách ảo hoá ở giao diện |
| NFR-07 | Truy vấn lọc danh sách phải đẩy điều kiện phân quyền xuống tầng SQL | Không tải dữ liệu về rồi lọc ở ứng dụng |

## Khả năng mở rộng

| ID | Yêu cầu | Ghi chú |
|---|---|---|
| NFR-08 | Mỗi vai trò ứng dụng phải scale ngang độc lập | Bốn vai trò có đặc tính tải khác hẳn nhau |
| NFR-09 | Một tiến trình phục vụ đồng bộ phải giữ được hàng chục nghìn kết nối đồng thời | Cần virtual thread để không ghim thread cho mỗi kết nối |
| NFR-10 | Mô hình dữ liệu phải giữ được khả năng phân mảnh theo workspace | Chưa phân mảnh thật, nhưng không được cản trở |
| NFR-11 | Các bảng chỉ ghi thêm phải có phân vùng và chính sách giữ dữ liệu ngay khi tạo | Nhật ký thay đổi, hoạt động, outbox |
| NFR-12 | Nhiều tiến trình xử lý nền phải chạy song song mà không giẫm chân nhau | Khoá ở mức dòng, bỏ qua dòng đang bị khoá |

## Khả dụng và khả năng chịu lỗi

| ID | Yêu cầu | Ghi chú |
|---|---|---|
| NFR-13 | Mất toàn bộ Redis thì hệ thống chậm đi nhưng **không sai và không mất dữ liệu** | Mọi đường đọc từ cache phải có đường dự phòng |
| NFR-14 | Ứng dụng phải dùng được khi mất kết nối: đọc, tạo và sửa vẫn hoạt động | Thay đổi xếp hàng chờ gửi |
| NFR-15 | Hàng đợi thay đổi chờ gửi phải sống sót qua việc tải lại trang và đóng trình duyệt | Lưu bền ở phía máy người dùng |
| NFR-16 | Tiến trình xử lý nền chết giữa chừng không được làm mất sự kiện nào | Sự kiện ghi cùng giao dịch nghiệp vụ |
| NFR-17 | Sự kiện được giao ít nhất một lần, nên mọi bên tiêu thụ phải chống trùng | Ràng buộc khó nhất của thiết kế hướng sự kiện |
| NFR-18 | Triển khai phiên bản mới không được làm đứt kết nối đồng bộ quá vài giây | Client tự nối lại và bắt kịp |
| NFR-19 | Thay đổi cấu trúc dữ liệu phải tương thích ngược trong thời gian triển khai cuốn chiếu | Nhiều phiên bản chạy song song trong chốc lát |

## Bảo mật

| ID | Yêu cầu | Ghi chú |
|---|---|---|
| NFR-20 | Dữ liệu giữa hai workspace **không bao giờ** được rò rỉ sang nhau | Phòng thủ hai lớp: tầng ứng dụng và tầng cơ sở dữ liệu |
| NFR-21 | Mọi truy vấn dữ liệu nghiệp vụ phải bị ràng buộc theo workspace ở tầng cơ sở dữ liệu, không chỉ ở tầng ứng dụng | Lưới an toàn cho lỗi quên điều kiện lọc |
| NFR-22 | Thu hồi quyền phải có hiệu lực **ngay**, kể cả với phiên đang mở và dữ liệu đã nằm trên máy người dùng | Phải xoá dữ liệu cục bộ tương ứng |
| NFR-23 | Thông tin xác thực chỉ lưu dưới dạng băm, dùng một lần, có thời hạn ngắn | Áp dụng cho magic link và token lời mời |
| NFR-24 | Giới hạn tần suất cho mọi điểm cuối gửi email hoặc tạo tài nguyên | Chống lạm dụng và chống dùng hệ thống để gửi thư rác |
| NFR-25 | Token truy cập không được mang danh sách quyền cố định | Nếu mang thì không thu hồi được trước khi hết hạn |
| NFR-26 | Mọi hành động thay đổi quyền phải được ghi nhật ký kiểm toán không sửa được | Phục vụ điều tra sự cố |
| NFR-27 | Tệp tải lên phải có giới hạn dung lượng và điểm móc để quét nội dung độc hại | |

## Khả năng quan sát

| ID | Yêu cầu | Ghi chú |
|---|---|---|
| NFR-28 | Một định danh tương quan duy nhất phải đi xuyên toàn bộ vòng đời một thao tác | Từ request, qua sự kiện, qua xử lý nền, tới luồng đồng bộ |
| NFR-29 | Phải đo được độ trễ của hàng đợi sự kiện, số kết nối đồng bộ, và độ trễ đồng bộ của client | Ba chỉ số sống còn của hệ thống |
| NFR-30 | Nhật ký phải có cấu trúc và không chứa dữ liệu nhạy cảm | Không ghi token, không ghi nội dung riêng tư |
| NFR-31 | Mỗi vai trò ứng dụng có điểm kiểm tra sức khoẻ riêng phản ánh đúng việc nó làm | Vai trò xử lý nền không có HTTP nghiệp vụ |

## Khả năng bảo trì

| ID | Yêu cầu | Ghi chú |
|---|---|---|
| NFR-32 | Biên giới giữa các module phải được kiểm tra tự động, không chỉ dựa vào kỷ luật | Vi phạm phải làm hỏng build |
| NFR-33 | Bất biến về khoá ngoại và về cột định danh workspace phải được kiểm tra tự động | Quét siêu dữ liệu của cơ sở dữ liệu trong test |
| NFR-34 | Kiểm thử tích hợp chạy trên cơ sở dữ liệu thật, không dùng bản giả lập trong bộ nhớ | Hành vi phân vùng, khoá dòng và bảo mật mức dòng không giả lập được |
| NFR-35 | Sự kiện phải có phiên bản ngay từ sự kiện đầu tiên | Thêm sau khi đã có dữ liệu là rất tốn kém |
| NFR-36 | Vị trí bit của một quyền không bao giờ được đổi ý nghĩa hay dùng lại | Là một phần hợp đồng dữ liệu |

## Tương thích và trải nghiệm nền tảng

| ID | Yêu cầu | Ghi chú |
|---|---|---|
| NFR-37 | Hỗ trợ hai phiên bản mới nhất của các trình duyệt nhân Chromium, Firefox và Safari | |
| NFR-38 | Mở nhiều tab chỉ dùng **một** kết nối đồng bộ và **một** nơi ghi dữ liệu cục bộ | Nếu không sẽ nhân traffic và ghi đè lẫn nhau |
| NFR-39 | Phải có phương án dự phòng khi trình duyệt không hỗ trợ cơ chế chia sẻ giữa các tab | Bầu một tab làm chủ |
| NFR-40 | Dung lượng lưu trữ cục bộ phải có giới hạn và cơ chế dọn dẹp | Trình duyệt có thể xoá dữ liệu bất cứ lúc nào, hệ thống phải chịu được |
| NFR-41 | Giao diện dùng tốt trên desktop; tablet và điện thoại ở mức đọc và thao tác cơ bản | |
| NFR-42 | Mọi mốc thời gian lưu kèm múi giờ và hiển thị theo múi giờ của người xem | Múi giờ thuộc hồ sơ trong từng workspace |
| NFR-43 | Chuỗi hiển thị phải tách khỏi mã nguồn để hỗ trợ đa ngôn ngữ về sau | |

## Yêu cầu hạ tầng

| ID | Yêu cầu | Ghi chú |
|---|---|---|
| NFR-44 | Máy chủ trung gian phải tắt đệm cho luồng đồng bộ | Nếu không, dữ liệu bị giữ lại và triệu chứng là "realtime không chạy" |
| NFR-45 | Luồng đồng bộ phải có nhịp tim định kỳ để không bị đóng vì nhàn rỗi | |
| NFR-46 | Phải có sao lưu định kỳ và quy trình khôi phục đã được thử nghiệm thật | Sao lưu chưa thử khôi phục thì chưa phải sao lưu |
| NFR-47 | Gửi email phải được coi là thành phần quan trọng, có giám sát | Đăng nhập phụ thuộc hoàn toàn vào nó |
