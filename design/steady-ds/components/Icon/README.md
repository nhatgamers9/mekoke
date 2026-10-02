# Icon

Icon nét Lucide (giấy phép ISC) 24px, nét 2px, ăn theo `color` của phần tử cha.

- Truyền `name` (một trong 24 tên ở `index.d.ts`). Truyền `label` khi icon đứng một mình và mang nghĩa; icon đi kèm chữ thì để trống, nó sẽ bị ẩn khỏi trình đọc màn hình.
- Kích thước: 20 trong nút và hàng danh sách, 22 trên thanh tab, 24 mặc định, 26 trong SoundTile, 32 trong nút Play.
- Màu: `ink` mặc định, `ink-muted` khi không hoạt động, `amber` khi đang chọn hoặc đang chạy. Không tô màu icon theo từng tính năng.
- Không thêm icon ngoài bộ Lucide. Cần icon mới thì lấy từ `lucide-static` cùng phiên bản (1.49.0) và thêm vào bundle cùng thư mục `assets/Icons/`.
