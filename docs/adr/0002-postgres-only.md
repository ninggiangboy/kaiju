# ADR-0002: PostgreSQL là datastore duy nhất, không dùng MongoDB

- **Trạng thái:** Accepted
- **Ngày:** 2026-09-17
- **Liên quan:** [ADR-0003](0003-redis-scope.md), [ADR-0005](0005-outbox-db-job.md), [ADR-0012](0012-shared-schema-tenancy-rls.md)

## Bối cảnh

Ba vùng dữ liệu của Kaiju thường được coi là lý do để thêm một document store:

1. **Custom field** — mỗi project có tập field khác nhau, schema động
2. **Activity log / changelog** — ghi rất nhiều, payload không đồng nhất
3. **Change log và notification** — khối lượng lớn, dạng append-only

Câu hỏi đặt ra: có nên đưa MongoDB vào cho các vùng này không.

## Quyết định

**Chỉ dùng PostgreSQL.** Không thêm MongoDB hay bất kỳ document store nào.
Schema động dùng `JSONB` với GIN index; dữ liệu append-only dùng bảng partition
theo thời gian.

## Lý do

- **Lý do quyết định là tính nguyên tử với outbox.** Outbox chỉ đúng khi thay đổi
  nghiệp vụ và bản ghi event nằm trong **cùng một transaction**. Nếu issue nằm ở
  Mongo còn outbox ở Postgres, ta mất đảm bảo đó và rơi đúng vào bài toán
  dual-write mà outbox sinh ra để tránh.
- `JSONB` cộng GIN index xử lý được toàn bộ nhu cầu schema động của custom field,
  bao gồm truy vấn theo giá trị field.
- Postgres xử lý bảng append-only hàng trăm triệu dòng tốt khi có partition theo
  thời gian và job retention.
- Thêm một datastore nghĩa là thêm một miền nhất quán thứ hai, thêm một thứ phải
  backup, migrate, giám sát và học cách vận hành khi hỏng.

## Hệ quả

- Truy vấn custom field phải viết qua `JSONB`, cần converter tự viết cho Spring
  Data JDBC và cần dùng jOOQ cho truy vấn động trên `JSONB`.
- Các bảng append-only **phải** có partition và retention ngay từ khi tạo. Thêm
  partition sau khi bảng đã lớn là việc khó chịu.
- Postgres trở thành điểm chịu tải tập trung; hiệu năng và vận hành của nó là rủi
  ro chính của hệ thống. Bù lại chỉ phải giỏi một thứ.
- Nếu về sau log sự kiện quá lớn, hướng xử lý đúng là partition mạnh hơn cộng
  archive sang object storage — **không** phải thêm Mongo.

## Phương án đã loại

**MongoDB cho custom field.** Không đổi lại được gì so với `JSONB`, mà mất tính
nguyên tử với outbox và mất khả năng join với dữ liệu quan hệ.

**MongoDB cho activity/change log.** Có lợi thế về khối lượng ghi, nhưng change
log **bắt buộc** phải ghi cùng transaction với thay đổi nghiệp vụ, nếu không
client sẽ nhận được trạng thái mà không nhận được thông báo thay đổi, hoặc ngược lại.

**Elasticsearch làm nơi lưu chính.** Sẽ được xem xét như một **index phụ** cho
tìm kiếm ở phase sau, nhưng không bao giờ là nguồn sự thật.
