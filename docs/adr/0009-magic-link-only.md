# ADR-0009: Magic link là phương thức xác thực duy nhất

- **Trạng thái:** Accepted
- **Ngày:** 2026-09-17
- **Liên quan:** [ADR-0011](0011-account-vs-member.md), [identity-and-permission.md](../04-system-design/identity-and-permission.md), [uc-auth.md](../03-features/usecases/uc-auth.md)

## Bối cảnh

Cần một cơ chế xác thực cho hệ thống có đăng ký mở, nhiều workspace, và có luồng
mời người ngoài vào workspace bằng email.

Hệ thống xác thực bằng mật khẩu kéo theo cả một mảng tính năng: password policy,
quên mật khẩu, đổi mật khẩu, phát hiện mật khẩu rò rỉ, và 2FA để bù lại điểm yếu
cố hữu của mật khẩu.

## Quyết định

**Chỉ hỗ trợ magic link.** Người dùng nhập email, nhận một liên kết dùng một lần
kèm mã 6 số, và đăng nhập. Cùng một luồng phục vụ cả đăng ký lẫn đăng nhập:
email chưa tồn tại thì tài khoản được tạo sau khi xác thực.

Không có mật khẩu ở bất kỳ đâu trong hệ thống. SSO doanh nghiệp để lại cho phase
tích hợp về sau.

## Lý do

- Xác thực bằng email là **possession-based** — đã tương đương về mặt yếu tố với
  việc bật 2FA trên một mật khẩu yếu.
- Loại bỏ toàn bộ một mảng tính năng cùng bề mặt tấn công đi kèm: không có mật
  khẩu để rò rỉ, để dùng lại, hay để đoán.
- **Token lời mời chính là magic link.** Người bấm được liên kết trong hộp thư đã
  chứng minh sở hữu email đó, nên luồng mời người chưa có tài khoản không cần
  thêm bước xác thực nào — một sự đơn giản hoá đáng kể cho tính năng invite.
- Hệ thống đã bắt buộc phải gửi được email cho luồng mời và luồng notification,
  nên không thêm phụ thuộc hạ tầng mới.

## Hệ quả

- **Email trở thành điểm phụ thuộc sống còn.** Email chậm hoặc vào spam là không
  ai đăng nhập được. Hạ tầng gửi mail phải được coi là thành phần quan trọng, có
  giám sát, không phải tiện ích phụ.
- **Bắt buộc phải có mã 6 số bên cạnh liên kết.** Người dùng thường mở mail trên
  điện thoại trong khi đang đăng nhập trên máy tính; chỉ có liên kết là họ kẹt.
- Việc chiếm được hộp thư đồng nghĩa với chiếm được tài khoản. Đây là đánh đổi
  đã chấp nhận, và cũng đúng với hệ thống dùng mật khẩu có chức năng đặt lại
  mật khẩu qua email.
- Cần rate limit chặt theo email và theo IP, nếu không hệ thống trở thành công cụ
  gửi thư rác.
- Token phải dùng một lần, lưu dưới dạng hash, có thời hạn ngắn, và bị vô hiệu
  hàng loạt khi một token của cùng email được sử dụng.
- Không cần làm 2FA riêng, không cần password policy, không cần luồng quên mật
  khẩu. Phase identity nhờ đó gọn hơn hẳn.

## Phương án đã loại

**Mật khẩu cộng 2FA tuỳ chọn.** Nhiều tính năng phải làm đầy đủ, bề mặt tấn công
lớn hơn, và trong thực tế phần lớn người dùng không bật 2FA.

**OAuth qua Google/GitHub.** Trải nghiệm tốt và có thể bổ sung sau, nhưng nếu là
phương thức duy nhất thì loại trừ người dùng không có tài khoản ở các nhà cung
cấp đó, và thêm phụ thuộc bên ngoài ngay từ ngày đầu.

**Passkey/WebAuthn.** Về bảo mật là tốt nhất, nhưng phục hồi khi mất thiết bị
phức tạp, và gần như luôn phải có một phương thức dự phòng — thường chính là
magic link. Có thể bổ sung về sau như một yếu tố thứ hai.
