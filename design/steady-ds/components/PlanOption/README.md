# PlanOption

Một gói đăng ký trên paywall, dạng thẻ chọn một (radio).

- Truyền `title`, `price` (đã định dạng theo locale từ Google Play Billing, không tự ghép), `period`, tuỳ chọn `note` (thời gian dùng thử) và `badge`, cùng `selected` và `onClick`.
- Giá trong bản mẫu chỉ là chỗ trống; giá thật lấy từ Play Console.
- Gói được chọn: viền `amber` 2px và dấu tích. Gói chưa chọn: viền `line-strong`.
- Nêu rõ thời gian dùng thử và kỳ thanh toán ngay trên thẻ, đúng chính sách gói đăng ký của Google Play. Một `badge` duy nhất trên cả paywall.
