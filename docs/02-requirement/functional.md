# Yêu cầu chức năng

Danh sách những gì hệ thống phải làm được, nhóm theo bounded context. Mỗi yêu cầu
có ID cố định, mức ưu tiên và phase dự kiến.

**Liên quan:** [README](README.md) · [non-functional.md](non-functional.md) · [constraints.md](constraints.md) · [Feature catalog](../03-features/README.md) · [Roadmap](../03-features/roadmap.md)

---

## IDN — Identity & authentication

| ID | Yêu cầu | Ưu tiên | Phase |
|---|---|---|---|
| FR-IDN-01 | Người dùng nhập email để nhận magic link; cùng một luồng phục vụ cả đăng ký lẫn đăng nhập | MUST | 1 |
| FR-IDN-02 | Email chứa cả liên kết bấm được **và** mã 6 số nhập tay, để dùng được khi mở mail ở thiết bị khác | MUST | 1 |
| FR-IDN-03 | Liên kết và mã dùng một lần, có thời hạn ngắn; dùng một cái thì các cái còn lại của cùng email bị vô hiệu | MUST | 1 |
| FR-IDN-04 | Hệ thống không tiết lộ một email đã có tài khoản hay chưa | MUST | 1 |
| FR-IDN-05 | Giới hạn tần suất gửi theo email và theo địa chỉ IP | MUST | 1 |
| FR-IDN-06 | Mở liên kết ở thiết bị khác thiết bị đã yêu cầu thì phải nhập mã 6 số thay vì tự đăng nhập | MUST | 1 |
| FR-IDN-07 | Tài khoản mới được dẫn qua onboarding: tên hiển thị, và tạo workspace hoặc chấp nhận lời mời | MUST | 1 |
| FR-IDN-08 | Người dùng xem được danh sách phiên đăng nhập đang hoạt động kèm thiết bị, IP, lần truy cập gần nhất | MUST | 1 |
| FR-IDN-09 | Người dùng thu hồi được một phiên bất kỳ hoặc toàn bộ phiên khác | MUST | 1 |
| FR-IDN-10 | Người dùng sửa được thông tin tài khoản toàn cục: tên mặc định, avatar mặc định | SHOULD | 1 |
| FR-IDN-11 | Người dùng xoá được tài khoản; dữ liệu nghiệp vụ được giữ lại dưới dạng ẩn danh | SHOULD | 1 |
| FR-IDN-12 | Mọi hành động liên quan tới bảo mật được ghi vào nhật ký kiểm toán | MUST | 1 |

## WSP — Workspace & member

| ID | Yêu cầu | Ưu tiên | Phase |
|---|---|---|---|
| FR-WSP-01 | Người dùng tạo được workspace, đặt tên và slug; slug kiểm tra trùng và sửa được | MUST | 1 |
| FR-WSP-02 | Một tài khoản tham gia được nhiều workspace và chuyển qua lại không cần đăng nhập lại | MUST | 1 |
| FR-WSP-03 | Hồ sơ của một người trong mỗi workspace là độc lập: tên hiển thị, avatar, timezone, ngôn ngữ | MUST | 1 |
| FR-WSP-04 | Mời người khác vào workspace bằng email, mời được nhiều email trong một lần | MUST | 1 |
| FR-WSP-05 | Mời được cả người **chưa có** tài khoản; họ đăng ký và vào thẳng workspace qua chính lời mời | MUST | 1 |
| FR-WSP-06 | Người được mời có mặt trong danh sách thành viên ngay khi được mời, và gán việc được cho họ trước khi họ chấp nhận | MUST | 1 |
| FR-WSP-07 | Quản trị viên xem, gửi lại và thu hồi được lời mời đang chờ | MUST | 1 |
| FR-WSP-08 | Bốn vai trò cấp workspace: OWNER, ADMIN, MEMBER, GUEST, với quyền khác nhau | MUST | 1 |
| FR-WSP-09 | GUEST chỉ thấy project được mời đích danh và không thấy danh sách thành viên workspace | MUST | 1 |
| FR-WSP-10 | Đổi được vai trò của một thành viên | MUST | 1 |
| FR-WSP-11 | Xoá được thành viên; trước khi xoá có tuỳ chọn gán lại hàng loạt công việc đang thuộc về họ | MUST | 1 |
| FR-WSP-12 | Người bị xoá khỏi workspace mất quyền truy cập ngay lập tức, kể cả khi đang mở ứng dụng | MUST | 1 |
| FR-WSP-13 | Thành viên tự rời workspace được | SHOULD | 1 |
| FR-WSP-14 | Chuyển được quyền OWNER; workspace luôn phải có ít nhất một OWNER | MUST | 1 |
| FR-WSP-15 | Xoá workspace theo cơ chế xoá mềm kèm thời gian ân hạn, khôi phục được trong thời gian đó | MUST | 1 |
| FR-WSP-16 | Tạo và quản lý được group thành viên, gán quyền theo group | SHOULD | 1 |
| FR-WSP-17 | Giới hạn số lời mời gửi ra trong một khoảng thời gian để hệ thống không bị dùng để gửi thư rác | MUST | 1 |

## PRJ — Project

| ID | Yêu cầu | Ưu tiên | Phase |
|---|---|---|---|
| FR-PRJ-01 | Tạo project với tên, key, mô tả, avatar, người dẫn dắt | MUST | 2 |
| FR-PRJ-02 | Key project là duy nhất trong workspace, viết hoa, và dùng để sinh mã issue | MUST | 2 |
| FR-PRJ-03 | Đổi key project được, mã issue cũ vẫn truy cập được qua key cũ | SHOULD | 2 |
| FR-PRJ-04 | Chọn loại project khi tạo (Scrum / Kanban), quyết định tính năng được bật | MUST | 2 |
| FR-PRJ-05 | Hai mức hiển thị: mọi thành viên workspace thấy được, hoặc chỉ người được mời đích danh | MUST | 2 |
| FR-PRJ-06 | Quản lý thành viên và vai trò trong từng project | MUST | 2 |
| FR-PRJ-07 | Danh sách project có tìm kiếm, lọc, sắp xếp, đánh dấu yêu thích và mục truy cập gần đây | MUST | 2 |
| FR-PRJ-08 | Quản lý component trong project, mỗi component có người phụ trách và người được gán mặc định | SHOULD | 2 |
| FR-PRJ-09 | Lưu trữ, khôi phục và xoá vĩnh viễn project | MUST | 2 |
| FR-PRJ-10 | Phân quyền theo permission scheme dùng lại được giữa nhiều project | SHOULD | 2 |
| FR-PRJ-11 | Nhật ký thay đổi cấp project | MUST | 2 |

## SYN — Sync & offline

| ID | Yêu cầu | Ưu tiên | Phase |
|---|---|---|---|
| FR-SYN-01 | Dữ liệu người dùng được giữ trên máy; ứng dụng mở ra hiển thị ngay mà không chờ mạng | MUST | 0 |
| FR-SYN-02 | Mọi thay đổi hiện ra ngay trên giao diện trước khi server xác nhận | MUST | 0 |
| FR-SYN-03 | Thay đổi thực hiện khi offline được xếp hàng và gửi đi khi có mạng trở lại, kể cả sau khi tải lại trang | MUST | 0 |
| FR-SYN-04 | Thay đổi bị server từ chối sẽ được hoàn tác trên giao diện kèm thông báo lý do | MUST | 0 |
| FR-SYN-05 | Thay đổi của người khác xuất hiện mà không cần tải lại trang | MUST | 0 |
| FR-SYN-06 | Mất kết nối rồi nối lại thì không có thay đổi nào bị bỏ sót | MUST | 0 |
| FR-SYN-07 | Mở nhiều tab cùng lúc thì các tab luôn nhất quán với nhau | MUST | 0 |
| FR-SYN-08 | Người dùng thấy được trạng thái kết nối và số thay đổi đang chờ gửi | MUST | 0 |
| FR-SYN-09 | Khi bị thu hồi quyền, dữ liệu tương ứng bị xoá khỏi máy người dùng ngay | MUST | 0 |
| FR-SYN-10 | Khi vắng mặt quá lâu, hệ thống tải lại trạng thái đầy đủ thay vì cố bắt kịp từng thay đổi | MUST | 0 |

## ISS — Issue

| ID | Yêu cầu | Ưu tiên | Phase |
|---|---|---|---|
| FR-ISS-01 | Tạo, xem, sửa, xoá issue; xoá là xoá mềm và khôi phục được | MUST | 3 |
| FR-ISS-02 | Năm loại issue: Epic, Story, Task, Sub-task, Bug; cấu hình được loại nào dùng trong project nào | MUST | 3 |
| FR-ISS-03 | Mỗi issue có mã dạng `KEY-số`, sinh tuần tự và không trùng kể cả khi tạo đồng thời | MUST | 3 |
| FR-ISS-04 | Các trường hệ thống: tiêu đề, mô tả, trạng thái, độ ưu tiên, người được gán, người báo cáo, nhãn, component, hạn hoàn thành, ước lượng, story point | MUST | 3 |
| FR-ISS-05 | Mô tả hỗ trợ định dạng phong phú kèm ảnh nhúng | MUST | 3 |
| FR-ISS-06 | Phân cấp Epic → Story/Task → Sub-task, kèm kiểm tra không tạo vòng lặp | MUST | 3 |
| FR-ISS-07 | Liên kết giữa issue với các loại quan hệ hai chiều (chặn, liên quan, trùng lặp, nhân bản) | MUST | 3 |
| FR-ISS-08 | Loại liên kết cấu hình được, gồm cả tên chiều nghịch | SHOULD | 3 |
| FR-ISS-09 | Sắp xếp thứ tự issue theo thứ hạng, phục vụ kéo thả ở board và backlog | MUST | 3 |
| FR-ISS-10 | Nhân bản issue, kèm tuỳ chọn nhân bản cả sub-task và liên kết | SHOULD | 3 |
| FR-ISS-11 | Chuyển issue sang project khác, sinh mã mới nhưng giữ toàn bộ lịch sử | SHOULD | 3 |
| FR-ISS-12 | Chuyển đổi giữa Task và Sub-task | SHOULD | 3 |
| FR-ISS-13 | Xem issue dạng bảng với cột cấu hình được | MUST | 3 |
| FR-ISS-14 | Mọi thay đổi trường được ghi lại đầy đủ: ai, lúc nào, từ giá trị gì sang giá trị gì | MUST | 3 |

## COL — Collaboration

| ID | Yêu cầu | Ưu tiên | Phase |
|---|---|---|---|
| FR-COL-01 | Bình luận có định dạng phong phú, sửa và xoá được, giữ lịch sử chỉnh sửa | MUST | 4 |
| FR-COL-02 | Nhắc tên thành viên và group trong bình luận | MUST | 4 |
| FR-COL-03 | Trả lời theo luồng | SHOULD | 4 |
| FR-COL-04 | Giới hạn người xem được một bình luận | COULD | 4 |
| FR-COL-05 | Thả biểu tượng cảm xúc lên bình luận | COULD | 4 |
| FR-COL-06 | Đính kèm nhiều tệp, xem trước ảnh và PDF, tải về, xoá | MUST | 4 |
| FR-COL-07 | Đính kèm tệp trực tiếp trong bình luận | SHOULD | 4 |
| FR-COL-08 | Giới hạn dung lượng tệp và có chỗ móc để quét mã độc | MUST | 4 |
| FR-COL-09 | Theo dõi issue: tự động khi tạo hoặc bình luận, và tự thêm bớt được | MUST | 4 |
| FR-COL-10 | Bình chọn cho issue | COULD | 4 |
| FR-COL-11 | Dòng hoạt động trên issue gộp bình luận, thay đổi trường và nhật ký công việc, lọc theo loại | MUST | 4 |
| FR-COL-12 | Thông báo trong ứng dụng: đếm số chưa đọc, đánh dấu đã đọc, trung tâm thông báo | MUST | 4 |
| FR-COL-13 | Thông báo qua email, có gom nhóm để không gửi quá nhiều | MUST | 4 |
| FR-COL-14 | Cấu hình thông báo theo project và theo loại sự kiện | MUST | 4 |
| FR-COL-15 | Người dùng ghi đè tuỳ chọn thông báo cho riêng mình, và huỷ nhận từ email | MUST | 4 |

## WKF — Workflow

| ID | Yêu cầu | Ưu tiên | Phase |
|---|---|---|---|
| FR-WKF-01 | Trạng thái do người dùng định nghĩa, mỗi trạng thái thuộc một nhóm (chưa làm / đang làm / đã xong) | MUST | 5 |
| FR-WKF-02 | Workflow gồm tập trạng thái và các bước chuyển, có bước chuyển khởi tạo, bước chuyển toàn cục và bước chuyển về chính nó | MUST | 5 |
| FR-WKF-03 | Điều kiện trên bước chuyển: ai được phép thực hiện | MUST | 5 |
| FR-WKF-04 | Kiểm tra hợp lệ trên bước chuyển: trường nào bắt buộc phải có | MUST | 5 |
| FR-WKF-05 | Hành động sau bước chuyển: đặt kết quả xử lý, gán người, phát sự kiện | MUST | 5 |
| FR-WKF-06 | Màn hình nhập liệu hiện ra khi thực hiện một bước chuyển | SHOULD | 5 |
| FR-WKF-07 | Workflow scheme ánh xạ loại issue sang workflow, gán cho project | MUST | 5 |
| FR-WKF-08 | Trình soạn workflow trực quan, có bản nháp và bản đã xuất bản | MUST | 5 |
| FR-WKF-09 | Đổi workflow của project thì các issue đang tồn tại được chuyển đổi trạng thái an toàn | MUST | 5 |
| FR-WKF-10 | Quản lý danh mục kết quả xử lý | MUST | 5 |

## FLD — Custom field & screen

| ID | Yêu cầu | Ưu tiên | Phase |
|---|---|---|---|
| FR-FLD-01 | Các kiểu trường: văn bản ngắn, văn bản dài, số, ngày, ngày giờ, chọn một, chọn nhiều, hộp kiểm, nút chọn, chọn người, chọn nhiều người, nhãn, URL, chọn phân cấp | MUST | 6 |
| FR-FLD-02 | Một trường có cấu hình khác nhau theo project và theo loại issue | MUST | 6 |
| FR-FLD-03 | Đặt bắt buộc, quy tắc hợp lệ, giá trị mặc định, văn bản hướng dẫn cho từng trường | MUST | 6 |
| FR-FLD-04 | Màn hình là một tập trường; screen scheme ánh xạ màn hình cho thao tác tạo, sửa, xem | MUST | 6 |
| FR-FLD-05 | Sắp xếp thứ tự trường và chia tab trong một màn hình | SHOULD | 6 |
| FR-FLD-06 | Xoá hoặc đổi trường có xử lý dữ liệu cũ một cách an toàn | MUST | 6 |
| FR-FLD-07 | Trường tuỳ biến dùng được trong tìm kiếm, bộ lọc và báo cáo | MUST | 6 |

## SRC — Search & query

| ID | Yêu cầu | Ưu tiên | Phase |
|---|---|---|---|
| FR-SRC-01 | Ngôn ngữ truy vấn hỗ trợ AND/OR/NOT, ngoặc, so sánh, thuộc tập hợp, chứa chuỗi, kiểm tra rỗng và sắp xếp | MUST | 7 |
| FR-SRC-02 | Hàm dựng sẵn trong truy vấn: người dùng hiện tại, mốc thời gian tương đối, thành viên của group | MUST | 7 |
| FR-SRC-03 | Truy vấn được trên cả trường tuỳ biến | MUST | 7 |
| FR-SRC-04 | Tìm kiếm toàn văn trên tiêu đề, mô tả và bình luận | MUST | 7 |
| FR-SRC-05 | Giao diện lọc cơ bản chuyển đổi hai chiều với truy vấn dạng văn bản | MUST | 7 |
| FR-SRC-06 | Lưu bộ lọc, đặt tên, chia sẻ theo người, group, project hoặc công khai | MUST | 7 |
| FR-SRC-07 | Xuất kết quả tìm kiếm ra CSV và XLSX | SHOULD | 7 |
| FR-SRC-08 | Tìm kiếm nhanh toàn cục có gợi ý và lịch sử | MUST | 7 |
| FR-SRC-09 | Kết quả tìm kiếm chỉ chứa dữ liệu người dùng có quyền xem | MUST | 7 |

## BRD — Board (Kanban)

| ID | Yêu cầu | Ưu tiên | Phase |
|---|---|---|---|
| FR-BRD-01 | Board gắn với một bộ lọc để xác định phạm vi issue | MUST | 8 |
| FR-BRD-02 | Cột board tạo, xoá, đổi tên và sắp xếp được; một cột ánh xạ được nhiều trạng thái | MUST | 8 |
| FR-BRD-03 | Giới hạn số việc đang làm trên mỗi cột kèm cảnh báo khi vượt | MUST | 8 |
| FR-BRD-04 | Làn ngang theo người được gán, theo epic, theo truy vấn hoặc theo độ ưu tiên | MUST | 8 |
| FR-BRD-05 | Bộ lọc nhanh tuỳ biến trên board | MUST | 8 |
| FR-BRD-06 | Chọn trường hiển thị trên thẻ và tô màu thẻ theo quy tắc | SHOULD | 8 |
| FR-BRD-07 | Kéo thả cập nhật trạng thái và thứ hạng, phản hồi tức thì và kiểm tra bước chuyển hợp lệ | MUST | 8 |
| FR-BRD-08 | Backlog cho board Kanban | SHOULD | 8 |
| FR-BRD-09 | Biểu đồ dòng tích luỹ và biểu đồ kiểm soát | SHOULD | 8 |

## SPR — Sprint & Scrum

| ID | Yêu cầu | Ưu tiên | Phase |
|---|---|---|---|
| FR-SPR-01 | Màn hình backlog kéo thả sắp xếp, gom nhóm theo epic, chọn nhiều issue cùng lúc | MUST | 9 |
| FR-SPR-02 | Tạo sprint với tên, mục tiêu và khoảng thời gian | MUST | 9 |
| FR-SPR-03 | Bắt đầu và kết thúc sprint; khi kết thúc phải quyết định issue chưa xong đi đâu | MUST | 9 |
| FR-SPR-04 | Nhiều sprint song song trong một project | SHOULD | 9 |
| FR-SPR-05 | Ước lượng bằng story point và lập kế hoạch theo năng lực từng thành viên | MUST | 9 |
| FR-SPR-06 | Board của sprint hiện tại | MUST | 9 |
| FR-SPR-07 | Báo cáo: burndown, burnup, velocity, báo cáo sprint, báo cáo epic | MUST | 9 |

## RDM — Roadmap & timeline

| ID | Yêu cầu | Ưu tiên | Phase |
|---|---|---|---|
| FR-RDM-01 | Trục thời gian hiển thị các epic | MUST | 10 |
| FR-RDM-02 | Ngày của epic tổng hợp từ các issue con | MUST | 10 |
| FR-RDM-03 | Phụ thuộc giữa các epic kèm cảnh báo xung đột lịch | MUST | 10 |
| FR-RDM-04 | Kéo để đổi ngày, thu phóng theo tuần/tháng/quý | MUST | 10 |
| FR-RDM-05 | Lọc và chia sẻ hoặc xuất ảnh roadmap | SHOULD | 10 |

## TIM — Time tracking

| ID | Yêu cầu | Ưu tiên | Phase |
|---|---|---|---|
| FR-TIM-01 | Ba giá trị thời gian trên issue: ước lượng ban đầu, còn lại, đã dùng | MUST | 11 |
| FR-TIM-02 | Ghi nhật ký công việc theo ngày kèm mô tả, sửa và xoá được | MUST | 11 |
| FR-TIM-03 | Tự động điều chỉnh thời gian còn lại khi ghi nhận công việc | MUST | 11 |
| FR-TIM-04 | Đơn vị thời gian cấu hình được | SHOULD | 11 |
| FR-TIM-05 | Báo cáo thời gian theo người, theo project và theo khoảng thời gian | MUST | 11 |

## VER — Version & release

| ID | Yêu cầu | Ưu tiên | Phase |
|---|---|---|---|
| FR-VER-01 | Tạo version với ngày bắt đầu và ngày phát hành | MUST | 12 |
| FR-VER-02 | Gán version bị ảnh hưởng và version sẽ sửa cho issue | MUST | 12 |
| FR-VER-03 | Trang release hiển thị tiến độ và các issue chưa hoàn thành | MUST | 12 |
| FR-VER-04 | Cảnh báo khi phát hành trong lúc còn issue chưa xong | MUST | 12 |
| FR-VER-05 | Sinh ghi chú phát hành tự động | SHOULD | 12 |
| FR-VER-06 | Lưu trữ version | SHOULD | 12 |

## DSH — Dashboard & report

| ID | Yêu cầu | Ưu tiên | Phase |
|---|---|---|---|
| FR-DSH-01 | Tạo dashboard với bố cục nhiều cột, kéo thả sắp xếp | MUST | 13 |
| FR-DSH-02 | Chia sẻ dashboard và đặt làm dashboard mặc định | MUST | 13 |
| FR-DSH-03 | Các loại gadget: kết quả bộ lọc, biểu đồ tròn, biểu đồ cột, tạo mới so với đã giải quyết, thống kê hai chiều, dòng hoạt động, sức khoẻ sprint, ghi chú | MUST | 13 |
| FR-DSH-04 | Cấu hình từng gadget và tự làm mới | SHOULD | 13 |
| FR-DSH-05 | Báo cáo dựng sẵn: tuổi trung bình, thời gian kể từ khi tạo, khối lượng công việc theo người | SHOULD | 13 |

## AUT — Automation

| ID | Yêu cầu | Ưu tiên | Phase |
|---|---|---|---|
| FR-AUT-01 | Quy tắc gồm điều kiện kích hoạt, điều kiện lọc và hành động | MUST | 14 |
| FR-AUT-02 | Nhánh rẽ để chạy hành động trên issue con hoặc issue liên quan | MUST | 14 |
| FR-AUT-03 | Kích hoạt khi: trường thay đổi, issue được tạo, bước chuyển được thực hiện, có bình luận mới, theo lịch, hoặc thủ công | MUST | 14 |
| FR-AUT-04 | Điều kiện dựa trên truy vấn, so sánh trường, hoặc thuộc tính người thực hiện | MUST | 14 |
| FR-AUT-05 | Hành động: sửa trường, thực hiện bước chuyển, bình luận, gán người, tạo issue hoặc sub-task, gửi email, gọi webhook, nhân bản, tạo liên kết | MUST | 14 |
| FR-AUT-06 | Giá trị động tham chiếu dữ liệu của issue trong nội dung hành động | MUST | 14 |
| FR-AUT-07 | Nhật ký chạy của từng quy tắc | MUST | 14 |
| FR-AUT-08 | Chống vòng lặp vô hạn và giới hạn số lần chạy | MUST | 14 |
| FR-AUT-09 | Bật tắt quy tắc, và phạm vi áp dụng theo project hoặc toàn workspace | MUST | 14 |

## BLK — Bulk operation & import/export

| ID | Yêu cầu | Ưu tiên | Phase |
|---|---|---|---|
| FR-BLK-01 | Thao tác hàng loạt: sửa, chuyển trạng thái, di chuyển, xoá, theo dõi, có bước xem trước và xác nhận | MUST | 15 |
| FR-BLK-02 | Nhập từ CSV với ánh xạ cột sang trường, chạy thử và báo lỗi theo từng dòng | MUST | 15 |
| FR-BLK-03 | Nhập dữ liệu từ Jira, Trello và GitHub Issues | SHOULD | 15 |
| FR-BLK-04 | Xuất toàn bộ dữ liệu project | MUST | 15 |
| FR-BLK-05 | Sao lưu và khôi phục ở cấp workspace | SHOULD | 15 |

## INT — Integration & public API

| ID | Yêu cầu | Ưu tiên | Phase |
|---|---|---|---|
| FR-INT-01 | REST API công khai kèm tài liệu OpenAPI | MUST | 16 |
| FR-INT-02 | API token có phạm vi quyền, tạo và thu hồi được | MUST | 16 |
| FR-INT-03 | Webhook đi ra: đăng ký, thử lại khi lỗi, nhật ký gửi, chữ ký xác thực | MUST | 16 |
| FR-INT-04 | Nhận diện mã issue trong commit, tên nhánh và pull request | MUST | 16 |
| FR-INT-05 | Bảng thông tin phát triển trên issue hiển thị commit, nhánh và pull request liên quan | MUST | 16 |
| FR-INT-06 | Lệnh trong commit để ghi nhận thời gian và chuyển trạng thái | SHOULD | 16 |
| FR-INT-07 | Gửi thông báo sang Slack hoặc Discord | SHOULD | 16 |
| FR-INT-08 | Đăng nhập một lần qua SAML/OIDC và tự động cấp phát tài khoản | COULD | 16 |
