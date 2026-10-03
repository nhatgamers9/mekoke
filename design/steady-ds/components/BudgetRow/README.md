# BudgetRow

Một phong bì ngân sách hoặc một nhóm của quy tắc 50/30/20: đã chi bao nhiêu so với hạn mức.

- Truyền `name`, `icon`, `spent`, `limit`, `left` (chuỗi đã định dạng: "$130 left", "Over by $24") và `value` (0–1). Truyền `over` khi đã vượt hạn mức.
- Thanh trong mức màu `amber`; vượt mức thì thanh đầy màu `rose`, kèm icon `triangle-alert` và chữ "Over by …". Màu không bao giờ là tín hiệu duy nhất.
- Giọng văn trung tính: "Over by $24", không viết "You overspent!". Bấm vào hàng thì mở danh sách giao dịch của phong bì đó.
