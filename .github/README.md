# .github/

Quy trình tích hợp liên tục. Thiết kế và lý do từng kiểm tra tồn tại:
[ci-cd.md](../docs/04-system-design/ci-cd.md).

| Tệp | Chạy khi |
|---|---|
| `workflows/ci.yml` | Mỗi pull request và mỗi lần đẩy lên `main` hoặc `dev` |
| `workflows/release.yml` | Đẩy lên `main` (chỉ dựng ảnh) và mỗi thẻ phiên bản (dựng và triển khai) |
| `workflows/security.yml` | Hằng tuần, và khi tệp khai báo phụ thuộc thay đổi |
| `workflows/pr-hygiene.yml` | Mỗi lần sửa tiêu đề pull request |
| `scripts/check-docs.py` | Trong `ci.yml`, và bằng tay: `make -C infra check-docs` |

---

## Hai điều dễ làm sai

### Cổng là kiểm tra bắt buộc duy nhất

Cấu hình bảo vệ nhánh chỉ khai báo **`Cổng`**, không khai báo từng công việc.
Nhờ vậy thêm một kiểm tra mới vào pipeline không phải sửa cấu hình đó.

### Công việc bị bỏ qua là THẤT BẠI

Trừ khi thư mục tương ứng không thay đổi (`CON-71`). Mặc định của phần lớn cấu
hình CI coi công việc bị bỏ qua là đã qua; kết hợp với một bộ lọc đường dẫn viết
sai, đó là cách một thay đổi backend merge được mà chưa chạy test nào.

Cổng cũng chặn theo chiều ngược lại: một công việc **chạy** dù thư mục của nó
không đổi cũng là bộ lọc sai, và cũng bị báo.

---

## Chạy tại chỗ

Mọi kiểm tra tĩnh chạy được từ máy cá nhân (`CON-72`):

```bash
make -C infra check
```

Riêng phần cú pháp của chính các quy trình:

```bash
actionlint
```

---

## Trạng thái

Các công việc backend và frontend **bị bỏ qua cho tới khi `backend/` và
`frontend/` tồn tại** — bộ lọc đường dẫn không khớp gì, nên chúng không chạy và
cổng tính đó là hợp lệ. Hôm nay chỉ `Tài liệu` và `Hạ tầng` thật sự chạy.

Hai bước triển khai trong `release.yml` cố ý **dừng với mã lỗi** và in ra đúng
lệnh cần chạy: chúng cần bí mật truy cập máy chủ và cụm, vốn chưa tồn tại. Để
chúng "thành công" mà không làm gì là cách tệ nhất — nó báo triển khai xong
trong khi không có gì được triển khai.
