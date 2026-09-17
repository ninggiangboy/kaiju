# ADR-0014: Hạ tầng khai báo bằng OpenTofu, Ansible và Argo CD; bậc 4 triển khai theo GitOps

- **Trạng thái:** Accepted — phần cơ chế thăng cấp được thay thế bởi [ADR-0015](0015-branch-per-environment.md)
- **Đã thay đổi (2026-09-18):** quyết định bốn lớp công cụ và GitOps vẫn giữ nguyên. Riêng cách thăng cấp thì không: thay vì mọi môi trường cùng đọc một nhánh và sửa thẻ ảnh trong overlay của từng môi trường, **mỗi môi trường nay là một nhánh riêng**. Lý do ở [ADR-0015](0015-branch-per-environment.md)
- **Ngày:** 2026-09-18
- **Liên quan:** [ADR-0005](0005-outbox-db-job.md), [ADR-0013](0013-explicit-two-way-migration.md), [environments.md](../04-system-design/environments.md), [ci-cd.md](../04-system-design/ci-cd.md)

## Bối cảnh

Trước quyết định này, toàn bộ phần vận hành nằm ở ba chỗ rời nhau và không chỗ nào
chạy được thật:

- `infra/Makefile` chạy được mọi thứ, nhưng **chỉ trên máy cá nhân**
- `infra/scripts/deploy-staging.sh` phải SSH vào đúng máy chủ đó mới gọi được
- Hai công việc triển khai trong `release.yml` đều dừng ở `exit 1` vì chưa có
  thông tin xác thực

Không có gì để tạo máy chủ, tạo cơ sở dữ liệu quản lý sẵn, tạo kho đối tượng hay
cấu hình dịch vụ gửi thư. Không có gì để thêm hay bớt một node của cụm. Và không
có chỗ nào trả lời được câu hỏi "bậc 4 đang chạy thẻ ảnh nào".

Câu hỏi đặt ra: xây một trung tâm điều khiển riêng, hay dùng công cụ sẵn có.

## Quyết định

Không xây trung tâm điều khiển riêng. Dùng **bốn lớp công cụ, mỗi lớp sở hữu một
thứ và không lấn sang nhau**:

| Lớp | Sở hữu | Dấu hiệu nhận biết |
|---|---|---|
| **OpenTofu** | Tài nguyên hạ tầng có vòng đời riêng: mạng, cơ sở dữ liệu quản lý sẵn, kho đối tượng, dịch vụ gửi thư, cụm, nhóm node | Mất đi là mất dữ liệu |
| **Ansible** | Cấu hình **bên trong** một máy đã tồn tại: máy chủ bậc 3, việc gắn một node vào cụm | Cài lại được |
| **Argo CD** | Mọi đối tượng chạy trong cụm ở bậc 4 | Trạng thái mong muốn nằm trong git |
| **Makefile và `infra/scripts/`** | Bậc 1-2, và các thao tác một lần do người chủ động gọi | Người bấm, không tự chạy |

**Bậc 4 triển khai theo GitOps.** Pipeline không gọi lệnh mệnh lệnh nào vào cụm.
Nó mở một pull request sửa thẻ ảnh trong overlay; **merge pull request đó chính là
hành động triển khai**, và cũng là cổng duyệt duy nhất.

**Bậc 3 không theo GitOps** vì nó chạy compose trên một máy chủ đơn chứ không phải
Kubernetes. Nó triển khai bằng Ansible gọi lại đúng trình tự của
`deploy-staging.sh`.

Dùng **OpenTofu** chứ không phải Terraform, vì lý do giấy phép.

## Lý do

- **Trạng thái mong muốn nằm trong git thì không cần nơi lưu trạng thái nào khác.**
  "Production đang chạy gì" là một commit, quay lui là `git revert`, nhật ký kiểm
  toán là `git log`. Toàn bộ phần này có sẵn, không phải xây.
- **Sync wave của Argo CD cưỡng chế được thứ tự triển khai bắt buộc** (CON-69).
  Trước đây thứ tự đó chỉ là một chú thích trong shell script và một dòng `echo`
  trong pipeline — tức là không có gì bảo đảm. Nay migration là `PreSync` hook,
  `worker` và `scheduler` ở wave 1, `api` và `realtime` ở wave 2; engine từ chối
  làm sai thứ tự.
- **Cổng duyệt nhìn được dưới dạng một diff.** Một nút "Approve" trong giao diện
  pipeline không nói cho ai biết là đang đi từ thẻ nào sang thẻ nào. Một pull
  request sửa một dòng thì nói.
- **Bốn lớp tách rời làm cho câu hỏi "sửa cái này ở đâu" luôn có đúng một câu trả
  lời.** Đây là lý do chính để không gộp chúng lại.
- OpenTofu và Ansible đều là công cụ phổ thông, không phải thứ tự viết phải tự bảo
  trì.

## Hệ quả

- **OpenTofu tuyệt đối không tạo đối tượng Kubernetes.** Không dùng provider
  `kubernetes` cho `Deployment` hay `Service`. Vi phạm điều này thì Argo CD và
  OpenTofu cùng tranh quyền sở hữu một đối tượng, sinh ra vòng lặp "Argo đồng bộ
  về, tofu áp đè lại" rất khó gỡ khi đã chạy thật.
- **Makefile và script không bao giờ ghi vào trạng thái mong muốn của bậc 3-4.**
  Chúng được đọc và được thao tác ở bậc 1-2. Không có `make deploy-production`:
  có nó là có hai thứ cùng đổi được production và chúng sẽ bất đồng.
- **Hai bậc triển khai bằng hai cơ chế khác nhau**, và đó là cái giá phải trả cho
  việc bậc 3 cố tình là một máy chủ đơn. Trình tự nghiệp vụ thì giống hệt nhau ở
  cả hai, chỉ khác thứ thi hành nó.
- **Tệp trạng thái của OpenTofu chứa bí mật** ở dạng đọc được: mật khẩu cơ sở dữ
  liệu, chuỗi kết nối, khoá truy cập. Nó phải nằm ở backend từ xa có mã hoá và
  không bao giờ được commit — cùng một luật với mọi bí mật khác của dự án.
- Có bài toán quả trứng con gà lúc khởi đầu: backend lưu trạng thái phải tồn tại
  trước khi OpenTofu chạy được lần đầu. Tạo tay một lần, và ghi lại trong
  `infra/README.md`.
- **Việc thêm hay bớt node phụ thuộc vào loại cụm.** Cụm quản lý sẵn thì đổi một
  số trong OpenTofu. Cụm tự quản thì OpenTofu tạo máy ảo rồi Ansible gắn nó vào.
  Bớt node luôn theo thứ tự: rút tải khỏi node, xoá node khỏi cụm, rồi mới huỷ máy.
- Argo CD tự mang theo một Redis nội bộ của riêng nó. Điều đó **không** vi phạm
  CON-03 và CON-04: hai ràng buộc ấy nói về kho dữ liệu của **ứng dụng**, không
  nói về thành phần vận hành. Ghi rõ ở đây để không phải tranh luận lại.
- Phạm vi của [ADR-0005](0005-outbox-db-job.md) không đổi. Dịch vụ gửi thư có thể
  báo lại thư hỏng và thư bị phàn nàn qua một cơ chế thông báo của nhà cung cấp;
  đó là webhook đến từ bên thứ ba, **không phải** kênh giao tiếp giữa các module,
  nên nó không mở lại quyết định "không dùng message broker".

## Phương án đã loại

**Pipeline tự gọi `kubectl set image`.** Đây là cách đang được phác trong
`release.yml`. Loại vì ba lý do: không có nơi nào ghi lại cụm đang chạy gì ngoài
chính cụm đó; quay lui phải dò lại thẻ ảnh cũ bằng tay; và thứ tự triển khai bắt
buộc lại tiếp tục chỉ là một chuỗi lệnh xếp cạnh nhau, không ai cưỡng chế.

**Argo CD Image Updater tự đẩy thẻ ảnh mới.** Loại vì nó biến triển khai
production thành hệ quả tự động của việc dựng ảnh, đúng thứ mà
[ci-cd.md](../04-system-design/ci-cd.md#đường-đi-lên-các-bậc) đã cố tình tránh:
phát hành là một hành động có chủ đích.

**Helm thay cho Kustomize.** Loại vì overlay hiện tại đã đủ và đang chạy, còn
Helm thêm một tầng template vào giữa thứ đã khai báo sẵn. Kustomize cũng cho phép
`kubectl kustomize` kiểm tra tại chỗ, thứ mà `make check-k8s` đang dùng.

**Terraform Cloud hoặc một nền tảng nội bộ dạng dịch vụ.** Loại vì dự án một
người không trả nổi chi phí vận hành của chúng, và vì chúng kéo trạng thái ra khỏi
git — đúng cái mà quyết định này muốn đưa vào.

**Viết một trung tâm điều khiển riêng có giao diện.** Loại vì Argo CD đã có sẵn
giao diện xem mọi môi trường, drift và nút quay lui. Tự viết nghĩa là bảo trì một
sản phẩm thứ hai bên cạnh sản phẩm chính.
