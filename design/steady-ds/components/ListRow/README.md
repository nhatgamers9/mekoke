# ListRow

Hàng trong Settings, lịch sử nhịn ăn, danh sách chuỗi rút gọn: icon, tiêu đề, dòng phụ, phần cuối.

- Truyền `title`; tuỳ chọn `detail`, `icon`, `trailing` (`'chevron'`, một chuỗi giá trị ngắn như "45 min", hoặc một node như Switch) và `onClick`.
- Có `onClick` thì hàng là một nút (chuyển màn hình, mở sheet). Không có thì là `div` (hàng chỉ để hiển thị, hoặc chứa Switch).
- Các hàng xếp liền nhau, ngăn bằng `line`. Bọc nhóm hàng trong khối `radius-lg` có `overflow: hidden`.
