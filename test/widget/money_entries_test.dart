import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/services.dart';
import 'package:steady/core/theme/tokens.dart';
import 'package:steady/core/theme/typography.dart';
import 'package:steady/core/time/local_date.dart';
import 'package:steady/data/database.dart';
import 'package:steady/data/money_types.dart';
import 'package:steady/features/money/entries_screen.dart';
import 'package:steady/features/money/entry_editor_screen.dart';
import 'package:steady/features/money/entry_row.dart';
import 'package:steady/features/money/money_screen.dart';
import 'package:steady/ui/components/bar_chart_row.dart';
import 'package:steady/ui/components/steady_button.dart';
import 'package:steady/ui/components/steady_icon.dart';
import 'package:steady/ui/components/steady_tab_bar.dart';

import '../helpers/money_helpers.dart';
import '../helpers/test_app.dart';
import '../helpers/timer_helpers.dart';
import '../helpers/widget_helpers.dart';

const _c = SteadyColors.dark;

Future<void> _back(WidgetTester t) async {
  await t.binding.handlePopRoute();
  await t.pumpAndSettle();
}

Finder _bigNumber() => find.byWidgetPredicate(
  (w) => w is Text && w.style?.fontSize == SteadyText.moneyXl.fontSize,
);

Future<MoneyEntry> _seed(
  WidgetTester t,
  AppServices s, {
  int amount = 1240,
  LocalDate? date,
  String? note,
  MoneyCategory category = MoneyCategory.groceries,
  DateTime? createdAt,
}) => seedExpense(
  t,
  s,
  amountMinor: amount,
  category: category,
  date: date ?? today,
  note: note,
  createdAt: createdAt ?? evening(),
);

Future<void> _openAll(WidgetTester t) async {
  await openMoney(t);
  await t.tap(find.text('See all'));
  await settle(t);
}

Future<void> _openSheet(WidgetTester t, {int row = 0}) async {
  await t.tap(find.byType(EntryRow).at(row));
  await settle(t);
}

/// Mọi widget trong cây con của [within] dùng một trong các màu [colors]
/// (chữ, icon, nền, viền, nút). Duyệt cả cây, không chỉ một kiểu widget.
List<Widget> _widgetsUsing(
  WidgetTester t,
  Set<Color> colors, {
  required Finder within,
}) {
  bool hit(Color? c) => c != null && colors.contains(c);
  final root = within.evaluate().single.widget;
  final all = [
    root,
    ...find
        .descendant(
          of: within,
          matching: find.byWidgetPredicate((_) => true),
          skipOffstage: false,
        )
        .evaluate()
        .map((e) => e.widget),
  ];
  return [
    for (final w in all)
      if (switch (w) {
        Text(:final style) => hit(style?.color),
        SteadyIcon(:final color) => hit(color),
        DecoratedBox(:final decoration) =>
          decoration is BoxDecoration &&
              (hit(decoration.color) ||
                  (decoration.border is Border &&
                      hit((decoration.border! as Border).top.color))),
        Material(:final color) => hit(color),
        FilledButton(:final style) =>
          hit(style?.backgroundColor?.resolve({})) ||
              hit(style?.foregroundColor?.resolve({})),
        _ => false,
      })
        w,
  ];
}

final _redAndBlue = {_c.rose, _c.roseSoft, _c.tide, _c.tideSoft};

void main() {
  group('Expenses screen', () {
    testWidgets('See all opens every expense on a full screen', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      // Hai ngày, mỗi ngày bốn khoản: danh sách lười vẫn dựng đủ cả tám hàng.
      for (var i = 1; i <= 8; i++) {
        await _seed(
          tester,
          services,
          amount: i * 100,
          date: LocalDate(2026, 9, i <= 4 ? 1 : 2),
        );
      }
      await openMoney(tester);
      expect(
        find.byType(EntryRow),
        findsNWidgets(5),
        reason: 'the tab shows five',
      );

      await tester.tap(find.text('See all'));
      await settle(tester);

      expect(find.byType(SteadyTabBar), findsNothing);
      expect(find.text('Expenses'), findsOne);
      expect(find.byType(EntryRow), findsNWidgets(8));
      expect(find.text('SEP 1'), findsOne);
      expect(find.text('SEP 2'), findsOne);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('groups by day with a header and a minus total for each', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services, amount: 4820, date: today);
      await _seed(
        tester,
        services,
        amount: 450,
        date: today,
        category: MoneyCategory.eatingOut,
      );
      await _seed(tester, services, amount: 1200, date: LocalDate(2026, 10, 1));
      await _seed(tester, services, amount: 300, date: LocalDate(2026, 9, 30));
      await _seed(tester, services, amount: 700, date: LocalDate(2026, 9, 30));
      await _seed(
        tester,
        services,
        amount: 9900,
        date: LocalDate(2025, 12, 31),
      );
      await _openAll(tester);

      for (final header in ['TODAY', 'YESTERDAY', 'SEP 30', 'DEC 31, 2025']) {
        expect(find.text(header), findsOne, reason: header);
      }
      // Tổng ngày: hôm nay 48.20 + 4.50; 30/9 là 3.00 + 7.00.
      expect(find.text('−\$52.70'), findsOne);
      expect(find.text('−\$10.00'), findsOne);
      // Ngày chỉ có một khoản: tổng bằng chính khoản đó (hàng + tổng ngày).
      expect(find.text('−\$12.00'), findsNWidgets(2));
      expect(find.text('−\$99.00'), findsNWidgets(2));
      expect(find.byType(EntryRow), findsNWidgets(6));

      final ys = [
        for (final h in ['TODAY', 'YESTERDAY', 'SEP 30', 'DEC 31, 2025'])
          tester.getTopLeft(find.text(h)).dy,
      ];
      expect(ys, orderedEquals([...ys]..sort()), reason: 'newest day first');
      expect(ys.toSet(), hasLength(4));

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the example of the plan: 48.20 and 4.50 total 52.70 dollars', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services, amount: 4820);
      await _seed(tester, services, amount: 450);
      await _openAll(tester);

      expect(find.text('TODAY'), findsOne);
      expect(find.text('−\$52.70'), findsOne);
      expect(find.text('−\$48.20'), findsOne);
      expect(find.text('−\$4.50'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('within a day, the newest saved comes first', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(
        tester,
        services,
        amount: 111,
        createdAt: DateTime(2026, 10, 2, 8),
      );
      await _seed(
        tester,
        services,
        amount: 222,
        createdAt: DateTime(2026, 10, 2, 20),
      );
      await _seed(
        tester,
        services,
        amount: 333,
        createdAt: DateTime(2026, 10, 2, 12),
      );
      await _openAll(tester);

      final ys = [
        for (final a in ['−\$2.22', '−\$3.33', '−\$1.11'])
          tester
              .getTopLeft(
                find.descendant(
                  of: find.byType(EntryRow),
                  matching: find.text(a),
                ),
              )
              .dy,
      ];
      expect(ys, orderedEquals([...ys]..sort()));
      expect(ys.toSet(), hasLength(3));

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the day totals use the same currency as the rows', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedCurrency(tester, services, 'JPY');
      await _seed(tester, services, amount: 1500);
      await _seed(tester, services, amount: 500);
      await _openAll(tester);

      expect(find.text('−¥2,000'), findsOne, reason: 'day total');
      expect(find.text('−¥1,500'), findsOne);
      expect(find.text('−¥500'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('X goes back to the tab', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services);
      await _openAll(tester);

      await tester.tap(semLabel('Close'));
      await settle(tester);

      expect(find.byType(SteadyTabBar), findsOne);
      expect(find.text('Expenses'), findsNothing);
      expect(currentTab(tester), 3);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Back goes back to the tab, not out of the app', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      final pops = captureSystemPop(tester);
      await _seed(tester, services);
      await _openAll(tester);

      await _back(tester);

      expect(find.byType(SteadyTabBar), findsOne);
      expect(currentTab(tester), 3);
      expect(pops, isEmpty);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a new expense shows up while the screen is open', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services, amount: 1000);
      await _openAll(tester);
      expect(find.byType(EntryRow), findsOne);

      await _seed(tester, services, amount: 250);
      await letDbFinish(tester);

      expect(find.byType(EntryRow), findsNWidgets(2));
      expect(find.text('−\$12.50'), findsOne, reason: 'new day total');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the headers follow the clock across midnight', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services, amount: 100, date: today);
      await _seed(tester, services, amount: 200, date: LocalDate(2026, 10, 1));
      await _openAll(tester);
      expect(find.text('TODAY'), findsOne);
      expect(find.text('YESTERDAY'), findsOne);

      now.value = DateTime(2026, 10, 3, 0, 0, 30);
      await tester.pump(const Duration(hours: 3, seconds: 5));

      expect(find.text('TODAY'), findsNothing);
      expect(
        find.text('YESTERDAY'),
        findsOne,
        reason: 'Oct 2 is now yesterday',
      );
      expect(find.text('OCT 1'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a huge day total does not overflow at text scale 2.0', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(
        tester,
        clock: now.clock,
        textScale: 2.0,
      );
      for (var i = 0; i < 3; i++) {
        await _seed(tester, services, amount: kMaxAmountMinor, note: 'N' * 60);
      }
      await _openAll(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(EntryRow), findsNWidgets(3));

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a database that cannot be read shows the load error', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services);
      await _openAll(tester);

      await tester.runAsync(() async {
        await services.db.customStatement('DROP TABLE money_entries');
        services.db.markTablesUpdated({services.db.moneyEntries});
      });
      await letDbFinish(tester);

      expect(find.text("Couldn't load your expenses."), findsOne);
      expect(find.byType(EntryRow), findsNothing);
      expect(find.text('Your expenses will show up here.'), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('shows the empty line after the last expense is deleted', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services);
      await _openAll(tester);

      await _openSheet(tester);
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

      expect(find.byType(EntryRow), findsNothing);
      expect(find.text('Your expenses will show up here.'), findsOne);
      expect(
        find.text('TODAY'),
        findsNothing,
        reason: 'the empty day header is gone',
      );

      await disposeSteadyApp(tester, services);
    });
  });

  group('The sheet of one expense', () {
    testWidgets('shows what it is and the two actions', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services, note: 'Weekly shop');
      await openMoney(tester);

      await _openSheet(tester);

      expect(
        find.text('Weekly shop'),
        findsNWidgets(2),
        reason: 'row + sheet title',
      );
      expect(find.text('−\$12.40'), findsNWidgets(2), reason: 'row + sheet');
      expect(find.text('Edit expense'), findsOne);
      expect(find.text('Delete expense'), findsOne);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the title is the category when there is no note', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services, category: MoneyCategory.bills);
      await openMoney(tester);

      await _openSheet(tester);

      expect(
        find.text('Bills'),
        findsNWidgets(3),
        reason: 'row + bar + sheet title',
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Delete expense is the danger button, Edit is not', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services);
      await openMoney(tester);
      await _openSheet(tester);

      expect(
        buttonLabeled(tester, 'Delete expense').variant,
        SteadyButtonVariant.danger,
      );
      expect(
        buttonLabeled(tester, 'Edit expense').variant,
        isNot(SteadyButtonVariant.danger),
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Edit closes the sheet and opens the editor on this row', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services, amount: 777);
      await openMoney(tester);
      await _openSheet(tester);

      await tester.tap(find.text('Edit expense'));
      await settle(tester);

      expect(find.text('Delete expense'), findsNothing, reason: 'sheet closed');
      expect(find.text('Save expense'), findsOne);
      expect(plain(tester.widget<Text>(_bigNumber().last).data!), r'$7.77');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('opens from the Expenses screen too', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services);
      await _openAll(tester);

      await _openSheet(tester);

      expect(find.text('Edit expense'), findsOne);
      expect(find.text('Delete expense'), findsOne);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Deleting an expense', () {
    Future<void> tapDelete(WidgetTester t) async {
      await t.tap(find.text('Delete expense'));
      await settle(t);
    }

    Future<void> confirmDelete(WidgetTester t) async {
      await t.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        ),
      );
      await afterTapDb(t);
      await settle(t);
    }

    testWidgets('asks first: the question, what it means, Cancel and Delete', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services);
      await openMoney(tester);
      await _openSheet(tester);

      await tapDelete(tester);

      expect(find.text('Delete this expense?'), findsOne);
      expect(
        find.text("This removes it from your history. It can't be undone."),
        findsOne,
      );
      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(of: dialog, matching: find.text('Cancel')),
        findsOne,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('Delete')),
        findsOne,
      );
      expect(
        (await storedExpenses(tester, services)),
        hasLength(1),
        reason: 'nothing is deleted before the answer',
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the Delete in the question is the danger button', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services);
      await openMoney(tester);
      await _openSheet(tester);
      await tapDelete(tester);

      final delete = tester.widget<SteadyButton>(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(SteadyButton, 'Delete'),
        ),
      );
      expect(delete.variant, SteadyButtonVariant.danger);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Cancel keeps the row and leaves the sheet open', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services);
      await openMoney(tester);
      await _openSheet(tester);
      await tapDelete(tester);

      await tester.tap(find.text('Cancel'));
      await settle(tester);

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Delete expense'), findsOne, reason: 'sheet still open');
      expect(await storedExpenses(tester, services), hasLength(1));
      expect(
        isButtonEnabled(tester, 'Delete expense'),
        isTrue,
        reason: 'can ask again',
      );
      expect(find.text(saveErrorText), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Delete removes the row, closes the sheet, updates the total', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services, amount: 1000);
      await _seed(tester, services, amount: 500, category: MoneyCategory.bills);
      await openMoney(tester);
      expect(plain(tester.widget<Text>(_bigNumber()).data!), r'$15.00');
      // Mở sheet của khoản Bills (5.00), không phải khoản Groceries.
      await tester.tap(
        find.descendant(
          of: find.byType(EntryRow),
          matching: find.text('Bills'),
        ),
      );
      await settle(tester);
      expect(find.text('Delete expense'), findsOne);

      await tapDelete(tester);
      await confirmDelete(tester);
      await letDbFinish(tester);

      expect(find.text('Delete expense'), findsNothing, reason: 'sheet closed');
      expect(find.byType(AlertDialog), findsNothing);
      final left = await storedExpenses(tester, services);
      expect(left.map((e) => e.category), [MoneyCategory.groceries]);
      expect(find.byType(EntryRow), findsOne);
      expect(plain(tester.widget<Text>(_bigNumber()).data!), r'$10.00');

      await disposeSteadyApp(tester, services);
    });

    testWidgets(
      'deleting the only expense returns the tab to its empty state',
      (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(tester, clock: now.clock);
        await _seed(tester, services);
        await openMoney(tester);
        await _openSheet(tester);
        await tapDelete(tester);
        await confirmDelete(tester);
        await letDbFinish(tester);

        expect(find.text('Your expenses will show up here.'), findsOne);
        expect(find.text('See all'), findsNothing);
        expect(find.text('BY CATEGORY'), findsNothing);
        expect(plain(tester.widget<Text>(_bigNumber()).data!), r'$0.00');

        await disposeSteadyApp(tester, services);
      },
    );

    testWidgets(
      'Back closes the question first, then the sheet, then nothing else',
      (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(tester, clock: now.clock);
        final pops = captureSystemPop(tester);
        await _seed(tester, services);
        await openMoney(tester);
        await _openSheet(tester);
        await tapDelete(tester);

        await _back(tester);
        expect(find.byType(AlertDialog), findsNothing);
        expect(
          find.text('Delete expense'),
          findsOne,
          reason: 'sheet still open',
        );
        expect(
          await storedExpenses(tester, services),
          hasLength(1),
          reason: 'Back is not a yes',
        );
        expect(isButtonEnabled(tester, 'Delete expense'), isTrue);

        await _back(tester);
        expect(find.text('Delete expense'), findsNothing);
        expect(currentTab(tester), 3, reason: 'still on Money');
        expect(pops, isEmpty);

        await disposeSteadyApp(tester, services);
      },
    );

    testWidgets('two quick taps on Delete open one question', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services);
      await openMoney(tester);
      await _openSheet(tester);

      final delete = buttonLabeled(tester, 'Delete expense');
      delete.onPressed!();
      delete.onPressed!();
      await settle(tester);

      expect(find.byType(AlertDialog), findsOne);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason: 'one Cancel closes it',
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('while the question is open, the two sheet buttons are off', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services);
      await openMoney(tester);
      await _openSheet(tester);

      buttonLabeled(tester, 'Delete expense').onPressed!();
      await tester.pump();

      expect(isButtonEnabled(tester, 'Delete expense'), isFalse);
      expect(isButtonEnabled(tester, 'Edit expense'), isFalse);

      await settle(tester);
      await disposeSteadyApp(tester, services);
    });

    testWidgets('a row that is already gone still closes the sheet quietly', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      final entry = await _seed(tester, services);
      await openMoney(tester);
      await _openSheet(tester);
      await tapDelete(tester);
      await dbAction(tester, () => services.money.delete(entry.id));

      await confirmDelete(tester);

      expect(find.text('Delete expense'), findsNothing, reason: 'sheet closed');
      expect(find.text(saveErrorText), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    // Case phải thất bại: ghi DB lỗi khi xoá.
    testWidgets(
      'a failed delete shows the error and keeps the row and the sheet',
      (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(tester, clock: now.clock);
        await _seed(tester, services);
        await openMoney(tester);
        await _openSheet(tester);
        await breakMoneyWrites(tester, services);
        await tapDelete(tester);

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Delete'),
          ),
        );
        await afterTapDb(tester);
        await settle(tester);

        expect(find.text(saveErrorText), findsOne);
        expect(
          find.text('Delete expense'),
          findsOne,
          reason: 'sheet stays open',
        );
        expect(find.byType(AlertDialog), findsNothing);
        expect(await storedExpenses(tester, services), hasLength(1));
        expect(
          isButtonEnabled(tester, 'Delete expense'),
          isTrue,
          reason: 'retry',
        );
        expect(isButtonEnabled(tester, 'Edit expense'), isTrue);
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      },
    );

    testWidgets('after the database recovers, Delete works', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services);
      await openMoney(tester);
      await _openSheet(tester);
      await breakMoneyWrites(tester, services);
      await tapDelete(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        ),
      );
      await afterTapDb(tester);
      await settle(tester);
      expect(find.text(saveErrorText), findsOne);

      await repairWrites(tester, services, 'money_entries');
      await tapDelete(tester);
      await confirmDelete(tester);

      expect(find.text('Delete expense'), findsNothing, reason: 'sheet closed');
      expect(await storedExpenses(tester, services), isEmpty);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Colours: tide never, rose only on the two Delete buttons', () {
    Future<void> openDialog(WidgetTester t) async {
      await t.tap(find.text('Delete expense'));
      await settle(t);
    }

    testWidgets('the scanner itself sees a red widget (a control)', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services);
      await openMoney(tester);
      await _openSheet(tester);

      final used = _widgetsUsing(tester, {
        _c.rose,
        _c.roseSoft,
      }, within: find.byType(BottomSheet));
      expect(used, isNotEmpty, reason: 'the Delete button is red');
      expect(used.whereType<Text>(), isNotEmpty);

      await disposeSteadyApp(tester, services);
    });

    testWidgets(
      'the Money tab, empty and with expenses, has no rose and no tide',
      (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(tester, clock: now.clock);
        await openMoney(tester);
        expect(
          _widgetsUsing(tester, _redAndBlue, within: find.byType(MoneyScreen)),
          isEmpty,
          reason: 'empty tab',
        );

        await _seed(tester, services, amount: 4820);
        await _seed(
          tester,
          services,
          amount: 450,
          category: MoneyCategory.bills,
        );
        await _seed(
          tester,
          services,
          amount: 900,
          date: LocalDate(2026, 9, 5),
          category: MoneyCategory.gifts,
        );
        await letDbFinish(tester);

        expect(find.byType(EntryRow), findsNWidgets(3));
        expect(find.byType(BarChartRow), findsNWidgets(2));
        expect(find.textContaining('Last month'), findsOne);
        expect(
          _widgetsUsing(tester, _redAndBlue, within: find.byType(MoneyScreen)),
          isEmpty,
        );

        await disposeSteadyApp(tester, services);
      },
    );

    testWidgets('the Add expense screen has no rose and no tide', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openMoney(tester);
      await openEditor(tester);
      await pressKeys(tester, '12.4');
      await pickCategory(tester, 'Groceries');

      expect(
        _widgetsUsing(
          tester,
          _redAndBlue,
          within: find.byType(EntryEditorScreen),
        ),
        isEmpty,
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the Expenses screen has no rose and no tide', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services);
      await _seed(tester, services, date: LocalDate(2026, 9, 30));
      await _openAll(tester);

      expect(
        _widgetsUsing(tester, _redAndBlue, within: find.byType(EntriesScreen)),
        isEmpty,
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('in the sheet, rose is only inside the Delete expense button', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services);
      await openMoney(tester);
      await _openSheet(tester);

      final sheet = find.byType(BottomSheet);
      final insideDelete = find
          .descendant(
            of: find.widgetWithText(SteadyButton, 'Delete expense'),
            matching: find.byWidgetPredicate((_) => true),
          )
          .evaluate()
          .map((e) => e.widget)
          .toSet();
      final red = _widgetsUsing(tester, {_c.rose, _c.roseSoft}, within: sheet);
      expect(red, isNotEmpty);
      for (final w in red) {
        expect(
          insideDelete.contains(w),
          isTrue,
          reason: 'a red widget outside the Delete button: $w',
        );
      }
      expect(
        _widgetsUsing(tester, {_c.tide, _c.tideSoft}, within: sheet),
        isEmpty,
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('in the question, only the Delete button is red', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await _seed(tester, services);
      await openMoney(tester);
      await _openSheet(tester);
      await openDialog(tester);

      final dialog = find.byType(AlertDialog);
      final insideDelete = find
          .descendant(
            of: find.descendant(
              of: dialog,
              matching: find.widgetWithText(SteadyButton, 'Delete'),
            ),
            matching: find.byWidgetPredicate((_) => true),
          )
          .evaluate()
          .map((e) => e.widget)
          .toSet();
      final red = _widgetsUsing(tester, {_c.rose, _c.roseSoft}, within: dialog);
      expect(red, isNotEmpty, reason: 'the Delete button is red');
      for (final w in red) {
        expect(
          insideDelete.contains(w),
          isTrue,
          reason: 'a red widget outside the Delete button: $w',
        );
      }
      expect(
        _widgetsUsing(tester, {_c.tide, _c.tideSoft}, within: dialog),
        isEmpty,
      );

      await disposeSteadyApp(tester, services);
    });
  });
}
