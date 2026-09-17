# ADR-0016: Nhánh làm việc ngắn hạn, merge commit ở mọi cấp, và một ngoại lệ cho quay lui

- **Trạng thái:** Accepted
- **Ngày:** 2026-09-18
- **Liên quan:** [ADR-0015](0015-branch-per-environment.md) (bổ sung nửa còn lại của dòng chảy), [git-flow.md](../04-system-design/git-flow.md), [ci-cd.md](../04-system-design/ci-cd.md)

## Bối cảnh

[ADR-0015](0015-branch-per-environment.md) chốt ba nhánh môi trường và cách thăng
cấp giữa chúng. Nhưng nó chỉ mô tả **nửa bên phải** của dòng chảy — từ `dev` trở
đi. Nửa bên trái, tức là code đi vào `dev` bằng đường nào, chưa có gì quy định.

Khi dựng repository thật thì ba câu hỏi lộ ra, và cả ba đều không có câu trả lời
mặc định an toàn:

1. **Nhánh làm việc tên là gì và sống bao lâu.** Không có quy ước thì tên nhánh
   trở thành ghi chú cá nhân, và không có cách nào kiểm tra tự động.
2. **Merge kiểu gì.** GitHub bật sẵn cả ba kiểu merge, và người bấm nút chọn kiểu
   nào là tuỳ lúc. Ở mô hình nhánh môi trường thì đây không phải chuyện thẩm mỹ:
   squash và rebase đều **sinh commit mới với mã băm mới**, nên nhánh nguồn thôi
   không còn là tổ tiên của nhánh đích. Lần thăng cấp kế tiếp sẽ thấy lại toàn bộ
   thay đổi cũ như thể chúng chưa từng được merge.
3. **Quay lui đi đường nào.** Đây là chỗ nghiêm trọng nhất: kiểm tra
   `Promotion order` chặn mọi pull request vào `production` không đến từ
   `staging`. Một pull request quay lui đến từ nhánh khác **cũng bị chặn**. Tức
   là ở trạng thái hiện tại, cơ chế an toàn quan trọng nhất của bậc 4 không có
   đường thi hành.

## Quyết định

Ba phần.

### 1. Mọi thay đổi đi qua một nhánh ngắn hạn cắt từ `dev`

Tên nhánh có dạng `<type>/<slug>`, trong đó `type` lấy đúng tập hợp type của
Conventional Commits mà `pr-hygiene.yml` đã dùng cho tiêu đề pull request:
`feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `build`, `ci`,
`infra`. Nhánh được xoá ngay sau khi merge.

Ngoại lệ duy nhất là **commit ghim thẻ ảnh** do pipeline đẩy thẳng lên `dev`.

### 2. Merge commit ở mọi cấp

Squash merge và rebase merge bị **tắt ở cấp repository**, không phải chỉ khuyến
nghị trong tài liệu. Cả ba cấp — vào `dev`, vào `staging`, vào `production` — đều
tạo merge commit.

### 3. `rollback/*` là ngoại lệ duy nhất của thứ tự thăng cấp

Một nhánh tên `rollback/*` được phép mở pull request thẳng vào bất kỳ nhánh môi
trường nào. Kèm theo đó là một **nghĩa vụ bắt buộc**: commit revert ấy phải được
đưa về `dev`, và việc đưa thay đổi trở lại sau này là revert của revert.

## Lý do

**Vì sao không squash.** Quy ước của dự án là commit theo từng giai đoạn công
việc, không gộp thành một commit lớn (`CON-50` và nguyên tắc trong `CLAUDE.md`).
Squash merge làm đúng cái việc mà quy ước ấy cấm, chỉ là làm ở bước cuối. Cả
nhánh trở thành một commit và toàn bộ trình tự suy nghĩ biến mất.

**Vì sao không rebase merge.** Nó giữ được từng commit nhưng xoá mất ranh giới
pull request, nên không còn trả lời được "thay đổi này vào theo pull request
nào". Và nó đổi mã băm, tức là dính đúng vấn đề nêu ở phần bối cảnh.

**Vì sao merge commit ở cả ba cấp, chứ không phải chỉ ở cấp thăng cấp.** Để
`git revert -m 1 <merge>` là **một luật duy nhất** áp ở mọi nơi. Nếu `dev` dùng
squash còn nhánh môi trường dùng merge commit thì có hai cơ chế quay lui khác
nhau, và người ta sẽ nhớ nhầm cái này thành cái kia đúng vào lúc đang có sự cố.

**Vì sao quay lui được miễn thứ tự thăng cấp.** `Promotion order` tồn tại để chặn
**code chưa qua bậc 3** lọt vào bậc 4. Một commit revert không mang code mới nào
— nó đưa `production` về đúng trạng thái mà chính `production` vừa chạy vài phút
trước. Bắt nó đi vòng `dev` → `staging` → `production` nghĩa là cộng thêm hai lượt
CI và một lần triển khai bậc 3 vào thời gian sự cố, để đổi lấy sự an toàn của một
trạng thái vốn đã được kiểm chứng bằng chính việc nó từng chạy thật.

Đây cũng là lý do ngoại lệ này **chỉ dành cho revert**, không dành cho bản vá
khẩn. Bản vá khẩn là code mới, và code mới thì không có ngoại lệ nào.

## Hệ quả

- **Lịch sử `dev` là hình bện, không thẳng.** Đọc theo dòng chính bằng
  `git log --first-parent`. Đây là cái giá đã biết trước của việc giữ lại từng
  commit và đồng thời giữ ranh giới pull request.

- **Cái bẫy revert-của-merge.** Sau khi `git revert -m 1` trên `production`, lần
  merge `staging` → `production` kế tiếp sẽ **không** mang các thay đổi ấy trở
  lại, vì chúng đã là tổ tiên của `production` rồi — git không có gì để merge.
  Đây chính là lý do bước đưa revert về `dev` là bắt buộc chứ không phải dọn dẹp
  cho gọn: thiếu nó thì `dev` và `production` phân kỳ theo cách mà không ai nhìn
  thấy cho tới lần phát hành sau.

- **Pull request thăng cấp có thể xung đột sau một lần quay lui**, cho tới khi
  revert đã đi hết vòng về `dev` rồi lên lại.

- **Nhánh làm việc được rebase thoải mái khi chưa merge**; ba nhánh môi trường
  thì không bao giờ.

- **`dev` không thể có kiểm tra bắt buộc**, vì pipeline đẩy commit ghim thẻ ảnh
  thẳng lên nó và kiểm tra bắt buộc sẽ chặn cả những lần đẩy như vậy. Nên kiểm
  tra tên nhánh hiện đỏ trên pull request nhưng không chặn merge. Xem
  [git-flow.md](../04-system-design/git-flow.md#những-thứ-không-cưỡng-chế-được).

## Phương án đã loại

**Squash merge vào `dev`.** Đây là mặc định phổ biến nhất và cho lịch sử sạch
nhất. Loại vì nó mâu thuẫn trực tiếp với quy ước commit theo giai đoạn, và vì nó
tạo ra hai cơ chế quay lui khác nhau trong cùng một repository.

**Lịch sử tuyến tính bằng rebase merge ở mọi cấp.** Loại vì đổi mã băm làm hỏng
quan hệ tổ tiên giữa các nhánh môi trường, vốn là thứ toàn bộ ADR-0015 dựa vào.

**GitFlow đầy đủ** với `develop`, `release/*` và `hotfix/*`. Loại vì trùng vai
trò: `release/*` chính là thứ `staging` đang làm, và `hotfix/*` chính là
`rollback/*` cộng với một bản vá đi đường thường. Thêm hai loại nhánh nữa chỉ để
diễn đạt lại thứ đã có.

**Trunk-based thuần, một nhánh, bật tắt bằng feature flag.** Loại vì nó bỏ hẳn
nhánh môi trường, tức là đảo ngược ADR-0015. Cơ chế feature flag cũng là một hệ
thống phải xây và phải bảo trì, trong khi vấn đề nó giải quyết ở đây chưa tồn tại.

**Bắt quay lui đi vòng `dev` → `staging` → `production` như mọi thay đổi khác.**
Nhất quán hơn, và đúng là tránh được cái bẫy revert-của-merge một cách tự nhiên.
Loại vì nó kéo dài thời gian sự cố để bảo vệ trước một rủi ro không có thật —
revert không mang code mới. Cái bẫy được xử lý bằng nghĩa vụ đưa revert về `dev`.
