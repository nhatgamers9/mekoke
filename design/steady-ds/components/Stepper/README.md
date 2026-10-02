# Stepper

Hàng chỉnh một con số bằng nút − và +: thời gian Work, Rest, số Rounds của bài tập ngắt quãng, độ dài hẹn giờ ngủ.

- Truyền `label`, `value` (đã định dạng, "0:20" hoặc "8"), tuỳ chọn `icon` và `detail`, `onDecrement`, `onIncrement`, `atMin` và `atMax` để khoá nút ở giới hạn.
- Bước nhảy: 5 giây cho thời lượng dưới 1 phút, 15 giây cho thời lượng dài hơn, 1 cho số lần. Nhấn giữ để tăng hoặc giảm liên tục.
- Nút − và + là vùng chạm `size-tap`. Con số dùng `stat` với chữ số rộng đều.
- Các hàng Stepper xếp liền nhau trong một khối `radius-lg`, giống ListRow.
