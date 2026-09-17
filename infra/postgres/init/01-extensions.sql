-- Chạy một lần khi khởi tạo cụm cơ sở dữ liệu ở bậc 1 và bậc 2.
--
-- Chỉ bật phần mở rộng. KHÔNG định nghĩa cấu trúc bảng ở đây — cấu trúc thuộc
-- về migration trong backend/, và mô hình dữ liệu vẫn đang chờ phân tích.
--
-- Không cần phần mở rộng sinh định danh: định danh do client sinh (CON-61).

-- So sánh chuỗi không phân biệt hoa thường, cho email và slug. Cần từ Phase 1.
CREATE EXTENSION IF NOT EXISTS citext;

-- So khớp chuỗi gần đúng, cho gợi ý tìm kiếm. Cần từ Phase 7; bật sẵn vì nó
-- không tốn gì khi không dùng.
CREATE EXTENSION IF NOT EXISTS pg_trgm;
