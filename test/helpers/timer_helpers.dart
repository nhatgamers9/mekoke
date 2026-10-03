import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/services.dart';
import 'package:steady/data/database.dart';
import 'package:steady/features/timer/fasting_plan.dart';
import 'package:steady/features/timer/interval_config.dart';
import 'package:steady/ui/components/steady_stepper.dart';
import 'package:steady/ui/components/timer_ring.dart';

import 'test_app.dart';
import 'widget_helpers.dart';

/// Chuỗi giờ của intl chứa U+202F (khoảng trắng hẹp) trước "AM"/"PM". Đổi về
/// dấu cách thường để so với chuỗi viết tay.
String plain(String s) => s.replaceAll(RegExp('[  ]'), ' ');

/// `Text` có nội dung (sau khi chuẩn hoá khoảng trắng) đúng bằng [expected].
Finder textPlain(String expected) => find.byWidgetPredicate(
  (w) => w is Text && w.data != null && plain(w.data!) == expected,
  description: 'Text "$expected"',
);

/// `Semantics` có nhãn đúng bằng [label] (nút Stepper, nút icon, chip...).
Finder semLabel(String label) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == label,
  description: 'Semantics "$label"',
);

/// Chờ DB (stream, nạp prefs, các lần lưu `unawaited`) làm xong rồi dựng lại
/// khung hình. Mỗi lần ghi DB một `runAsync`.
Future<void> letDbFinish(WidgetTester t) async {
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 80)),
  );
  await t.pump();
  await t.pump();
}

/// Sau một lần chạm có ghi DB: dựng khung hình, chờ DB, dựng lại.
Future<void> afterTapDb(WidgetTester t) async {
  await t.pump();
  await letDbFinish(t);
}

/// Mở tab Timer (chế độ Fasting) và chờ stream đầu tiên.
Future<void> openTimer(WidgetTester t) async {
  await tapTab(t, 'Timer');
  await letDbFinish(t);
}

/// Mở tab Timer rồi sang chế độ Interval.
Future<void> openInterval(WidgetTester t) async {
  await openTimer(t);
  await t.tap(find.text('Interval'));
  await t.pump();
  await letDbFinish(t);
}

/// Ghi một lần nhịn thẳng vào DB (đã kết thúc nếu có [endedAt]).
Future<Fast> seedFast(
  WidgetTester t,
  AppServices s, {
  required DateTime startedAt,
  DateTime? endedAt,
  FastingPlan plan = FastingPlan.h16,
}) {
  return dbAction(
    t,
    () => s.db
        .into(s.db.fasts)
        .insertReturning(
          FastsCompanion.insert(
            plan: plan,
            goalMinutes: plan.fastHours * 60,
            startedAt: startedAt,
            endedAt: Value(endedAt),
          ),
        ),
  );
}

/// Ghi trực tiếp một khoá prefs (mỗi lần một `runAsync`).
Future<void> seedPref(
  WidgetTester t,
  AppServices s,
  String name,
  String value,
) async {
  await t.runAsync(() => s.prefs.write(name, value));
}

/// Ghi sẵn bài Custom và chọn nó, như thể người dùng đã lưu ở lần mở trước.
Future<void> seedCustomWorkout(
  WidgetTester t,
  AppServices s,
  IntervalConfig config,
) async {
  await seedPref(t, s, 'interval.preset', IntervalPresetId.custom.name);
  await seedPref(t, s, 'interval.custom', config.toJson());
}

FakeScreenAwake awakeOf(AppServices s) => s.screenAwake as FakeScreenAwake;

/// Ghi lại mọi lệnh rung (`HapticFeedback.*`) gửi qua `SystemChannels.platform`.
/// `heavyImpact` mang tham số `HapticFeedbackType.heavyImpact`; `vibrate` thì
/// không có tham số.
class HapticLog {
  final calls = <MethodCall>[];

  Iterable<MethodCall> get all =>
      calls.where((c) => c.method == 'HapticFeedback.vibrate');

  int get heavy =>
      all.where((c) => c.arguments == 'HapticFeedbackType.heavyImpact').length;

  int get vibrate => all.where((c) => c.arguments == null).length;

  int get total => all.length;
}

HapticLog captureHaptics(WidgetTester t) {
  final log = HapticLog();
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      log.calls.add(call);
      return null;
    },
  );
  addTearDown(
    () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return log;
}

/// Hàng Stepper có nhãn [label] (so khớp đúng cả chuỗi nên "Work" không nhầm
/// với "Work + rest").
Finder stepperRow(String label) => find.widgetWithText(SteadyStepper, label);

String stepperValue(WidgetTester t, String label) =>
    t.widget<SteadyStepper>(stepperRow(label)).value;

/// Cuộn tới nút rồi chạm. Trong test Stepper cao hơn máy thật (phông Ahem) nên
/// phải `ensureVisible` trước.
Future<void> tapVisible(WidgetTester t, Finder finder) async {
  await t.ensureVisible(finder);
  await t.pump();
  await t.tap(finder);
  await t.pump();
}

Future<void> stepUpBy(WidgetTester t, String label, {int times = 1}) async {
  for (var i = 0; i < times; i++) {
    await tapVisible(t, semLabel('Increase $label'));
  }
}

Future<void> stepDownBy(WidgetTester t, String label, {int times = 1}) async {
  for (var i = 0; i < times; i++) {
    await tapVisible(t, semLabel('Decrease $label'));
  }
}

/// Vòng đếm giờ đang hiện (chỉ có một vòng nhìn thấy).
TimerRing ring(WidgetTester t) => t.widget<TimerRing>(find.byType(TimerRing));

/// Đưa đồng hồ giả tới [to] rồi để Timer một giây nổ để màn hình dựng lại.
Future<void> advanceTo(WidgetTester t, FakeNow now, DateTime to) async {
  now.value = to;
  await t.pump(const Duration(seconds: 1));
}

/// Mở app trên DB trong bộ nhớ với đồng hồ 24 giờ.
Future<AppServices> pumpSteadyApp24h(
  WidgetTester t, {
  required FakeNow now,
}) async {
  t.platformDispatcher.alwaysUse24HourFormatTestValue = true;
  addTearDown(t.platformDispatcher.clearAlwaysUse24HourTestValue);
  return pumpSteadyApp(t, clock: now.clock);
}
