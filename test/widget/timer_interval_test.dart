import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/app.dart';
import 'package:steady/core/services.dart';
import 'package:steady/features/timer/interval_config.dart';
import 'package:steady/features/timer/interval_run_screen.dart';
import 'package:steady/ui/components/steady_button.dart';
import 'package:steady/ui/components/steady_filter_chips.dart';
import 'package:steady/ui/components/steady_progress_bar.dart';
import 'package:steady/ui/components/steady_stepper.dart';
import 'package:steady/ui/components/steady_tab_bar.dart';
import 'package:steady/ui/components/timer_ring.dart';

import '../helpers/test_app.dart';
import '../helpers/timer_helpers.dart';
import '../helpers/widget_helpers.dart';

IntervalPresetId _chosenPreset(WidgetTester t) => t
    .widget<SteadyFilterChips<IntervalPresetId>>(
      find.byType(SteadyFilterChips<IntervalPresetId>),
    )
    .value;

Future<IntervalSetup> _storedSetup(WidgetTester t, AppServices s) async {
  final setup = await t.runAsync(s.prefs.loadIntervalSetup);
  return setup!;
}

const _tabata = IntervalConfig.tabata;

/// Chuyển màn hình của Material mất tới 800 ms; chỉ sau đó màn bên dưới mới
/// thôi hiện (và `find` mới bỏ qua nó).
const _routeTransition = Duration(seconds: 1);

/// Mở màn chạy bài từ tab Timer. Đồng hồ giả đang ở 21:00:00.
Future<AppServices> _openRun(
  WidgetTester t,
  FakeNow now, {
  IntervalConfig? custom,
  IntervalPresetId? preset,
  Size size = const Size(360, 800),
}) async {
  final services = await pumpSteadyApp(t, clock: now.clock, size: size);
  if (custom != null) await seedCustomWorkout(t, services, custom);
  if (preset != null) {
    await seedPref(t, services, 'interval.preset', preset.name);
  }
  await openInterval(t);
  await t.tap(find.text('Start workout'));
  await t.pump();
  await t.pump(_routeTransition);
  return services;
}

/// Đưa đồng hồ tới [seconds] giây kể từ lúc bắt đầu bài rồi để Timer nổ.
Future<void> _runAt(WidgetTester t, FakeNow now, int seconds) async {
  now.value = evening().add(Duration(seconds: seconds));
  await t.pump(const Duration(seconds: 1));
}

/// Cho đồng hồ chạy thêm [seconds] giây kể từ bây giờ (dùng sau khi đã nhảy
/// hiệp hoặc tạm dừng, lúc đó mốc tuyệt đối của `_runAt` không còn đúng).
Future<void> _advance(WidgetTester t, FakeNow now, int seconds) async {
  now.value = now.value.add(Duration(seconds: seconds));
  await t.pump(const Duration(seconds: 1));
}

Future<void> _tapIcon(WidgetTester t, String label) async {
  await t.tap(semLabel(label));
  await t.pump();
}

SteadyProgressBar _bar(WidgetTester t) =>
    t.widget<SteadyProgressBar>(find.byType(SteadyProgressBar));

Future<void> _back(WidgetTester t) async {
  await t.binding.handlePopRoute();
  await t.pump();
  await t.pump(_routeTransition);
}

/// Chạm rồi chờ màn hình đóng hẳn.
Future<void> _tapAndLeave(WidgetTester t, Finder finder) async {
  await t.tap(finder);
  await t.pump();
  await t.pump(_routeTransition);
}

Finder _inDialog(String text) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

void main() {
  group('Interval setup', () {
    testWidgets('Tabata by default: 4:00, 16 intervals, 8 rounds', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openInterval(tester);

      expect(find.text('Start workout'), findsOne);
      expect(
        buttonLabeled(tester, 'Start workout').variant,
        SteadyButtonVariant.primary,
      );
      for (final chip in ['Tabata', 'HIIT 30/30', 'Custom']) {
        expect(find.text(chip), findsOne);
      }
      expect(_chosenPreset(tester), IntervalPresetId.tabata);
      expect(find.text('4:00'), findsOne);
      expect(find.text('16 intervals · 8 rounds'), findsOne);

      expect(stepperValue(tester, 'Prepare'), '0:10');
      expect(stepperValue(tester, 'Work'), '0:20');
      expect(stepperValue(tester, 'Rest'), '0:10');
      expect(stepperValue(tester, 'Rounds'), '8');
      expect(stepperValue(tester, 'Sets'), '1');
      expect(find.text('Work + rest'), findsOne, reason: 'detail of Rounds');
      expect(stepperRow('Rest between sets'), findsNothing, reason: '1 set');
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('HIIT 30/30 has its own numbers', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openInterval(tester);

      await tapVisible(tester, find.text('HIIT 30/30'));

      expect(_chosenPreset(tester), IntervalPresetId.hiit3030);
      expect(find.text('10:00'), findsOne);
      expect(find.text('20 intervals · 10 rounds'), findsOne);
      expect(stepperValue(tester, 'Prepare'), '0:10');
      expect(stepperValue(tester, 'Work'), '0:30');
      expect(stepperValue(tester, 'Rest'), '0:30');
      expect(stepperValue(tester, 'Rounds'), '10');

      await tapVisible(tester, find.text('Tabata'));
      expect(find.text('4:00'), findsOne);

      await letDbFinish(tester);
      await disposeSteadyApp(tester, services);
    });

    testWidgets('choosing Custom shows the saved custom workout', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openInterval(tester);

      await tapVisible(tester, find.text('Custom'));

      expect(_chosenPreset(tester), IntervalPresetId.custom);
      expect(find.text('4:00'), findsOne, reason: 'custom starts as Tabata');

      await letDbFinish(tester);
      await disposeSteadyApp(tester, services);
    });

    testWidgets('a Stepper changes the number, the total and the summary', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openInterval(tester);

      await stepUpBy(tester, 'Rounds');

      expect(stepperValue(tester, 'Rounds'), '9');
      expect(find.text('4:30'), findsOne);
      expect(find.text('18 intervals · 9 rounds'), findsOne);

      await stepUpBy(tester, 'Work');
      expect(stepperValue(tester, 'Work'), '0:25');
      expect(find.text('5:15'), findsOne, reason: '9 x (25 + 10) = 315 s');

      await stepDownBy(tester, 'Rest');
      expect(stepperValue(tester, 'Rest'), '0:05');
      expect(find.text('4:30'), findsOne, reason: '9 x (25 + 5) = 270 s');

      await stepUpBy(tester, 'Prepare');
      expect(stepperValue(tester, 'Prepare'), '0:15');
      expect(find.text('4:30'), findsOne, reason: 'prepare is not counted');

      await letDbFinish(tester);
      await disposeSteadyApp(tester, services);
    });

    testWidgets('editing a number moves the selection to Custom', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openInterval(tester);
      expect(_chosenPreset(tester), IntervalPresetId.tabata);

      await stepUpBy(tester, 'Rounds');

      expect(_chosenPreset(tester), IntervalPresetId.custom);
      // Tabata gốc không bị đổi.
      await tapVisible(tester, find.text('Tabata'));
      expect(stepperValue(tester, 'Rounds'), '8');
      expect(find.text('4:00'), findsOne);
      await tapVisible(tester, find.text('Custom'));
      expect(stepperValue(tester, 'Rounds'), '9');

      await letDbFinish(tester);
      await disposeSteadyApp(tester, services);
    });

    testWidgets('editing HIIT copies HIIT into Custom first', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openInterval(tester);
      await tapVisible(tester, find.text('HIIT 30/30'));

      await stepUpBy(tester, 'Work');

      expect(_chosenPreset(tester), IntervalPresetId.custom);
      expect(stepperValue(tester, 'Work'), '0:35');
      expect(stepperValue(tester, 'Rest'), '0:30');
      expect(stepperValue(tester, 'Rounds'), '10');
      await letDbFinish(tester);
      final stored = await _storedSetup(tester, services);
      expect(stored.preset, IntervalPresetId.custom);
      expect(stored.custom.work, 35);
      expect(stored.custom.rest, 30);
      expect(stored.custom.rounds, 10);

      await disposeSteadyApp(tester, services);
    });

    testWidgets(
      'the step is 5 s under a minute and 15 s over: 55 -> 60 -> 75',
      (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(tester, clock: now.clock);
        await seedCustomWorkout(
          tester,
          services,
          _tabata.withValue(IntervalField.work, 55),
        );
        await openInterval(tester);
        expect(stepperValue(tester, 'Work'), '0:55');

        await stepUpBy(tester, 'Work');
        expect(stepperValue(tester, 'Work'), '1:00');
        await stepUpBy(tester, 'Work');
        expect(stepperValue(tester, 'Work'), '1:15');
        await stepDownBy(tester, 'Work');
        expect(stepperValue(tester, 'Work'), '1:00');
        await stepDownBy(tester, 'Work');
        expect(stepperValue(tester, 'Work'), '0:55');

        await letDbFinish(tester);
        await disposeSteadyApp(tester, services);
      },
    );

    testWidgets('at the lowest values the minus buttons are disabled', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedCustomWorkout(
        tester,
        services,
        const IntervalConfig(
          prepare: 0,
          work: 5,
          rest: 0,
          rounds: 1,
          sets: 1,
          setRest: 0,
        ),
      );
      await openInterval(tester);

      for (final label in ['Prepare', 'Work', 'Rest', 'Rounds', 'Sets']) {
        final row = tester.widget<SteadyStepper>(stepperRow(label));
        expect(row.onDecrement, isNull, reason: '$label at its minimum');
        expect(row.onIncrement, isNotNull, reason: '$label can still go up');
      }
      expect(stepperValue(tester, 'Prepare'), '0:00');
      expect(stepperValue(tester, 'Work'), '0:05');

      // Chạm vào nút đã tắt không đổi gì.
      await tester.ensureVisible(semLabel('Decrease Rounds'));
      await tester.tap(semLabel('Decrease Rounds'), warnIfMissed: false);
      await tester.pump();
      expect(stepperValue(tester, 'Rounds'), '1');
      expect(
        find.text('0:05'),
        findsNWidgets(2),
        reason: 'summary (1 x 5 s) and the Work row',
      );

      await letDbFinish(tester);
      await disposeSteadyApp(tester, services);
    });

    testWidgets('at the highest values the plus buttons are disabled', (
      tester,
    ) async {
      final now = FakeNow(evening());
      // Màn rộng: với phông Ahem của môi trường test, "10:00" trong hàng
      // Stepper rộng hơn nhiều so với phông Figtree thật.
      final services = await pumpSteadyApp(
        tester,
        clock: now.clock,
        size: const Size(700, 1000),
      );
      await seedCustomWorkout(
        tester,
        services,
        const IntervalConfig(
          prepare: 60,
          work: 600,
          rest: 600,
          rounds: 50,
          sets: 10,
          setRest: 600,
        ),
      );
      await openInterval(tester);

      for (final label in [
        'Prepare',
        'Work',
        'Rest',
        'Rounds',
        'Sets',
        'Rest between sets',
      ]) {
        final row = tester.widget<SteadyStepper>(stepperRow(label));
        expect(row.onIncrement, isNull, reason: '$label at its maximum');
        expect(row.onDecrement, isNotNull, reason: '$label can still go down');
      }
      expect(stepperValue(tester, 'Prepare'), '1:00');
      expect(stepperValue(tester, 'Work'), '10:00');
      expect(stepperValue(tester, 'Rounds'), '50');
      expect(stepperValue(tester, 'Sets'), '10');
      expect(tester.takeException(), isNull);

      await letDbFinish(tester);
      await disposeSteadyApp(tester, services);
    });

    testWidgets('Sets above 1 reveals "Rest between sets"', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openInterval(tester);
      expect(stepperRow('Rest between sets'), findsNothing);

      await stepUpBy(tester, 'Sets');

      expect(stepperValue(tester, 'Sets'), '2');
      expect(stepperRow('Rest between sets'), findsOne);
      expect(stepperValue(tester, 'Rest between sets'), '1:00');
      expect(find.text('9:00'), findsOne, reason: '2 x 240 + 60 = 540 s');
      expect(find.text('32 intervals · 16 rounds'), findsOne);

      await stepUpBy(tester, 'Rest between sets');
      expect(stepperValue(tester, 'Rest between sets'), '1:15');
      expect(find.text('9:15'), findsOne);

      await stepDownBy(tester, 'Sets');
      expect(stepperRow('Rest between sets'), findsNothing);
      expect(find.text('4:00'), findsOne);

      await letDbFinish(tester);
      await disposeSteadyApp(tester, services);
    });

    testWidgets('one round and one interval use the singular', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedCustomWorkout(
        tester,
        services,
        const IntervalConfig(
          prepare: 0,
          work: 20,
          rest: 0,
          rounds: 1,
          sets: 1,
          setRest: 0,
        ),
      );
      await openInterval(tester);

      expect(find.text('1 interval · 1 round'), findsOne);
      expect(find.text('0:20'), findsNWidgets(2), reason: 'total + Work row');

      await letDbFinish(tester);
      await disposeSteadyApp(tester, services);
    });
  });

  group('Interval setup: holding a button', () {
    Future<TestGesture> hold(WidgetTester t, String label) async {
      await t.ensureVisible(semLabel(label));
      await t.pump();
      return t.startGesture(t.getCenter(semLabel(label)));
    }

    testWidgets('a quick tap is exactly one step', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openInterval(tester);

      await stepUpBy(tester, 'Rounds');
      expect(stepperValue(tester, 'Rounds'), '9');
      await tester.pump(const Duration(seconds: 2));
      expect(stepperValue(tester, 'Rounds'), '9', reason: 'no repeat');

      await letDbFinish(tester);
      await disposeSteadyApp(tester, services);
    });

    testWidgets('released before 400 ms: one step, no repeat', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openInterval(tester);

      final g = await hold(tester, 'Increase Rounds');
      await tester.pump(const Duration(milliseconds: 300));
      expect(stepperValue(tester, 'Rounds'), '8', reason: 'not yet');
      await g.up();
      await tester.pump();
      expect(stepperValue(tester, 'Rounds'), '9');
      await tester.pump(const Duration(seconds: 1));
      expect(stepperValue(tester, 'Rounds'), '9');

      await letDbFinish(tester);
      await disposeSteadyApp(tester, services);
    });

    testWidgets('held: first repeat at 400 ms, then one step every 100 ms', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openInterval(tester);

      final g = await hold(tester, 'Increase Rounds');
      await tester.pump(const Duration(milliseconds: 399));
      expect(stepperValue(tester, 'Rounds'), '8');
      await tester.pump(const Duration(milliseconds: 1));
      expect(stepperValue(tester, 'Rounds'), '9');
      for (final expected in ['10', '11', '12']) {
        await tester.pump(const Duration(milliseconds: 100));
        expect(stepperValue(tester, 'Rounds'), expected);
      }

      // Thả tay: không thêm một bước nữa, và không còn lặp.
      await g.up();
      await tester.pump();
      expect(stepperValue(tester, 'Rounds'), '12');
      await tester.pump(const Duration(seconds: 1));
      expect(stepperValue(tester, 'Rounds'), '12');

      await letDbFinish(tester);
      await disposeSteadyApp(tester, services);
    });

    testWidgets('holding the minus button counts down', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openInterval(tester);

      final g = await hold(tester, 'Decrease Rounds');
      await tester.pump(const Duration(milliseconds: 400));
      for (var i = 0; i < 2; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await g.up();
      await tester.pump();

      expect(stepperValue(tester, 'Rounds'), '5', reason: '8 -> 7 -> 6 -> 5');

      await letDbFinish(tester);
      await disposeSteadyApp(tester, services);
    });

    testWidgets('a cancelled touch stops the repeat', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openInterval(tester);

      final g = await hold(tester, 'Increase Rounds');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 100));
      final atCancel = stepperValue(tester, 'Rounds');
      expect(atCancel, '10');
      await g.cancel();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(stepperValue(tester, 'Rounds'), atCancel);

      await letDbFinish(tester);
      await disposeSteadyApp(tester, services);
    });

    testWidgets('holding stops at the limit and does not go past it', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openInterval(tester);

      final g = await hold(tester, 'Increase Rounds');
      for (var ms = 0; ms < 6000; ms += 100) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(stepperValue(tester, 'Rounds'), '50');
      expect(
        tester.widget<SteadyStepper>(stepperRow('Rounds')).onIncrement,
        isNull,
        reason: 'the plus button is now disabled',
      );
      await g.up();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(stepperValue(tester, 'Rounds'), '50');
      expect(tester.takeException(), isNull);

      await letDbFinish(tester);
      await disposeSteadyApp(tester, services);
    });

    testWidgets('holding the minus button stops at the minimum', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openInterval(tester);

      final g = await hold(tester, 'Decrease Rounds');
      for (var ms = 0; ms < 3000; ms += 100) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await g.up();
      await tester.pump();

      expect(stepperValue(tester, 'Rounds'), '1');
      expect(
        tester.widget<SteadyStepper>(stepperRow('Rounds')).onDecrement,
        isNull,
      );

      await letDbFinish(tester);
      await disposeSteadyApp(tester, services);
    });

    testWidgets('holding a disabled button does nothing', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedCustomWorkout(
        tester,
        services,
        _tabata.withValue(IntervalField.rounds, 1),
      );
      await openInterval(tester);

      final g = await hold(tester, 'Decrease Rounds');
      await tester.pump(const Duration(seconds: 2));
      await g.up();
      await tester.pump();

      expect(stepperValue(tester, 'Rounds'), '1');
      expect(tester.takeException(), isNull);

      await letDbFinish(tester);
      await disposeSteadyApp(tester, services);
    });

    /// Đặt ngón tay lên nút "Increase Rounds" rồi kéo 10 bước x 10 px, 100 ms
    /// mỗi bước (quá mốc 400 ms của nhấn giữ). Mỗi bước nhỏ hơn ngưỡng chạm,
    /// tổng thì vượt xa ngưỡng. Trả về độ dời của hàng Rounds trên màn hình.
    Future<double> dragFromButton(
      WidgetTester t,
      AppServices services,
      double dy,
    ) async {
      final g = await hold(t, 'Increase Rounds');
      final before = t.getTopLeft(stepperRow('Rounds')).dy;
      for (var i = 0; i < 10; i++) {
        await g.moveBy(Offset(0, dy));
        await t.pump(const Duration(milliseconds: 100));
      }
      await g.up();
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      final moved = t.getTopLeft(stepperRow('Rounds')).dy - before;

      expect(stepperValue(t, 'Rounds'), '8', reason: 'no step happened');
      expect(_chosenPreset(t), IntervalPresetId.tabata);
      await letDbFinish(t);
      expect(
        await _storedSetup(t, services),
        IntervalSetup.initial,
        reason: 'the drag must not switch to Custom or save anything',
      );
      expect(t.takeException(), isNull);
      return moved;
    }

    testWidgets('a drag that starts on a button scrolls and never steps', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openInterval(tester);

      // `hold` kéo hàng này vào tầm nhìn nên trang đang nằm ở cuối: kéo xuống
      // mới là kéo làm trang cuộn.
      final moved = await dragFromButton(tester, services, 10);

      expect(moved, greaterThan(0), reason: 'the page really scrolled');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a drag upward from a button never steps either', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openInterval(tester);

      // Trang đã ở cuối nên không cuộn thêm được, nhưng ngón tay vẫn đi 100 px.
      await dragFromButton(tester, services, -10);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Interval setup: remembered between runs', () {
    testWidgets('Custom is still there after the app is rebuilt', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openInterval(tester);
      await stepUpBy(tester, 'Rounds');
      await stepUpBy(tester, 'Work');
      await letDbFinish(tester);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(SteadyApp(services: services));
      await tester.pump();
      await openInterval(tester);

      expect(_chosenPreset(tester), IntervalPresetId.custom);
      expect(stepperValue(tester, 'Rounds'), '9');
      expect(stepperValue(tester, 'Work'), '0:25');
      expect(find.text('5:15'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the chosen preset is remembered too', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openInterval(tester);
      await tapVisible(tester, find.text('HIIT 30/30'));
      await letDbFinish(tester);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(SteadyApp(services: services));
      await tester.pump();
      await openInterval(tester);

      expect(_chosenPreset(tester), IntervalPresetId.hiit3030);
      expect(find.text('10:00'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a saved custom workout survives choosing a built-in one', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openInterval(tester);
      await stepUpBy(tester, 'Rounds'); // Custom: 9 hiệp
      await tapVisible(tester, find.text('Tabata'));
      await letDbFinish(tester);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(SteadyApp(services: services));
      await tester.pump();
      await openInterval(tester);
      expect(_chosenPreset(tester), IntervalPresetId.tabata);
      await tapVisible(tester, find.text('Custom'));

      expect(stepperValue(tester, 'Rounds'), '9');

      await letDbFinish(tester);
      await disposeSteadyApp(tester, services);
    });

    testWidgets('a saving error is ignored: the setup still works', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openInterval(tester);
      await breakWrites(tester, services, 'prefs');

      await stepUpBy(tester, 'Rounds');
      await letDbFinish(tester);

      expect(stepperValue(tester, 'Rounds'), '9');
      expect(find.text(saveErrorText), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    for (final entry in {
      'text that is not JSON': ('custom', 'not json'),
      'JSON of the wrong shape': ('custom', '[1,2,3]'),
      'a number out of range': (
        'custom',
        '{"prepare":10,"work":20,"rest":10,"rounds":99,"sets":1,"setRest":60}',
      ),
      'a missing key': (
        'custom',
        '{"prepare":10,"work":20,"rest":10,"rounds":8,"sets":1}',
      ),
      'an unknown preset name': ('marathon', null),
    }.entries) {
      testWidgets('damaged saved data (${entry.key}) falls back to Tabata', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(tester, clock: now.clock);
        await seedPref(tester, services, 'interval.preset', entry.value.$1);
        final json = entry.value.$2;
        if (json != null) {
          await seedPref(tester, services, 'interval.custom', json);
        }
        await openInterval(tester);

        expect(_chosenPreset(tester), IntervalPresetId.tabata);
        expect(find.text('4:00'), findsOne);
        expect(find.text('16 intervals · 8 rounds'), findsOne);
        expect(stepperValue(tester, 'Rounds'), '8');
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      });
    }
  });

  group('Interval run screen', () {
    testWidgets('Start workout covers the tab bar and begins at PREPARE', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _openRun(tester, now);

      expect(find.byType(IntervalRunScreen), findsOne);
      expect(find.byType(SteadyTabBar), findsNothing);
      expect(find.text('Tabata'), findsOne, reason: 'the title');
      expect(find.text('1 / 8'), findsOne);
      expect(find.text('Round 1 of 8'), findsOne);
      expect(find.text('4:00 left'), findsOne);
      expect(ring(tester).phase, 'PREPARE');
      expect(ring(tester).time, '0:10');
      expect(ring(tester).tone, TimerRingTone.tide);
      expect(ring(tester).numerals, TimerRingNumerals.gym);
      expect(ring(tester).caption, '20 s work · 10 s rest');
      expect(ring(tester).progress, 0);
      expect(find.text('Next: Work 0:20'), findsOne);
      expect(_bar(tester).value, 0);
      expect(_bar(tester).semanticLabel, 'Workout progress');
      expect(semLabel('Pause'), findsOne);
      expect(semLabel('Restart round'), findsOne);
      expect(semLabel('Skip round'), findsOne);
      expect(semLabel('End workout'), findsOne);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the title is the name of the chosen workout', (tester) async {
      for (final (preset, title) in [
        (IntervalPresetId.hiit3030, 'HIIT 30/30'),
        (IntervalPresetId.custom, 'Custom'),
      ]) {
        final now = FakeNow(evening());
        final services = await _openRun(tester, now, preset: preset);
        expect(find.text(title), findsOne, reason: title);
        await disposeSteadyApp(tester, services);
      }
    });

    testWidgets('PREPARE, WORK, REST, WORK: the numbers follow the clock', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final haptics = captureHaptics(tester);
      final services = await _openRun(tester, now);
      expect(haptics.total, 0, reason: 'no buzz when the workout starts');

      await _runAt(tester, now, 3);
      expect(ring(tester).phase, 'PREPARE');
      expect(ring(tester).time, '0:07');
      expect(find.text('4:00 left'), findsOne);
      expect(haptics.total, 0);

      await _runAt(tester, now, 10);
      expect(ring(tester).phase, 'WORK');
      expect(ring(tester).time, '0:20');
      expect(ring(tester).tone, TimerRingTone.amber);
      expect(find.text('Next: Rest 0:10'), findsOne);
      expect(find.text('1 / 8'), findsOne);
      expect(find.text('4:00 left'), findsOne);
      expect(haptics.heavy, 1, reason: 'PREPARE -> WORK');

      await _runAt(tester, now, 22);
      expect(ring(tester).time, '0:08');
      expect(ring(tester).progress, closeTo(12 / 20, 1e-9));
      expect(haptics.heavy, 1, reason: 'same phase: no buzz');

      await _runAt(tester, now, 30);
      expect(ring(tester).phase, 'REST');
      expect(ring(tester).time, '0:10');
      expect(ring(tester).tone, TimerRingTone.tide);
      expect(find.text('Next: Work 0:20'), findsOne);
      expect(haptics.heavy, 2);

      await _runAt(tester, now, 40);
      expect(ring(tester).phase, 'WORK');
      expect(find.text('2 / 8'), findsOne);
      expect(find.text('Round 2 of 8'), findsOne);
      expect(find.text('3:30 left'), findsOne);
      expect(haptics.heavy, 3);
      expect(haptics.vibrate, 0);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the phase name is a live region in the semantics tree', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final now = FakeNow(evening());
      final services = await _openRun(tester, now);
      // find.semantics duyệt từ gốc cây: chỉ node thật sự nằm trong cây mới tính.
      SemanticsFinder liveRegion(String label) => find.semantics.byPredicate(
        (node) => node.flagsCollection.isLiveRegion && node.label == label,
      );

      // Chỉ có đúng một live region trong cây: không node cũ nào còn sót lại.
      final anyLiveRegion = find.semantics.byPredicate(
        (node) => node.flagsCollection.isLiveRegion,
      );

      expect(liveRegion('PREPARE'), findsOne);
      expect(anyLiveRegion, findsOne);
      await _runAt(tester, now, 10);
      expect(liveRegion('WORK'), findsOne);
      expect(liveRegion('PREPARE'), findsNothing);
      expect(anyLiveRegion, findsOne);
      await _runAt(tester, now, 30);
      expect(liveRegion('REST'), findsOne);
      expect(liveRegion('WORK'), findsNothing);
      expect(anyLiveRegion, findsOne);
      await _runAt(tester, now, 300); // quá cuối bài
      expect(ring(tester).phase, 'DONE');
      expect(liveRegion('DONE'), findsOne);
      expect(liveRegion('REST'), findsNothing);
      expect(anyLiveRegion, findsOne);

      await disposeSteadyApp(tester, services);
      handle.dispose();
    });

    testWidgets('the mockup numbers: 76 s in is 27.5% with 2:54 left', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _openRun(tester, now);

      await _runAt(tester, now, 76);

      expect(ring(tester).phase, 'WORK');
      expect(ring(tester).time, '0:14');
      expect(ring(tester).progress, closeTo(0.3, 1e-9));
      expect(_bar(tester).value, closeTo(0.275, 1e-9));
      expect(find.text('2:54 left'), findsOne);
      expect(find.text('Round 3 of 8'), findsOne);
      expect(find.text('3 / 8'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the display counts down every second', (tester) async {
      final now = FakeNow(evening());
      final services = await _openRun(tester, now);

      for (var s = 1; s <= 4; s++) {
        await _runAt(tester, now, s);
        expect(ring(tester).time, '0:0${10 - s}', reason: 'after $s s');
      }

      await disposeSteadyApp(tester, services);
    });

    testWidgets('pause freezes the workout; resume continues', (tester) async {
      final now = FakeNow(evening());
      final services = await _openRun(tester, now);
      final awake = awakeOf(services);
      expect(awake.calls, [true], reason: 'screen kept on from the start');

      await _runAt(tester, now, 14);
      expect(ring(tester).phase, 'WORK');
      expect(ring(tester).time, '0:16');

      await _tapIcon(tester, 'Pause');
      expect(semLabel('Pause'), findsNothing);
      expect(semLabel('Resume'), findsOne);
      expect(awake.calls, [true, false]);

      await _runAt(tester, now, 74); // một phút trôi qua khi đang tạm dừng
      await tester.pump(const Duration(seconds: 3));
      expect(ring(tester).phase, 'WORK');
      expect(ring(tester).time, '0:16', reason: 'frozen');
      expect(find.text('Round 1 of 8'), findsOne);

      await _tapIcon(tester, 'Resume');
      expect(semLabel('Pause'), findsOne);
      expect(awake.calls, [true, false, true]);
      now.value = now.value.add(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));
      expect(ring(tester).time, '0:11', reason: '5 s after resuming');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Restart round goes back to the start of the round', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final haptics = captureHaptics(tester);
      final services = await _openRun(tester, now);
      await _runAt(tester, now, 10 + 30 + 12); // hiệp 2, đang tập
      expect(find.text('Round 2 of 8'), findsOne);
      expect(ring(tester).time, '0:08');
      final before = haptics.heavy;

      await _tapIcon(tester, 'Restart round');

      expect(ring(tester).phase, 'WORK');
      expect(ring(tester).time, '0:20');
      expect(find.text('Round 2 of 8'), findsOne);
      expect(haptics.heavy, before, reason: 'same phase: no buzz');

      // Đang nghỉ thì về đầu phần tập của hiệp đó.
      await _advance(tester, now, 25); // 25 giây sau đầu hiệp 2: đang nghỉ
      expect(ring(tester).phase, 'REST');
      await _tapIcon(tester, 'Restart round');
      expect(ring(tester).phase, 'WORK');
      expect(ring(tester).time, '0:20');
      expect(find.text('Round 2 of 8'), findsOne);
      expect(haptics.heavy, greaterThan(before), reason: 'REST -> WORK buzzes');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Restart round while preparing goes to the start of prepare', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _openRun(tester, now);
      await _runAt(tester, now, 6);
      expect(ring(tester).time, '0:04');

      await _tapIcon(tester, 'Restart round');

      expect(ring(tester).phase, 'PREPARE');
      expect(ring(tester).time, '0:10');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Skip round jumps to the next round and buzzes', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final haptics = captureHaptics(tester);
      final services = await _openRun(tester, now);

      await _tapIcon(tester, 'Skip round'); // PREPARE -> hiệp 1
      expect(ring(tester).phase, 'WORK');
      expect(find.text('Round 1 of 8'), findsOne);
      expect(ring(tester).time, '0:20');
      expect(haptics.heavy, 1);

      await _tapIcon(tester, 'Skip round');
      expect(find.text('Round 2 of 8'), findsOne);
      expect(ring(tester).phase, 'WORK');
      expect(find.text('3:30 left'), findsOne);
      expect(haptics.heavy, 2);

      // Từ giữa pha nghỉ cũng sang hiệp kế tiếp.
      await _advance(tester, now, 25); // 25 giây sau đầu hiệp 2: đang nghỉ
      expect(ring(tester).phase, 'REST');
      await _tapIcon(tester, 'Skip round');
      expect(find.text('Round 3 of 8'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Skip while paused moves the position and stays paused', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _openRun(tester, now);
      await _tapIcon(tester, 'Pause');

      await _tapIcon(tester, 'Skip round');

      expect(semLabel('Resume'), findsOne, reason: 'still paused');
      expect(ring(tester).phase, 'WORK');
      expect(find.text('Round 1 of 8'), findsOne);
      await _runAt(tester, now, 100);
      expect(ring(tester).time, '0:20', reason: 'time does not run');
      expect(awakeOf(services).calls.last, isFalse);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('skipping the last round ends the workout', (tester) async {
      final now = FakeNow(evening());
      final haptics = captureHaptics(tester);
      final services = await _openRun(tester, now);
      await _runAt(tester, now, 10 + 7 * 30 + 5); // hiệp 8
      expect(find.text('Round 8 of 8'), findsOne);
      expect(find.text('Next: Rest 0:10'), findsOne);

      await _tapIcon(tester, 'Skip round');

      expect(ring(tester).phase, 'DONE');
      expect(haptics.vibrate, 1, reason: 'a long buzz when it is over');
      expect(awakeOf(services).calls.last, isFalse);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('DONE: full ring, total time, summary and a Close button', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final haptics = captureHaptics(tester);
      final services = await _openRun(tester, now);
      final awake = awakeOf(services);

      await _runAt(tester, now, 250);

      expect(ring(tester).phase, 'DONE');
      expect(ring(tester).time, '4:00');
      expect(ring(tester).caption, '16 intervals · 8 rounds');
      expect(ring(tester).progress, 1);
      expect(ring(tester).tone, TimerRingTone.tide);
      expect(_bar(tester).value, 1);
      expect(find.text('0:00 left'), findsOne);
      expect(find.text('Close'), findsOne);
      expect(
        buttonLabeled(tester, 'Close').variant,
        SteadyButtonVariant.primary,
      );
      expect(semLabel('Pause'), findsNothing);
      expect(semLabel('Resume'), findsNothing);
      expect(semLabel('Skip round'), findsNothing);
      expect(semLabel('Restart round'), findsNothing);
      expect(find.textContaining('Next:'), findsNothing);
      expect(haptics.vibrate, 1);
      expect(haptics.heavy, 0, reason: 'it jumped straight to the end');
      expect(awake.calls, [true, false]);

      // Thêm thời gian trôi qua: vẫn xong, không rung thêm.
      await _runAt(tester, now, 900);
      expect(ring(tester).phase, 'DONE');
      expect(haptics.vibrate, 1);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Close goes back to the setup, the screen may sleep again', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _openRun(tester, now);
      await _runAt(tester, now, 300);
      expect(ring(tester).phase, 'DONE');

      await _tapAndLeave(tester, find.text('Close'));

      expect(find.byType(IntervalRunScreen), findsNothing);
      expect(find.text('Start workout'), findsOne);
      expect(find.byType(SteadyTabBar), findsOne);
      expect(awakeOf(services).calls, [true, false, false]);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Back after DONE leaves at once, with no question', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _openRun(tester, now);
      await _runAt(tester, now, 300);

      await _back(tester);

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(IntervalRunScreen), findsNothing);
      expect(find.text('Start workout'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the screen stays on only while the workout runs', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _openRun(tester, now);
      final awake = awakeOf(services);
      expect(awake.calls, [true]);

      await _tapIcon(tester, 'Pause');
      expect(awake.calls, [true, false]);
      await _tapIcon(tester, 'Resume');
      expect(awake.calls, [true, false, true]);
      await _runAt(tester, now, 260);
      expect(awake.calls, [true, false, true, false], reason: 'done');
      await _tapAndLeave(tester, find.text('Close'));
      expect(awake.calls.last, isFalse);
      expect(
        awake.calls.where((on) => on).length,
        2,
        reason: 'turned on only at the start and on resume',
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('leaving while it runs turns the screen lock back on', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _openRun(tester, now);
      final awake = awakeOf(services);

      await disposeSteadyApp(tester, services);

      expect(awake.calls.first, isTrue);
      expect(awake.calls.last, isFalse, reason: 'dispose releases it');
    });
  });

  group('Interval run screen: leaving early', () {
    testWidgets('Back asks first and pauses; Keep going stays paused', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _openRun(tester, now);
      await _runAt(tester, now, 15);
      expect(ring(tester).time, '0:15');

      await _back(tester);

      expect(find.text('End workout?'), findsOne);
      expect(find.text('This workout stops here.'), findsOne);
      expect(find.text('Keep going'), findsOne);
      expect(_inDialog('End workout'), findsOne);
      expect(
        tester
            .widget<SteadyButton>(
              find.descendant(
                of: find.byType(AlertDialog),
                matching: find.widgetWithText(SteadyButton, 'End workout'),
              ),
            )
            .variant,
        SteadyButtonVariant.primary,
        reason: 'neutral: stopping a workout deletes nothing',
      );

      await tester.tap(find.text('Keep going'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(IntervalRunScreen), findsOne);
      expect(semLabel('Resume'), findsOne, reason: 'still paused');
      await _runAt(tester, now, 200);
      expect(ring(tester).time, '0:15', reason: 'time stays frozen');
      expect(awakeOf(services).calls.last, isFalse);

      await _tapIcon(tester, 'Resume');
      expect(semLabel('Pause'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Back then End workout leaves; nothing is saved', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _openRun(tester, now);
      await _runAt(tester, now, 15);

      await _back(tester);
      await _tapAndLeave(tester, _inDialog('End workout'));

      expect(find.byType(IntervalRunScreen), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Start workout'), findsOne);
      expect(find.byType(SteadyTabBar), findsOne);
      expect(awakeOf(services).calls.last, isFalse);
      // Setup vẫn như cũ.
      expect(_chosenPreset(tester), IntervalPresetId.tabata);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the X button follows the same path as Back', (tester) async {
      final now = FakeNow(evening());
      final services = await _openRun(tester, now);
      await _runAt(tester, now, 15);

      await _tapIcon(tester, 'End workout');
      await tester.pump(_routeTransition);

      expect(find.text('End workout?'), findsOne);
      expect(
        semLabel('Resume'),
        findsOne,
        reason: 'paused behind the question',
      );

      await tester.tap(find.text('Keep going'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(IntervalRunScreen), findsOne);

      await _tapIcon(tester, 'End workout');
      await tester.pump(_routeTransition);
      await _tapAndLeave(tester, _inDialog('End workout'));
      expect(find.byType(IntervalRunScreen), findsNothing);
      expect(find.text('Start workout'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets(
      'two exit requests at once open one question; End workout leaves',
      (tester) async {
        final now = FakeNow(evening());
        final services = await _openRun(tester, now);
        await _runAt(tester, now, 15);
        expect(awakeOf(services).calls, [true]);

        // Hai yêu cầu thoát tới cùng lúc, không có khung hình nào ở giữa. Gọi
        // thẳng callback của PopScope: chạm X hai lần thì lần hai vấp
        // assert(scope != null) của Flutter, ngoài code của app.
        final scope = tester.widget<PopScope>(
          find.descendant(
            of: find.byType(IntervalRunScreen),
            matching: find.byWidgetPredicate((w) => w is PopScope),
          ),
        );
        scope.onPopInvokedWithResult!(false, null);
        scope.onPopInvokedWithResult!(false, null);
        await tester.pump();
        await tester.pump(_routeTransition);

        expect(find.byType(AlertDialog), findsOne);
        expect(
          semLabel('Resume'),
          findsOne,
          reason: 'paused behind the question',
        );
        expect(awakeOf(services).calls, [
          true,
          false,
        ], reason: 'the second request does not pause again');

        // Một hộp thoại thì "End workout" đóng hộp thoại và cả màn chạy bài.
        await _tapAndLeave(tester, _inDialog('End workout'));

        expect(find.byType(IntervalRunScreen), findsNothing);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('Start workout'), findsOne);

        await disposeSteadyApp(tester, services);
      },
    );

    testWidgets('tapping outside the question does not leave', (tester) async {
      final now = FakeNow(evening());
      final services = await _openRun(tester, now);
      await _back(tester);

      await tester.tapAt(const Offset(8, 8));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(IntervalRunScreen), findsOne);
      expect(find.text('End workout?'), findsNothing);
      expect(semLabel('Resume'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the Android Back button never closes the app mid-workout', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final pops = captureSystemPop(tester);
      final services = await _openRun(tester, now);

      await _back(tester);
      await tester.tap(find.text('Keep going'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(pops, isEmpty);
      expect(find.byType(IntervalRunScreen), findsOne);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Interval run screen: the app in the background', () {
    testWidgets('past the end of the workout: DONE and exactly one buzz', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final haptics = captureHaptics(tester);
      final services = await _openRun(tester, now);
      await _runAt(tester, now, 14);
      final heavyBefore = haptics.heavy;

      sendToBackground(tester);
      now.value = evening().add(const Duration(minutes: 20));
      await tester.pump(const Duration(seconds: 5));
      expect(haptics.vibrate, 0, reason: 'nothing happens in the background');
      expect(haptics.heavy, heavyBefore);

      bringToForeground(tester);
      await tester.pump();

      expect(ring(tester).phase, 'DONE');
      expect(haptics.vibrate, 1);
      expect(
        haptics.heavy,
        heavyBefore,
        reason: 'the middle phases are skipped',
      );
      expect(awakeOf(services).calls.last, isFalse);

      await tester.pump(const Duration(seconds: 5));
      expect(haptics.vibrate, 1, reason: 'no second buzz');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a short time away: back in the right round, one buzz', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final haptics = captureHaptics(tester);
      final services = await _openRun(tester, now);
      await _runAt(tester, now, 5);

      sendToBackground(tester);
      now.value = evening().add(const Duration(seconds: 10 + 30 * 3 + 5));
      bringToForeground(tester);
      await tester.pump();

      expect(find.text('Round 4 of 8'), findsOne);
      expect(ring(tester).phase, 'WORK');
      expect(ring(tester).time, '0:15');
      expect(haptics.heavy, 1, reason: 'one buzz for the jump');
      expect(haptics.vibrate, 0);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a paused workout does not advance in the background', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _openRun(tester, now);
      await _runAt(tester, now, 15);
      await _tapIcon(tester, 'Pause');

      sendToBackground(tester);
      now.value = evening().add(const Duration(hours: 1));
      bringToForeground(tester);
      await tester.pump();

      expect(ring(tester).phase, 'WORK');
      expect(ring(tester).time, '0:15');
      expect(semLabel('Resume'), findsOne);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Interval run screen: other shapes of workout', () {
    testWidgets('several sets show "Set x of y" and the rest between sets', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _openRun(
        tester,
        now,
        custom: const IntervalConfig(
          prepare: 10,
          work: 20,
          rest: 10,
          rounds: 2,
          sets: 2,
          setRest: 60,
        ),
      );
      expect(find.text('Set 1 of 2 · Round 1 of 2'), findsOne);
      expect(find.text('1 / 2'), findsOne);
      expect(find.text('Custom'), findsOne);
      // Hiệp 2 của set 1 -> 10 + 30 = 40 giây.
      await _runAt(tester, now, 40);
      expect(find.text('Set 1 of 2 · Round 2 of 2'), findsOne);

      // Hết set 1 -> nghỉ giữa các set, hiện là REST với thời gian 1:00.
      await _runAt(tester, now, 70);
      expect(ring(tester).phase, 'REST');
      expect(ring(tester).time, '1:00');
      expect(ring(tester).tone, TimerRingTone.tide);
      expect(find.text('Next: Work 0:20'), findsOne);
      expect(find.text('Set 1 of 2 · Round 2 of 2'), findsOne);

      await _runAt(tester, now, 130);
      expect(ring(tester).phase, 'WORK');
      expect(find.text('Set 2 of 2 · Round 1 of 2'), findsOne);
      expect(find.text('1 / 2'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('prepare of 0 starts straight on WORK', (tester) async {
      final now = FakeNow(evening());
      final haptics = captureHaptics(tester);
      final services = await _openRun(
        tester,
        now,
        custom: _tabata.withValue(IntervalField.prepare, 0),
      );

      expect(ring(tester).phase, 'WORK');
      expect(ring(tester).time, '0:20');
      expect(find.text('Round 1 of 8'), findsOne);
      expect(find.text('4:00 left'), findsOne);
      expect(haptics.total, 0);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('rest of 0 goes from work straight to the next work', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _openRun(
        tester,
        now,
        custom: _tabata.withValue(IntervalField.rest, 0),
      );
      expect(find.text('2:40 left'), findsOne, reason: '8 x 20 s');
      expect(ring(tester).caption, '20 s work · 0 s rest');

      await _runAt(tester, now, 10);
      expect(ring(tester).phase, 'WORK');
      expect(find.text('Next: Work 0:20'), findsOne);
      await _runAt(tester, now, 30);
      expect(ring(tester).phase, 'WORK');
      expect(find.text('Round 2 of 8'), findsOne);
      expect(find.text('REST'), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('minutes in the ring caption: 1:30 work, 2:00 rest', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _openRun(
        tester,
        now,
        custom: _tabata
            .withValue(IntervalField.work, 90)
            .withValue(IntervalField.rest, 120),
      );

      expect(ring(tester).caption, '1:30 work · 2:00 rest');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a workout of one round has no "Next" after its last phase', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _openRun(
        tester,
        now,
        custom: const IntervalConfig(
          prepare: 0,
          work: 20,
          rest: 0,
          rounds: 1,
          sets: 1,
          setRest: 0,
        ),
      );

      expect(ring(tester).phase, 'WORK');
      expect(find.textContaining('Next:'), findsNothing);
      expect(find.text('1 / 1'), findsOne);

      await _runAt(tester, now, 20);
      expect(ring(tester).phase, 'DONE');
      expect(ring(tester).time, '0:20');
      expect(ring(tester).caption, '1 interval · 1 round');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a time of an hour or more is shown as H:MM:SS', (
      tester,
    ) async {
      final now = FakeNow(evening());
      // Màn rộng: với phông Ahem của môi trường test, "10:00" trong hàng
      // Stepper rộng hơn nhiều so với phông Figtree thật.
      final services = await _openRun(
        tester,
        now,
        size: const Size(700, 1000),
        custom: const IntervalConfig(
          prepare: 10,
          work: 600,
          rest: 600,
          rounds: 4,
          sets: 1,
          setRest: 0,
        ),
      );

      expect(find.text('1:20:00 left'), findsOne);

      await disposeSteadyApp(tester, services);
    });
  });
}
