# Kaiju

Hệ quản lý dự án kiểu Jira, xây dựng theo hướng **local-first** và **realtime**.

Tài liệu đầy đủ ở [`docs/`](docs/README.md). File này chỉ liệt kê các **luật bất
biến** để không phải đọc hết tài liệu trước mỗi thay đổi.

---

## Cấu trúc repository

```
kaiju/
├── docs/        # tài liệu
├── backend/     # Spring Boot, Gradle multi-module
├── frontend/    # Next.js
└── infra/       # Docker Compose, Dockerfile, reverse proxy, script vận hành
```

Không tạo thêm thư mục ở cấp cao nhất.

---

## Nguyên tắc phát triển

**Làm từng tính năng một, nhưng mỗi tính năng phải đầy đủ.** Không làm sơ sài rồi
bổ sung dần. Một tính năng chỉ xong khi đã xử lý các nhánh ngoại lệ, phân quyền,
cách ly tenant và đồng bộ — không chỉ luồng hạnh phúc.

Thứ tự phase do **phụ thuộc kỹ thuật** quyết định. Xem
[roadmap](docs/03-features/roadmap.md) và
[feature catalog](docs/03-features/README.md).

---

## Luật bất biến

### Kiến trúc

1. Module **không** import package nội bộ của module khác — chỉ qua package `api`
2. Module **không** truy vấn bảng thuộc sở hữu của module khác
3. Giao tiếp bất đồng bộ giữa các module **chỉ** qua domain event
4. Không dùng JPA/Hibernate. Ghi bằng Spring Data JDBC, truy vấn động bằng jOOQ,
   đọc đơn giản bằng `JdbcClient`
5. Không thêm kho dữ liệu nào ngoài PostgreSQL. Redis chỉ là cache, phát tán,
   khoá, giới hạn tần suất — mất Redis thì hệ thống chậm chứ không sai

### Dữ liệu

6. **Mọi bảng nghiệp vụ có cột định danh workspace**, kể cả khi đã có định danh project
7. **Mọi bảng nghiệp vụ bật bảo mật mức dòng** theo workspace
8. **Không khoá ngoại** từ bảng nghiệp vụ tới bảng thuộc vùng dữ liệu toàn cục
9. **Mọi tham chiếu tới con người trỏ tới `member`, không trỏ tới `account`**
10. Người rời workspace bị vô hiệu hoá, **không bị xoá cứng**

### Sự kiện

11. Domain event ghi vào bảng chuyển tiếp **trong cùng giao dịch** với thay đổi nghiệp vụ
12. Giao hàng là ít nhất một lần, nên **mọi bên tiêu thụ phải chống trùng**
13. Sự kiện có trường phiên bản ngay từ sự kiện đầu tiên
14. Kết nối lắng nghe thông báo của PostgreSQL **không lấy từ connection pool chung**

### Đồng bộ

15. Mọi thay đổi dữ liệu sinh bản ghi nhật ký thay đổi, patch **chỉ chứa trường đã đổi**
16. Mutation đi qua HTTP POST kèm khoá chống trùng, không đi qua luồng đồng bộ
17. **Mọi thay đổi làm thu hẹp quyền phải phát sự kiện thu hồi**, và client phải
    xoá dữ liệu cục bộ của scope đó

### Frontend

18. **Cấm Server Action cho thay đổi dữ liệu nghiệp vụ**
19. **Cấm lấy dữ liệu nghiệp vụ trong server component**
20. Khu vực ứng dụng render hoàn toàn phía client; chỉ trang giới thiệu và trang
    nhận liên kết đăng nhập được render phía server
21. Nhiều tab dùng **một** kết nối đồng bộ và **một** nơi ghi dữ liệu cục bộ

### Phân quyền

22. Không có mật khẩu ở bất kỳ đâu. Magic link là phương thức xác thực duy nhất
23. Token truy cập **không mang danh sách quyền**
24. **Vị trí bit của một quyền không bao giờ đổi ý nghĩa hay dùng lại**
25. Mọi kiểm tra quyền đi qua một điểm vào duy nhất nhận cả ngữ cảnh dữ liệu, để
    tầng permission condition cắm vào được

Lý do đầy đủ cho từng luật: [ADR](docs/adr/) và
[constraints.md](docs/02-requirement/constraints.md).

---

## Quy ước

| | |
|---|---|
| Ngôn ngữ tài liệu | Tiếng Việt, thuật ngữ kỹ thuật giữ tiếng Anh |
| Ngôn ngữ code và định danh | Tiếng Anh |
| **Commit message** | **Tiếng Anh**, theo Conventional Commits |
| Chia commit | Theo từng giai đoạn công việc, không dồn vào một commit lớn |
| Trạng thái feature | Chỉ ở [feature catalog](docs/03-features/README.md), không lặp ở nơi khác |
| Chỗ chưa chốt | Ghi `> **Chưa chốt:** ...` thay vì đoán |

---

## Trạng thái hiện tại

Dự án **chưa bắt đầu implement**. Mới có tài liệu.

| Phần | Trạng thái |
|---|---|
| Brief, Requirement, System Design, Features & Roadmap | ✅ Hoàn thiện |
| UX/UI design, ERD, Detail design | ⬜ Chưa bắt đầu |
| `backend/`, `frontend/`, `infra/` | ⬜ Chưa tạo |

Việc tiếp theo theo roadmap: phân tích mô hình dữ liệu ([ERD](docs/06-erd/)) rồi
bắt đầu [Phase 0](docs/03-features/roadmap.md#phase-0--nền-tảng).
