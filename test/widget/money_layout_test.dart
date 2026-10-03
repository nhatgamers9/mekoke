import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/services.dart';
import 'package:steady/core/time/local_date.dart';
import 'package:steady/data/money_types.dart';
import 'package:steady/features/money/entry_row.dart';
import 'package:steady/ui/components/bar_chart_row.dart';
import 'package:steady/ui/components/icon_tile.dart';
import 'package:steady/ui/components/keypad.dart';

import '../helpers/money_helpers.dart';
import '../helpers/test_app.dart';
import '../helpers/timer_helpers.dart';
import '../helpers/widget_helpers.dart';

/// Mọi vùng chạm kiểu nút nhìn thấy được phải rộng và cao ít nhất 48.
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

/// Mỗi hàng khoản chi (chạm được) cao ít nhất 48.
void _expectRowTargets(WidgetTester t, String where) {
  final rows = find.byType(EntryRow, skipOffstage: false);
  for (var i = 0; i < rows.evaluate().length; i++) {
    final size = t.getSize(rows.at(i));
    expect(size.height, greaterThanOrEqualTo(48), reason: '$where: row #$i');
    expect(size.width, greaterThanOrEqualTo(48), reason: '$where: row #$i');
  }
}

/// 12 khoản, mỗi danh mục một khoản, số tiền lớn nhất mà repository cho phép.
Future<void> _seedTwelveHuge(WidgetTester t, AppServices s) async {
  for (final c in MoneyCategory.values) {
    await seedExpense(
      t,
      s,
      amountMinor: kMaxAmountMinor,
      category: c,
      date: today,
      note: 'N' * 60,
      createdAt: evening(),
    );
  }
}

Future<void> _openEditorFor(WidgetTester t, {int row = 0}) async {
  await tapScrolled(t, find.byType(EntryRow).at(row));
  await settle(t);
  await t.tap(find.text('Edit expense'));
  await settle(t);
}

void main() {
  for (final scale in [1.0, 2.0]) {
    group('Money: no overflow at 360x800, text scale $scale', () {
      Future<AppServices> pump(WidgetTester t, FakeNow now) =>
          pumpSteadyApp(t, clock: now.clock, textScale: scale);

      testWidgets('the tab: empty', (tester) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        await openMoney(tester);

        expect(find.text('Your expenses will show up here.'), findsOne);
        expect(tester.takeException(), isNull);
        if (scale == 1.0) _expectTapTargets(tester, 'Money empty');

        await disposeSteadyApp(tester, services);
      });

      testWidgets('the tab: some rows, bars and the Last month line', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        await seedExpense(
          tester,
          services,
          amountMinor: 4820,
          date: today,
          note: 'Weekly shop',
        );
        await seedExpense(
          tester,
          services,
          amountMinor: 450,
          category: MoneyCategory.eatingOut,
          date: today,
        );
        await seedExpense(
          tester,
          services,
          amountMinor: 12000,
          category: MoneyCategory.bills,
          date: LocalDate(2026, 10, 1),
        );
        await seedExpense(
          tester,
          services,
          amountMinor: 9900,
          date: LocalDate(2026, 9, 10),
        );
        await openMoney(tester);

        expect(find.byType(EntryRow), findsNWidgets(4));
        expect(find.byType(BarChartRow), findsNWidgets(3));
        expect(tester.takeException(), isNull);
        if (scale == 1.0) {
          _expectTapTargets(tester, 'Money with rows');
          _expectRowTargets(tester, 'Money with rows');
        }

        await disposeSteadyApp(tester, services);
      });

      testWidgets('the tab: the biggest amounts and 60-character notes', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        for (var i = 0; i < 5; i++) {
          await seedExpense(
            tester,
            services,
            amountMinor: kMaxAmountMinor,
            category: MoneyCategory.values[i],
            date: today,
            note: 'W' * 60,
            createdAt: evening(),
          );
        }
        await openMoney(tester);

        expect(find.byType(EntryRow), findsNWidgets(5));
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      });

      testWidgets('the tab: all 12 bars with the biggest amounts', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        await _seedTwelveHuge(tester, services);
        await openMoney(tester);

        expect(
          find.byType(BarChartRow, skipOffstage: false),
          findsNWidgets(12),
        );
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      });

      testWidgets('the tab: the last month line with a huge total', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        for (var i = 0; i < 3; i++) {
          await seedExpense(
            tester,
            services,
            amountMinor: kMaxAmountMinor,
            date: LocalDate(2026, 9, 3),
          );
        }
        await openMoney(tester);

        expect(find.textContaining('Last month'), findsOne);
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      });

      testWidgets('the Add expense screen: as first opened', (tester) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        await openMoney(tester);
        await openEditor(tester);

        expect(tester.takeException(), isNull);
        if (scale == 1.0) {
          _expectTapTargets(tester, 'Add expense');
          for (final tile in find.byType(IconTile).evaluate()) {
            final size = tester.getSize(find.byWidget(tile.widget));
            expect(size.width, greaterThanOrEqualTo(48));
            expect(size.height, greaterThanOrEqualTo(48));
          }
        }

        await disposeSteadyApp(tester, services);
      });

      testWidgets('the Add expense screen: with More open (12 tiles)', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        await openMoney(tester);
        await openEditor(tester);
        await tapScrolled(tester, find.text('More'));

        expect(find.byType(IconTile, skipOffstage: false), findsNWidgets(12));
        expect(tester.takeException(), isNull);
        if (scale == 1.0) _expectTapTargets(tester, 'Add expense + More');

        await disposeSteadyApp(tester, services);
      });

      testWidgets(
        'the Add expense screen: the biggest typed amount, a long note, a date',
        (tester) async {
          final now = FakeNow(evening());
          final services = await pump(tester, now);
          await openMoney(tester);
          await openEditor(tester);
          await pressKeys(tester, '999999999.99');
          await pickCategory(tester, 'Eating out');
          await tester.tap(find.text('Note'));
          await settle(tester);
          await tester.enterText(find.byType(TextField), 'N' * 60);
          await tester.tap(find.text('Done'));
          await settle(tester);

          expect(find.text('N' * 60), findsOne);
          expect(tester.takeException(), isNull);

          await disposeSteadyApp(tester, services);
        },
      );

      testWidgets('the Add expense screen: with the error line', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        await openMoney(tester);
        await openEditor(tester);
        await breakMoneyWrites(tester, services);
        await pressKeys(tester, '5');
        await pickCategory(tester, 'Bills');
        await tester.tap(find.text('Save expense'));
        await afterTapDb(tester);

        expect(find.text(saveErrorText), findsOne);
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      });

      testWidgets(
        'the Edit screen: a row at the repository limit, More opened',
        (tester) async {
          final now = FakeNow(evening());
          final services = await pump(tester, now);
          await seedExpense(
            tester,
            services,
            amountMinor: kMaxAmountMinor,
            category: MoneyCategory.education,
            date: today,
            note: 'N' * 60,
          );
          await openMoney(tester);
          await _openEditorFor(tester);

          expect(find.byType(IconTile, skipOffstage: false), findsNWidgets(12));
          expect(tester.takeException(), isNull);

          await disposeSteadyApp(tester, services);
        },
      );

      testWidgets('Expenses: many days, big totals, long notes', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        for (var d = 0; d < 6; d++) {
          await seedExpense(
            tester,
            services,
            amountMinor: kMaxAmountMinor,
            category: MoneyCategory.values[d],
            date: LocalDate(2026, 10, 2).addDays(-d),
            note: 'N' * 60,
            createdAt: evening(),
          );
        }
        await seedExpense(
          tester,
          services,
          amountMinor: kMaxAmountMinor,
          date: LocalDate(2025, 12, 31),
        );
        await openMoney(tester);
        await tapScrolled(tester, find.text('See all'));
        await settle(tester);

        // Danh sách lười: cuộn tới ngày cuối để dựng cả những hàng ở xa.
        await tester.dragUntilVisible(
          find.text('DEC 31, 2025'),
          find.byType(ListView),
          const Offset(0, -200),
        );
        expect(find.text('DEC 31, 2025'), findsOne);
        expect(tester.takeException(), isNull);
        if (scale == 1.0) {
          _expectTapTargets(tester, 'Expenses');
          _expectRowTargets(tester, 'Expenses');
        }

        await disposeSteadyApp(tester, services);
      });

      testWidgets('Expenses: empty after the last delete', (tester) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        final entry = await seedExpense(
          tester,
          services,
          amountMinor: 100,
          date: today,
        );
        await openMoney(tester);
        await tapScrolled(tester, find.text('See all'));
        await settle(tester);
        await dbAction(tester, () => services.money.delete(entry.id));
        await letDbFinish(tester);

        expect(find.text('Your expenses will show up here.'), findsOne);
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      });

      testWidgets(
        'the sheet of one expense: a 60-character note, a huge amount',
        (tester) async {
          final now = FakeNow(evening());
          final services = await pump(tester, now);
          await seedExpense(
            tester,
            services,
            amountMinor: kMaxAmountMinor,
            date: today,
            note: 'W' * 60,
          );
          await openMoney(tester);
          await tapScrolled(tester, find.byType(EntryRow).first);
          await settle(tester);

          expect(find.text('Delete expense'), findsOne);
          expect(tester.takeException(), isNull);
          if (scale == 1.0) _expectTapTargets(tester, 'Expense sheet');

          await disposeSteadyApp(tester, services);
        },
      );

      testWidgets('the sheet of one expense: with the error line', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        await seedExpense(tester, services, amountMinor: 100, date: today);
        await openMoney(tester);
        await tapScrolled(tester, find.byType(EntryRow).first);
        await settle(tester);
        await breakMoneyWrites(tester, services);
        await tester.tap(find.text('Delete expense'));
        await settle(tester);
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Delete'),
          ),
        );
        await afterTapDb(tester);
        await settle(tester);

        expect(find.text(saveErrorText), findsOne);
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      });

      testWidgets('the confirm question does not overflow', (tester) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        await seedExpense(tester, services, amountMinor: 100, date: today);
        await openMoney(tester);
        await tapScrolled(tester, find.byType(EntryRow).first);
        await settle(tester);
        await tester.tap(find.text('Delete expense'));
        await settle(tester);

        expect(find.text('Delete this expense?'), findsOne);
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      });

      testWidgets('the note sheet with a 300px keyboard keeps Done in reach', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pump(tester, now);
        await openMoney(tester);
        await openEditor(tester);
        await tapScrolled(tester, find.text('Note'));
        await settle(tester);
        expect(
          find.byType(TextField),
          findsOne,
          reason: 'the note sheet is open',
        );

        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();

        final done = tester.getRect(find.widgetWithText(FilledButton, 'Done'));
        expect(
          done.bottom,
          lessThanOrEqualTo(800 - 300),
          reason: 'Done is above the keyboard',
        );
        expect(done.top, greaterThanOrEqualTo(0));
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        expect(
          find.byType(TextField),
          findsNothing,
          reason: 'Done closes the sheet',
        );

        await disposeSteadyApp(tester, services);
      });
    });
  }

  group('the Keypad in the editor', () {
    testWidgets('every key is at least 48 x 48 on the real screen', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openMoney(tester);
      await openEditor(tester);

      for (final key in [
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        '.',
        '0',
      ]) {
        final inkWell = find
            .ancestor(of: keypadKey(key), matching: find.byType(InkWell))
            .first;
        final size = tester.getSize(inkWell);
        expect(size.width, greaterThanOrEqualTo(48), reason: key);
        expect(size.height, greaterThanOrEqualTo(48), reason: key);
      }
      expect(tester.getSize(find.byType(Keypad)).width, 320);

      await disposeSteadyApp(tester, services);
    });
  });
}
