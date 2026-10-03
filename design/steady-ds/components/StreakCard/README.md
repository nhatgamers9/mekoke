# StreakCard

Bộ đếm số ngày "sạch" cho một thói quen đang bỏ, trong tab Streaks.

- Truyền `habit`, `days`, `since` (chuỗi đã định dạng, "Since May 28") và tuỳ chọn `milestone` `{ label, progress }`.
- `size="lg"`: chuỗi chính ở đầu tab, con số `count-xl`. `size="sm"`: các chuỗi còn lại, con số `stat`.
- Mốc mặc định: 1, 3, 7, 14, 30, 60, 90, 180, 365 ngày. Thanh mốc màu `tide`.
- Giọng văn không phán xét. Tái phạm thì nút là "Reset streak" (secondary) kèm câu "That's okay. Day 1 starts now." Không dùng màu đỏ, không dùng từ "failed".
