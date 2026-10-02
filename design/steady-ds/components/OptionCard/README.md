# OptionCard

Thẻ chọn nhiều cho câu hỏi có nhiều đáp án, như màn hình "What brings you here?" lúc giới thiệu app.

- Truyền `title`, tuỳ chọn `detail` và `icon`, `selected`, `onClick`. Thẻ có vai trò `checkbox`.
- Đã chọn: viền 2px `amber`, icon trên nền `amber-soft`, ô tích nền `amber`. Chưa chọn: ô tích viền `line-strong`.
- Chọn một đáp án (radio) thì dùng PlanOption hoặc SegmentedControl, không dùng OptionCard.
