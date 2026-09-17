# infra/

Bốn bậc môi trường và những gì cần để dựng chúng. Lý do từng bậc tồn tại và
loại lỗi mà **chỉ bậc đó** bắt được nằm ở
[environments.md](../docs/04-system-design/environments.md).

---

## Bắt đầu

```bash
cd infra
make up        # bậc 1 — đủ để chạy backend và bộ test
make up-dev    # bậc 2 — thêm phần vận hành
make check     # toàn bộ kiểm tra tĩnh, giống hệt CI
```

`make` không có tham số sẽ liệt kê mọi lệnh.

---

## Bốn bậc

| Bậc | Dựng bằng | Chỉ nó bắt được |
|---|---|---|
| `local-mini` | `compose/docker-compose.yml` | Mọi thứ **không** liên quan tới môi trường: logic, migration, biên giới module |
| `dev` | thêm `compose/docker-compose.dev.yml` | Vi phạm trạng thái phiên, luồng đồng bộ bị đệm, chuỗi lần vết đứt, vai trò thiếu cấu hình khi chạy tách rời |
| `staging` | `staging/docker-compose.yml` trên một VPS | Hành vi của **dịch vụ thật**: thư vào hộp thư rác, liên kết có chữ ký, TLS và tên miền thật |
| `production` | `k8s/overlays/production` | Nhiều bản cùng vai trò: tranh chấp cấp số thứ tự, khoá chống chạy trùng, phát tán giữa nhiều bản, triển khai cuốn chiếu |

**Cùng một ảnh chạy ở cả bốn** (`CON-66`). Vai trò chọn bằng `KAIJU_ROLE`, khác
biệt còn lại nằm ở biến môi trường. Không có nhánh code nào rẽ theo tên môi
trường (`CON-67`).

---

## Cổng ở máy phát triển

| | Bậc 1 | Bậc 2 |
|---|---|---|
| Cơ sở dữ liệu | 5432 | 5432 (thẳng) và **6432** (qua bộ gộp) |
| Máy chủ giao thức Redis | 6379 | 6379 |
| Thư — giao diện web | **8025** | 8025 |
| Lưu trữ đối tượng — giao diện | 9001 | 9001 |
| Ứng dụng qua máy chủ trung gian | — | **8080** |
| Quan sát hệ thống — giao diện | — | **3001** |

Cổng quan sát là 3001 chứ không phải 3000 vì 3000 để dành cho Next.

---

## Hai chi tiết dễ làm sai

### `KAIJU_DB_URL` và `KAIJU_DB_LISTEN_URL` là hai biến khác nhau

Ở bậc 1 chúng trỏ cùng một nơi, và **vẫn phải tách**. Ở bậc 2 trở đi, đường
ghi/đọc thường đi qua bộ gộp kết nối còn kết nối lắng nghe thông báo đi **thẳng**
tới cơ sở dữ liệu — ở chế độ gộp theo giao dịch, cơ chế lắng nghe không bao giờ
hoạt động qua bộ gộp (`CON-25`).

Viết tách ngay từ dòng code đầu tiên, không phải thêm vào lúc triển khai bộ gộp.

### Tắt đệm cho luồng đồng bộ

Đó là lý do tồn tại của `proxy/Caddyfile.*` và của chú thích
`proxy-buffering: off` trong `k8s/base/ingress.yaml`. Cấu hình sai ở chỗ này
**không sinh ra lỗi nào** — triệu chứng duy nhất là "realtime không chạy".

`scripts/smoke.sh` có một kiểm tra dành riêng cho nó.

---

## Bí mật

Không bí mật thật nào nằm trong repository, **kể cả cho bậc 1**.

| Bậc | Bí mật đến từ |
|---|---|
| 1, 2 | Giá trị giả trong `env/*.env.example`; cụm cơ sở dữ liệu bị vứt đi mỗi lần dựng lại |
| 3 | `/etc/kaiju/staging.env` trên máy chủ, quyền `600` |
| 4 | Secret `kaiju-secrets` của nền tảng điều phối |

Thiếu một biến bắt buộc thì ứng dụng **dừng ngay lúc khởi động**. Chết sớm còn
hơn chạy sai âm thầm.

---

## Cây thư mục

```
infra/
├── Makefile                      # mọi lệnh, chạy được từ máy cá nhân
├── compose/
│   ├── docker-compose.yml        # bậc 1
│   └── docker-compose.dev.yml    # bậc 2, chồng lên bậc 1
├── staging/
│   ├── docker-compose.yml        # bậc 3, một VPS
├── k8s/
│   ├── base/                     # bậc 4, bốn vai trò + công việc migration
│   └── overlays/{staging,production}/
├── docker/                       # Dockerfile của backend và frontend
├── proxy/                        # Caddyfile.dev và Caddyfile.staging
├── pgbouncer/                    # cấu hình bộ gộp, dùng chung với CI
├── postgres/init/                # chỉ bật phần mở rộng, không có cấu trúc bảng
├── scripts/                      # deploy-staging.sh, smoke.sh
└── env/                          # tệp mẫu cho cả bốn bậc, chỉ giá trị giả
```

Quy trình CI và đường đi từ commit lên các bậc:
[ci-cd.md](../docs/04-system-design/ci-cd.md).
