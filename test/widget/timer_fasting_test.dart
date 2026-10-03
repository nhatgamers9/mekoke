import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/app.dart';
import 'package:steady/features/timer/fasting_plan.dart';
import 'package:steady/features/timer/fasting_view.dart';
import 'package:steady/features/timer/interval_setup_view.dart';
import 'package:steady/ui/components/steady_button.dart';
import 'package:steady/ui/components/steady_chip.dart';
import 'package:steady/ui/components/steady_segmented_control.dart';
import 'package:steady/ui/components/timer_ring.dart';

import '../helpers/test_app.dart';
import '../helpers/timer_helpers.dart';
import '../helpers/widget_helpers.dart';

/// 2026-10-02 21:00 là mốc của `evening()`.
final _start = DateTime(2026, 10, 2, 21);

FastingPlan _selectedPlan(WidgetTester t) => t
    .widget<SteadySegmentedControl<FastingPlan>>(
      find.byType(SteadySegmentedControl<FastingPlan>),
    )
    .value;

/// Giá trị nằm trên nhãn của ô số liệu ([label] là dòng nhãn bên dưới).
String _stat(WidgetTester t, String label) {
  final tile = find
      .ancestor(of: find.text(label), matching: find.byType(Container))
      .first;
  final texts = t
      .widgetList<Text>(find.descendant(of: tile, matching: find.byType(Text)))
      .map((w) => w.data)
      .whereType<String>()
      .toList();
  return texts.first;
}

Future<void> _startFast(WidgetTester t) async {
  await t.tap(find.text('Start fasting'));
  await afterTapDb(t);
}

void main() {
  group('Opening the Timer tab', () {
    testWidgets('before the tab is first opened nothing of Timer is built', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);

      expect(find.byType(FastingView, skipOffstage: false), findsNothing);
      expect(find.byType(IntervalSetupView, skipOffstage: false), findsNothing);

      await tapTab(tester, 'Timer');
      expect(find.byType(FastingView), findsOne);
      expect(
        find.byType(IntervalSetupView, skipOffstage: false),
        findsOne,
        reason: 'both modes are built once the tab has been opened',
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('idle: Start fasting, plan 16:8, an empty ring', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);

      expect(find.text('Timer'), findsNWidgets(2)); // tab + tiêu đề
      expect(find.text('Fasting'), findsOne);
      expect(find.text('Interval'), findsOne);
      expect(find.text('Start fasting'), findsOne);
      expect(find.text('End fast'), findsNothing);
      expect(isButtonEnabled(tester, 'Start fasting'), isTrue);
      expect(
        buttonLabeled(tester, 'Start fasting').variant,
        SteadyButtonVariant.primary,
      );
      for (final plan in ['16:8', '18:6', '20:4', 'OMAD']) {
        expect(find.text(plan), findsOne);
      }
      expect(_selectedPlan(tester), FastingPlan.h16);

      expect(ring(tester).time, '0:00:00');
      expect(ring(tester).phase, isNull);
      expect(ring(tester).progress, 0);
      expect(ring(tester).caption, 'Goal: 16 hours');
      expect(find.text('FASTING'), findsNothing);
      expect(find.text('EATING'), findsNothing);

      expect(_stat(tester, 'Last fast'), '—');
      expect(_stat(tester, 'Fasting streak'), '0 days');
      expect(
        find.text(
          "Fasting isn't right for everyone. Check with your doctor first.",
        ),
        findsOne,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('choosing a plan changes the goal shown', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);

      for (final (label, plan, goal) in [
        ('18:6', FastingPlan.h18, 'Goal: 18 hours'),
        ('20:4', FastingPlan.h20, 'Goal: 20 hours'),
        ('OMAD', FastingPlan.omad, 'Goal: 23 hours'),
        ('16:8', FastingPlan.h16, 'Goal: 16 hours'),
      ]) {
        await tester.tap(find.text(label));
        await tester.pump();
        expect(_selectedPlan(tester), plan, reason: label);
        expect(ring(tester).caption, goal, reason: label);
      }

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the plan that was chosen is the plan that starts', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await tester.tap(find.text('OMAD'));
      await tester.pump();

      await _startFast(tester);

      final rows = await tester.runAsync(
        () => services.db.select(services.db.fasts).get(),
      );
      expect(rows!.single.plan, FastingPlan.omad);
      expect(rows.single.goalMinutes, 23 * 60);
      expect(textPlain('Ends 8:00 PM'), findsOne, reason: '21:00 + 23 h');

      await disposeSteadyApp(tester, services);
    });
  });

  group('Starting and watching a fast', () {
    testWidgets('start: FASTING, "Started today", "Ends 1:00 PM"', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);

      await _startFast(tester);

      expect(find.text('FASTING'), findsOne);
      expect(ring(tester).phase, 'FASTING');
      expect(ring(tester).time, '0:00:00');
      expect(ring(tester).tone, TimerRingTone.amber);
      expect(ring(tester).progress, 0);
      expect(textPlain('Started today, 9:00 PM'), findsOne);
      expect(textPlain('Ends 1:00 PM'), findsOne);
      expect(find.text('16:8'), findsOne, reason: 'the plan chip');
      expect(
        find.byType(SteadySegmentedControl<FastingPlan>),
        findsNothing,
        reason: 'the plan cannot be changed while fasting',
      );
      expect(find.text('End fast'), findsOne);
      expect(find.text('Start fasting'), findsNothing);
      expect(
        buttonLabeled(tester, 'End fast').variant,
        SteadyButtonVariant.secondary,
      );
      expect(_stat(tester, 'Left in this fast'), '16h 00m');

      final rows = await tester.runAsync(
        () => services.db.select(services.db.fasts).get(),
      );
      expect(rows, hasLength(1));
      expect(rows!.single.startedAt, _start);
      expect(rows.single.endedAt, isNull);
      expect(rows.single.goalMinutes, 960);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the display counts up every second', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await _startFast(tester);
      expect(ring(tester).time, '0:00:00');

      for (var i = 1; i <= 3; i++) {
        await advanceTo(tester, now, _start.add(Duration(seconds: i)));
        expect(ring(tester).time, '0:00:0$i');
      }
      await advanceTo(
        tester,
        now,
        _start.add(const Duration(minutes: 5, seconds: 7)),
      );
      expect(ring(tester).time, '0:05:07');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('overnight: 10:00:00, "Started yesterday", 6h 00m left', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await _startFast(tester);

      await advanceTo(tester, now, DateTime(2026, 10, 3, 7));

      expect(ring(tester).time, '10:00:00');
      expect(textPlain('Started yesterday, 9:00 PM'), findsOne);
      expect(textPlain('Started today, 9:00 PM'), findsNothing);
      expect(_stat(tester, 'Left in this fast'), '6h 00m');
      expect(ring(tester).progress, closeTo(10 / 16, 1e-9));
      expect(textPlain('Ends 1:00 PM'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a fast started two days ago shows its date', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await _startFast(tester);

      await advanceTo(tester, now, DateTime(2026, 10, 4, 9));

      expect(textPlain('Started Oct 2, 9:00 PM'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('crossing midnight turns "today" into "yesterday"', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await _startFast(tester);
      expect(textPlain('Started today, 9:00 PM'), findsOne);

      await advanceTo(tester, now, DateTime(2026, 10, 3, 0, 0, 30));

      expect(textPlain('Started yesterday, 9:00 PM'), findsOne);
      expect(ring(tester).time, '3:00:30');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('past 24 hours: 31:12:05, a full ring, "Past your goal"', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await _startFast(tester);

      await advanceTo(
        tester,
        now,
        _start.add(const Duration(hours: 31, minutes: 12, seconds: 5)),
      );

      expect(ring(tester).time, '31:12:05');
      expect(ring(tester).progress, 1);
      expect(find.text('Past your goal'), findsOne);
      expect(find.text('Left in this fast'), findsNothing);
      expect(_stat(tester, 'Past your goal'), '15h 12m');
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('reaching the goal: "Goal reached at", "Past your goal"', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await _startFast(tester);

      await advanceTo(tester, now, DateTime(2026, 10, 3, 12, 59, 59));
      expect(textPlain('Ends 1:00 PM'), findsOne);
      expect(find.text('Left in this fast'), findsOne);

      await advanceTo(tester, now, DateTime(2026, 10, 3, 13));
      expect(ring(tester).time, '16:00:00');
      expect(textPlain('Goal reached at 1:00 PM'), findsOne);
      expect(textPlain('Ends 1:00 PM'), findsNothing);
      expect(find.text('Past your goal'), findsOne);
      expect(_stat(tester, 'Past your goal'), '0h 00m');
      expect(ring(tester).progress, 1);

      await advanceTo(tester, now, DateTime(2026, 10, 3, 14, 30));
      expect(ring(tester).time, '17:30:00');
      expect(_stat(tester, 'Past your goal'), '1h 30m');

      await disposeSteadyApp(tester, services);
    });

    testWidgets(
      'the clock set before the start gives 0:00:00, not a negative',
      (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(tester, clock: now.clock);
        await openTimer(tester);
        await _startFast(tester);

        await advanceTo(tester, now, _start.subtract(const Duration(hours: 1)));

        expect(ring(tester).time, '0:00:00');
        expect(ring(tester).progress, 0);
        expect(_stat(tester, 'Left in this fast'), '16h 00m');
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      },
    );

    testWidgets('the 24-hour clock shows 21:00 and 13:00', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp24h(tester, now: now);
      await openTimer(tester);
      await _startFast(tester);

      expect(find.text('Started today, 21:00'), findsOne);
      expect(find.text('Ends 13:00'), findsOne);
      expect(find.textContaining('PM'), findsNothing);

      await advanceTo(tester, now, DateTime(2026, 10, 3, 13));
      expect(find.text('Goal reached at 13:00'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets(
      'a fast across the daylight-saving change uses real elapsed time',
      (tester) async {
        // 2026-03-08 là ngày Mỹ chuyển sang giờ mùa hè (02:00 -> 03:00). Ở múi
        // giờ không đổi giờ (như UTC) chỉ có nhánh `hasGap == false`.
        final hasGap =
            DateTime(2026, 3, 7, 20).timeZoneOffset !=
            DateTime(2026, 3, 8, 13).timeZoneOffset;
        final now = FakeNow(DateTime(2026, 3, 7, 20));
        final services = await pumpSteadyApp(tester, clock: now.clock);
        await openTimer(tester);
        await _startFast(tester);

        // 16 giờ thật sau 20:00 ngày 7/3.
        expect(textPlain(hasGap ? 'Ends 1:00 PM' : 'Ends 12:00 PM'), findsOne);

        await advanceTo(tester, now, DateTime(2026, 3, 8, 13));
        expect(ring(tester).time, hasGap ? '16:00:00' : '17:00:00');
        expect(
          textPlain(
            hasGap ? 'Goal reached at 1:00 PM' : 'Goal reached at 12:00 PM',
          ),
          findsOne,
        );

        await disposeSteadyApp(tester, services);
      },
    );
  });

  group('Ending a fast', () {
    testWidgets('ending early asks first; Keep fasting changes nothing', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await _startFast(tester);
      await advanceTo(tester, now, DateTime(2026, 10, 3, 7));

      await tester.tap(find.text('End fast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('End fast now?'), findsOne);
      expect(find.text("You're 6h 00m from your goal."), findsOne);
      expect(find.text('Keep fasting'), findsOne);

      await tester.tap(find.text('Keep fasting'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await letDbFinish(tester);

      expect(find.text('End fast now?'), findsNothing);
      expect(find.text('FASTING'), findsOne);
      expect(find.text('EATING'), findsNothing);
      expect(find.text('End fast'), findsOne);
      final rows = await tester.runAsync(
        () => services.db.select(services.db.fasts).get(),
      );
      expect(rows!.single.endedAt, isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('tapping outside the question does not end the fast', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await _startFast(tester);
      await advanceTo(tester, now, DateTime(2026, 10, 3, 7));

      await tester.tap(find.text('End fast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tapAt(const Offset(8, 8));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await letDbFinish(tester);

      expect(find.text('End fast now?'), findsNothing);
      expect(find.text('FASTING'), findsOne);
      final rows = await tester.runAsync(
        () => services.db.select(services.db.fasts).get(),
      );
      expect(rows!.single.endedAt, isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('two taps on End fast open one question', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await _startFast(tester);
      await advanceTo(tester, now, DateTime(2026, 10, 3, 7));

      // Hai lần bấm tới trước khi có khung hình nào. Không viết bằng hai lần
      // tester.tap: sau khi đẩy hộp thoại, Navigator hấp thụ con trỏ tới khung
      // kế tiếp nên lần chạm thứ hai không bao giờ tới nút, và test xanh cả
      // khi code sai. Gọi thẳng callback của nút thì lần hai chắc chắn tới.
      final end = tester.widget<SteadyButton>(
        find.widgetWithText(SteadyButton, 'End fast'),
      );
      end.onPressed!();
      end.onPressed!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(AlertDialog), findsOne);
      expect(find.text('End fast now?'), findsOne);

      await tester.tap(find.text('Keep fasting'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await letDbFinish(tester);

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('FASTING'), findsOne);
      expect(isButtonEnabled(tester, 'End fast'), isTrue);
      final rows = await tester.runAsync(
        () => services.db.select(services.db.fasts).get(),
      );
      expect(rows!.single.endedAt, isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('tapping outside the question gives the End button back', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await _startFast(tester);
      await advanceTo(tester, now, DateTime(2026, 10, 3, 7));

      await tester.tap(find.text('End fast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tapAt(const Offset(8, 8));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await letDbFinish(tester);

      expect(find.byType(AlertDialog), findsNothing);
      expect(isButtonEnabled(tester, 'End fast'), isTrue, reason: 'not stuck');

      // Và hỏi lại được: nút không bị kẹt ở trạng thái bận.
      await tester.tap(find.text('End fast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('End fast now?'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the confirmation is neutral: the End button is not red', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await _startFast(tester);
      await advanceTo(tester, now, DateTime(2026, 10, 3, 7));

      await tester.tap(find.text('End fast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final confirm = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(SteadyButton, 'End fast'),
      );
      expect(
        tester.widget<SteadyButton>(confirm).variant,
        SteadyButtonVariant.primary,
        reason: 'ending a fast early deletes nothing: no danger colour',
      );
      final keep = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(SteadyButton, 'Keep fasting'),
      );
      expect(
        tester.widget<SteadyButton>(keep).variant,
        SteadyButtonVariant.ghost,
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('confirming an early end goes to EATING', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await _startFast(tester);
      await advanceTo(tester, now, DateTime(2026, 10, 3, 7));

      await tester.tap(find.text('End fast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('End fast'),
        ),
      );
      await afterTapDb(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('End fast now?'), findsNothing);
      expect(find.text('EATING'), findsOne);
      expect(find.text('FASTING'), findsNothing);
      expect(ring(tester).tone, TimerRingTone.tide);
      expect(ring(tester).time, '0:00:00');
      expect(textPlain('Eating window ends 3:00 PM'), findsOne);
      expect(_stat(tester, 'Last fast'), '10h 00m');
      expect(find.text('Start fasting'), findsOne);
      expect(find.text('End fast'), findsNothing);
      // Kết thúc sớm: không được tính vào chuỗi nhịn ăn.
      expect(_stat(tester, 'Fasting streak'), '0 days');

      final rows = await tester.runAsync(
        () => services.db.select(services.db.fasts).get(),
      );
      expect(rows!.single.endedAt, DateTime(2026, 10, 3, 7));

      await disposeSteadyApp(tester, services);
    });

    testWidgets('after the goal, End asks nothing and the streak is 1 day', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await _startFast(tester);
      await advanceTo(tester, now, DateTime(2026, 10, 3, 13, 30));
      expect(textPlain('Goal reached at 1:00 PM'), findsOne);

      await tester.tap(find.text('End fast'));
      await afterTapDb(tester);

      expect(find.text('End fast now?'), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('EATING'), findsOne);
      expect(textPlain('Eating window ends 9:30 PM'), findsOne);
      expect(_stat(tester, 'Last fast'), '16h 30m');
      expect(_stat(tester, 'Fasting streak'), '1 day');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the EATING ring fills over the window and then goes idle', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await _startFast(tester);
      await advanceTo(tester, now, DateTime(2026, 10, 3, 13));
      await tester.tap(find.text('End fast'));
      await afterTapDb(tester);
      expect(find.text('EATING'), findsOne);

      await advanceTo(tester, now, DateTime(2026, 10, 3, 17));
      expect(ring(tester).time, '4:00:00');
      expect(ring(tester).progress, closeTo(0.5, 1e-9));

      await advanceTo(tester, now, DateTime(2026, 10, 3, 20, 59, 59));
      expect(find.text('EATING'), findsOne);

      await advanceTo(tester, now, DateTime(2026, 10, 3, 21));
      expect(find.text('EATING'), findsNothing, reason: 'the window is over');
      expect(ring(tester).phase, isNull);
      expect(ring(tester).time, '0:00:00');
      expect(find.text('Start fasting'), findsOne);
      expect(_stat(tester, 'Last fast'), '16h 00m');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a new fast can start during the eating window', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await _startFast(tester);
      await advanceTo(tester, now, DateTime(2026, 10, 3, 13));
      await tester.tap(find.text('End fast'));
      await afterTapDb(tester);
      expect(find.text('EATING'), findsOne);

      await tester.tap(find.text('Start fasting'));
      await afterTapDb(tester);

      expect(find.text('FASTING'), findsOne);
      expect(find.text('EATING'), findsNothing);
      expect(find.text('End fast'), findsOne);
      final rows = await tester.runAsync(
        () => services.db.select(services.db.fasts).get(),
      );
      expect(rows, hasLength(2));
      expect(rows!.where((r) => r.endedAt == null), hasLength(1));

      await disposeSteadyApp(tester, services);
    });

    testWidgets(
      'a clock set before the start ends the fast at its start time',
      (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(tester, clock: now.clock);
        await openTimer(tester);
        await _startFast(tester);
        await advanceTo(tester, now, _start.subtract(const Duration(hours: 2)));

        await tester.tap(find.text('End fast'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('End fast'),
          ),
        );
        await afterTapDb(tester);

        final rows = await tester.runAsync(
          () => services.db.select(services.db.fasts).get(),
        );
        expect(rows!.single.endedAt, rows.single.startedAt);
        expect(_stat(tester, 'Last fast'), '0h 00m');
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      },
    );
  });

  group('Remembering across restarts', () {
    testWidgets('a running fast is still there after the app is rebuilt', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await _startFast(tester);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(SteadyApp(services: services));
      await tester.pump();
      await openTimer(tester);

      expect(find.text('FASTING'), findsOne);
      expect(textPlain('Started today, 9:00 PM'), findsOne);
      expect(find.text('End fast'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets(
      'closing the app for hours: elapsed time comes from the database',
      (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(tester, clock: now.clock);
        await openTimer(tester);
        await _startFast(tester);

        await tester.pumpWidget(const SizedBox.shrink());
        // App tắt hẳn 10 giờ rồi mở lại.
        now.value = DateTime(2026, 10, 3, 7);
        await tester.pumpWidget(SteadyApp(services: services));
        await tester.pump();
        await openTimer(tester);

        expect(ring(tester).time, '10:00:00');
        expect(textPlain('Started yesterday, 9:00 PM'), findsOne);
        expect(_stat(tester, 'Left in this fast'), '6h 00m');

        await disposeSteadyApp(tester, services);
      },
    );

    testWidgets('the plan of the last fast is the default for the next', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedFast(
        tester,
        services,
        startedAt: DateTime(2026, 10, 1, 20),
        endedAt: DateTime(2026, 10, 2, 16),
        plan: FastingPlan.h20,
      );
      await openTimer(tester);

      expect(_selectedPlan(tester), FastingPlan.h20);
      expect(ring(tester).caption, 'Goal: 20 hours');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a plan picked but never started is not remembered', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await tester.tap(find.text('OMAD'));
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(SteadyApp(services: services));
      await tester.pump();
      await openTimer(tester);

      expect(_selectedPlan(tester), FastingPlan.h16);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the app always opens on Fasting', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openInterval(tester);
      expect(find.text('Start workout'), findsOne);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(SteadyApp(services: services));
      await tester.pump();
      await openTimer(tester);

      expect(find.text('Start fasting'), findsOne);
      expect(find.text('Start workout'), findsNothing);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Statistics', () {
    testWidgets('the last fast and the streak come from ended fasts', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      // Ba ngày liền đạt mục tiêu, mỗi lần kết thúc vào ngày đó: 30/9, 1/10, 2/10.
      await seedFast(
        tester,
        services,
        startedAt: DateTime(2026, 9, 29, 20),
        endedAt: DateTime(2026, 9, 30, 12),
      );
      await seedFast(
        tester,
        services,
        startedAt: DateTime(2026, 9, 30, 20),
        endedAt: DateTime(2026, 10, 1, 12),
      );
      await seedFast(
        tester,
        services,
        startedAt: DateTime(2026, 10, 1, 20),
        endedAt: DateTime(2026, 10, 2, 13, 30),
      );
      await openTimer(tester);

      expect(_stat(tester, 'Fasting streak'), '3 days');
      expect(_stat(tester, 'Last fast'), '17h 30m');
      expect(find.text('EATING'), findsOne, reason: '13:30 + 8 h = 21:30');
      expect(textPlain('Eating window ends 9:30 PM'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the streak survives until a whole day is missed', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedFast(
        tester,
        services,
        startedAt: DateTime(2026, 10, 1, 20),
        endedAt: DateTime(2026, 10, 2, 12),
      );
      await openTimer(tester);
      expect(_stat(tester, 'Fasting streak'), '1 day');

      // Hôm sau chưa nhịn: tính từ hôm qua, vẫn là 1.
      now.value = DateTime(2026, 10, 3, 8);
      services.today.refresh();
      await tester.pump();
      expect(_stat(tester, 'Fasting streak'), '1 day');

      // Cách hai ngày: về 0.
      now.value = DateTime(2026, 10, 4, 8);
      services.today.refresh();
      await tester.pump();
      expect(_stat(tester, 'Fasting streak'), '0 days');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('an idle screen shows the last fast and keeps its plan', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedFast(
        tester,
        services,
        startedAt: DateTime(2026, 9, 28, 20),
        endedAt: DateTime(2026, 9, 29, 11, 15),
        plan: FastingPlan.h18,
      );
      await openTimer(tester);

      expect(find.text('EATING'), findsNothing);
      expect(_stat(tester, 'Last fast'), '15h 15m');
      expect(_selectedPlan(tester), FastingPlan.h18);
      expect(_stat(tester, 'Fasting streak'), '0 days');

      await disposeSteadyApp(tester, services);
    });
  });

  group('When the database fails', () {
    testWidgets('Start: an error line above the button, no snackbar, no row', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await breakWrites(tester, services, 'fasts');

      await tester.tap(find.text('Start fasting'));
      await afterTapDb(tester);

      expect(find.text(saveErrorText), findsOne);
      expect(find.byType(SnackBar), findsNothing);
      final error = tester.getRect(find.text(saveErrorText));
      final button = tester.getRect(
        find.widgetWithText(SteadyButton, 'Start fasting'),
      );
      expect(error.bottom, lessThanOrEqualTo(button.top));
      expect(find.text('Start fasting'), findsOne);
      expect(find.text('FASTING'), findsNothing);
      expect(isButtonEnabled(tester, 'Start fasting'), isTrue, reason: 'retry');
      final rows = await tester.runAsync(
        () => services.db.select(services.db.fasts).get(),
      );
      expect(rows, isEmpty);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Start works after the database recovers; the error goes', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await breakWrites(tester, services, 'fasts');
      await tester.tap(find.text('Start fasting'));
      await afterTapDb(tester);
      expect(find.text(saveErrorText), findsOne);

      await repairWrites(tester, services, 'fasts');
      await tester.tap(find.text('Start fasting'));
      await afterTapDb(tester);

      expect(find.text(saveErrorText), findsNothing);
      expect(find.text('FASTING'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('End: an error line, the fast keeps running', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await _startFast(tester);
      await advanceTo(tester, now, DateTime(2026, 10, 3, 14));
      await breakWrites(
        tester,
        services,
        'fasts',
        insert: false,
        delete: false,
      );

      await tester.tap(find.text('End fast'));
      await afterTapDb(tester);

      expect(find.text(saveErrorText), findsOne);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('FASTING'), findsOne);
      expect(find.text('EATING'), findsNothing);
      expect(isButtonEnabled(tester, 'End fast'), isTrue);
      final rows = await tester.runAsync(
        () => services.db.select(services.db.fasts).get(),
      );
      expect(rows!.single.endedAt, isNull);

      await repairWrites(tester, services, 'fasts');
      await tester.tap(find.text('End fast'));
      await afterTapDb(tester);
      expect(find.text(saveErrorText), findsNothing);
      expect(find.text('EATING'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('two taps before any frame: one fast and no error line', (
      tester,
    ) async {
      // Hai chạm tới trước khi có khung hình nào: chốt _busy chặn ngay lần
      // chạm thứ hai, nên không có lần ghi thứ hai nào và không hiện dòng lỗi.
      // Transaction vẫn là lớp bảo vệ thứ hai (mục 11, điểm 4).
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);

      await tester.tap(find.text('Start fasting'));
      await tester.tap(find.text('Start fasting'), warnIfMissed: false);
      await afterTapDb(tester);

      final rows = await tester.runAsync(
        () => services.db.select(services.db.fasts).get(),
      );
      expect(rows, hasLength(1));
      expect(rows!.where((r) => r.endedAt == null), hasLength(1));
      expect(find.text('FASTING'), findsOne);
      expect(find.text(saveErrorText), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('End early: the database fails after the question', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await _startFast(tester);
      await advanceTo(tester, now, DateTime(2026, 10, 3, 7));
      await breakWrites(
        tester,
        services,
        'fasts',
        insert: false,
        delete: false,
      );

      await tester.tap(find.text('End fast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('End fast'),
        ),
      );
      await afterTapDb(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(saveErrorText), findsOne);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('FASTING'), findsOne);
      expect(find.text('EATING'), findsNothing);
      expect(isButtonEnabled(tester, 'End fast'), isTrue, reason: 'retry');
      var rows = await tester.runAsync(
        () => services.db.select(services.db.fasts).get(),
      );
      expect(rows!.single.endedAt, isNull);

      // Hỏi lại rồi chọn Keep fasting: dòng lỗi cũ vẫn còn, vì chưa có lần
      // lưu nào thành công.
      await tester.tap(find.text('End fast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AlertDialog), findsOne);
      await tester.tap(find.text('Keep fasting'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await letDbFinish(tester);
      expect(find.text(saveErrorText), findsOne);
      expect(isButtonEnabled(tester, 'End fast'), isTrue);

      // DB lành lại: xác nhận lần nữa thì xong, dòng lỗi mất.
      await repairWrites(tester, services, 'fasts');
      await tester.tap(find.text('End fast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('End fast'),
        ),
      );
      await afterTapDb(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(saveErrorText), findsNothing);
      expect(find.text('EATING'), findsOne);
      rows = await tester.runAsync(
        () => services.db.select(services.db.fasts).get(),
      );
      expect(rows!.single.endedAt, DateTime(2026, 10, 3, 7));

      await disposeSteadyApp(tester, services);
    });
  });

  group('The ticker and the app lifecycle', () {
    testWidgets('returning from the background shows the new time at once', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await _startFast(tester);

      sendToBackground(tester);
      now.value = _start.add(const Duration(hours: 10));
      await tester.pump(const Duration(seconds: 5));
      bringToForeground(tester);
      await tester.pump();

      expect(ring(tester).time, '10:00:00');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('switching to another tab and back shows the right time', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await _startFast(tester);

      await tapTab(tester, 'Streaks');
      now.value = _start.add(const Duration(hours: 3, minutes: 4, seconds: 5));
      await tester.pump(const Duration(seconds: 3));
      await tapTab(tester, 'Timer');

      expect(ring(tester).time, '3:04:05');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('no timer is left running after the screen is closed', (
      tester,
    ) async {
      // La flutter_test báo "A Timer is still pending" nếu nhịp đếm còn sót.
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await _startFast(tester);
      await advanceTo(tester, now, _start.add(const Duration(seconds: 1)));

      await disposeSteadyApp(tester, services);
      expect(tester.takeException(), isNull);
    });
  });

  group('Chip and header details', () {
    testWidgets('while fasting the plan is a neutral chip', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openTimer(tester);
      await tester.tap(find.text('18:6'));
      await tester.pump();
      await _startFast(tester);

      final chip = tester.widget<SteadyChip>(
        find.widgetWithText(SteadyChip, '18:6'),
      );
      expect(chip.tone, SteadyChipTone.neutral);
      expect(textPlain('Ends 3:00 PM'), findsOne, reason: '21:00 + 18 h');

      await disposeSteadyApp(tester, services);
    });
  });
}
