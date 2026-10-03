# Keypad

Bàn phím số riêng để nhập số tiền, nằm ở nửa dưới màn hình thêm khoản thu hoặc chi.

- Truyền `onKey`, nhận một trong `0`–`9`, `.` và `del`. Màn hình tự giữ chuỗi số và định dạng tiền theo locale (dấu thập phân của máy).
- Số đang nhập hiện phía trên bằng `money-xl`, căn giữa. Không tự mở bàn phím hệ thống.
- Phím cao 56px, nền `surface`; phím xoá trong suốt, icon `ink-muted`.
