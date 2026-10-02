# SoundTile

Một âm thanh trong lưới 2 cột của tab Focus; bấm để phát hoặc dừng.

- Truyền `icon`, `name`, `detail` (một cụm mô tả ngắn), `active`, `locked` và `onClick`.
- Đang phát: nền `amber-soft`, icon `amber`, ba vạch equalizer tĩnh. Không làm vạch nhảy liên tục; màn hình Focus phải yên.
- `locked`: âm thanh Premium. Vẫn bấm được: mở sheet "Unlock for 24 hours" (xem quảng cáo có thưởng) hoặc paywall. Không ẩn âm thanh khoá đi.
- Icon theo loại âm: `waves` = brown noise, `wind` = white noise, `leaf` = pink noise, `cloud-rain` = mưa.
