# TransactionRow

Một khoản chi, thu hoặc chuyển tiền trong danh sách lịch sử và trên màn hình Money.

- Truyền `title` (tên danh mục hoặc ghi chú), `detail` (tài khoản · giờ), `amount` đã định dạng sẵn kèm dấu và ký hiệu tiền, `kind` và `icon` của danh mục.
- `expense`: số tiền màu `ink`, có dấu "−". Chi tiêu là chuyện bình thường, không tô đỏ. `income`: màu `tide`, có dấu "+". `transfer`: màu `ink-muted`, không dấu.
- Số tiền dùng `body-strong` với chữ số rộng đều để các hàng thẳng cột. Các hàng nhóm theo ngày, mỗi nhóm có tiêu đề `overline` ghi ngày và tổng của ngày đó.
