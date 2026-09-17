# Danh tính và phân quyền

Danh tính chia làm hai tầng: một `account` toàn cục dùng để đăng nhập, và một
`member` cho mỗi workspace dùng cho mọi việc còn lại. Xác thực chỉ có magic link.
Phân quyền dùng mặt nạ bit ở hai cấp, kèm một tầng điều kiện cho các quyền phụ
thuộc dữ liệu.

Tài liệu này mô tả **cơ chế**. Luồng người dùng đầy đủ kèm các nhánh ngoại lệ nằm
ở [use case](../03-features/usecases/).

**Liên quan:** [ADR-0009](../adr/0009-magic-link-only.md) · [ADR-0010](../adr/0010-bitmask-permission.md) · [ADR-0011](../adr/0011-account-vs-member.md) · [uc-auth.md](../03-features/usecases/uc-auth.md) · [uc-member-invite.md](../03-features/usecases/uc-member-invite.md)

---

## Mô hình danh tính hai tầng

```mermaid
flowchart TB
    subgraph g["Vùng toàn cục"]
        acc["account<br/>email · thông tin đăng nhập"]
        ses["session"]
        acc --- ses
    end

    subgraph w1["Workspace A"]
        m1["member<br/>tên hiển thị · avatar · vai trò"]
    end
    subgraph w2["Workspace B"]
        m2["member<br/>tên hiển thị khác · vai trò khác"]
    end

    acc -. "không có khoá ngoại" .-> m1
    acc -. "không có khoá ngoại" .-> m2

    m1 --> iss1["Mọi dữ liệu nghiệp vụ<br/>tham chiếu member"]
    m2 --> iss2["Mọi dữ liệu nghiệp vụ<br/>tham chiếu member"]
```

| | `account` | `member` |
|---|---|---|
| Phạm vi | Toàn hệ thống | Một workspace |
| Định danh bằng | Email | Cặp workspace và người |
| Giữ gì | Email, thông tin đăng nhập, giá trị mặc định để điền sẵn | Tên hiển thị, avatar, múi giờ, ngôn ngữ, vai trò, trạng thái |
| Dữ liệu nghiệp vụ tham chiếu | **Không bao giờ** | **Luôn luôn** |
| Có thể tồn tại độc lập | Có (chưa tham gia workspace nào) | Có (được mời nhưng chưa có tài khoản) |

Lý do tách và hệ quả đầy đủ: [ADR-0011](../adr/0011-account-vs-member.md).

### Ba tình huống mà mô hình này giải quyết

| Tình huống | Cách hoạt động |
|---|---|
| Gán việc cho người chưa đăng ký | `member` được tạo ngay lúc mời, ở trạng thái chờ. Gán issue, cấp quyền bình thường. Khi người đó chấp nhận thì chỉ gắn `account` vào |
| Người rời workspace | `member` chuyển sang vô hiệu, dòng vẫn còn. Issue họ tạo hai năm trước vẫn hiển thị đúng tên |
| Xoá tài khoản | Các `member` mất liên kết tới `account` và bị vô hiệu; dữ liệu nghiệp vụ nguyên vẹn |

### Đồng bộ thông tin giữa hai tầng

Đổi tên hiển thị ở một workspace **không** lan sang workspace khác. Giá trị mặc
định ở `account` chỉ dùng để **điền sẵn** khi tạo `member` mới.

Muốn áp dụng cho tất cả thì phải là một hành động tường minh của người dùng, và
hành động đó ghi vào từng workspace. Giữ như vậy để **mọi thao tác đọc đều nằm
gọn trong một tenant** — điều kiện để phân mảnh về sau.

Tuỳ chọn thông báo và múi giờ cũng thuộc `member`: người ta muốn nhận email từ
workspace công ty nhưng im lặng ở workspace cá nhân.

---

## Magic link

### Cơ chế

```mermaid
sequenceDiagram
    participant U as Người dùng
    participant F as Frontend
    participant A as Backend
    participant M as Dịch vụ email

    U->>F: Nhập email
    F->>A: Yêu cầu liên kết
    A->>A: Sinh token ngẫu nhiên và mã 6 số
    A->>A: Lưu bản băm, gắn với định danh yêu cầu
    A->>M: Xếp hàng gửi (qua bảng chuyển tiếp)
    A-->>F: Luôn trả về thành công
    F-->>U: "Đã gửi, hãy kiểm tra hộp thư"
    M-->>U: Email chứa liên kết và mã

    alt Cùng thiết bị
        U->>F: Bấm liên kết
        F->>A: Xác thực token
        A-->>F: Cấp phiên đăng nhập
    else Thiết bị khác
        U->>F: Nhập mã 6 số
        F->>A: Xác thực mã kèm định danh yêu cầu
        A-->>F: Cấp phiên đăng nhập
    end
```

### Các thuộc tính bảo mật

| Thuộc tính | Cách làm | Vì sao |
|---|---|---|
| Token không lưu dạng rõ | Chỉ lưu bản băm | Rò rỉ cơ sở dữ liệu không cho phép đăng nhập |
| Dùng một lần | Đánh dấu đã dùng ngay khi xác thực | Chặn việc dùng lại liên kết đã bị chuyển tiếp |
| Thời hạn ngắn | Khoảng mười phút | Thu hẹp cửa sổ tấn công |
| Vô hiệu hàng loạt | Dùng một token thì các token chưa dùng của cùng email bị vô hiệu | Tránh tồn đọng nhiều liên kết còn hiệu lực |
| Không tiết lộ sự tồn tại | Luôn trả về thành công dù email có tài khoản hay không | Chặn việc dò danh sách email |
| Giới hạn tần suất | Theo email và theo địa chỉ IP | Chặn lạm dụng và chặn dùng hệ thống để gửi thư rác |
| Ràng buộc thiết bị | Token gắn với định danh yêu cầu sinh ra lúc gửi | Mở liên kết ở thiết bị khác thì phải nhập mã, giảm rủi ro bị lừa chuyển tiếp email |

### Vì sao bắt buộc có mã 6 số

Người dùng thường mở hộp thư trên điện thoại trong khi đang đăng nhập trên máy
tính. Nếu chỉ có liên kết, họ đăng nhập được trên điện thoại chứ không phải trên
thiết bị đang cần. **Đây không phải tính năng phụ mà là điều kiện để luồng đăng
nhập dùng được trong thực tế.**

### Phiên đăng nhập

| Thành phần | Tính chất |
|---|---|
| Token truy cập | Thời hạn ngắn, **chỉ mang claims cơ bản** |
| Token làm mới | Lưu dạng băm, xoay vòng mỗi lần dùng, gắn với một phiên cụ thể |
| Phiên | Ghi thiết bị, địa chỉ IP, lần truy cập gần nhất; người dùng xem và thu hồi được |

Phát hiện dùng lại token làm mới đã bị xoay vòng thì thu hồi toàn bộ phiên của
tài khoản đó — dấu hiệu token đã bị đánh cắp.

### Token truy cập chứa gì

Đây là **hợp đồng cố định**. Thêm bất cứ thứ gì ngoài danh sách bên trái đều phải
có lý do được ghi lại.

| Có trong token | Không bao giờ có trong token |
|---|---|
| Định danh `account` | Danh sách quyền hoặc mặt nạ quyền |
| Định danh phiên | Tên vai trò |
| Thời điểm phát hành và hết hạn | Danh sách workspace người dùng thuộc về |
| Loại token | Định danh `member` ở bất kỳ workspace nào |
| | Email hoặc thông tin cá nhân khác |

### Vì sao quyền không nằm trong token

Ba lý do, lý do đầu là lý do quyết định:

| Lý do | Diễn giải |
|---|---|
| **Không thu hồi được** | Đuổi một người khỏi workspace mà quyền nằm trong token thì họ vẫn giữ nguyên quyền cho tới khi token hết hạn. Rút ngắn thời hạn token chỉ làm hẹp cửa sổ chứ không đóng được nó |
| **Phình theo số workspace** | Một người thuộc mười workspace, mỗi nơi một vai trò và một tập project — nhét hết vào token thì token to hơn phần lớn request dùng nó |
| **Sai nguồn sự thật** | Token do client giữ và gửi lên. Bất cứ quyết định phân quyền nào dựa trên dữ liệu client gửi lên đều là quyết định dựa trên dữ liệu không đáng tin |

Hệ quả: **mặt nạ quyền luôn được tra lại phía server theo từng request.** Chi phí
của việc này được bù bằng cache, xem mục dưới.

---

## Token lời mời

**Token lời mời chính là một magic link.** Người bấm được liên kết trong hộp thư
của họ đã chứng minh sở hữu email đó, nên không cần thêm bước xác thực email nào
nữa. Người chưa có tài khoản đi thẳng từ email vào workspace.

Khác biệt duy nhất so với magic link thông thường: thời hạn dài hơn (khoảng một
tuần), và khi xác thực thì ngoài việc cấp phiên còn gắn `account` vào `member` đã
tạo sẵn.

Các nhánh xử lý đầy đủ: [uc-member-invite.md](../03-features/usecases/uc-member-invite.md).

---

## Phân quyền bằng mặt nạ bit

### Bố trí

Quyền chia hai nhóm theo phạm vi:

| Nhóm | Ví dụ |
|---|---|
| Cấp workspace | Quản trị workspace, mời thành viên, xoá thành viên, tạo project, sửa cấu hình |
| Cấp project | Xem issue, tạo issue, sửa issue, xoá issue, gán người, thực hiện bước chuyển, quản trị workflow, quản trị board, quản lý sprint |

### Tính quyền hiệu lực

```
mặt nạ hiệu lực = mặt nạ vai trò workspace
                ∪ mặt nạ vai trò project
                ∪ mặt nạ từ các group người dùng thuộc về
```

Kiểm tra một quyền là phép giao bit. Rẻ, và **đẩy được xuống tầng SQL** để lọc
danh sách trong một truy vấn duy nhất thay vì tải về rồi lọc.

### Ràng buộc về kích thước

Một số nguyên 64 bit chỉ an toàn cho khoảng 63 quyền. Riêng phần quản lý issue và
workflow đã chiếm phần lớn con số đó, chưa kể quyền cấp workspace.

**Phải thiết kế cho trường hợp vượt 64 bit ngay từ đầu** — nhiều phần ghép lại,
hoặc một kiểu chuỗi bit. Nếu bắt đầu bằng một số nguyên đơn rồi mới đổi thì phải
sửa mọi truy vấn đã viết.

### Vị trí bit là hợp đồng dữ liệu

**Không bao giờ đổi ý nghĩa hay dùng lại một vị trí bit đã cấp.** Quyền bị bỏ thì
để trống vị trí đó vĩnh viễn. Dùng lại một vị trí nghĩa là mọi vai trò đã lưu
trong cơ sở dữ liệu đột nhiên mang một quyền khác — và không có cách nào phát
hiện bằng test.

### Gỡ lỗi

Mặt nạ thô không đọc được bằng mắt. Cần một tiện ích giải mã mặt nạ thành danh
sách tên quyền, và **nhật ký phải ghi tên quyền, không ghi con số**.

---

## Kiểm tra quyền ở mọi hành động

Luật nền: **mọi hành động đều phải qua một lần kiểm tra mặt nạ bit.** Không có
hành động nào được miễn, và không có đường nào đi vòng qua bước này.

### Đường đi của một request

```mermaid
flowchart LR
    tok["Token truy cập<br/>→ account, session"] --> ws["Workspace<br/>lấy từ đường dẫn"]
    ws --> mem["Tra member<br/>= f(account, workspace)"]
    mem --> mask["Tra mặt nạ hiệu lực"]
    mask --> cache{"Có trong cache?"}
    cache -->|có| chk["Kiểm tra"]
    cache -->|không| db[("Tính lại từ<br/>cơ sở dữ liệu")] --> chk
    chk --> cond["Điều kiện phụ thuộc dữ liệu<br/>nếu quyền đó có"]
    cond --> act["Thực hiện hành động"]
```

Token chỉ đóng góp **bước đầu tiên**. Mọi thứ sau đó là dữ liệu phía server.

### Bốn chỗ bắt buộc kiểm tra

Kiểm tra ở controller là **chưa đủ**, vì một hành động có thể được kích hoạt từ
nhiều đường vào khác nhau.

| Chỗ | Kiểm tra gì | Vì sao không bỏ được |
|---|---|---|
| **Command và query handler** | Quyền tương ứng với hành động | Đây là chỗ duy nhất mọi đường vào đều đi qua: HTTP, tác vụ nền, quy tắc tự động, thao tác hàng loạt |
| **Truy vấn danh sách** | Điều kiện quyền ghép thẳng vào SQL | Lọc sau khi đã tải về vừa chậm vừa dễ sót; xem [NFR-07](../02-requirement/non-functional.md) |
| **Cấp scope đồng bộ** | Người dùng được nhận scope nào | Sai ở đây là gửi thẳng dữ liệu của người khác xuống máy client |
| **Quy tắc tự động** | Quyền của người mà quy tắc chạy dưới danh nghĩa | Nếu không, automation trở thành đường leo thang quyền |

Controller **không** phải là chỗ kiểm tra chính. Nó chỉ nên từ chối sớm những
trường hợp hiển nhiên để tiết kiệm công.

### Mặc định là từ chối

| Quy tắc | |
|---|---|
| Mỗi hành động khai báo **đúng một** quyền cần có | Không có hành động nào "không cần quyền" |
| Hành động không khai báo quyền thì **bị từ chối**, không phải được cho qua | Quên khai báo là lỗi hiển nhiên, không phải lỗ hổng âm thầm |
| Có test liệt kê mọi hành động và bắt lỗi khi có hành động chưa khai báo | Chỉ dựa vào review thì sớm muộn sẽ lọt |
| Danh mục quyền nằm ở **một chỗ duy nhất** | Để đối chiếu được với vị trí bit đã cấp |

### Một điểm vào duy nhất

Mọi lời gọi kiểm tra đi qua cùng một hàm, và hàm đó nhận **cả ngữ cảnh dữ liệu**
chứ không chỉ nhận mặt nạ:

```
require(permission, context)
```

`context` mang workspace, project, và đối tượng bị tác động khi có. Nhờ đó tầng
[permission condition](#permission-condition) cắm vào được mà không phải sửa chỗ gọi.

**Đây là lý do chỗ nối phải có ngay từ Phase 1**, dù chưa hiện thực điều kiện nào.
Thêm tham số `context` sau nghĩa là sửa mọi lời gọi kiểm tra quyền trong toàn hệ thống.

### Cache mặt nạ

| | |
|---|---|
| Khoá | Theo cặp người dùng và phạm vi (workspace hoặc project) |
| Nơi lưu | Redis, có đường dự phòng tính lại từ cơ sở dữ liệu |
| Thời hạn | Ngắn — cache chỉ để giảm tải, **không phải** để giảm độ trễ thu hồi |
| Xoá cache | Ngay khi vai trò đổi, thành viên bị thêm hoặc bớt, group đổi thành viên, hoặc permission scheme đổi |

**Xoá cache luôn đi kèm phát sự kiện thu hồi cho sync engine.** Xoá cache mà không
báo cho client thì server đã chặn nhưng client vẫn giữ nguyên dữ liệu đã tải về.

### Mặt nạ ở phía client chỉ là gợi ý giao diện

Client **cũng** nhận mặt nạ của chính nó qua scope đồng bộ, để ẩn hoặc vô hiệu hoá
nút bấm và để làm được việc đó khi offline.

> ⚠️ Mặt nạ phía client **không phải** là biện pháp kiểm soát. Nó chỉ quyết định
> giao diện trông thế nào. Server kiểm tra lại mọi hành động, và **không bao giờ**
> đọc mặt nạ từ dữ liệu client gửi lên.

Hệ quả thực tế: một mutation lạc quan có thể bị server từ chối vì thiếu quyền dù
giao diện đã cho bấm — ví dụ quyền vừa bị thu hồi mà client chưa nhận được tin.
Đường xử lý là hoàn tác và báo lý do, giống mọi mutation bị từ chối khác.

### Những cách làm sai

| Sai | Vì sao |
|---|---|
| Đọc vai trò hoặc quyền từ token | Dữ liệu do client giữ; và không thu hồi được |
| Nhận mặt nạ hoặc vai trò từ tham số của request | Client tự khai quyền cho mình |
| Chỉ kiểm tra ở controller | Tác vụ nền, automation và thao tác hàng loạt đi đường khác |
| Chỉ ẩn nút ở giao diện | Không phải kiểm soát, chỉ là trang trí |
| Tải danh sách về rồi lọc ở tầng ứng dụng | Chậm, và dễ sót ở nhánh phân trang hoặc đếm số lượng |
| Bỏ qua kiểm tra vì "hành động này ai cũng làm được" | Vẫn phải khai báo một quyền, kể cả quyền mà mọi vai trò đều có |

### Ghi nhận

Mọi lần **từ chối** vì thiếu quyền đều được ghi nhật ký kèm người thực hiện, hành
động, phạm vi và quyền còn thiếu. Nhật ký ghi **tên quyền**, không ghi giá trị số.

Một chuỗi từ chối liên tiếp của cùng một người là tín hiệu đáng xem: hoặc giao
diện đang hiển thị sai, hoặc có người đang dò tìm.

---

## Permission condition

Mặt nạ bit không biểu diễn được quyền phụ thuộc dữ liệu: "chỉ sửa issue mình
tạo", "chỉ xem issue của team mình". Đó không phải một bit.

Giải pháp: một tầng mỏng chạy **sau** khi mặt nạ đã cho phép.

```
kiểm tra quyền = mặt nạ cho phép
                 VÀ mọi điều kiện gắn với quyền đó đều thoả
```

Các điều kiện dự kiến: chỉ người báo cáo, chỉ người được gán, chỉ người dẫn dắt
project, chỉ thành viên của một group.

**Chỗ nối cho tầng này phải có ngay từ Phase 1**, dù chưa hiện thực điều kiện
nào. Nghĩa là mọi lời gọi kiểm tra quyền đi qua một điểm vào duy nhất nhận cả
ngữ cảnh dữ liệu, không phải chỉ nhận mặt nạ. Thêm vào sau nghĩa là sửa mọi chỗ
gọi trong toàn bộ hệ thống.

---

## Bốn vai trò mặc định

| Vai trò | Phạm vi |
|---|---|
| `OWNER` | Toàn quyền, gồm xoá workspace và chuyển quyền sở hữu. Luôn phải có ít nhất một |
| `ADMIN` | Quản trị workspace, mời và xoá thành viên, tạo project |
| `MEMBER` | Tham gia các project được cấp quyền |
| `GUEST` | **Chỉ** thấy project được mời đích danh; không thấy danh bạ thành viên workspace |

### Vì sao `GUEST` phải có từ Phase 1

`GUEST` là ca kiểm thử buộc hệ thống **không được giả định** rằng thành viên
workspace thì thấy mọi project, và không được giả định rằng ai cũng nhận được
scope workspace đầy đủ.

Nếu Phase 1 bỏ qua vai trò này, giả định sai sẽ nằm rải khắp code — trong truy
vấn danh sách project, trong ô chọn người, trong việc cấp scope đồng bộ — và
Phase sau sẽ phải đi gỡ từng chỗ.

---

## Liên kết với sync engine

Bốn sự kiện nối phân quyền với đồng bộ, phải được xử lý ngay từ Phase 0:

| Sự kiện | Client phải làm gì |
|---|---|
| Thành viên được thêm vào project hoặc workspace | Mở đăng ký scope mới và tải trạng thái ban đầu |
| Thành viên bị xoá | **Xoá sạch dữ liệu cục bộ của scope đó**, huỷ mutation đang chờ thuộc scope, điều hướng khỏi màn hình đang mở |
| Vai trò thay đổi theo hướng thu hẹp | Xử lý như bị xoá đối với những scope không còn quyền |
| Lời mời được chấp nhận | Cập nhật danh bạ thành viên trong scope workspace |
