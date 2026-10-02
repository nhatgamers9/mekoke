# FilterChips

Hàng chip lọc cuộn ngang, chọn một: danh mục âm thanh, khoảng thời gian trong lịch sử.

- Truyền `options`, `value`, `onChange` và `label` (tên nhóm cho trình đọc màn hình).
- Chip đang chọn có nền `ink` và chữ `bg`, giống SegmentedControl. Dùng FilterChips khi có từ năm lựa chọn trở lên hoặc nhãn dài; ít hơn thì dùng SegmentedControl.
- Chip đầu tiên luôn là "All". Hàng chip dính ở đầu danh sách khi cuộn.
