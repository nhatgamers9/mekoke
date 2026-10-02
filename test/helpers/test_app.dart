import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:steady/app.dart';
import 'package:steady/core/screen_awake.dart';
import 'package:steady/core/services.dart';
import 'package:steady/data/database.dart';

/// Giữ sáng màn hình giả: chỉ ghi lại các lần gọi `keepOn`.
class FakeScreenAwake implements ScreenAwake {
  final calls = <bool>[];

  @override
  Future<void> keepOn(bool on) async {
    calls.add(on);
  }
}

/// Dựng app với DB trong bộ nhớ và đồng hồ giả.
/// Cuối mỗi widget test phải gọi [disposeSteadyApp].
Future<AppServices> pumpSteadyApp(
  WidgetTester t, {
  required Clock clock,
  Size size = const Size(360, 800),
  double textScale = 1.0,
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  await initializeDateFormatting();
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  t.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    t.view.resetPhysicalSize();
    t.view.resetDevicePixelRatio();
    t.platformDispatcher.clearTextScaleFactorTestValue();
  });
  final services = AppServices(
    db: AppDatabase(NativeDatabase.memory()),
    clock: clock,
    screenAwake: FakeScreenAwake(),
  );
  await t.pumpWidget(SteadyApp(services: services));
  await t.pump();
  return services;
}

/// Gỡ cây widget rồi đóng DB, tránh lỗi "A Timer is still pending" của
/// stream Drift.
Future<void> disposeSteadyApp(WidgetTester t, AppServices s) async {
  await t.pumpWidget(const SizedBox.shrink());
  await t.pump(Duration.zero);
  await s.dispose();
}
