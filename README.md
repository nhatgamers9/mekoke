# mekoke

## Phát triển

Flutter 3.47.6 (stable), Dart 3.13.5.

```
export PATH="/opt/flutter/bin:$PATH"
```

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
dart format lib test
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Khi đổi schema Drift (`lib/data/database.dart`), chạy lần lượt:

```
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev schema dump lib/data/database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
```

Chạy `schema dump` trước mỗi lần tăng `schemaVersion`: file `drift_schemas/drift_schema_v<N>.json` của phiên bản cũ phải có sẵn thì mới kiểm được migration.

## Xem trước trên web

Sản phẩm là app Android; thư mục `web/` chỉ để xem app trong trình duyệt lúc đang làm.

```
flutter run -d web-server --web-hostname localhost --web-port 5317 --no-web-resources-cdn
```

Mở `http://localhost:5317` ở khung nhìn cỡ điện thoại (360×800). Dữ liệu của bản xem trước nằm trong kho lưu trữ của trình duyệt (IndexedDB trên Chrome/Edge; Firefox dùng OPFS), tách khỏi máy thật. Ở chế độ debug, `main()` ghim nền tảng về Android để giao diện không đổi theo trình duyệt.

Bản xem trước khác máy thật ở mấy điểm:

- Khung trình duyệt mất focus thì web báo `inactive`: đồng hồ ở tab Timer đứng hình cho tới khi bấm lại vào khung.
- Tiền tệ và định dạng ngày lấy theo ngôn ngữ đứng đầu của trình duyệt, không theo vùng của điện thoại. Tiền tệ được lưu ở lần mở tab Money đầu tiên: muốn ra tiền khác phải đổi ngôn ngữ trình duyệt rồi xoá dữ liệu trang của bản xem trước. Web không theo cài đặt 24 giờ của máy.
- Không có thanh trạng thái, thanh điều hướng hay bàn phím ảo, nên mọi vùng an toàn bằng 0.
- Chuột cuộn bằng con lăn, không kéo để cuộn được như ngón tay; rê chuột có lớp phủ hover mà máy thật không có.
- Ký tự Figtree không có (₫, chữ Việt nhiều dấu) lấy từ phông dự phòng tải ở fonts.gstatic.com, cần mạng; `--no-web-resources-cdn` chỉ áp dụng cho CanvasKit.

Drift trên web cần hai file trong `web/`, phải khớp phiên bản trong `pubspec.lock`:

- `sqlite3.wasm`: tải từ bản phát hành `sqlite3-<phiên bản>` của [sqlite3.dart](https://github.com/simolus3/sqlite3.dart/releases) (đang dùng 3.5.2).
- `drift_worker.js`: biên dịch từ `tool/drift_worker.dart` (file `.deps` sinh kèm đã có trong `.gitignore`):

```
dart compile js -O2 --no-source-maps -o web/drift_worker.js tool/drift_worker.dart
```

Cập nhật lại cả hai mỗi khi nâng `sqlite3` hoặc `drift`.
