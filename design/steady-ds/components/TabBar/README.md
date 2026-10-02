# TabBar

Thanh điều hướng dưới cùng với 5 tab: Focus, Timer, Streaks, Money, Check-in.

- Truyền `items` (`{ icon, label }`), `active` và `onChange`.
- Tab đang mở: icon `amber` trong viên nền `amber-soft`, chữ `ink`. Tab khác: `ink-muted`.
- Ẩn thanh tab trên màn hình hẹn giờ ngủ (theme Bedtime) và khi đồng hồ HIIT chạy toàn màn hình.
- Settings không phải một tab: mở từ IconButton `settings` ở góc trên của mỗi tab.
- Tab Money dùng icon `wallet`. Không thêm tab thứ sáu: tính năng mới vào trong một tab có sẵn hoặc vào Settings.
