import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/services.dart';
import 'data/database.dart';

Future<void> main() async {
  // Bản web chỉ để xem trước app Android: ghim nền tảng để mật độ, thanh cuộn
  // và hiệu ứng chuyển trang không đổi theo trình duyệt đang mở.
  if (kIsWeb && kDebugMode) {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  }
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initializeDateFormatting();
  runApp(
    SteadyApp(
      services: AppServices(
        db: AppDatabase.openDefault(),
        clock: const Clock(),
      ),
    ),
  );
}
