# Ràng buộc

Các quyết định **đã chốt và không mở lại**. Đây là tài liệu tra cứu nhanh khi
implement: nếu một cách làm vi phạm một trong các ràng buộc dưới đây thì cách làm
đó sai, bất kể nó tiện tới đâu.

Mỗi ràng buộc dẫn tới ADR chứa lý do đầy đủ. Muốn thay đổi một ràng buộc thì phải
viết ADR mới thay thế ADR cũ, không sửa tại chỗ.

**Liên quan:** [ADR](../adr/) · [functional.md](functional.md) · [non-functional.md](non-functional.md) · [CLAUDE.md](../../CLAUDE.md)

---

## Nền tảng và hạ tầng

| ID | Ràng buộc | Nguồn |
|---|---|---|
| CON-01 | Backend là Spring Boot dòng 4.x chạy trên Java 26, bật virtual thread | Quyết định của chủ dự án, xem [phiên bản nền](../04-system-design/backend-modules.md#phiên-bản-nền) |
| CON-02 | Frontend là Next.js | Quyết định của chủ dự án |
| CON-03 | PostgreSQL là kho dữ liệu duy nhất. Không thêm kho dữ liệu nào khác làm nguồn sự thật | [ADR-0002](../adr/0002-postgres-only.md) |
| CON-04 | Redis chỉ dùng cho cache, phát tán thông điệp, khoá phân tán, giới hạn tần suất và trạng thái tạm. Mất Redis thì hệ thống chậm chứ không sai | [ADR-0003](../adr/0003-redis-scope.md) |
| CON-05 | Không dùng message broker ngoài và không dùng cơ chế bắt thay đổi ở tầng cơ sở dữ liệu | [ADR-0005](../adr/0005-outbox-db-job.md) |
| CON-06 | Repository có đúng bốn thư mục cấp cao: `docs/`, `backend/`, `frontend/`, `infra/` | Quyết định của chủ dự án |
| CON-61 | Định danh của thực thể do **client sinh**, kiểu định danh duy nhất có thành phần thời gian; server chỉ kiểm tra chứ không tự sinh | [infrastructure.md](../04-system-design/infrastructure.md#định-danh-do-client-sinh) |
| CON-62 | Biến phiên cho cách ly tenant chỉ đặt ở **phạm vi giao dịch**; khoá tư vấn nếu dùng phải là loại gắn với giao dịch | [infrastructure.md](../04-system-design/infrastructure.md#bộ-gộp-kết-nối) |
| CON-63 | Tệp đính kèm lưu ở kho lưu trữ đối tượng, không lưu trong cơ sở dữ liệu; cơ sở dữ liệu chỉ giữ siêu dữ liệu | [infrastructure.md](../04-system-design/infrastructure.md#lưu-trữ-đối-tượng) |
| CON-64 | Ứng dụng chỉ phát tín hiệu quan sát theo chuẩn mở, không gắn với một sản phẩm giám sát cụ thể | [infrastructure.md](../04-system-design/infrastructure.md#nguyên-tắc-ứng-dụng-chỉ-nói-một-giao-thức) |
| CON-65 | Ngữ cảnh lần vết phải được truyền qua siêu dữ liệu của sự kiện để chuỗi không đứt ở ranh giới bất đồng bộ | [infrastructure.md](../04-system-design/infrastructure.md#nguyên-tắc-ứng-dụng-chỉ-nói-một-giao-thức) |
| CON-66 | Cùng một ảnh container chạy ở cả bốn bậc môi trường; khác biệt chỉ nằm ở biến môi trường và profile vai trò | [environments.md](../04-system-design/environments.md#nguyên-tắc-một-artifact-bốn-cấu-hình) |
| CON-67 | **Cấm** mọi nhánh code rẽ theo tên môi trường. Khác biệt giữa các bậc phải biểu diễn bằng biến cấu hình nói lên tính chất, không nói lên nơi chốn | [environments.md](../04-system-design/environments.md#nguyên-tắc-một-artifact-bốn-cấu-hình) |
| CON-68 | Ở bậc `production`, migration chạy như một công việc riêng **trước** khi triển khai, không chạy lúc ứng dụng khởi động | [environments.md](../04-system-design/environments.md#những-thứ-chỉ-xuất-hiện-ở-bậc-này) |
| CON-69 | Thứ tự triển khai bắt buộc: migration → `worker` và `scheduler` → `api` và `realtime` | [ci-cd.md](../04-system-design/ci-cd.md#thứ-tự-triển-khai) |
| CON-70 | Triển khai luôn theo thẻ ảnh cố định gắn với commit, không bao giờ theo thẻ động | [ci-cd.md](../04-system-design/ci-cd.md#ảnh-container) |
| CON-71 | Cổng chặn merge coi công việc bị bỏ qua là **thất bại**, trừ khi thư mục tương ứng không thay đổi | [ci-cd.md](../04-system-design/ci-cd.md#cổng) |
| CON-72 | Mọi script kiểm tra của CI phải chạy được từ máy cá nhân bằng một lệnh | [ci-cd.md](../04-system-design/ci-cd.md#cấu-trúc) |
| CON-73 | Bậc `staging` **không** được dùng dịch vụ giả lập: email, lưu trữ đối tượng, cơ sở dữ liệu và đích thu thập tín hiệu quan sát đều phải là hàng thật | [environments.md](../04-system-design/environments.md#bậc-3--staging) |

## Kiến trúc

| ID | Ràng buộc | Nguồn |
|---|---|---|
| CON-07 | Một codebase backend duy nhất, triển khai thành bốn vai trò ứng dụng. Không tách microservice | [ADR-0001](../adr/0001-modular-monolith-multi-app.md) |
| CON-08 | Module không được import package nội bộ của module khác | [ADR-0001](../adr/0001-modular-monolith-multi-app.md) |
| CON-09 | Module không được truy vấn bảng thuộc sở hữu của module khác | [ADR-0001](../adr/0001-modular-monolith-multi-app.md) |
| CON-10 | Giao tiếp bất đồng bộ giữa các module chỉ qua domain event | [ADR-0001](../adr/0001-modular-monolith-multi-app.md) |
| CON-11 | Vi phạm biên giới module phải làm hỏng build, không chỉ bị nhắc nhở | [ADR-0001](../adr/0001-modular-monolith-multi-app.md) |

## Dữ liệu

| ID | Ràng buộc | Nguồn |
|---|---|---|
| CON-12 | Tầng ghi dùng Spring Data JDBC. Không dùng JPA/Hibernate ở bất kỳ đâu | [ADR-0004](../adr/0004-spring-data-jdbc.md) |
| CON-13 | Truy vấn động dùng jOOQ; truy vấn đơn giản trả DTO dùng `JdbcClient` | [ADR-0004](../adr/0004-spring-data-jdbc.md) |
| CON-14 | Mọi bảng nghiệp vụ đều có cột định danh workspace, kể cả khi đã có định danh project | [ADR-0012](../adr/0012-shared-schema-tenancy-rls.md) |
| CON-15 | Mọi bảng nghiệp vụ bật bảo mật ở mức dòng theo workspace | [ADR-0012](../adr/0012-shared-schema-tenancy-rls.md) |
| CON-16 | Không bảng nghiệp vụ nào được có khoá ngoại tới bảng thuộc vùng dữ liệu toàn cục, ngoài bảng workspace | [ADR-0011](../adr/0011-account-vs-member.md) |
| CON-17 | Mọi tham chiếu tới con người trong dữ liệu nghiệp vụ đều trỏ tới hồ sơ trong workspace, không trỏ tới danh tính toàn cục | [ADR-0011](../adr/0011-account-vs-member.md) |
| CON-18 | Các cột nối giữa vùng toàn cục và vùng workspace không khai báo khoá ngoại | [ADR-0011](../adr/0011-account-vs-member.md) |
| CON-19 | Khoá phân mảnh của toàn hệ thống là định danh workspace. Chưa phân mảnh, nhưng mô hình không được cản trở | [ADR-0012](../adr/0012-shared-schema-tenancy-rls.md) |
| CON-20 | Aggregate phải nhỏ. Collection con nằm trong aggregate phải có chặn trên về số lượng | [ADR-0004](../adr/0004-spring-data-jdbc.md) |
| CON-21 | Người rời workspace không bị xoá cứng; hồ sơ được giữ ở trạng thái vô hiệu | [ADR-0011](../adr/0011-account-vs-member.md) |

## Sự kiện

| ID | Ràng buộc | Nguồn |
|---|---|---|
| CON-22 | Domain event ghi vào bảng chuyển tiếp **trong cùng giao dịch** với thay đổi nghiệp vụ | [ADR-0005](../adr/0005-outbox-db-job.md) |
| CON-23 | Mọi bên tiêu thụ sự kiện phải chống trùng, vì giao hàng là ít nhất một lần | [ADR-0005](../adr/0005-outbox-db-job.md) |
| CON-24 | Sự kiện phải có trường phiên bản ngay từ sự kiện đầu tiên | [ADR-0005](../adr/0005-outbox-db-job.md) |
| CON-25 | Kết nối dùng để lắng nghe thông báo của cơ sở dữ liệu không được lấy từ connection pool chung | [ADR-0005](../adr/0005-outbox-db-job.md) |
| CON-26 | Không dùng cơ chế theo dõi sự kiện có sẵn của framework nền, và không đưa thư viện lưu trữ sự kiện của nó lên classpath | [ADR-0005](../adr/0005-outbox-db-job.md) |

## Đồng bộ và realtime

| ID | Ràng buộc | Nguồn |
|---|---|---|
| CON-27 | Luồng đồng bộ dùng SSE; định danh sự kiện mang vị trí đồng bộ của client | [ADR-0006](../adr/0006-sse-over-websocket.md) |
| CON-28 | Thay đổi do người dùng tạo ra đi qua HTTP POST kèm khoá chống trùng, không đi qua luồng đồng bộ | [ADR-0006](../adr/0006-sse-over-websocket.md) |
| CON-29 | WebSocket chỉ dành cho soạn thảo văn bản cộng tác ở phase sau, và là kênh riêng | [ADR-0006](../adr/0006-sse-over-websocket.md) |
| CON-30 | Sync engine do dự án tự xây; không dùng thư viện đồng bộ đi vòng qua backend | [ADR-0007](../adr/0007-build-own-sync-engine.md) |
| CON-31 | Xung đột dữ liệu có cấu trúc giải quyết theo nguyên tắc ghi sau thắng, ở mức từng trường | [ADR-0007](../adr/0007-build-own-sync-engine.md) |
| CON-32 | Mọi thay đổi dữ liệu phải sinh bản ghi nhật ký thay đổi, và phần dữ liệu gửi đi chỉ chứa trường đã đổi | [ADR-0007](../adr/0007-build-own-sync-engine.md) |
| CON-33 | Tầng truyền tải ở client phải nằm sau một interface để đổi được về sau | [ADR-0006](../adr/0006-sse-over-websocket.md) |

## Frontend

| ID | Ràng buộc | Nguồn |
|---|---|---|
| CON-34 | Khu vực ứng dụng render hoàn toàn ở phía client. Chỉ trang giới thiệu, tài liệu và trang nhận liên kết đăng nhập được render phía server | [ADR-0008](../adr/0008-nextjs-as-spa-shell.md) |
| CON-35 | **Cấm** dùng Server Action cho thay đổi dữ liệu nghiệp vụ | [ADR-0008](../adr/0008-nextjs-as-spa-shell.md) |
| CON-36 | **Cấm** lấy dữ liệu nghiệp vụ trong server component | [ADR-0008](../adr/0008-nextjs-as-spa-shell.md) |
| CON-37 | Nhiều tab chỉ dùng một kết nối đồng bộ và một nơi ghi dữ liệu cục bộ | [ADR-0007](../adr/0007-build-own-sync-engine.md) |
| CON-38 | Middleware của Next chỉ kiểm tra sự tồn tại của cookie để điều hướng, không tự xác thực token | [ADR-0008](../adr/0008-nextjs-as-spa-shell.md) |

## Danh tính và phân quyền

| ID | Ràng buộc | Nguồn |
|---|---|---|
| CON-39 | Magic link là phương thức xác thực duy nhất. Không có mật khẩu ở bất kỳ đâu | [ADR-0009](../adr/0009-magic-link-only.md) |
| CON-40 | Email đăng nhập phải kèm cả liên kết và mã nhập tay | [ADR-0009](../adr/0009-magic-link-only.md) |
| CON-41 | Token lời mời chính là một magic link; không yêu cầu thêm bước xác thực email nào khác | [ADR-0009](../adr/0009-magic-link-only.md) |
| CON-42 | Phân quyền biểu diễn bằng mặt nạ bit ở hai cấp; quyền hiệu lực là phép hợp của các mặt nạ | [ADR-0010](../adr/0010-bitmask-permission.md) |
| CON-43 | Vị trí bit của một quyền không bao giờ được đổi ý nghĩa hay dùng lại | [ADR-0010](../adr/0010-bitmask-permission.md) |
| CON-44 | Thiết kế phải dự phòng cho trường hợp số quyền vượt quá độ rộng của một số nguyên 64 bit | [ADR-0010](../adr/0010-bitmask-permission.md) |
| CON-45 | Token truy cập chỉ mang danh tính, không mang danh sách quyền | [ADR-0010](../adr/0010-bitmask-permission.md) |
| CON-46 | Quyền phụ thuộc dữ liệu được xử lý bởi một tầng riêng chạy sau khi mặt nạ bit đã cho phép; chỗ nối cho tầng này phải có ngay từ Phase 1 | [ADR-0010](../adr/0010-bitmask-permission.md) |
| CON-47 | Workspace là đơn vị tenancy duy nhất. Không có cấp tổ chức phía trên | [ADR-0012](../adr/0012-shared-schema-tenancy-rls.md) |
| CON-57 | Token truy cập chỉ chứa claims cơ bản: danh tính tài khoản, phiên, thời điểm phát hành và hết hạn, loại token. Không chứa vai trò, quyền, hay danh sách workspace | [identity-and-permission.md](../04-system-design/identity-and-permission.md#token-truy-cập-chứa-gì) |
| CON-58 | Mặt nạ quyền luôn được tra lại phía server theo từng request, không bao giờ đọc từ token hay từ tham số client gửi lên | [identity-and-permission.md](../04-system-design/identity-and-permission.md#vì-sao-quyền-không-nằm-trong-token) |
| CON-59 | Mọi hành động khai báo đúng một quyền cần có; hành động chưa khai báo thì **bị từ chối**, không được cho qua | [identity-and-permission.md](../04-system-design/identity-and-permission.md#mặc-định-là-từ-chối) |
| CON-60 | Kiểm tra quyền nằm ở command và query handler, không phải ở controller, vì tác vụ nền và quy tắc tự động đi đường khác | [identity-and-permission.md](../04-system-design/identity-and-permission.md#bốn-chỗ-bắt-buộc-kiểm-tra) |

## Khung mã nguồn

| ID | Ràng buộc | Nguồn |
|---|---|---|
| CON-51 | Công cụ build phải ở phiên bản chạy được trên Java 26, và công cụ kiểm tra biên giới dùng dòng tương ứng với Spring Boot 4 | [backend-modules.md](../04-system-design/backend-modules.md#phiên-bản-nền) |
| CON-52 | Mọi module nghiệp vụ là package **con trực tiếp** của package gốc ứng dụng, khớp một-một với Gradle module | [backend-modules.md](../04-system-design/backend-modules.md#quy-ước-package-bắt-buộc) |
| CON-53 | Package gốc của mỗi module để trống; phần lộ ra ngoài nằm ở package `api` và phải được khai báo tường minh | [backend-modules.md](../04-system-design/backend-modules.md#quy-ước-package-bắt-buộc) |
| CON-54 | Hạ tầng dùng chung nằm **ngoài** package gốc ứng dụng, để không trở thành một module nghiệp vụ | [backend-modules.md](../04-system-design/backend-modules.md#quy-ước-package-bắt-buộc) |
| CON-55 | Mỗi module sở hữu một tiền tố tên bảng, và có test tự động bắt việc truy cập bảng của module khác | [backend-modules.md](../04-system-design/backend-modules.md#2-không-truy-vấn-bảng-thuộc-sở-hữu-của-module-khác) |
| CON-56 | Có test kiểm tra classpath và báo lỗi khi phát hiện thư viện bị cấm | [events-and-outbox.md](../04-system-design/events-and-outbox.md#ba-điều-cấm) |

## Quy trình

| ID | Ràng buộc | Nguồn |
|---|---|---|
| CON-48 | Làm từng tính năng một, mỗi tính năng phải đầy đủ. Không làm sơ sài rồi bổ sung dần | [Brief](../01-brief/) |
| CON-49 | Thứ tự phase do phụ thuộc kỹ thuật quyết định, không do độ khó hay mức độ hấp dẫn | [Brief](../01-brief/) |
| CON-50 | Tài liệu trong `docs/` viết bằng tiếng Việt, thuật ngữ kỹ thuật giữ tiếng Anh. **Mọi thứ nằm ngoài `docs/` viết bằng tiếng Anh**, kể cả phần chú thích bên trong script và tệp cấu hình. Thông điệp commit viết bằng tiếng Anh | Quyết định của chủ dự án |
| | *Ghi chú (2026-09-17): bản trước của ràng buộc này chỉ nói "tài liệu viết bằng tiếng Việt" mà không nêu ranh giới, nên `infra/` và `.github/` ban đầu được viết bằng tiếng Việt. Ranh giới đúng là thư mục `docs/`.* | |
