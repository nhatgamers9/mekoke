# Button

Nút dạng viên thuốc. `secondary` là mặc định; `primary` (nền amber) tối đa một nút trên mỗi màn hình, dành cho việc chính của màn hình đó.

- Truyền nhãn dạng động từ đứng đầu, viết hoa chữ đầu câu: "Start fasting", "Save check-in", "Try 3 days free".
- `size="lg"` (52px) cho nút chính ở cuối màn hình, thường kèm `block`. `size="md"` (44px) trong thẻ và sheet.
- `ghost` cho lựa chọn phụ cạnh nút chính ("Not now"). `danger` chỉ cho hành động xoá dữ liệu, luôn có hộp xác nhận.
- Không đặt hai nút `primary` cạnh nhau. Không dùng `danger` cho nút "Reset streak": đặt lại chuỗi là hành động trung tính, dùng `secondary`.
