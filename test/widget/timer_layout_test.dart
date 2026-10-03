import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/services.dart';
import 'package:steady/features/timer/interval_config.dart';

import '../helpers/test_app.dart';
import '../helpers/timer_helpers.dart';
import '../helpers/widget_helpers.dart';

/// Mọi vùng chạm nhìn thấy được trên màn hình phải rộng và cao ít nhất 48.
void _expectTapTargets(WidgetTester t, String where) {
  final buttons = find.byWidgetPredicate(
    (w) => w is Semantics && w.properties.button == true,
  );
  final count = buttons.evaluate().length;
  expect(count, greaterThan(0), reason: '$where has buttons');
  for (var i = 0; i < count; i++) {
    final size = t.getSize(buttons.at(i));
    expect(
      size.width,
      greaterThanOrEqualTo(48),
      reason: '$where: button #$i is ${size.width} wide',
    );
    expect(
      size.height,
      greaterThanOrEqualTo(48),
      reason: '$where: button #$i is ${size.height} tall',
    );
  }
}

Future<void> _startWorkout(WidgetTester t) async {
  await t.ensureVisible(find.text('Start workout'));
  await t.tap(find.text('Start workout'));
  await t.pump();
  await t.pump(const Duration(seconds: 1));
}

void main() {
  for (final scale in [1.0, 2.0]) {
    group('Timer: no overflow at 360x800, text scale $scale', () {
      Future<AppServices> pump(WidgetTester t, FakeNow now) =>
          pumpSteadyApp(t, clock: now.clock, textScale: scale);

      testWidgets('Fasting: idle', (tester) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        await openTimer(tester);

        expect(find.text('Start fasting'), findsOne);
        expect(tester.takeException(), isNull);
        if (scale == 1.0) _expectTapTargets(tester, 'Fasting idle');

        await disposeSteadyApp(tester, services);
      });

      testWidgets('Fasting: running', (tester) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        await seedFast(
          tester,
          services,
          startedAt: evening().subtract(const Duration(hours: 6)),
        );
        await openTimer(tester);

        expect(find.text('FASTING'), findsOne);
        expect(tester.takeException(), isNull);
        if (scale == 1.0) _expectTapTargets(tester, 'Fasting running');

        await disposeSteadyApp(tester, services);
      });

      testWidgets('Fasting: past 24 hours (31:12:05)', (tester) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        await seedFast(
          tester,
          services,
          startedAt: evening().subtract(
            const Duration(hours: 31, minutes: 12, seconds: 5),
          ),
        );
        await openTimer(tester);

        expect(find.text('31:12:05'), findsOne);
        expect(find.text('Past your goal'), findsOne);
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      });

      testWidgets('Fasting: a fast that started on another day', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        await seedFast(tester, services, startedAt: DateTime(2026, 9, 28, 20));
        await openTimer(tester);

        expect(textPlain('Started Sep 28, 8:00 PM'), findsOne);
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      });

      testWidgets('Fasting: eating window', (tester) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        await seedFast(
          tester,
          services,
          startedAt: evening().subtract(const Duration(hours: 17)),
          endedAt: evening().subtract(const Duration(hours: 1)),
        );
        await openTimer(tester);

        expect(find.text('EATING'), findsOne);
        expect(tester.takeException(), isNull);
        if (scale == 1.0) _expectTapTargets(tester, 'Fasting eating');

        await disposeSteadyApp(tester, services);
      });

      testWidgets('Fasting: a long streak and a long last fast', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        // 40 ngày liền, lần gần nhất dài 99 giờ.
        for (var d = 40; d >= 1; d--) {
          final end = DateTime(
            2026,
            10,
            2,
          ).subtract(Duration(days: d - 1, hours: -12));
          await seedFast(
            tester,
            services,
            startedAt: end.subtract(Duration(hours: d == 1 ? 99 : 17)),
            endedAt: end,
          );
        }
        await openTimer(tester);

        expect(find.text('40 days'), findsOne);
        expect(find.text('99h 00m'), findsOne);
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      });

      testWidgets('Interval setup: Tabata', (tester) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        await openInterval(tester);

        expect(find.text('Start workout'), findsOne);
        expect(tester.takeException(), isNull);
        if (scale == 1.0) _expectTapTargets(tester, 'Interval setup');

        await disposeSteadyApp(tester, services);
      });

      testWidgets('Interval setup: several sets with a rest between', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        await seedCustomWorkout(
          tester,
          services,
          IntervalConfig.tabata
              .withValue(IntervalField.sets, 2)
              .withValue(IntervalField.work, 45)
              .withValue(IntervalField.rest, 90),
        );
        await openInterval(tester);

        expect(stepperRow('Rest between sets'), findsOne);
        expect(tester.takeException(), isNull);
        if (scale == 1.0) _expectTapTargets(tester, 'Interval setup sets');
        // Cuộn xuống cuối: hàng cuối và nút Start workout vẫn tới được.
        await tester.ensureVisible(semLabel('Increase Rest between sets'));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(isButtonEnabled(tester, 'Start workout'), isTrue);

        await letDbFinish(tester);
        await disposeSteadyApp(tester, services);
      });

      testWidgets('Interval setup: HIIT 30/30 and Custom chips', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        await openInterval(tester);

        await tapVisible(tester, find.text('HIIT 30/30'));
        await tapVisible(tester, find.text('Custom'));
        expect(tester.takeException(), isNull);

        await letDbFinish(tester);
        await disposeSteadyApp(tester, services);
      });

      testWidgets('Run screen: PREPARE, WORK, REST', (tester) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        await openInterval(tester);
        await _startWorkout(tester);

        expect(ring(tester).phase, 'PREPARE');
        expect(tester.takeException(), isNull);
        if (scale == 1.0) _expectTapTargets(tester, 'Run screen');

        now.value = evening().add(const Duration(seconds: 12));
        await tester.pump(const Duration(seconds: 1));
        expect(ring(tester).phase, 'WORK');
        expect(tester.takeException(), isNull);

        now.value = evening().add(const Duration(seconds: 33));
        await tester.pump(const Duration(seconds: 1));
        expect(ring(tester).phase, 'REST');
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      });

      testWidgets('Run screen: paused, with the Resume button', (tester) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        await openInterval(tester);
        await _startWorkout(tester);

        await tester.tap(semLabel('Pause'));
        await tester.pump();

        expect(semLabel('Resume'), findsOne);
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      });

      testWidgets('Run screen: DONE with the Close button', (tester) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        await openInterval(tester);
        await _startWorkout(tester);

        now.value = evening().add(const Duration(minutes: 10));
        await tester.pump(const Duration(seconds: 1));

        expect(ring(tester).phase, 'DONE');
        expect(find.text('Close'), findsOne);
        expect(tester.takeException(), isNull);
        if (scale == 1.0) _expectTapTargets(tester, 'Run screen done');

        await disposeSteadyApp(tester, services);
      });

      testWidgets('Run screen: sets, a long title and minutes in the caption', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        await seedCustomWorkout(
          tester,
          services,
          const IntervalConfig(
            prepare: 5,
            work: 90,
            rest: 120,
            rounds: 12,
            sets: 3,
            setRest: 180,
          ),
        );
        await openInterval(tester);
        await _startWorkout(tester);

        expect(find.text('Set 1 of 3 · Round 1 of 12'), findsOne);
        expect(tester.takeException(), isNull);

        // Tới nghỉ giữa các set: thời gian dài hơn một giờ ở "còn lại".
        now.value = evening().add(const Duration(seconds: 5 + 12 * 210 + 30));
        await tester.pump(const Duration(seconds: 1));
        expect(ring(tester).phase, 'REST');
        expect(find.textContaining('Set 1 of 3'), findsOne);
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      });
    });
  }
}
