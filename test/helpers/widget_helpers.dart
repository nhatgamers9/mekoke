import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/services.dart';
import 'package:steady/core/theme/tokens.dart';
import 'package:steady/core/time/local_date.dart';
import 'package:steady/data/database.dart';
import 'package:steady/ui/components/steady_button.dart';
import 'package:steady/ui/components/steady_tab_bar.dart';

/// Đồng hồ giả có thể chỉnh giờ giữa chừng.
class FakeNow {
  FakeNow(this.value);

  DateTime value;

  Clock get clock => Clock(() => value);
}

/// 2026-10-02 21:00, mốc dùng chung của các widget test.
DateTime evening() => DateTime(2026, 10, 2, 21);

final today = LocalDate(2026, 10, 2);

const saveErrorText = "Couldn't save. Try again.";
const resetDoneText = "That's okay. Your count starts again today.";
const checkInSavedText = 'Check-in saved.';

/// Chạm vào nhãn trên thanh tab (không nhầm với tiêu đề màn hình).
Finder tabLabel(String label) =>
    find.descendant(of: find.byType(SteadyTabBar), matching: find.text(label));

Future<void> tapTab(WidgetTester t, String label) async {
  await t.tap(tabLabel(label));
  await t.pump();
  await t.pump();
}

int currentTab(WidgetTester t) =>
    t.widget<SteadyTabBar>(find.byType(SteadyTabBar)).current;

/// Ghi DB trong một `runAsync` riêng rồi để stream và khung hình kịp cập nhật.
/// Mỗi lần ghi một lần gọi: ghi hai lần trong cùng một runAsync có thể treo.
Future<T> dbAction<T>(WidgetTester t, Future<T> Function() action) async {
  final result = await t.runAsync(action);
  await t.pump();
  await t.pump();
  return result as T;
}

Future<Habit> seedHabit(
  WidgetTester t,
  AppServices s, {
  String name = 'No smoking',
  LocalDate? since,
}) {
  return dbAction(
    t,
    () => s.habits.addHabit(
      name: name,
      cleanSince: since ?? LocalDate(2026, 5, 28),
      today: s.today.value,
    ),
  );
}

/// Chặn mọi lần ghi vào bảng [table] bằng trigger SQLite, mô phỏng DB lỗi mà
/// không làm hỏng các truy vấn đọc (stream vẫn sống).
Future<void> breakWrites(
  WidgetTester t,
  AppServices s,
  String table, {
  bool insert = true,
  bool update = true,
  bool delete = true,
}) async {
  await t.runAsync(() async {
    for (final (enabled, op) in [
      (insert, 'INSERT'),
      (update, 'UPDATE'),
      (delete, 'DELETE'),
    ]) {
      if (!enabled) continue;
      await s.db.customStatement(
        'CREATE TRIGGER fail_${table}_$op BEFORE $op ON $table '
        "BEGIN SELECT RAISE(ABORT, 'simulated write failure'); END;",
      );
    }
  });
}

Future<void> repairWrites(WidgetTester t, AppServices s, String table) async {
  await t.runAsync(() async {
    for (final op in ['INSERT', 'UPDATE', 'DELETE']) {
      await s.db.customStatement('DROP TRIGGER IF EXISTS fail_${table}_$op');
    }
  });
}

SteadyButton buttonLabeled(WidgetTester t, String label) =>
    t.widget<SteadyButton>(find.widgetWithText(SteadyButton, label).first);

bool isButtonEnabled(WidgetTester t, String label) =>
    buttonLabeled(t, label).onPressed != null;

/// Đưa mọi animation (đóng sheet, snackbar vào) về trạng thái yên.
Future<void> settle(WidgetTester t) => t.pumpAndSettle();

/// Ghi lại các lần gọi `SystemNavigator.pop` (thoát app).
List<MethodCall> captureSystemPop(WidgetTester t) {
  final calls = <MethodCall>[];
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemNavigator.pop') calls.add(call);
      return null;
    },
  );
  addTearDown(
    () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

/// Màu ARGB của điểm ảnh tại [p] trên khung hình đang vẽ (đúng thứ người dùng
/// nhìn thấy, tính cả thứ tự chồng lớp).
Future<int> pixelAt(WidgetTester t, Offset p) async {
  final size = t.view.physicalSize;
  final layer = t.binding.renderViews.first.debugLayer! as OffsetLayer;
  final argb = await t.runAsync(() async {
    final image = await layer.toImage(Offset.zero & size);
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final i = (p.dy.toInt() * image.width + p.dx.toInt()) * 4;
    return (data.getUint8(i + 3) << 24) |
        (data.getUint8(i) << 16) |
        (data.getUint8(i + 1) << 8) |
        data.getUint8(i + 2);
  });
  return argb!;
}

/// Người dùng có thật sự nhìn thấy snackbar không: điểm ảnh bên trong thân
/// snackbar phải có màu nền của snackbar (surface-2), không bị lớp khác che.
Future<bool> snackBarIsVisibleToUser(WidgetTester t) async {
  final body = find
      .descendant(of: find.byType(SnackBar), matching: find.byType(Material))
      .first;
  final rect = t.getRect(body);
  final sample = Offset(rect.left + 8, rect.center.dy);
  return await pixelAt(t, sample) == SteadyColors.dark.surface2.toARGB32();
}

/// Đưa app ra nền theo đúng chuỗi trạng thái mà Android gửi:
/// inactive -> hidden -> paused.
void sendToBackground(WidgetTester t) {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    t.binding.handleAppLifecycleStateChanged(state);
  }
}

/// Đưa app trở lại: paused -> hidden -> inactive -> resumed.
void bringToForeground(WidgetTester t) {
  for (final state in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    t.binding.handleAppLifecycleStateChanged(state);
  }
}

/// Chờ snackbar tự biến mất (4 giây) như người dùng thật phải chờ.
Future<void> waitSnackBarGone(WidgetTester t) async {
  await t.pump(const Duration(seconds: 5));
  await t.pumpAndSettle();
}
