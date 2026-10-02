import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/theme/tokens.dart';
import 'package:steady/core/time/local_date.dart';
import 'package:steady/ui/components/steady_button.dart';
import 'package:steady/ui/components/steady_progress_bar.dart';
import 'package:steady/ui/components/streak_card.dart';

import '../helpers/test_app.dart';
import '../helpers/widget_helpers.dart';

const _family = '👨‍👩‍👧';

/// Lỗi hiện ngay trong sheet, không phải ở chỗ nào khác:
/// (1) đúng một chữ lỗi nằm trong `BottomSheet` (và không có bản nào ngoài nó);
/// (2) không có `SnackBar`;
/// (3) khung chữ nằm trọn trong khung sheet và trong màn hình, cạnh dưới của
///     chữ không thấp hơn cạnh trên của nút [buttonLabel];
/// (4) chạm vào tâm chữ lỗi rơi vào sheet (không rơi vào lớp chắn phía sau).
void _expectErrorInsideSheet(WidgetTester t, {required String buttonLabel}) {
  final inSheet = find.descendant(
    of: find.byType(BottomSheet),
    matching: find.text(saveErrorText),
  );
  expect(inSheet, findsOne, reason: 'exactly one error text inside the sheet');
  expect(
    find.text(saveErrorText),
    findsOne,
    reason: 'and no copy of it outside the sheet',
  );
  expect(find.byType(SnackBar), findsNothing);

  final sheet = t.getRect(find.byType(BottomSheet));
  final error = t.getRect(inSheet);
  final screen = Offset.zero & t.view.physicalSize;
  for (final (name, outer) in [('sheet', sheet), ('screen', screen)]) {
    expect(error.left, greaterThanOrEqualTo(outer.left), reason: name);
    expect(error.right, lessThanOrEqualTo(outer.right), reason: name);
    expect(error.top, greaterThanOrEqualTo(outer.top), reason: name);
    expect(error.bottom, lessThanOrEqualTo(outer.bottom), reason: name);
  }
  final button = t.getRect(find.widgetWithText(SteadyButton, buttonLabel));
  expect(
    error.bottom,
    lessThanOrEqualTo(button.top),
    reason: 'the error sits above the "$buttonLabel" button, not over it',
  );

  final hits = t.hitTestOnBinding(error.center).path.map((e) => e.target);
  expect(hits, contains(t.renderObject(inSheet)));
  expect(
    hits,
    contains(t.renderObject(find.byType(BottomSheet))),
    reason: 'a tap on the error text lands in the sheet',
  );
}

Future<void> _openStreaks(WidgetTester t, FakeNow now) => tapTab(t, 'Streaks');

void main() {
  group('Streaks list', () {
    testWidgets('no habits: title, hint and the Add habit button', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);

      expect(find.text('Streaks'), findsNWidgets(2)); // tab + screen title
      expect(find.text('Add a habit you want to leave behind.'), findsOne);
      expect(find.text('Add habit'), findsOne);
      expect(find.byType(StreakCard), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the main card shows 127, the date and the next milestone', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(tester, services);

      expect(find.text('127'), findsOne);
      expect(find.text('days'), findsOne);
      expect(find.text('No smoking'), findsOne);
      expect(find.text('Since May 28'), findsOne);
      expect(find.text('Next: 180 days · 53 to go'), findsOne);
      // Có thẻ thì không còn dòng gợi ý của trạng thái rỗng.
      expect(find.text('Add a habit you want to leave behind.'), findsNothing);

      final card = tester.widget<StreakCard>(find.byType(StreakCard));
      expect(card.size, StreakCardSize.lg);
      expect(card.days, 127);

      final bar = tester.widget<SteadyProgressBar>(
        find.byType(SteadyProgressBar),
      );
      expect(bar.value, closeTo(37 / 90, 1e-9));
      expect(bar.tone, SteadyBarTone.tide);
      expect(bar.semanticLabel, 'Next: 180 days · 53 to go');
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('1 day is singular and 2 days is plural', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);

      await seedHabit(tester, services, since: LocalDate(2026, 10, 1));
      expect(find.text('1'), findsOne);
      expect(find.text('day'), findsOne);
      expect(find.text('days'), findsNothing);
      expect(find.text('Since Oct 1'), findsOne);
      expect(find.text('Next: 3 days · 2 to go'), findsOne);

      now.value = DateTime(2026, 10, 3, 9);
      services.today.refresh();
      await tester.pump();
      expect(find.text('2'), findsOne);
      expect(find.text('days'), findsOne);
      expect(find.text('day'), findsNothing);
      expect(find.text('Next: 3 days · 1 to go'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a habit started today shows 0 days and the 1 day milestone', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(tester, services, since: today);

      expect(find.text('0'), findsOne);
      expect(find.text('days'), findsOne);
      expect(find.text('Since Oct 2'), findsOne);
      expect(find.text('Next: 1 day · 1 to go'), findsOne);
      expect(
        tester.widget<SteadyProgressBar>(find.byType(SteadyProgressBar)).value,
        0.0,
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('from 365 days on the milestone bar is hidden', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(tester, services, since: LocalDate(2025, 10, 2));

      expect(find.text('365'), findsOne);
      expect(find.text('Since Oct 2, 2025'), findsOne);
      expect(find.byType(SteadyProgressBar), findsNothing);
      expect(find.textContaining('Next:'), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('364 days still shows the milestone, 1 to go', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(tester, services, since: LocalDate(2025, 10, 3));

      expect(find.text('364'), findsOne);
      expect(find.text('Next: 365 days · 1 to go'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('several habits: most days first, only the first is large', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(
        tester,
        services,
        name: 'Newest',
        since: LocalDate(2026, 9, 1),
      );
      await seedHabit(
        tester,
        services,
        name: 'Oldest',
        since: LocalDate(2026, 1, 1),
      );
      await seedHabit(
        tester,
        services,
        name: 'Middle',
        since: LocalDate(2026, 5, 1),
      );

      final cards = tester
          .widgetList<StreakCard>(find.byType(StreakCard))
          .toList();
      expect(cards.map((c) => c.habit), ['Oldest', 'Middle', 'Newest']);
      expect(cards.map((c) => c.size), [
        StreakCardSize.lg,
        StreakCardSize.sm,
        StreakCardSize.sm,
      ]);
      expect(cards[0].milestone, isNotNull);
      expect(cards[1].milestone, isNull);
      expect(cards[2].milestone, isNull);
      expect(find.byType(SteadyProgressBar), findsOne);

      // Thứ tự trên màn hình đúng như thứ tự dữ liệu.
      final y = [
        for (final n in ['Oldest', 'Middle', 'Newest'])
          tester.getTopLeft(find.text(n)).dy,
      ];
      expect(y, orderedEquals([...y]..sort()));
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('equal days: the habit added first stays on top', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(
        tester,
        services,
        name: 'First',
        since: LocalDate(2026, 9, 1),
      );
      now.value = DateTime(2026, 10, 2, 22);
      await seedHabit(
        tester,
        services,
        name: 'Second',
        since: LocalDate(2026, 9, 1),
      );

      final names = tester
          .widgetList<StreakCard>(find.byType(StreakCard))
          .map((c) => c.habit)
          .toList();
      expect(names, ['First', 'Second']);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a start date in the future shows 0, never a negative', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(tester, services, since: today);

      // Đồng hồ máy bị chỉnh lùi 12 ngày.
      now.value = DateTime(2026, 9, 20, 10);
      services.today.refresh();
      await tester.pump();

      expect(find.text('0'), findsOne);
      expect(
        find.descendant(
          of: find.byType(StreakCard),
          matching: find.textContaining('-'),
        ),
        findsNothing,
      );
      expect(tester.widget<StreakCard>(find.byType(StreakCard)).days, 0);
      expect(find.text('Next: 1 day · 1 to go'), findsOne);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Streaks across midnight', () {
    testWidgets('the day count goes up after TodayNotifier.refresh()', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(tester, services);
      expect(find.text('127'), findsOne);
      expect(find.text('Next: 180 days · 53 to go'), findsOne);

      now.value = DateTime(2026, 10, 3, 9);
      services.today.refresh();
      await tester.pump();

      expect(find.text('128'), findsOne);
      expect(find.text('127'), findsNothing);
      expect(find.text('Next: 180 days · 52 to go'), findsOne);
      expect(find.text('Since May 28'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the app updates by itself when the clock passes midnight', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(tester, services);
      expect(find.text('127'), findsOne);

      // Không gọi refresh(): Timer của TodayNotifier phải tự báo ngày mới.
      now.value = DateTime(2026, 10, 3, 0, 0, 30);
      await tester.pump(const Duration(hours: 3, seconds: 5));

      expect(find.text('128'), findsOne);
      expect(find.text('127'), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('returning from the background picks up the new day', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(tester, services);

      sendToBackground(tester);
      now.value = DateTime(2026, 10, 5, 7);
      bringToForeground(tester);
      await tester.pump();

      expect(find.text('130'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a daylight-saving night adds exactly one day', (tester) async {
      // 2026-03-08 (Mỹ) và 2026-03-29 (châu Âu) đều có đêm đổi giờ.
      final now = FakeNow(DateTime(2026, 3, 8, 23, 30));
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(tester, services, since: LocalDate(2026, 3, 7));
      expect(find.text('1'), findsOne);

      now.value = DateTime(2026, 3, 9, 8);
      services.today.refresh();
      await tester.pump();
      expect(find.text('2'), findsOne);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Add habit sheet', () {
    Future<void> openSheet(WidgetTester t) async {
      await t.tap(find.text('Add habit'));
      await settle(t);
    }

    testWidgets('shows its fields; Save is disabled while the name is empty', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await openSheet(tester);

      expect(find.text('Add habit'), findsNWidgets(2)); // nút + tiêu đề sheet
      expect(find.text('Habit'), findsOne);
      expect(find.text('No sugar'), findsOne); // hint
      expect(find.text('Clean since'), findsOne);
      expect(find.text('Oct 2'), findsOne); // mặc định là hôm nay
      expect(find.text('Save habit'), findsOne);
      expect(isButtonEnabled(tester, 'Save habit'), isFalse);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(
        isButtonEnabled(tester, 'Save habit'),
        isFalse,
        reason: 'whitespace only counts as empty',
      );

      await tester.enterText(find.byType(TextField), 'No sugar');
      await tester.pump();
      expect(isButtonEnabled(tester, 'Save habit'), isTrue);

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(isButtonEnabled(tester, 'Save habit'), isFalse);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('saving adds the habit, closes the sheet and shows the card', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await openSheet(tester);

      await tester.enterText(find.byType(TextField), 'No sugar');
      await tester.pump();
      await tester.tap(find.text('Save habit'));
      await settle(tester);

      expect(find.text('Save habit'), findsNothing, reason: 'sheet closed');
      expect(find.text('No sugar'), findsOne);
      expect(find.text('0'), findsOne);
      expect(find.text('Since Oct 2'), findsOne);
      final stored = await tester.runAsync(
        () => services.habits.watchHabits().first,
      );
      expect(stored!.single.name, 'No sugar');
      expect(stored.single.cleanSince, today);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the name is trimmed before it is stored', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await openSheet(tester);

      await tester.enterText(find.byType(TextField), '   Walk daily   ');
      await tester.pump();
      await tester.tap(find.text('Save habit'));
      await settle(tester);

      final stored = await tester.runAsync(
        () => services.habits.watchHabits().first,
      );
      expect(stored!.single.name, 'Walk daily');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a second habit can be added after the first', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(tester, services);

      await tester.scrollUntilVisible(
        find.text('Add habit'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await openSheet(tester);
      await tester.enterText(find.byType(TextField), 'No sugar');
      await tester.pump();
      await tester.tap(find.text('Save habit'));
      await settle(tester);

      final cards = tester
          .widgetList<StreakCard>(find.byType(StreakCard))
          .map((c) => c.habit)
          .toList();
      expect(cards, ['No smoking', 'No sugar']);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the field stops at 40 characters (ASCII)', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await openSheet(tester);

      await tester.enterText(find.byType(TextField), 'a' * 50);
      await tester.pump();
      final text = tester
          .widget<TextField>(find.byType(TextField))
          .controller!
          .text;
      expect(text, 'a' * 40);
      expect(isButtonEnabled(tester, 'Save habit'), isTrue);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the limit counts a ZWJ family emoji as one character', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await openSheet(tester);

      await tester.enterText(find.byType(TextField), _family * 41);
      await tester.pump();
      final controller = tester
          .widget<TextField>(find.byType(TextField))
          .controller!;
      expect(controller.text.characters.length, 40);
      expect(controller.text, _family * 40);
      expect(isButtonEnabled(tester, 'Save habit'), isTrue);

      await tester.tap(find.text('Save habit'));
      await settle(tester);
      final stored = await tester.runAsync(
        () => services.habits.watchHabits().first,
      );
      expect(stored!.single.name, _family * 40);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a line break typed or pasted never reaches the name', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await openSheet(tester);

      await tester.enterText(find.byType(TextField), 'No\nsugar');
      await tester.pump();
      final text = tester
          .widget<TextField>(find.byType(TextField))
          .controller!
          .text;
      final blocked =
          !isButtonEnabled(tester, 'Save habit') && text.contains('\n');
      expect(
        text.contains(RegExp(r'[\r\n]')) == false || blocked,
        isTrue,
        reason: 'either the field strips line breaks or Save stays disabled',
      );

      if (isButtonEnabled(tester, 'Save habit')) {
        await tester.tap(find.text('Save habit'));
        await settle(tester);
      }
      final stored = await tester.runAsync(
        () => services.habits.watchHabits().first,
      );
      for (final h in stored!) {
        expect(h.name.contains(RegExp(r'[\r\n]')), isFalse);
      }

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the date picker changes the start date', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await openSheet(tester);

      await tester.tap(find.text('Oct 2'));
      await settle(tester);
      expect(find.text('OK'), findsOne);
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('OK'));
      await settle(tester);

      expect(find.text('Oct 1'), findsOne);
      await tester.enterText(find.byType(TextField), 'No sugar');
      await tester.pump();
      await tester.tap(find.text('Save habit'));
      await settle(tester);

      expect(find.text('Since Oct 1'), findsOne);
      expect(find.text('1'), findsOne);
      expect(find.text('day'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('cancelling the date picker keeps the date', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await openSheet(tester);

      await tester.tap(find.text('Oct 2'));
      await settle(tester);
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await settle(tester);

      expect(find.text('Oct 2'), findsOne);
      expect(find.text('Oct 1'), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the date picker does not allow a date after today', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await openSheet(tester);

      await tester.tap(find.text('Oct 2'));
      await settle(tester);
      await tester.tap(find.text('15')); // tương lai: không chọn được
      await tester.pump();
      await tester.tap(find.text('OK'));
      await settle(tester);

      expect(find.text('Oct 2'), findsOne);
      expect(find.text('Oct 15'), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a date in an earlier year is shown with the year', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await openSheet(tester);

      await tester.tap(find.text('Oct 2'));
      await settle(tester);
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.byTooltip('Previous month'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('15'));
      await tester.pump();
      await tester.tap(find.text('OK'));
      await settle(tester);

      expect(find.text('Dec 15, 2025'), findsOne);
      await tester.enterText(find.byType(TextField), 'No sugar');
      await tester.pump();
      await tester.tap(find.text('Save habit'));
      await settle(tester);

      expect(find.text('Since Dec 15, 2025'), findsOne);
      expect(find.text('291'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('after midnight the new habit uses the new today', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await openSheet(tester);
      await tester.enterText(find.byType(TextField), 'No sugar');
      await tester.pump();

      now.value = DateTime(2026, 10, 3, 0, 10);
      services.today.refresh();
      await tester.pump();
      await tester.tap(find.text('Save habit'));
      await settle(tester);

      // Ngày bắt đầu mặc định (2026-10-02) vẫn hợp lệ: nay là 1 ngày.
      expect(find.text('1'), findsOne);
      expect(find.text('day'), findsOne);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    // Case phải thất bại: ghi DB lỗi.
    testWidgets('a failed save shows the error and keeps the sheet and input', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await breakWrites(tester, services, 'habits');
      await openSheet(tester);
      await tester.enterText(find.byType(TextField), 'No sugar');
      await tester.pump();

      await tester.tap(find.text('Save habit'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(saveErrorText), findsOne);
      expect(find.text('Save habit'), findsOne, reason: 'sheet stays open');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'No sugar',
        reason: 'what the user typed is not lost',
      );
      expect(
        isButtonEnabled(tester, 'Save habit'),
        isTrue,
        reason: 'the user can try again',
      );
      final stored = await tester.runAsync(
        () => services.habits.watchHabits().first,
      );
      expect(stored, isEmpty);
      expect(tester.takeException(), isNull);

      // Sau khi DB khoẻ lại, bấm lần nữa thì lưu được.
      await repairWrites(tester, services, 'habits');
      await tester.tap(find.text('Save habit'));
      await settle(tester);
      expect(find.text('Save habit'), findsNothing);
      expect(find.text('No sugar'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the save error is visible inside the add-habit sheet', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await breakWrites(tester, services, 'habits');
      await openSheet(tester);
      await tester.enterText(find.byType(TextField), 'No sugar');
      await tester.pump();
      await tester.tap(find.text('Save habit'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      _expectErrorInsideSheet(tester, buttonLabel: 'Save habit');
      expect(isButtonEnabled(tester, 'Save habit'), isTrue);

      // Bấm lần nữa mà vẫn lỗi: vẫn chỉ có một dòng lỗi, không chồng lên nhau.
      await tester.tap(find.text('Save habit'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      _expectErrorInsideSheet(tester, buttonLabel: 'Save habit');

      await disposeSteadyApp(tester, services);
    });

    testWidgets(
      'control: a snackbar on a plain screen is visible to the user',
      (tester) async {
        // Kiểm chứng chính phép đo: cùng cách đo, không có sheet đè lên.
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(tester, clock: now.clock);
        await _openStreaks(tester, now);
        await seedHabit(tester, services);
        await tester.tap(find.text('No smoking'));
        await settle(tester);
        await tester.tap(find.text('Reset streak'));
        await settle(tester);

        expect(find.text(resetDoneText), findsOne);
        expect(await snackBarIsVisibleToUser(tester), isTrue);

        await disposeSteadyApp(tester, services);
      },
    );

    // R5: "hôm nay" lùi lại khi sheet đang mở (chỉnh đồng hồ, đổi múi giờ).
    testWidgets('a start date left in the future is clamped to today', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await openSheet(tester);
      await tester.enterText(find.byType(TextField), 'No sugar');
      await tester.pump();

      now.value = DateTime(2026, 9, 20, 10); // lùi 12 ngày
      services.today.refresh();
      await tester.pump();
      await tester.tap(find.text('Save habit'));
      await settle(tester);

      expect(find.text(saveErrorText), findsNothing);
      expect(find.text('Save habit'), findsNothing, reason: 'sheet closed');
      final stored = await tester.runAsync(
        () => services.habits.watchHabits().first,
      );
      expect(stored!.single.cleanSince, LocalDate(2026, 9, 20));
      expect(find.text('0'), findsOne);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the date picker still opens after the clock moved back', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await openSheet(tester);

      now.value = DateTime(2026, 9, 20, 10);
      services.today.refresh();
      await tester.pump();
      await tester.tap(find.textContaining(RegExp(r'^(Oct 2|Sep 20)$')));
      await settle(tester);
      expect(find.text('OK'), findsOne, reason: 'the picker is open');
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('OK'));
      await settle(tester);

      expect(find.text('Sep 20'), findsOne);
      expect(find.text('Oct 2'), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('two taps on Save (one frame apart) add one habit', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await openSheet(tester);
      await tester.enterText(find.byType(TextField), 'No sugar');
      await tester.pump();

      await tester.tap(find.text('Save habit'));
      await tester.pump();
      await tester.tap(find.text('Save habit'), warnIfMissed: false);
      await settle(tester);

      final stored = await tester.runAsync(
        () => services.habits.watchHabits().first,
      );
      expect(stored, hasLength(1));

      await disposeSteadyApp(tester, services);
    });
  });

  group('Habit actions sheet', () {
    testWidgets('tapping a card opens the sheet with its name and actions', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(tester, services);

      await tester.tap(find.text('No smoking'));
      await settle(tester);

      expect(find.text('No smoking'), findsNWidgets(2)); // thẻ + tiêu đề sheet
      expect(find.text('Reset streak'), findsOne);
      expect(find.text('Delete habit'), findsOne);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('reset sets the count to 0 and shows the encouragement', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(tester, services);
      await tester.tap(find.text('No smoking'));
      await settle(tester);

      await tester.tap(find.text('Reset streak'));
      await settle(tester);

      expect(find.text('Reset streak'), findsNothing, reason: 'sheet closed');
      expect(find.text('127'), findsNothing);
      expect(find.text('0'), findsOne);
      expect(find.text('Since Oct 2'), findsOne);
      expect(find.text(resetDoneText), findsOne);
      expect(find.text('Next: 1 day · 1 to go'), findsOne);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('reset only affects the tapped habit', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(
        tester,
        services,
        name: 'Main',
        since: LocalDate(2026, 1, 1),
      );
      await seedHabit(
        tester,
        services,
        name: 'Second',
        since: LocalDate(2026, 5, 1),
      );

      await tester.tap(find.text('Second'));
      await settle(tester);
      await tester.tap(find.text('Reset streak'));
      await settle(tester);

      final cards = {
        for (final c in tester.widgetList<StreakCard>(find.byType(StreakCard)))
          c.habit: c.days,
      };
      expect(cards, {'Main': 274, 'Second': 0});

      await disposeSteadyApp(tester, services);
    });

    testWidgets('delete asks first; Cancel keeps the habit', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(tester, services);
      await tester.tap(find.text('No smoking'));
      await settle(tester);

      await tester.tap(find.text('Delete habit'));
      await settle(tester);
      expect(find.text('Delete No smoking?'), findsOne);
      expect(
        find.text("This removes the habit and its count. It can't be undone."),
        findsOne,
      );
      expect(find.text('Cancel'), findsOne);
      expect(find.text('Delete'), findsOne);

      await tester.tap(find.text('Cancel'));
      await settle(tester);

      expect(find.text('Delete No smoking?'), findsNothing);
      expect(find.text('Delete habit'), findsOne, reason: 'sheet still open');
      final stored = await tester.runAsync(
        () => services.habits.watchHabits().first,
      );
      expect(stored, hasLength(1));

      await disposeSteadyApp(tester, services);
    });

    testWidgets('tapping outside the dialog does not delete', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(tester, services);
      await tester.tap(find.text('No smoking'));
      await settle(tester);
      await tester.tap(find.text('Delete habit'));
      await settle(tester);
      expect(find.text('Delete No smoking?'), findsOne);

      await tester.tapAt(const Offset(8, 8));
      await settle(tester);

      expect(find.text('Delete No smoking?'), findsNothing);
      final stored = await tester.runAsync(
        () => services.habits.watchHabits().first,
      );
      expect(stored, hasLength(1));
      expect(find.text('127'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Delete then Delete removes the habit and closes the sheet', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(tester, services);
      await tester.tap(find.text('No smoking'));
      await settle(tester);
      await tester.tap(find.text('Delete habit'));
      await settle(tester);

      await tester.tap(find.text('Delete'));
      await settle(tester);

      expect(find.text('Delete habit'), findsNothing, reason: 'sheet closed');
      expect(find.text('Delete No smoking?'), findsNothing);
      expect(find.text('No smoking'), findsNothing);
      expect(find.byType(StreakCard), findsNothing);
      expect(find.text('Add a habit you want to leave behind.'), findsOne);
      final stored = await tester.runAsync(
        () => services.habits.watchHabits().first,
      );
      expect(stored, isEmpty);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('resetting a habit that was already deleted does not crash', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      final habit = await seedHabit(tester, services);
      await tester.tap(find.text('No smoking'));
      await settle(tester);

      await dbAction(tester, () => services.habits.deleteHabit(habit.id));
      await tester.tap(find.text('Reset streak'));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Reset streak'), findsNothing, reason: 'sheet closed');
      expect(find.text(resetDoneText), findsNothing);
      expect(find.text(saveErrorText), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('deleting a habit that was already deleted does not crash', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      final habit = await seedHabit(tester, services);
      await tester.tap(find.text('No smoking'));
      await settle(tester);

      await dbAction(tester, () => services.habits.deleteHabit(habit.id));
      await tester.tap(find.text('Delete habit'));
      await settle(tester);
      await tester.tap(find.text('Delete'));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Delete habit'), findsNothing, reason: 'sheet closed');
      expect(find.text(saveErrorText), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    // Case phải thất bại: ghi DB lỗi.
    testWidgets('a failed reset shows the error and leaves the habit as is', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(tester, services);
      await breakWrites(tester, services, 'habits');
      await tester.tap(find.text('No smoking'));
      await settle(tester);

      await tester.tap(find.text('Reset streak'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(saveErrorText), findsOne);
      expect(find.text(resetDoneText), findsNothing);
      expect(find.text('Reset streak'), findsOne, reason: 'sheet stays open');
      expect(isButtonEnabled(tester, 'Reset streak'), isTrue);
      expect(isButtonEnabled(tester, 'Delete habit'), isTrue);
      expect(find.text('127'), findsOne);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a failed delete shows the error and keeps the habit', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(tester, services);
      await breakWrites(tester, services, 'habits');
      await tester.tap(find.text('No smoking'));
      await settle(tester);
      await tester.tap(find.text('Delete habit'));
      await settle(tester);

      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(saveErrorText), findsOne);
      expect(find.text('Delete habit'), findsOne, reason: 'sheet stays open');
      expect(isButtonEnabled(tester, 'Delete habit'), isTrue);
      final stored = await tester.runAsync(
        () => services.habits.watchHabits().first,
      );
      expect(stored, hasLength(1));
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the reset error is visible inside the actions sheet', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(tester, services);
      await breakWrites(tester, services, 'habits');
      await tester.tap(find.text('No smoking'));
      await settle(tester);
      await tester.tap(find.text('Reset streak'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      _expectErrorInsideSheet(tester, buttonLabel: 'Reset streak');
      expect(find.text(resetDoneText), findsNothing);
      expect(isButtonEnabled(tester, 'Reset streak'), isTrue);
      expect(find.text('127'), findsOne, reason: 'the count is unchanged');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the delete error is visible inside the actions sheet', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(tester, services);
      await breakWrites(tester, services, 'habits');
      await tester.tap(find.text('No smoking'));
      await settle(tester);
      await tester.tap(find.text('Delete habit'));
      await settle(tester);
      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      _expectErrorInsideSheet(tester, buttonLabel: 'Reset streak');
      expect(isButtonEnabled(tester, 'Delete habit'), isTrue);
      expect(isButtonEnabled(tester, 'Reset streak'), isTrue);
      final stored = await tester.runAsync(
        () => services.habits.watchHabits().first,
      );
      expect(stored, hasLength(1));

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a reset error goes away once a retry succeeds', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(tester, services);
      await breakWrites(tester, services, 'habits');
      await tester.tap(find.text('No smoking'));
      await settle(tester);
      await tester.tap(find.text('Reset streak'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(saveErrorText), findsOne);

      await repairWrites(tester, services, 'habits');
      await tester.tap(find.text('Reset streak'));
      await settle(tester);

      expect(find.text('Reset streak'), findsNothing, reason: 'sheet closed');
      expect(find.text(saveErrorText), findsNothing);
      expect(find.text(resetDoneText), findsOne);
      expect(find.text('0'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a very long habit name is clipped in the sheet title', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(tester, services, name: 'W' * 40);
      await tester.tap(find.text('W' * 40).first);
      await settle(tester);

      final title = tester.widget<Text>(find.text('W' * 40).last);
      expect(title.maxLines, 2);
      expect(title.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Sheets and dialogs are not tinted', () {
    testWidgets('sheet and dialog surfaces are exactly the surface color', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openStreaks(tester, now);
      await seedHabit(tester, services);
      final surface = SteadyColors.dark.surface.toARGB32();

      await tester.tap(find.text('No smoking'));
      await settle(tester);
      final sheet = tester.getRect(find.byType(BottomSheet));
      expect(
        await pixelAt(tester, sheet.centerLeft + const Offset(6, 0)),
        surface,
        reason: 'sheet body',
      );

      await tester.tap(find.text('Delete habit'));
      await settle(tester);
      final dialog = tester.getRect(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(
        await pixelAt(tester, dialog.centerLeft + const Offset(8, 0)),
        surface,
        reason: 'dialog body: no amber tint from elevation',
      );

      await disposeSteadyApp(tester, services);
    });
  });
}
