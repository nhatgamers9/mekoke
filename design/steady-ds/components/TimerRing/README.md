# TimerRing

Vòng đếm giờ tròn, trung tâm của tab Timer (nhịn ăn, HIIT/Tabata) và hẹn giờ ngủ trong Focus.

- Truyền `progress` (0–1, phần đã trôi qua), `time` đã định dạng sẵn, `phase` (FASTING, EATING, WORK, REST, SLEEP) và `caption` (giờ kết thúc, hiệp hiện tại).
- `tone="amber"` cho pha nỗ lực (nhịn ăn, hiệp WORK); `tone="tide"` cho pha nghỉ (cửa sổ ăn, hiệp REST). Pha luôn có chữ ở `phase`, không chỉ đổi màu.
- `numerals="serif"` (timer-xl, Newsreader) cho nhịn ăn và hẹn giờ ngủ, nơi người dùng nhìn gần và bình tĩnh. `numerals="gym"` (count-gym, Figtree 800) cho HIIT/Tabata, nơi người dùng nhìn từ xa giữa lúc tập.
- Kích thước chuẩn `size-ring` (264px) và nét `size-ring-stroke` (14px) trên màn hình 360dp. Không đặt hai vòng trên cùng một màn hình.
- Cập nhật mỗi giây; trình đọc màn hình chỉ nên đọc khi chuyển pha, không đọc từng giây.
