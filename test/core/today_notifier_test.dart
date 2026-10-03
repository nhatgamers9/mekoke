import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/time/local_date.dart';
import 'package:steady/core/time/today_notifier.dart';

import '../helpers/widget_helpers.dart';

/// Chạy [body] rồi luôn dispose notifier, để bộ kiểm tra "Timer is still
/// pending" cuối test chỉ bắt đúng lỗi của code sản phẩm, không bắt lỗi dọn dẹp.
Future<void> _withNotifier(
  TodayNotifier today,
  Future<void> Function() body,
) async {
  try {
    await body();
  } finally {
    today.dispose();
  }
}

void main() {
  testWidgets('starts at the date of the clock', (tester) async {
    final now = DateTime(2026, 10, 2, 21);
    final today = TodayNotifier(Clock(() => now));
    expect(today.value, LocalDate(2026, 10, 2));
    today.dispose();
  });

  testWidgets('refresh follows the clock and notifies once per change', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 2, 21);
    final today = TodayNotifier(Clock(() => now));
    await _withNotifier(today, () async {
      var notifications = 0;
      today.addListener(() => notifications++);

      today.refresh();
      expect(notifications, 0, reason: 'same day: nothing to announce');

      now = DateTime(2026, 10, 3, 0, 0, 5);
      today.refresh();
      expect(today.value, LocalDate(2026, 10, 3));
      expect(notifications, 1);

      today.refresh();
      expect(notifications, 1);
    });
  });

  testWidgets('the timer fires just after midnight and updates the day', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 2, 23, 59, 30);
    final today = TodayNotifier(Clock(() => now))..start();
    await _withNotifier(today, () async {
      // Đồng hồ giả đã qua nửa đêm; Timer thì chưa tới 00:00:01.
      now = DateTime(2026, 10, 3, 0, 0, 5);
      await tester.pump(const Duration(seconds: 30));
      expect(today.value, LocalDate(2026, 10, 2), reason: 'timer not due yet');

      await tester.pump(const Duration(seconds: 2));
      expect(today.value, LocalDate(2026, 10, 3));
    });
  });

  testWidgets('after firing it schedules the next midnight', (tester) async {
    var now = DateTime(2026, 10, 2, 23, 59, 30);
    final today = TodayNotifier(Clock(() => now))..start();
    await _withNotifier(today, () async {
      now = DateTime(2026, 10, 3, 0, 0, 5);
      await tester.pump(const Duration(seconds: 31));
      expect(today.value, LocalDate(2026, 10, 3));

      // Hẹn lại tới 00:00:01 của ngày 4: từ 00:00:05 còn khoảng 24 giờ.
      now = DateTime(2026, 10, 4, 0, 0, 5);
      await tester.pump(const Duration(hours: 23));
      expect(today.value, LocalDate(2026, 10, 3));
      await tester.pump(const Duration(hours: 2));
      expect(today.value, LocalDate(2026, 10, 4));
    });
  });

  testWidgets('stop cancels the timer and is safe to repeat', (tester) async {
    var now = DateTime(2026, 10, 2, 23, 59, 30);
    final today = TodayNotifier(Clock(() => now))..start();
    await _withNotifier(today, () async {
      today.stop();
      today.stop();
      now = DateTime(2026, 10, 3, 0, 0, 5);
      await tester.pump(const Duration(seconds: 60));
      expect(today.value, LocalDate(2026, 10, 2));
    });
  });

  testWidgets('stop before start does not throw', (tester) async {
    final today = TodayNotifier(Clock(() => DateTime(2026, 10, 2, 21)));
    await _withNotifier(today, () async {
      expect(today.stop, returnsNormally);
    });
  });

  testWidgets('starting twice does not leave a second timer behind', (
    tester,
  ) async {
    final now = DateTime(2026, 10, 2, 23, 59, 30);
    final today = TodayNotifier(Clock(() => now));
    await _withNotifier(today, () async {
      today
        ..start()
        ..start()
        ..stop();
      // Nếu start() lần hai bỏ rơi Timer cũ thì test rớt vì Timer còn treo.
    });
  });

  testWidgets('dispose stops the timer without calling stop first', (
    tester,
  ) async {
    final now = DateTime(2026, 10, 2, 23, 59, 30);
    TodayNotifier(Clock(() => now))
      ..start()
      ..dispose();
  });

  testWidgets('resuming from the background refreshes the day', (tester) async {
    var now = DateTime(2026, 10, 2, 21);
    final today = TodayNotifier(Clock(() => now))..start();
    await _withNotifier(today, () async {
      sendToBackground(tester);
      now = DateTime(2026, 10, 4, 8);
      expect(
        today.value,
        LocalDate(2026, 10, 2),
        reason: 'unchanged while paused',
      );
      bringToForeground(tester);
      expect(today.value, LocalDate(2026, 10, 4));
    });
  });

  testWidgets('after resuming, the timer is re-armed for the new day', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 2, 21);
    final today = TodayNotifier(Clock(() => now))..start();
    await _withNotifier(today, () async {
      sendToBackground(tester);
      now = DateTime(2026, 10, 4, 23, 59, 30);
      bringToForeground(tester);
      expect(today.value, LocalDate(2026, 10, 4));

      now = DateTime(2026, 10, 5, 0, 0, 5);
      await tester.pump(const Duration(seconds: 31));
      expect(today.value, LocalDate(2026, 10, 5));
    });
  });

  testWidgets('after stop, resuming no longer refreshes', (tester) async {
    var now = DateTime(2026, 10, 2, 21);
    final today = TodayNotifier(Clock(() => now))
      ..start()
      ..stop();
    await _withNotifier(today, () async {
      sendToBackground(tester);
      now = DateTime(2026, 10, 4, 8);
      bringToForeground(tester);
      expect(today.value, LocalDate(2026, 10, 2));
    });
  });
}
