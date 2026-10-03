// Nguồn của web/drift_worker.js: worker giữ kết nối SQLite khi app chạy trên
// trình duyệt. Biên dịch lại mỗi khi nâng phiên bản drift (xem README).
import 'package:drift/wasm.dart';

void main() => WasmDatabase.workerMainForOpen();
