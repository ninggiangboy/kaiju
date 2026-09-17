# ADR-0013: Migration chạy tường minh và đi được hai chiều, không chạy lúc ứng dụng khởi động

- **Trạng thái:** Accepted
- **Ngày:** 2026-09-17
- **Liên quan:** [ADR-0002](0002-postgres-only.md), [ADR-0012](0012-shared-schema-tenancy-rls.md), [data-access-and-tenancy.md](../04-system-design/data-access-and-tenancy.md), [environments.md](../04-system-design/environments.md), [ci-cd.md](../04-system-design/ci-cd.md)

## Bối cảnh

Tài liệu ban đầu chọn Flyway và để framework tự chạy migration lúc ứng dụng khởi
động ở bậc 1–3, chỉ tách thành công việc riêng ở bậc 4 vì ở đó nhiều bản khởi
động cùng lúc sẽ giẫm lên nhau.

Cách đó có hai vấn đề. Thứ nhất, **hành vi ở bậc dùng hằng ngày khác hành vi ở bậc
thật** — đúng loại khác biệt mà cả bốn bậc môi trường sinh ra để loại bỏ, và
đường chạy ở bậc 4 gần như không bao giờ được diễn tập. Thứ hai, migration trở
thành tác dụng phụ của việc khởi động: không có thời điểm nào để nhìn xem sắp
chạy cái gì, và **không có chiều đi xuống** — bản miễn phí của Flyway không có
lệnh đảo ngược, nó nằm ở bản trả tiền.

Trong khi phát triển, thứ cần nhất lại chính là chiều đi xuống: viết một migration,
chạy, thấy sai, lùi lại, sửa, chạy lại — mà không phải xoá sạch cơ sở dữ liệu.

## Quyết định

Migration **không bao giờ chạy lúc ứng dụng khởi động, ở bất kỳ bậc nào**. Nó là
một thao tác được gọi tường minh, và gọi được **cả hai chiều lên và xuống**.

Công cụ là **Liquibase bản Community**. Script vẫn là SQL thô; mỗi changeset kèm
phần lùi viết tay ngay cạnh nó.

Thao tác chạy qua **vai trò `migrate` của chính ảnh container đã có**, không phải
một binary hay một dịch vụ riêng — giữ nguyên nguyên tắc một ảnh cho cả bốn bậc
tại [CON-66](../02-requirement/constraints.md).

**Không dựng dashboard lúc này.** Việc điều khiển đi qua lệnh trong `infra/Makefile`
ở bậc 1–2 và qua công việc chạy trước khi triển khai ở bậc 3–4.

## Lý do

- Migration là thứ **đổi dữ liệu thật và khó hoàn tác**. Nó xứng đáng là một hành
  động có chủ ý, không phải một tác dụng phụ của lệnh khởi động.
- Một đường chạy duy nhất cho cả bốn bậc nghĩa là đường chạy ở bậc 4 được diễn tập
  mỗi ngày ở bậc 1, thay vì chỉ được chạy thật lần đầu lúc triển khai.
- Flyway bản miễn phí không có chiều đi xuống. Giữ Flyway là tự loại bỏ yêu cầu
  chính, nên phải đổi công cụ.
- Liquibase chạy trên JVM, nên nó nằm sẵn trong ảnh container đã có và dùng lại
  được trong test tích hợp. Không thêm binary vào ảnh, không thêm dịch vụ vào hạ tầng.
- Script vẫn là SQL thô vì schema ở đây cần chính sách bảo mật mức dòng, kiểu dữ
  liệu mở rộng và chỉ mục đặc thù — phần trừu tượng của công cụ không diễn đạt nổi
  những thứ đó, và cũng không cần diễn đạt.

## Hệ quả

- **Phần lùi phải viết tay cho từng changeset.** Bản Community không sinh giúp.
  Changeset không có phần lùi là changeset không lùi được, và điều đó phải được
  kiểm tra trong CI chứ không phát hiện lúc cần lùi.
- **Đi xuống không phải là khôi phục dữ liệu.** Lùi một migration đã bỏ cột sẽ
  dựng lại cột rỗng; dữ liệu trong đó đã mất. Vì vậy chiều đi xuống là công cụ của
  bậc 1–2, dùng dè dặt ở bậc 3, và **ở bậc 4 vẫn là sửa tiến kèm migration tương
  thích ngược**, không phải lùi.
- Không còn cách "chạy app là có schema". Mọi hướng dẫn khởi động, mọi script
  test, mọi quy trình CI phải gọi migration ra thành một bước riêng.
- Ứng dụng có thể khởi động khi schema chưa đúng phiên bản. Vì vậy vai trò `api`
  phải **kiểm tra phiên bản schema trong health check** và báo chưa sẵn sàng, thay
  vì chạy rồi lỗi ở câu truy vấn đầu tiên.
- Phải tự kiểm tra tính tương thích ngược, vì lệnh phân tích migration của các
  công cụ khác đều ở bản trả tiền. CI đã có sẵn công việc chạy migration mới trên
  cơ sở dữ liệu có phiên bản ứng dụng cũ đang chạy — đó chính là chỗ bắt.

## Phương án đã loại

**Giữ Flyway, chỉ tách ra khỏi lúc khởi động.** Giải quyết được nửa vấn đề, nhưng
chiều đi xuống nằm sau tường phí, nên nửa còn lại vẫn không có.

**Atlas.** Chiều đi xuống tốt nhất trong các công cụ đã xét: nó không đọc file lùi
viết tay mà soi trạng thái thật của cơ sở dữ liệu rồi tính ra SQL lùi, kèm chạy
thử và kiểm tra an toàn trước khi chạy. Nhưng `migrate down` nằm sau `atlas login`,
tức bản trả tiền sau ba mươi ngày dùng thử; bản Apache 2.0 không có lệnh này. Nó
cũng là binary ngoài JVM, phải thêm vào ảnh container và vào phần dựng test.
Đáng xem lại nếu sau này migration trở nên phức tạp tới mức phần lùi viết tay hay
sai.

**Bytebase.** Công cụ duy nhất có dashboard thật và tự host được, bản Community
miễn phí thừa sức cho quy mô này. Loại vì ba lý do: nó là một dịch vụ nữa phải
chạy và phải có cơ sở dữ liệu riêng của nó; nó giữ sổ migration thay cho thư mục
script trong repository, nên repository không còn là nguồn sự thật; và thứ nó gọi
là "quay lui một cú nhấp" là **quay lui dữ liệu** dựa trên bản sao lưu dòng bị ảnh
hưởng trước khi chạy, không phải chiều đi xuống của thay đổi cấu trúc. Vẫn là
phương án tốt nếu sau này có nhiều người cùng đổi schema và cần duyệt trước khi chạy.

**Nhóm CLI viết cặp file lên/xuống (goose, dbmate, golang-migrate, Sqitch).** Đúng
mô hình mong muốn và đơn giản nhất, nhưng đều là binary ngoài JVM: phải thêm vào
ảnh container, vào phần dựng test, và vào từng máy phát triển. Đổi lại không được
gì mà Liquibase không có.
