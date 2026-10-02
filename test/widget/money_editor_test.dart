import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/services.dart';
import 'package:steady/core/theme/typography.dart';
import 'package:steady/core/time/local_date.dart';
import 'package:steady/data/database.dart';
import 'package:steady/data/money_types.dart';
import 'package:steady/features/money/entry_row.dart';
import 'package:steady/ui/components/bar_chart_row.dart';
import 'package:steady/ui/components/icon_tile.dart';
import 'package:steady/ui/components/keypad.dart';
import 'package:steady/ui/components/steady_tab_bar.dart';

import '../helpers/money_helpers.dart';
import '../helpers/test_app.dart';
import '../helpers/timer_helpers.dart';
import '../helpers/widget_helpers.dart';

/// Số lớn trên màn nhập (và trên tab Money): cùng kiểu chữ `moneyXl`.
Finder _bigNumber() => find.byWidgetPredicate(
  (w) => w is Text && w.style?.fontSize == SteadyText.moneyXl.fontSize,
);

String _shown(WidgetTester t) => plain(t.widget<Text>(_bigNumber().last).data!);

Finder _tile(String label) =>
    find.widgetWithText(IconTile, label, skipOffstage: false);

bool? _selected(WidgetTester t, String label) =>
    t.widget<IconTile>(_tile(label)).selected;

int _tileCount(WidgetTester t) =>
    find.byType(IconTile, skipOffstage: false).evaluate().length;

Future<void> _back(WidgetTester t) async {
  await t.binding.handlePopRoute();
  await t.pumpAndSettle();
}

/// Mở tab Money, rồi màn nhập.
Future<void> _openAddScreen(WidgetTester t) async {
  await openMoney(t);
  await openEditor(t);
}

/// Ô ngày [day] trong hộp chọn ngày (không nhầm với phím số của Keypad nằm
/// dưới lớp phủ của hộp thoại).
Finder _calendarDay(int day) => find.descendant(
  of: find.byType(CalendarDatePicker),
  matching: find.text('$day'),
);

/// Chọn ngày [day] của tháng đang hiện trong hộp chọn ngày và bấm OK.
Future<void> _pickDay(WidgetTester t, String currentLabel, int day) async {
  await t.tap(find.text(currentLabel));
  await settle(t);
  await t.tap(_calendarDay(day));
  await t.pump();
  await t.tap(find.text('OK'));
  await settle(t);
}

void main() {
  group('Add expense screen', () {
    testWidgets('opens over the whole app with the empty form', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openMoney(tester);
      expect(find.byType(SteadyTabBar), findsOne);

      await openEditor(tester);

      expect(
        find.byType(SteadyTabBar),
        findsNothing,
        reason: 'tab bar is gone',
      );
      expect(find.text('Add expense'), findsOne, reason: 'screen title');
      expect(_shown(tester), r'$0');
      expect(find.text('Choose a category'), findsOne);
      expect(find.text('Today'), findsOne);
      expect(find.text('Note'), findsOne);
      expect(isButtonEnabled(tester, 'Save expense'), isFalse);
      expect(find.byType(Keypad), findsOne);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('shows seven categories and a More tile, nothing preselected', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);

      for (final label in [
        'Groceries',
        'Eating out',
        'Transport',
        'Bills',
        'Shopping',
        'Health',
        'Gifts',
      ]) {
        expect(_selected(tester, label), isFalse, reason: label);
      }
      expect(_selected(tester, 'More'), isNull, reason: 'an action tile');
      expect(_tileCount(tester), 8);
      for (final hidden in [
        'Housing',
        'Travel',
        'Phone',
        'Education',
        'Other',
      ]) {
        expect(_tile(hidden), findsNothing, reason: hidden);
      }

      await disposeSteadyApp(tester, services);
    });

    testWidgets(
      'the amount is a live region and the grid is labelled "Category"',
      (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(tester, clock: now.clock);
        await _openAddScreen(tester);
        final handle = tester.ensureSemantics();

        expect(
          tester.getSemantics(find.text(r'$0')),
          isSemantics(isLiveRegion: true, label: r'$0'),
          reason: 'a screen reader announces each keypress',
        );
        await pressKeys(tester, '12.4');
        expect(
          tester.getSemantics(find.text(r'$12.4')),
          isSemantics(isLiveRegion: true, label: r'$12.4'),
        );
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.container &&
                w.properties.label == 'Category',
          ),
          findsOne,
        );
        expect(tester.takeException(), isNull);

        handle.dispose();
        await disposeSteadyApp(tester, services);
      },
    );

    testWidgets('More reveals the other five and goes away', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);

      await tester.tap(find.text('More'));
      await tester.pump();

      expect(_tileCount(tester), 12);
      expect(_tile('More'), findsNothing);
      for (final label in [
        'Housing',
        'Travel',
        'Phone',
        'Education',
        'Other',
      ]) {
        expect(_tile(label), findsOne, reason: label);
      }
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets(
      'typing 1 2 . 4 shows 12.4 dollars; Save waits for a category',
      (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(tester, clock: now.clock);
        await _openAddScreen(tester);

        await pressKeys(tester, '12.4');
        expect(_shown(tester), r'$12.4');
        expect(isButtonEnabled(tester, 'Save expense'), isFalse);

        await pickCategory(tester, 'Groceries');
        expect(isButtonEnabled(tester, 'Save expense'), isTrue);
        expect(_selected(tester, 'Groceries'), isTrue);
        expect(find.text('Choose a category'), findsNothing);

        await disposeSteadyApp(tester, services);
      },
    );

    testWidgets('the display follows each key, including the bare point', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);

      final shown = <String>[];
      for (final key in ['1', '2', '.', '4', '0']) {
        await pressKeys(tester, key);
        shown.add(_shown(tester));
      }
      expect(shown, [r'$1', r'$12', r'$12.', r'$12.4', r'$12.40']);

      await pressKeys(tester, '5');
      expect(_shown(tester), r'$12.40', reason: 'a third decimal is ignored');

      await pressKeys(tester, '<<');
      expect(_shown(tester), r'$12.');
      await pressKeys(tester, '<<<');
      expect(_shown(tester), r'$0');
      await pressKeys(tester, '<');
      expect(_shown(tester), r'$0', reason: 'del on empty does nothing');

      await disposeSteadyApp(tester, services);
    });

    testWidgets(
      'a point on an empty amount gives 0. and a second point is ignored',
      (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(tester, clock: now.clock);
        await _openAddScreen(tester);

        await pressKeys(tester, '.');
        expect(_shown(tester), r'$0.');
        await pressKeys(tester, '..');
        expect(_shown(tester), r'$0.');
        await pressKeys(tester, '5');
        expect(_shown(tester), r'$0.5');

        await disposeSteadyApp(tester, services);
      },
    );

    testWidgets('a leading zero is replaced, not stacked', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);

      await pressKeys(tester, '00');
      expect(_shown(tester), r'$0');
      await pressKeys(tester, '5');
      expect(_shown(tester), r'$5');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Save stays off for a zero amount, however it is written', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);
      await pickCategory(tester, 'Bills');
      expect(isButtonEnabled(tester, 'Save expense'), isFalse, reason: 'empty');

      for (final keys in ['0', '.', '0', '0']) {
        await pressKeys(tester, keys);
        expect(
          isButtonEnabled(tester, 'Save expense'),
          isFalse,
          reason: 'after "$keys": ${_shown(tester)}',
        );
      }
      expect(_shown(tester), r'$0.00');

      // "0.00" đã đầy phần thập phân nên phím 1 bị bỏ qua và Save vẫn tắt.
      await pressKeys(tester, '1');
      expect(_shown(tester), r'$0.00');
      expect(isButtonEnabled(tester, 'Save expense'), isFalse);

      // Xoá về "0" rồi gõ 1: có số tiền dương, Save bật.
      await pressKeys(tester, '<<<1');
      expect(_shown(tester), r'$1');
      expect(isButtonEnabled(tester, 'Save expense'), isTrue);
      await pressKeys(tester, '<');
      expect(isButtonEnabled(tester, 'Save expense'), isFalse);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('nine integer digits at most; decimals still fit after them', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);

      await pressKeys(tester, '1234567890');
      expect(_shown(tester), r'$123,456,789');
      await pressKeys(tester, '.99');
      expect(_shown(tester), r'$123,456,789.99');
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('choosing another category moves the selection', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);

      await pickCategory(tester, 'Groceries');
      await pickCategory(tester, 'Bills');

      expect(_selected(tester, 'Groceries'), isFalse);
      expect(_selected(tester, 'Bills'), isTrue);
      expect(
        find.text('Bills'),
        findsNWidgets(2),
        reason: 'tile + label under the amount',
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a category from More can be chosen and saved', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);

      await pressKeys(tester, '900');
      await tester.tap(find.text('More'));
      await tester.pump();
      await pickCategory(tester, 'Housing');
      await tapSave(tester);

      final rows = await storedExpenses(tester, services);
      expect(rows.single.category, MoneyCategory.housing);
      expect(rows.single.amountMinor, 90000);
      expect(find.text('BY CATEGORY'), findsOne);
      expect(find.text('Housing'), findsNWidgets(2), reason: 'bar + row');

      await disposeSteadyApp(tester, services);
    });
  });

  group('Saving an expense', () {
    testWidgets('Save goes back to the tab with the new total, row and bar', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);
      await pressKeys(tester, '12.4');
      await pickCategory(tester, 'Groceries');

      await tapSave(tester);

      expect(find.byType(SteadyTabBar), findsOne, reason: 'back on the tab');
      expect(find.text('Save expense'), findsNothing);
      expect(
        plain(tester.widget<Text>(_bigNumber()).data!),
        r'$12.40',
        reason: 'the total',
      );
      expect(
        find.descendant(
          of: find.byType(EntryRow),
          matching: find.text('Groceries'),
        ),
        findsOne,
      );
      expect(
        find.descendant(
          of: find.byType(EntryRow),
          matching: textPlain('9:00 PM'),
        ),
        findsOne,
      );
      expect(
        find.descendant(
          of: find.byType(EntryRow),
          matching: find.text('−\$12.40'),
        ),
        findsOne,
      );
      expect(find.text('BY CATEGORY'), findsOne);
      expect(
        find.descendant(
          of: find.byType(BarChartRow),
          matching: find.text('Groceries'),
        ),
        findsOne,
      );
      expect(
        find.descendant(
          of: find.byType(BarChartRow),
          matching: find.text(r'$12.40'),
        ),
        findsOne,
      );
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('what is stored: amount in cents, category, today, no note', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);
      await pressKeys(tester, '12.4');
      await pickCategory(tester, 'Groceries');
      await tapSave(tester);

      final row = (await storedExpenses(tester, services)).single;
      expect(row.amountMinor, 1240);
      expect(row.category, MoneyCategory.groceries);
      expect(row.date, today);
      expect(row.note, isNull);
      expect(row.createdAt, evening());

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a whole-dollar amount and a point with nothing after it', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);
      await pressKeys(tester, '7.');
      await pickCategory(tester, 'Gifts');
      await tapSave(tester);

      expect((await storedExpenses(tester, services)).single.amountMinor, 700);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('five cents is stored as 5', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);
      await pressKeys(tester, '0.05');
      await pickCategory(tester, 'Gifts');
      await tapSave(tester);

      expect((await storedExpenses(tester, services)).single.amountMinor, 5);
      expect(plain(tester.widget<Text>(_bigNumber()).data!), r'$0.05');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the biggest amount the keypad allows is saved exactly', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);
      await pressKeys(tester, '999999999.99');
      await pickCategory(tester, 'Bills');
      await tapSave(tester);

      expect(
        (await storedExpenses(tester, services)).single.amountMinor,
        99999999999,
      );
      expect(
        plain(tester.widget<Text>(_bigNumber()).data!),
        r'$999,999,999.99',
      );
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('two expenses in a row make two rows', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openMoney(tester);
      await addExpenseThroughUi(tester, keys: '48.2', category: 'Groceries');
      now.value = DateTime(2026, 10, 2, 21, 5);
      await addExpenseThroughUi(tester, keys: '4.5', category: 'Eating out');

      expect(find.byType(EntryRow), findsNWidgets(2));
      expect(plain(tester.widget<Text>(_bigNumber()).data!), r'$52.70');
      final rows = await storedExpenses(tester, services);
      expect(rows.map((r) => r.amountMinor), [
        450,
        4820,
      ], reason: 'newest first');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the form starts empty again the next time', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openMoney(tester);
      await addExpenseThroughUi(tester, keys: '9', category: 'Bills');

      await openEditor(tester);

      expect(_shown(tester), r'$0');
      expect(find.text('Choose a category'), findsOne);
      expect(isButtonEnabled(tester, 'Save expense'), isFalse);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Leaving without saving', () {
    testWidgets('X closes the screen and stores nothing', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);
      await pressKeys(tester, '12');
      await pickCategory(tester, 'Bills');

      await tester.tap(semLabel('Close'));
      await settle(tester);

      expect(find.byType(SteadyTabBar), findsOne);
      expect(await storedExpenses(tester, services), isEmpty);
      expect(find.byType(EntryRow), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Back closes the screen and stores nothing', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      final pops = captureSystemPop(tester);
      await _openAddScreen(tester);
      await pressKeys(tester, '12');
      await pickCategory(tester, 'Bills');

      await _back(tester);

      expect(find.byType(SteadyTabBar), findsOne);
      expect(currentTab(tester), 3, reason: 'still on Money');
      expect(pops, isEmpty);
      expect(await storedExpenses(tester, services), isEmpty);

      await disposeSteadyApp(tester, services);
    });
  });

  group('The note', () {
    testWidgets('a note becomes the title and the detail names the category', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);
      await pressKeys(tester, '12.4');
      await pickCategory(tester, 'Groceries');

      await tester.tap(find.text('Note'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'Weekly shop');
      await tester.tap(find.text('Done'));
      await settle(tester);
      expect(
        find.text('Weekly shop'),
        findsOne,
        reason: 'the Note button shows it',
      );
      expect(find.text('Note'), findsNothing);

      await tapSave(tester);

      expect(
        find.descendant(
          of: find.byType(EntryRow),
          matching: find.text('Weekly shop'),
        ),
        findsOne,
      );
      expect(
        find.descendant(
          of: find.byType(EntryRow),
          matching: textPlain('Groceries · 9:00 PM'),
        ),
        findsOne,
      );
      expect(
        (await storedExpenses(tester, services)).single.note,
        'Weekly shop',
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('closing the sheet without Done keeps the note as it was', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);

      await tester.tap(find.text('Note'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'First');
      await tester.tap(find.text('Done'));
      await settle(tester);
      expect(find.text('First'), findsOne);

      await tester.tap(find.text('First'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'Changed my mind');
      await _back(tester);

      expect(find.text('First'), findsOne, reason: 'unchanged');
      expect(find.text('Changed my mind'), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('closing a first sheet without Done leaves "Note"', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);

      await tester.tap(find.text('Note'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'Never confirmed');
      await _back(tester);

      expect(find.text('Note'), findsOne);
      expect(find.text('Never confirmed'), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Done with an empty field clears the note', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);
      await tester.tap(find.text('Note'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'Something');
      await tester.tap(find.text('Done'));
      await settle(tester);

      await tester.tap(find.text('Something'));
      await settle(tester);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Something',
        reason: 'the sheet starts with the current note',
      );
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Done'));
      await settle(tester);

      expect(find.text('Note'), findsOne);
      expect(find.text('Something'), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the sheet stops typing at 60 characters', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);
      await tester.tap(find.text('Note'));
      await settle(tester);

      await tester.enterText(find.byType(TextField), 'x' * 80);
      await tester.pump();

      expect(
        tester
            .widget<TextField>(find.byType(TextField))
            .controller!
            .text
            .length,
        lessThanOrEqualTo(60),
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('spaces around a note are not stored', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);
      await pressKeys(tester, '3');
      await pickCategory(tester, 'Bills');
      await tester.tap(find.text('Note'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), '  Power bill  ');
      await tester.tap(find.text('Done'));
      await settle(tester);

      await tapSave(tester);

      expect(
        (await storedExpenses(tester, services)).single.note,
        'Power bill',
      );

      await disposeSteadyApp(tester, services);
    });
  });

  group('The date', () {
    testWidgets('the calendar ends today and starts a century back', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);

      await tester.tap(find.text('Today'));
      await settle(tester);

      final calendar = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      expect(calendar.lastDate, DateTime(2026, 10, 2));
      expect(calendar.firstDate, DateTime(1926));
      expect(calendar.initialDate, DateTime(2026, 10, 2));

      // Ngày mai (3/10) bị tắt: chạm vào không chọn được gì.
      await tester.tap(_calendarDay(3), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('OK'));
      await settle(tester);
      expect(find.text('Today'), findsOne, reason: 'tomorrow cannot be picked');
      expect(find.text('Oct 3'), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('yesterday sits under YESTERDAY in the list, with no time', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);
      await pressKeys(tester, '12.4');
      await pickCategory(tester, 'Groceries');

      await _pickDay(tester, 'Today', 1);
      expect(find.text('Yesterday'), findsOne);
      await tapSave(tester);

      expect(
        (await storedExpenses(tester, services)).single.date,
        LocalDate(2026, 10, 1),
      );
      expect(
        find.descendant(
          of: find.byType(EntryRow),
          matching: find.textContaining('PM'),
        ),
        findsNothing,
      );

      await tester.tap(find.text('See all'));
      await settle(tester);
      expect(find.text('YESTERDAY'), findsOne);
      expect(find.text('TODAY'), findsNothing);
      expect(find.textContaining('PM'), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('an older date shows as "Sep 15" and counts as last month', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);
      await pressKeys(tester, '50');
      await pickCategory(tester, 'Bills');

      // Hộp chọn ngày mở ở tháng 10; lùi một tháng bằng nút mũi tên.
      await tester.tap(find.text('Today'));
      await settle(tester);
      await tester.tap(find.byTooltip('Previous month'));
      await settle(tester);
      await tester.tap(_calendarDay(15));
      await tester.pump();
      await tester.tap(find.text('OK'));
      await settle(tester);
      expect(find.text('Sep 15'), findsOne);

      await tapSave(tester);

      expect(
        plain(tester.widget<Text>(_bigNumber()).data!),
        r'$0.00',
        reason: 'not this month',
      );
      expect(find.text(r'Last month: $50.00'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('cancelling the calendar keeps the date', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);

      await tester.tap(find.text('Today'));
      await settle(tester);
      await tester.tap(_calendarDay(1));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await settle(tester);

      expect(find.text('Today'), findsOne);
      expect(find.text('Yesterday'), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the label turns into Yesterday when midnight passes', (
      tester,
    ) async {
      final now = FakeNow(DateTime(2026, 10, 2, 23, 59, 30));
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);
      expect(find.text('Today'), findsOne);

      now.value = DateTime(2026, 10, 3, 0, 0, 20);
      await tester.pump(const Duration(seconds: 40));

      expect(find.text('Yesterday'), findsOne);
      expect(find.text('Today'), findsNothing);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Currencies', () {
    testWidgets('JPY: the point key is off and amounts are whole yen', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedCurrency(tester, services, 'JPY');
      await _openAddScreen(tester);
      expect(_shown(tester), '¥0');

      await pressKeys(tester, '1');
      await tester.tap(keypadKey('.'), warnIfMissed: false);
      await tester.pump();
      await pressKeys(tester, '235');
      expect(_shown(tester), '¥1,235', reason: 'the point did nothing');

      await pickCategory(tester, 'Transport');
      await tapSave(tester);

      expect((await storedExpenses(tester, services)).single.amountMinor, 1235);
      expect(plain(tester.widget<Text>(_bigNumber()).data!), '¥1,235');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('EUR: two decimals, stored in cents', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedCurrency(tester, services, 'EUR');
      await _openAddScreen(tester);

      await pressKeys(tester, '12.4');
      expect(_shown(tester), '€12.4');
      await pickCategory(tester, 'Health');
      await tapSave(tester);

      expect((await storedExpenses(tester, services)).single.amountMinor, 1240);
      expect(plain(tester.widget<Text>(_bigNumber()).data!), '€12.40');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('KWD: three decimals, stored in fils', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedCurrency(tester, services, 'KWD');
      await _openAddScreen(tester);

      await pressKeys(tester, '1.2345');
      await pickCategory(tester, 'Health');
      await tapSave(tester);

      expect((await storedExpenses(tester, services)).single.amountMinor, 1234);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the point key is enabled for dollars', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);
      expect(tester.widget<Keypad>(find.byType(Keypad)).decimalEnabled, isTrue);
      await disposeSteadyApp(tester, services);
    });

    testWidgets('the point key is disabled for yen', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedCurrency(tester, services, 'JPY');
      await _openAddScreen(tester);
      expect(
        tester.widget<Keypad>(find.byType(Keypad)).decimalEnabled,
        isFalse,
      );
      await disposeSteadyApp(tester, services);
    });
  });

  group('Editing an expense', () {
    Future<MoneyEntry> seedGroceries(
      WidgetTester t,
      AppServices s, {
      String? note,
      MoneyCategory category = MoneyCategory.groceries,
      LocalDate? date,
    }) => seedExpense(
      t,
      s,
      amountMinor: 1240,
      category: category,
      date: date ?? today,
      note: note,
      createdAt: evening(),
    );

    Future<void> openEdit(WidgetTester t) async {
      await t.tap(find.byType(EntryRow).first);
      await settle(t);
      await t.tap(find.text('Edit expense'));
      await settle(t);
    }

    testWidgets('the form opens filled with the saved values', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedGroceries(tester, services, note: 'Weekly shop');
      await openMoney(tester);

      await openEdit(tester);

      expect(find.text('Edit expense'), findsOne, reason: 'screen title');
      expect(find.byType(SteadyTabBar), findsNothing);
      expect(_shown(tester), r'$12.40');
      expect(_selected(tester, 'Groceries'), isTrue);
      expect(find.text('Weekly shop'), findsOne, reason: 'on the Note button');
      expect(find.text('Today'), findsOne);
      expect(isButtonEnabled(tester, 'Save expense'), isTrue);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a category from More opens with More already open', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedGroceries(tester, services, category: MoneyCategory.education);
      await openMoney(tester);

      await openEdit(tester);

      expect(_tileCount(tester), 12);
      expect(_tile('More'), findsNothing);
      expect(_selected(tester, 'Education'), isTrue);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a category from the first seven opens with More closed', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedGroceries(tester, services, category: MoneyCategory.gifts);
      await openMoney(tester);

      await openEdit(tester);

      expect(_tileCount(tester), 8);
      expect(_selected(tester, 'Gifts'), isTrue);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('changing the amount keeps the row, its id and its createdAt', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      final original = await seedGroceries(tester, services);
      await openMoney(tester);
      await openEdit(tester);

      now.value = DateTime(2026, 10, 2, 22, 30);
      await pressKeys(tester, '<<<<<');
      await pressKeys(tester, '15');
      expect(_shown(tester), r'$15');
      await tapSave(tester);

      final rows = await storedExpenses(tester, services);
      expect(rows, hasLength(1), reason: 'edited, not added');
      expect(rows.single.id, original.id);
      expect(rows.single.amountMinor, 1500);
      expect(rows.single.createdAt, evening(), reason: 'createdAt is kept');
      expect(plain(tester.widget<Text>(_bigNumber()).data!), r'$15.00');
      expect(
        find.descendant(
          of: find.byType(EntryRow),
          matching: textPlain('9:00 PM'),
        ),
        findsOne,
        reason: 'the time of the first save is still the time shown',
      );
      expect(find.byType(EntryRow), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('changing category, date and note together', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedGroceries(tester, services, note: 'Old note');
      await openMoney(tester);
      await openEdit(tester);

      await pickCategory(tester, 'Transport');
      await _pickDay(tester, 'Today', 1);
      await tester.tap(find.text('Old note'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'Taxi home');
      await tester.tap(find.text('Done'));
      await settle(tester);
      await tapSave(tester);

      final row = (await storedExpenses(tester, services)).single;
      expect(row.category, MoneyCategory.transport);
      expect(row.date, LocalDate(2026, 10, 1));
      expect(row.note, 'Taxi home');
      expect(row.amountMinor, 1240);
      expect(row.createdAt, evening());
      // Đã sửa sang ngày khác ngày tạo: không còn giờ, ghi chú còn nên chi tiết là danh mục.
      expect(
        find.descendant(
          of: find.byType(EntryRow),
          matching: find.text('Taxi home'),
        ),
        findsOne,
      );
      expect(
        find.descendant(
          of: find.byType(EntryRow),
          matching: find.text('Transport'),
        ),
        findsOne,
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('clearing the note stores no note', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedGroceries(tester, services, note: 'Old note');
      await openMoney(tester);
      await openEdit(tester);

      await tester.tap(find.text('Old note'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('Done'));
      await settle(tester);
      await tapSave(tester);

      expect((await storedExpenses(tester, services)).single.note, isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets(
      'an expense dated after today opens the calendar without a crash',
      (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(tester, clock: now.clock);
        await seedGroceries(tester, services, date: LocalDate(2026, 10, 9));
        await openMoney(tester);
        await openEdit(tester);

        await tester.tap(find.text('Oct 9'));
        await settle(tester);

        expect(find.text('OK'), findsOne, reason: 'the calendar is open');
        expect(tester.takeException(), isNull);
        final calendar = tester.widget<CalendarDatePicker>(
          find.byType(CalendarDatePicker),
        );
        expect(
          calendar.lastDate,
          DateTime(2026, 10, 9),
          reason: 'the later of the two',
        );
        await tester.tap(find.text('OK'));
        await settle(tester);
        expect(find.text('Oct 9'), findsOne);

        await disposeSteadyApp(tester, services);
      },
    );

    // Case phải thất bại: khoản đã bị xoá ở nơi khác trong lúc đang sửa.
    testWidgets(
      'a row deleted while it is open: Save shows the error, stays open',
      (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(tester, clock: now.clock);
        final entry = await seedGroceries(tester, services);
        await openMoney(tester);
        await openEdit(tester);
        await dbAction(tester, () => services.money.delete(entry.id));

        await tapSave(tester);

        expect(find.text(saveErrorText), findsOne);
        expect(
          find.text('Edit expense'),
          findsOne,
          reason: 'still on the editor',
        );
        expect(
          await storedExpenses(tester, services),
          isEmpty,
          reason: 'nothing resurrected',
        );
        expect(_shown(tester), r'$12.40', reason: 'the values are kept');

        await disposeSteadyApp(tester, services);
      },
    );

    testWidgets('a failed update shows the error and keeps the old row', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      final entry = await seedGroceries(tester, services);
      await openMoney(tester);
      await openEdit(tester);
      await breakMoneyWrites(tester, services, insert: false, delete: false);

      await pressKeys(tester, '<<<<<');
      await pressKeys(tester, '9');
      await tester.tap(find.text('Save expense'));
      await afterTapDb(tester);

      expect(find.text(saveErrorText), findsOne);
      expect(find.text('Edit expense'), findsOne);
      expect(_shown(tester), r'$9');
      expect(await storedExpenses(tester, services), [entry]);
      expect(isButtonEnabled(tester, 'Save expense'), isTrue);

      await disposeSteadyApp(tester, services);
    });
  });

  group('When the database fails on Save', () {
    testWidgets('an error line shows, the input is kept, nothing is stored', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);
      await breakMoneyWrites(tester, services);
      await pressKeys(tester, '12.4');
      await pickCategory(tester, 'Groceries');

      await tester.tap(find.text('Save expense'));
      await afterTapDb(tester);

      expect(find.text(saveErrorText), findsOne);
      expect(find.text('Save expense'), findsOne, reason: 'screen not closed');
      expect(find.byType(SteadyTabBar), findsNothing);
      expect(_shown(tester), r'$12.4', reason: 'the amount is kept');
      expect(
        _selected(tester, 'Groceries'),
        isTrue,
        reason: 'the category is kept',
      );
      expect(
        isButtonEnabled(tester, 'Save expense'),
        isTrue,
        reason: 'can retry',
      );
      expect(await storedExpenses(tester, services), isEmpty);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('after the database recovers, Save works again', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);
      await breakMoneyWrites(tester, services);
      await pressKeys(tester, '12.4');
      await pickCategory(tester, 'Groceries');
      await tester.tap(find.text('Save expense'));
      await afterTapDb(tester);
      expect(find.text(saveErrorText), findsOne);

      await repairWrites(tester, services, 'money_entries');
      await tapSave(tester);

      expect(find.text(saveErrorText), findsNothing);
      expect(find.byType(SteadyTabBar), findsOne);
      expect(await storedExpenses(tester, services), hasLength(1));

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a second failure still shows one error line, not two', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);
      await breakMoneyWrites(tester, services);
      await pressKeys(tester, '5');
      await pickCategory(tester, 'Gifts');

      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Save expense'));
        await afterTapDb(tester);
      }

      expect(find.text(saveErrorText), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('typing a key or choosing a category clears the error', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);
      await breakMoneyWrites(tester, services);
      await pressKeys(tester, '5');
      await pickCategory(tester, 'Gifts');

      await tester.tap(find.text('Save expense'));
      await afterTapDb(tester);
      expect(find.text(saveErrorText), findsOne);
      await pressKeys(tester, '1');
      expect(find.text(saveErrorText), findsNothing);

      await tester.tap(find.text('Save expense'));
      await afterTapDb(tester);
      expect(find.text(saveErrorText), findsOne);
      await pickCategory(tester, 'Bills');
      expect(find.text(saveErrorText), findsNothing);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Two taps on Save', () {
    testWidgets('before any frame: one expense and no error line', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);
      await pressKeys(tester, '12.4');
      await pickCategory(tester, 'Groceries');

      final save = buttonLabeled(tester, 'Save expense');
      save.onPressed!();
      save.onPressed!();
      await afterTapDb(tester);
      await settle(tester);

      final rows = await storedExpenses(tester, services);
      expect(rows, hasLength(1));
      expect(find.text(saveErrorText), findsNothing);
      expect(find.byType(SteadyTabBar), findsOne);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('three taps in a row still make one expense', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);
      await pressKeys(tester, '3');
      await pickCategory(tester, 'Bills');

      final save = buttonLabeled(tester, 'Save expense');
      save.onPressed!();
      save.onPressed!();
      save.onPressed!();
      await afterTapDb(tester);
      await settle(tester);

      expect(await storedExpenses(tester, services), hasLength(1));

      await disposeSteadyApp(tester, services);
    });

    testWidgets('two quick taps on Date open one calendar', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);

      final date = buttonLabeled(tester, 'Today');
      date.onPressed!();
      date.onPressed!();
      await settle(tester);

      expect(find.byType(CalendarDatePicker), findsOne);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(
        find.byType(CalendarDatePicker),
        findsNothing,
        reason: 'one Cancel closes it',
      );
      expect(
        find.text('Save expense'),
        findsOne,
        reason: 'the editor is still there',
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('two quick taps on Note open one sheet', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);

      final note = buttonLabeled(tester, 'Note');
      note.onPressed!();
      note.onPressed!();
      await settle(tester);

      expect(find.byType(TextField), findsOne);
      await _back(tester);
      expect(
        find.byType(TextField),
        findsNothing,
        reason: 'one Back closes it',
      );
      expect(
        find.text('Save expense'),
        findsOne,
        reason: 'the editor is still there',
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets(
      'when editing, two taps change the row once and show no error',
      (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(tester, clock: now.clock);
        await seedExpense(
          tester,
          services,
          amountMinor: 1240,
          date: today,
          createdAt: evening(),
        );
        await openMoney(tester);
        await tester.tap(find.byType(EntryRow).first);
        await settle(tester);
        await tester.tap(find.text('Edit expense'));
        await settle(tester);
        await pressKeys(tester, '<<<<<');
        await pressKeys(tester, '8');

        final save = buttonLabeled(tester, 'Save expense');
        save.onPressed!();
        save.onPressed!();
        await afterTapDb(tester);
        await settle(tester);

        final rows = await storedExpenses(tester, services);
        expect(rows, hasLength(1));
        expect(rows.single.amountMinor, 800);
        expect(find.text(saveErrorText), findsNothing);
        expect(find.byType(SteadyTabBar), findsOne);

        await disposeSteadyApp(tester, services);
      },
    );

    testWidgets('after a failed save, the next tap is not swallowed', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _openAddScreen(tester);
      await breakMoneyWrites(tester, services);
      await pressKeys(tester, '3');
      await pickCategory(tester, 'Bills');

      buttonLabeled(tester, 'Save expense').onPressed!();
      await afterTapDb(tester);
      expect(find.text(saveErrorText), findsOne);
      expect(await storedExpenses(tester, services), isEmpty);

      await repairWrites(tester, services, 'money_entries');
      buttonLabeled(tester, 'Save expense').onPressed!();
      buttonLabeled(tester, 'Save expense').onPressed!();
      await afterTapDb(tester);
      await settle(tester);

      expect(await storedExpenses(tester, services), hasLength(1));
      expect(find.text(saveErrorText), findsNothing);

      await disposeSteadyApp(tester, services);
    });
  });
}
