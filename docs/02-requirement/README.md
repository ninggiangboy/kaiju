# 02 — Requirement

Ba tài liệu trong phần này mô tả **cái gì** hệ thống phải làm được, tách khỏi
**cách** làm (thuộc [System Design](../04-system-design/)). Đây là nơi tra cứu
khi cần biết phạm vi của một tính năng hoặc kiểm tra một ràng buộc trước khi implement.

**Liên quan:** [Brief](../01-brief/) · [Feature catalog](../03-features/README.md) · [System Design](../04-system-design/) · [ADR](../adr/)

---

## Ba tài liệu

| Tài liệu | Nội dung |
|---|---|
| [functional.md](functional.md) | Yêu cầu chức năng — hệ thống phải làm được gì |
| [non-functional.md](non-functional.md) | Yêu cầu phi chức năng — hiệu năng, khả dụng, bảo mật, vận hành |
| [constraints.md](constraints.md) | Ràng buộc đã chốt và không mở lại, mỗi ràng buộc dẫn tới ADR |

## Cách đánh ID

| Loại | Dạng | Ví dụ |
|---|---|---|
| Yêu cầu chức năng | `FR-<NHÓM>-<nn>` | `FR-IDN-04` |
| Yêu cầu phi chức năng | `NFR-<nn>` | `NFR-07` |
| Ràng buộc | `CON-<nn>` | `CON-03` |

**ID không bao giờ được tái sử dụng.** Yêu cầu bị bỏ thì giữ nguyên ID và đánh
dấu, không xoá dòng — nếu không, một `FR-ISS-12` trong lịch sử commit sẽ trỏ sang
một yêu cầu hoàn toàn khác.

### Nhóm yêu cầu chức năng

| Mã | Nhóm | Mã | Nhóm |
|---|---|---|---|
| `IDN` | Identity & authentication | `SRC` | Search & query |
| `WSP` | Workspace & member | `BRD` | Board (Kanban) |
| `PRJ` | Project | `SPR` | Sprint & Scrum |
| `ISS` | Issue | `RDM` | Roadmap & timeline |
| `COL` | Collaboration (comment, attachment, notification) | `TIM` | Time tracking |
| `SYN` | Sync & offline | `VER` | Version & release |
| `WKF` | Workflow | `DSH` | Dashboard & report |
| `FLD` | Custom field & screen | `AUT` | Automation |
| `BLK` | Bulk operation & import/export | `INT` | Integration & public API |

## Mức ưu tiên

| Mức | Nghĩa |
|---|---|
| `MUST` | Không có thì phase chứa nó chưa được coi là xong |
| `SHOULD` | Cần có để tính năng đầy đủ, nhưng có thể là hạng mục cuối cùng của phase |
| `COULD` | Có thì tốt; được phép đẩy sang phase sau mà không vi phạm nguyên tắc đầy đủ |

Lưu ý: nguyên tắc "làm từng tính năng một nhưng đầy đủ" nghĩa là `MUST` và
`SHOULD` của một phase **đều phải xong** trước khi sang phase kế tiếp. `COULD` là
phần duy nhất được phép hoãn, và khi hoãn thì phải ghi rõ trong
[feature catalog](../03-features/README.md) với trạng thái `DEFERRED`.

## Quan hệ với feature catalog

Yêu cầu trả lời "phải làm được gì". Feature trả lời "đơn vị công việc nào sẽ làm
điều đó" và mang trạng thái tiến độ. Một yêu cầu có thể được hiện thực hoá bởi
nhiều feature; một feature có thể phục vụ nhiều yêu cầu.

**Mọi `FR` đều phải có ít nhất một feature hiện thực hoá nó.** Đây là một trong
các mục kiểm tra khi rà soát tài liệu.
