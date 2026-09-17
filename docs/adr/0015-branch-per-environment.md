# ADR-0015: Mỗi môi trường là một nhánh, thăng cấp bằng pull request giữa các nhánh

- **Trạng thái:** Accepted
- **Ngày:** 2026-09-18
- **Liên quan:** [ADR-0014](0014-declarative-infra-gitops.md) (thay thế phần cơ chế thăng cấp), [ci-cd.md](../04-system-design/ci-cd.md)

## Bối cảnh

[ADR-0014](0014-declarative-infra-gitops.md) chốt GitOps cho bậc 4 và mô tả cơ
chế thăng cấp như sau: mọi môi trường cùng đọc một nhánh, mỗi môi trường có một
overlay riêng, và triển khai là một pull request sửa thẻ ảnh **trong overlay của
môi trường đó**.

Khi dựng repository thật thì lộ ra hai điểm cơ chế đó không trả lời được:

1. **Không có chỗ nào ghi lại một môi trường đang ở commit nào.** Overlay ghi
   được thẻ ảnh, nhưng thẻ ảnh không phải là toàn bộ trạng thái — manifest,
   cấu hình, ngưỡng mở rộng đều có thể đổi mà thẻ ảnh không đổi. Hai môi trường
   cùng đọc một nhánh nghĩa là mọi thay đổi **không phải thẻ ảnh** lập tức có
   hiệu lực ở cả hai, cùng lúc, không qua bước thăng cấp nào.
2. **`staging` bị chặn sau thẻ phiên bản.** Nó chỉ nhận thay đổi khi có người
   gắn thẻ phát hành, tức là luôn đi *sau* thời điểm đã sẵn sàng phát hành —
   trong khi lý do tồn tại của bậc 3 là bắt lỗi **trước** thời điểm đó.

## Quyết định

**Mỗi môi trường là một nhánh dài hạn.** Thăng cấp là pull request từ nhánh này
sang nhánh kế tiếp:

```
dev ──PR──> staging ──PR──> production
```

- `dev` là nhánh phát triển, và là nơi pipeline ghim thẻ ảnh mới sau khi dựng
- Merge vào `staging` **là** hành động triển khai bậc 3
- Merge vào `production` **là** hành động triển khai bậc 4

Argo CD trỏ `targetRevision` của mỗi Application vào nhánh tương ứng.

**Thẻ ảnh quay về `k8s/base/kustomization.yaml`**, một giá trị cho mỗi nhánh.
Overlay chỉ còn giữ thứ thật sự khác nhau giữa các môi trường: namespace, số bản
chạy, tên miền.

## Lý do

- **Nhánh ghi lại được toàn bộ trạng thái, không chỉ thẻ ảnh.** Đổi ngưỡng mở
  rộng hay sửa manifest giờ cũng phải đi qua thăng cấp như mọi thay đổi khác,
  thay vì có hiệu lực ngay ở mọi môi trường.
- **Diff của pull request thăng cấp là đúng thứ sắp xảy ra**, gồm cả thay đổi
  không phải thẻ ảnh. Cơ chế cũ giấu mất chúng.
- **`staging` không còn bị chặn sau thẻ phát hành.** Merge vào `staging` là đủ,
  nên bậc 3 lại làm đúng việc của nó là bắt lỗi sớm.
- Thẻ ảnh nằm ở `base` thì nó đi theo nhánh một cách tự nhiên khi merge, không
  cần ai chép giá trị giữa hai overlay.

## Hệ quả

- **Ba nhánh dài hạn không bao giờ bị xoá**, và không bao giờ force-push. Chúng
  là bản ghi trạng thái môi trường chứ không phải nhánh làm việc.
- **`production` có thể tụt lại sau `dev` khá xa**, và điều đó là bình thường —
  đó chính là thứ mà cơ chế cũ không biểu diễn được.
- **Phải merge tuần tự.** Đưa thẳng `dev` vào `production` là bỏ qua bậc 3, và
  không có gì kỹ thuật ngăn việc đó ngoài quy tắc bảo vệ nhánh. Cấu hình bảo vệ
  nhánh phải yêu cầu `production` chỉ nhận pull request từ `staging`.
- **Quay lui vẫn là `git revert` merge commit** trên nhánh của môi trường đó.
  Không đổi so với ADR-0014.
- Pipeline tự commit một lần ghim thẻ ảnh lên `dev`. Commit đó phải được loại
  khỏi điều kiện kích hoạt workflow, nếu không nó tự gọi lại chính nó vô hạn.
- Hai overlay vẫn tồn tại và vẫn cần thiết, nhưng **không còn chứa thẻ ảnh**.

## Phương án đã loại

**Giữ nguyên cơ chế của ADR-0014.** Loại vì hai vấn đề nêu ở phần bối cảnh: nó
chỉ thăng cấp được thẻ ảnh, và nó buộc `staging` chờ thẻ phát hành.

**Một nhánh, thư mục môi trường, thăng cấp bằng cách chép thư mục.** Đây là
phương án mà tài liệu của Argo CD thường khuyến nghị thay cho nhánh môi trường.
Loại vì nó chép cấu hình thành nhiều bản trong cùng một cây thư mục, và bản chép
sẽ phân kỳ âm thầm — đúng loại lỗi mà overlay sinh ra để tránh. Khuyến nghị đó
nhắm vào trường hợp **manifest giữa các môi trường khác nhau nhiều**; ở đây
chúng gần như giống hệt, chỉ khác namespace, số bản chạy và tên miền.

**Argo CD Image Updater.** Đã loại ở [ADR-0014](0014-declarative-infra-gitops.md)
và lý do không đổi: nó biến triển khai thành hệ quả tự động của việc dựng ảnh.
