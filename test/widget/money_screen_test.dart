import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:steady/app.dart';
import 'package:steady/core/services.dart';
import 'package:steady/core/theme/tokens.dart';
import 'package:steady/core/theme/typography.dart';
import 'package:steady/core/time/local_date.dart';
import 'package:steady/data/database.dart';
import 'package:steady/data/money_types.dart';
import 'package:steady/features/money/entry_row.dart';
import 'package:steady/ui/components/bar_chart_row.dart';

import '../helpers/money_helpers.dart';
import '../helpers/test_app.dart';
import '../helpers/timer_helpers.dart';
import '../helpers/widget_helpers.dart';

/// Chữ trong các hàng "gần đây".
Finder _inRows(Finder f) =>
    find.descendant(of: find.byType(EntryRow), matching: f);

/// Chữ trong mục BY CATEGORY.
Finder _inBars(Finder f) =>
    find.descendant(of: find.byType(BarChartRow), matching: f);

/// Số lớn "Spent this month".
Finder _bigNumber() => find.byWidgetPredicate(
  (w) => w is Text && w.style?.fontSize == SteadyText.moneyXl.fontSize,
  description: 'the big "Spent this month" number',
);

String _big(WidgetTester t) => plain(t.widget<Text>(_bigNumber()).data!);

/// Bề rộng thanh amber của một hàng BY CATEGORY.
double _barWidth(WidgetTester t, String category) {
  final row = find.ancestor(
    of: _inBars(find.text(category)),
    matching: find.byType(BarChartRow),
  );
  final bar = find.descendant(
    of: row,
    matching: find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).borderRadius ==
              const BorderRadius.horizontal(right: Radius.circular(4)),
    ),
  );
  return t.getSize(bar).width;
}

void main() {
  group('Money tab: before anything is saved', () {
    testWidgets('shows the empty state', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openMoney(tester);

      expect(find.text('Money'), findsNWidgets(2)); // tab + tiêu đề
      expect(find.text('October'), findsOne);
      expect(find.text('Offline · no bank link'), findsOne);
      expect(find.text('Spent this month'), findsOne);
      expect(_big(tester), r'$0.00');
      expect(find.text('Add expense'), findsOne);
      expect(find.text('RECENT'), findsOne);
      expect(find.text('Your expenses will show up here.'), findsOne);
      expect(find.text('See all'), findsNothing);
      expect(find.text('BY CATEGORY'), findsNothing);
      expect(find.textContaining('Last month'), findsNothing);
      expect(find.byType(EntryRow), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('nothing about Money is built before the tab is opened', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedExpense(tester, services, amountMinor: 1240, date: today);
      await letDbFinish(tester);

      expect(find.text('Spent this month', skipOffstage: false), findsNothing);
      expect(
        find.text('Offline · no bank link', skipOffstage: false),
        findsNothing,
      );
      expect(find.byType(EntryRow, skipOffstage: false), findsNothing);
      // Chưa mở tab: chưa đọc, cũng chưa ghi tiền tệ vào prefs.
      expect(
        await tester.runAsync(() => services.prefs.read('money.currency')),
        isNull,
      );

      await tapTab(tester, 'Timer');
      await letDbFinish(tester);
      expect(find.text('Spent this month', skipOffstage: false), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('no query on money_entries runs before the tab is opened, '
        'and none after it is gone', (tester) async {
      // Ghi lại mọi câu SQL mà Drift gửi đi.
      final sql = <String>[];
      final oldPrint = driftRuntimeOptions.debugPrint;
      driftRuntimeOptions.debugPrint = sql.add;
      addTearDown(() => driftRuntimeOptions.debugPrint = oldPrint);
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      await initializeDateFormatting();
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = FakeNow(evening());
      final services = AppServices(
        db: AppDatabase(NativeDatabase.memory(logStatements: true)),
        clock: now.clock,
        screenAwake: FakeScreenAwake(),
      );
      int moneyReads() => sql
          .where((q) => q.contains('SELECT') && q.contains('money_entries'))
          .length;

      await tester.pumpWidget(SteadyApp(services: services));
      await tester.pump();
      await letDbFinish(tester);
      await tapTab(tester, 'Timer');
      await letDbFinish(tester);
      expect(
        sql,
        isNotEmpty,
        reason: 'the log works: the Timer tab read prefs',
      );
      expect(moneyReads(), 0, reason: 'Money was never opened');

      await tapTab(tester, 'Money');
      await letDbFinish(tester);
      expect(
        moneyReads(),
        greaterThanOrEqualTo(2),
        reason: 'recent + two months',
      );

      // Gỡ app: mọi subscription phải được huỷ, nên ghi thêm một khoản không
      // làm câu SELECT nào chạy lại.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      sql.clear();
      await dbAction(
        tester,
        () => services.money.add(
          amountMinor: 100,
          category: MoneyCategory.gifts,
          date: today,
        ),
      );
      await letDbFinish(tester);
      expect(sql.where((q) => q.contains('INSERT')), isNotEmpty);
      expect(moneyReads(), 0, reason: 'no subscription is left after dispose');

      await services.dispose();
    });

    testWidgets('a database that cannot be read shows the load error', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tester.runAsync(
        () => services.db.customStatement('DROP TABLE money_entries'),
      );

      await openMoney(tester);

      expect(find.text("Couldn't load your expenses."), findsOne);
      expect(
        find.text('Money'),
        findsNWidgets(2),
        reason: 'title is still there',
      );
      expect(find.text('Add expense'), findsNothing);
      expect(find.text('Spent this month'), findsNothing);
      // Không hiện "$0.00" như thể không có khoản nào.
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data ?? '').contains(r'$0'),
        ),
        findsNothing,
      );
      await disposeSteadyApp(tester, services);
    });

    testWidgets('opening the tab twice does not start over', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openMoney(tester);
      await seedExpense(tester, services, amountMinor: 500, date: today);
      expect(_big(tester), r'$5.00');

      await tapTab(tester, 'Streaks');
      await tapTab(tester, 'Money');
      expect(_big(tester), r'$5.00', reason: 'no empty flash on return');
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Money tab: totals and months', () {
    testWidgets('adds up this month; the amount is plain ink-sized text', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedExpense(tester, services, amountMinor: 4820, date: today);
      await seedExpense(tester, services, amountMinor: 450, date: today);
      await seedExpense(
        tester,
        services,
        amountMinor: 100000,
        date: LocalDate(2026, 10, 1),
      );
      await openMoney(tester);

      expect(_big(tester), r'$1,052.70');
      expect(find.textContaining('Last month'), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the first and the last day of the month are counted', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedExpense(
        tester,
        services,
        amountMinor: 1000,
        date: LocalDate(2026, 10, 1),
      );
      await seedExpense(
        tester,
        services,
        amountMinor: 200,
        date: LocalDate(2026, 10, 31),
      );
      await openMoney(tester);
      expect(_big(tester), r'$12.00');
      await disposeSteadyApp(tester, services);
    });

    testWidgets('the day before and the day after the month are not counted', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedExpense(
        tester,
        services,
        amountMinor: 700,
        date: LocalDate(2026, 9, 30),
      );
      await seedExpense(
        tester,
        services,
        amountMinor: 900,
        date: LocalDate(2026, 11, 1),
      );
      await seedExpense(tester, services, amountMinor: 100, date: today);
      await openMoney(tester);

      expect(_big(tester), r'$1.00');
      // Tháng trước chỉ gồm 30/9; khoản 1/11 (ngày tương lai) không vào đâu cả.
      expect(find.text(r'Last month: $7.00'), findsOne);
      // Nhưng cả ba vẫn nằm trong danh sách gần đây.
      expect(find.byType(EntryRow), findsNWidgets(3));

      await disposeSteadyApp(tester, services);
    });

    testWidgets(
      'last month: not in the total, shown on its own line, kept in RECENT',
      (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(tester, clock: now.clock);
        await seedExpense(
          tester,
          services,
          amountMinor: 5000,
          date: LocalDate(2026, 9, 15),
          createdAt: DateTime(2026, 9, 15, 12),
        );
        await openMoney(tester);

        expect(_big(tester), r'$0.00');
        expect(find.text(r'Last month: $50.00'), findsOne);
        expect(find.byType(EntryRow), findsOne);
        expect(_inRows(find.text('Groceries')), findsOne);
        expect(
          find.text('BY CATEGORY'),
          findsNothing,
          reason: 'nothing this month',
        );

        await disposeSteadyApp(tester, services);
      },
    );

    testWidgets('the Last month line covers the whole of last month', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      for (final (day, amount) in [(1, 1000), (15, 2000), (30, 3000)]) {
        await seedExpense(
          tester,
          services,
          amountMinor: amount,
          date: LocalDate(2026, 9, day),
        );
      }
      await seedExpense(
        tester,
        services,
        amountMinor: 99999,
        date: LocalDate(2026, 8, 31),
      );
      await openMoney(tester);
      expect(find.text(r'Last month: $60.00'), findsOne);
      await disposeSteadyApp(tester, services);
    });

    testWidgets('the Last month line is hidden when last month is 0', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      // Hai tháng trước, không phải tháng trước.
      await seedExpense(
        tester,
        services,
        amountMinor: 5000,
        date: LocalDate(2026, 8, 20),
      );
      await seedExpense(tester, services, amountMinor: 100, date: today);
      await openMoney(tester);

      expect(find.textContaining('Last month'), findsNothing);
      expect(_big(tester), r'$1.00');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('January: Last month is December of the year before', (
      tester,
    ) async {
      final now = FakeNow(DateTime(2026, 1, 15, 21));
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedExpense(
        tester,
        services,
        amountMinor: 2000,
        date: LocalDate(2025, 12, 31),
      );
      await seedExpense(
        tester,
        services,
        amountMinor: 1000,
        date: LocalDate(2025, 12, 1),
      );
      await seedExpense(
        tester,
        services,
        amountMinor: 9900,
        date: LocalDate(2025, 11, 30),
      );
      await seedExpense(
        tester,
        services,
        amountMinor: 500,
        date: LocalDate(2026, 1, 1),
      );
      await openMoney(tester);

      expect(find.text('January'), findsOne);
      expect(_big(tester), r'$5.00');
      expect(find.text(r'Last month: $30.00'), findsOne);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a leap-year February counts the 29th', (tester) async {
      final now = FakeNow(DateTime(2028, 2, 29, 21));
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedExpense(
        tester,
        services,
        amountMinor: 700,
        date: LocalDate(2028, 2, 29),
      );
      await seedExpense(
        tester,
        services,
        amountMinor: 300,
        date: LocalDate(2028, 2, 1),
      );
      await seedExpense(
        tester,
        services,
        amountMinor: 50,
        date: LocalDate(2028, 3, 1),
      );
      await openMoney(tester);
      expect(find.text('February'), findsOne);
      expect(_big(tester), r'$10.00');
      await disposeSteadyApp(tester, services);
    });

    testWidgets('the biggest amount the repository allows fits on screen', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedExpense(
        tester,
        services,
        amountMinor: kMaxAmountMinor,
        date: today,
      );
      await seedExpense(
        tester,
        services,
        amountMinor: kMaxAmountMinor,
        date: today,
      );
      await openMoney(tester);

      expect(_big(tester), r'$19,999,999,999.98');
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Money tab: recent expenses', () {
    testWidgets('shows a row with the category, the time and a minus amount', (
      tester,
    ) async {
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

      expect(_inRows(find.text('Groceries')), findsOne);
      expect(_inRows(textPlain('9:00 PM')), findsOne);
      expect(_inRows(find.text('−\$12.40')), findsOne);
      expect(find.text('See all'), findsOne);
      expect(find.text('Your expenses will show up here.'), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('shows only the five newest', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      for (var d = 1; d <= 7; d++) {
        await seedExpense(
          tester,
          services,
          amountMinor: d * 100,
          date: LocalDate(2026, 9, d),
        );
      }
      await openMoney(tester);

      expect(find.byType(EntryRow), findsNWidgets(5));
      expect(_inRows(find.text('−\$7.00')), findsOne);
      expect(_inRows(find.text('−\$3.00')), findsOne);
      expect(_inRows(find.text('−\$2.00')), findsNothing);
      expect(_inRows(find.text('−\$1.00')), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a note is the title and the category moves to the detail', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedExpense(
        tester,
        services,
        amountMinor: 1240,
        date: today,
        note: 'Weekly shop',
        createdAt: evening(),
      );
      await openMoney(tester);

      expect(_inRows(find.text('Weekly shop')), findsOne);
      expect(_inRows(textPlain('Groceries · 9:00 PM')), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a 24-hour phone shows 21:00', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp24h(tester, now: now);
      await seedExpense(
        tester,
        services,
        amountMinor: 1240,
        category: MoneyCategory.transport,
        date: today,
        createdAt: evening(),
        note: 'Bus',
      );
      await openMoney(tester);

      expect(_inRows(textPlain('Transport · 21:00')), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets(
      'a row saved for another day than it was created shows no time',
      (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(tester, clock: now.clock);
        await seedExpense(
          tester,
          services,
          amountMinor: 1240,
          date: LocalDate(2026, 10, 1),
          createdAt: evening(),
        );
        await openMoney(tester);

        expect(_inRows(find.text('Groceries')), findsOne);
        expect(find.textContaining('PM'), findsNothing);
        expect(find.textContaining(':00'), findsNothing);

        await disposeSteadyApp(tester, services);
      },
    );

    testWidgets('every amount is ink, never red or green', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedExpense(tester, services, amountMinor: 1240, date: today);
      await openMoney(tester);

      final amount = tester.widget<Text>(find.text('−\$12.40'));
      expect(amount.style!.color, SteadyColors.dark.ink);
      final big = tester.widget<Text>(_bigNumber());
      expect(big.style!.color, SteadyColors.dark.ink);
      expect(_big(tester), r'$12.40');

      await disposeSteadyApp(tester, services);
    });
  });

  group('Money tab: BY CATEGORY', () {
    Future<void> seedThree(WidgetTester t, AppServices services) async {
      await seedExpense(
        t,
        services,
        amountMinor: 18400,
        category: MoneyCategory.eatingOut,
        date: today,
      );
      await seedExpense(
        t,
        services,
        amountMinor: 32000,
        category: MoneyCategory.groceries,
        date: today,
      );
      await seedExpense(
        t,
        services,
        amountMinor: 21000,
        category: MoneyCategory.bills,
        date: today,
      );
    }

    testWidgets('lists the categories with spending, largest first', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedThree(tester, services);
      await openMoney(tester);

      expect(find.text('BY CATEGORY'), findsOne);
      expect(find.byType(BarChartRow), findsNWidgets(3));
      final ys = [
        for (final c in ['Groceries', 'Bills', 'Eating out'])
          tester.getTopLeft(_inBars(find.text(c))).dy,
      ];
      expect(ys, orderedEquals([...ys]..sort()), reason: 'top to bottom');
      expect(ys.toSet(), hasLength(3));
      expect(_inBars(find.text(r'$320.00')), findsOne);
      expect(_inBars(find.text(r'$210.00')), findsOne);
      expect(_inBars(find.text(r'$184.00')), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the biggest bar is the longest, the rest in proportion', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedThree(tester, services);
      await openMoney(tester);

      final groceries = _barWidth(tester, 'Groceries');
      final bills = _barWidth(tester, 'Bills');
      final eating = _barWidth(tester, 'Eating out');
      expect(groceries, greaterThan(bills));
      expect(bills, greaterThan(eating));
      expect(bills, closeTo(groceries * 210 / 320, 0.5));
      expect(eating, closeTo(groceries * 184 / 320, 0.5));
      // Thanh dài nhất = w - w/3 - 8, với w là bề rộng trong của khung.
      final w = tester.getSize(find.byType(BarChartRow).first).width;
      expect(groceries, closeTo(w - w / 3 - 8, 0.5));

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a tiny spend still gets a visible bar of 4', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedExpense(
        tester,
        services,
        amountMinor: 99999999,
        category: MoneyCategory.housing,
        date: today,
      );
      await seedExpense(
        tester,
        services,
        amountMinor: 1,
        category: MoneyCategory.gifts,
        date: today,
      );
      await openMoney(tester);

      expect(_barWidth(tester, 'Gifts'), 4);
      expect(_barWidth(tester, 'Housing'), greaterThan(100));

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a tie keeps the order of the categories in the grid', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedExpense(
        tester,
        services,
        amountMinor: 500,
        category: MoneyCategory.gifts,
        date: today,
      );
      await seedExpense(
        tester,
        services,
        amountMinor: 500,
        category: MoneyCategory.bills,
        date: today,
      );
      await seedExpense(
        tester,
        services,
        amountMinor: 500,
        category: MoneyCategory.health,
        date: today,
      );
      await openMoney(tester);

      final ys = [
        for (final c in ['Bills', 'Health', 'Gifts'])
          tester.getTopLeft(_inBars(find.text(c))).dy,
      ];
      expect(ys, orderedEquals([...ys]..sort()));
      expect(ys.toSet(), hasLength(3));

      await disposeSteadyApp(tester, services);
    });

    testWidgets('only this month counts: last month adds no bar', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedExpense(
        tester,
        services,
        amountMinor: 5000,
        category: MoneyCategory.travel,
        date: LocalDate(2026, 9, 30),
      );
      await seedExpense(
        tester,
        services,
        amountMinor: 100,
        category: MoneyCategory.phone,
        date: today,
      );
      await openMoney(tester);

      expect(find.byType(BarChartRow), findsOne);
      expect(_inBars(find.text('Phone')), findsOne);
      expect(_inBars(find.text('Travel')), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('twelve categories give twelve bars', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      for (final (i, c) in MoneyCategory.values.indexed) {
        await seedExpense(
          tester,
          services,
          amountMinor: 1000 + i,
          category: c,
          date: today,
        );
      }
      await openMoney(tester);

      expect(find.byType(BarChartRow, skipOffstage: false), findsNWidgets(12));

      await disposeSteadyApp(tester, services);
    });

    testWidgets(
      'an edit that moves the only expense out of this month hides the section',
      (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(tester, clock: now.clock);
        final entry = await seedExpense(
          tester,
          services,
          amountMinor: 500,
          date: today,
        );
        await openMoney(tester);
        expect(find.text('BY CATEGORY'), findsOne);

        await dbAction(
          tester,
          () => services.money.update(
            entry.id,
            amountMinor: 500,
            category: MoneyCategory.groceries,
            date: LocalDate(2026, 9, 3),
          ),
        );
        await letDbFinish(tester);

        expect(find.text('BY CATEGORY'), findsNothing);
        expect(_big(tester), r'$0.00');
        expect(find.text(r'Last month: $5.00'), findsOne);

        await disposeSteadyApp(tester, services);
      },
    );
  });

  group('Money tab: the clock', () {
    testWidgets('crossing midnight into a new month', (tester) async {
      final now = FakeNow(DateTime(2026, 10, 31, 21));
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedExpense(
        tester,
        services,
        amountMinor: 3000,
        category: MoneyCategory.groceries,
        date: LocalDate(2026, 10, 30),
      );
      await seedExpense(
        tester,
        services,
        amountMinor: 1500,
        category: MoneyCategory.bills,
        date: LocalDate(2026, 10, 31),
      );
      await openMoney(tester);
      expect(find.text('October'), findsOne);
      expect(_big(tester), r'$45.00');
      expect(find.text('BY CATEGORY'), findsOne);
      expect(find.textContaining('Last month'), findsNothing);

      now.value = DateTime(2026, 11, 1, 0, 0, 30);
      await tester.pump(const Duration(hours: 3, seconds: 5));
      await letDbFinish(tester);

      expect(find.text('November'), findsOne);
      expect(find.text('October'), findsNothing);
      expect(_big(tester), r'$0.00');
      expect(find.text(r'Last month: $45.00'), findsOne);
      expect(find.text('BY CATEGORY'), findsNothing);
      expect(find.byType(BarChartRow), findsNothing);
      expect(
        find.byType(EntryRow),
        findsNWidgets(2),
        reason: 'RECENT keeps both',
      );
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('crossing midnight into a new year', (tester) async {
      final now = FakeNow(DateTime(2026, 12, 31, 22));
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedExpense(
        tester,
        services,
        amountMinor: 8000,
        date: LocalDate(2026, 12, 31),
      );
      await seedExpense(
        tester,
        services,
        amountMinor: 1000,
        date: LocalDate(2026, 11, 5),
      );
      await openMoney(tester);
      expect(find.text('December'), findsOne);
      expect(_big(tester), r'$80.00');
      expect(find.text(r'Last month: $10.00'), findsOne);

      now.value = DateTime(2027, 1, 1, 0, 0, 10);
      await tester.pump(const Duration(hours: 3));
      await letDbFinish(tester);

      expect(find.text('January'), findsOne);
      expect(_big(tester), r'$0.00');
      expect(find.text(r'Last month: $80.00'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a new day in the same month keeps the month totals', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedExpense(tester, services, amountMinor: 4500, date: today);
      await seedExpense(
        tester,
        services,
        amountMinor: 1000,
        date: LocalDate(2026, 9, 10),
      );
      await openMoney(tester);

      now.value = DateTime(2026, 10, 3, 0, 0, 30);
      await tester.pump(const Duration(hours: 3, seconds: 5));
      await letDbFinish(tester);

      expect(find.text('October'), findsOne);
      expect(_big(tester), r'$45.00');
      expect(find.text(r'Last month: $10.00'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('after the new month, a new expense lands in the new month', (
      tester,
    ) async {
      final now = FakeNow(DateTime(2026, 10, 31, 21));
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedExpense(
        tester,
        services,
        amountMinor: 4500,
        date: LocalDate(2026, 10, 31),
      );
      await openMoney(tester);

      now.value = DateTime(2026, 11, 1, 9);
      services.today.refresh();
      await tester.pump();
      await letDbFinish(tester);
      await dbAction(
        tester,
        () => services.money.add(
          amountMinor: 700,
          category: MoneyCategory.groceries,
          date: LocalDate(2026, 11, 1),
        ),
      );
      await letDbFinish(tester);

      expect(_big(tester), r'$7.00');
      expect(find.text(r'Last month: $45.00'), findsOne);
      expect(find.byType(BarChartRow), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a clock moved back into the previous month follows it', (
      tester,
    ) async {
      final now = FakeNow(DateTime(2026, 10, 15, 21));
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedExpense(
        tester,
        services,
        amountMinor: 3000,
        date: LocalDate(2026, 10, 10),
      );
      await seedExpense(
        tester,
        services,
        amountMinor: 2000,
        date: LocalDate(2026, 9, 20),
      );
      await seedExpense(
        tester,
        services,
        amountMinor: 700,
        date: LocalDate(2026, 8, 20),
      );
      await openMoney(tester);
      expect(_big(tester), r'$30.00');

      now.value = DateTime(2026, 9, 28, 9);
      services.today.refresh();
      await tester.pump();
      await letDbFinish(tester);

      expect(find.text('September'), findsOne);
      expect(_big(tester), r'$20.00');
      expect(find.text(r'Last month: $7.00'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('coming back from the background picks up the new month', (
      tester,
    ) async {
      final now = FakeNow(DateTime(2026, 10, 31, 21));
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedExpense(
        tester,
        services,
        amountMinor: 2500,
        date: LocalDate(2026, 10, 31),
      );
      await openMoney(tester);

      sendToBackground(tester);
      now.value = DateTime(2026, 11, 2, 8);
      bringToForeground(tester);
      await tester.pump();
      await letDbFinish(tester);

      expect(find.text('November'), findsOne);
      expect(_big(tester), r'$0.00');
      expect(find.text(r'Last month: $25.00'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('nothing throws if the day changes after the app is gone', (
      tester,
    ) async {
      final now = FakeNow(DateTime(2026, 10, 31, 21));
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openMoney(tester);

      // Gỡ app, để Timer(0) đóng các stream Drift chạy hết.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      now.value = DateTime(2026, 11, 1, 9);
      services.today.refresh();
      await dbAction(
        tester,
        () => services.money.add(
          amountMinor: 100,
          category: MoneyCategory.gifts,
          date: LocalDate(2026, 11, 1),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      await services.dispose();
    });
  });

  group('Money tab: currency', () {
    testWidgets('a first open on an en_US phone saves USD', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openMoney(tester);

      expect(_big(tester), r'$0.00');
      expect(
        await tester.runAsync(() => services.prefs.read('money.currency')),
        'USD',
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a de_DE phone gets euros and keeps them', (tester) async {
      setDeviceLocale(tester, const Locale('de', 'DE'));
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedExpense(tester, services, amountMinor: 1240, date: today);
      await openMoney(tester);

      expect(_big(tester), '€12.40', reason: 'English digits, euro symbol');
      expect(
        await tester.runAsync(() => services.prefs.read('money.currency')),
        'EUR',
      );

      // Máy đổi vùng về en_US, dựng lại app trên cùng DB: vẫn là euro.
      tester.platformDispatcher.localeTestValue = const Locale('en', 'US');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pumpWidget(SteadyApp(services: services));
      await tester.pump();
      await openMoney(tester);

      expect(_big(tester), '€12.40');
      expect(_inRows(find.text('−€12.40')), findsOne);
      expect(find.textContaining(r'$'), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a saved EUR gives euros on an en_US phone', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedCurrency(tester, services, 'EUR');
      await openMoney(tester);

      expect(_big(tester), '€0.00');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a saved JPY has no decimals', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedCurrency(tester, services, 'JPY');
      await seedExpense(tester, services, amountMinor: 1235, date: today);
      await openMoney(tester);

      expect(_big(tester), '¥1,235');
      expect(_inRows(find.text('−¥1,235')), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a ja_JP phone gets yen on the first open', (tester) async {
      setDeviceLocale(tester, const Locale('ja', 'JP'));
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openMoney(tester);

      expect(_big(tester), '¥0');
      expect(
        await tester.runAsync(() => services.prefs.read('money.currency')),
        'JPY',
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a vi_VN phone gets dong, not dollars', (tester) async {
      setDeviceLocale(tester, const Locale('vi', 'VN'));
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openMoney(tester);

      expect(
        await tester.runAsync(() => services.prefs.read('money.currency')),
        'VND',
      );
      expect(find.textContaining(r'$'), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('an es_AR phone gets Argentine pesos, not euros', (
      tester,
    ) async {
      // intl một mình ra EUR cho es_AR; bảng theo vùng mới ra ARS. Ký hiệu
      // của ARS trong tiếng Anh cũng là "$", nên chỉ kiểm mã đã lưu.
      setDeviceLocale(tester, const Locale('es', 'AR'));
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openMoney(tester);

      expect(
        await tester.runAsync(() => services.prefs.read('money.currency')),
        'ARS',
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('an en_VN phone gets dong: the region wins over the language', (
      tester,
    ) async {
      setDeviceLocale(tester, const Locale('en', 'VN'));
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openMoney(tester);

      expect(
        await tester.runAsync(() => services.prefs.read('money.currency')),
        'VND',
      );
      expect(find.textContaining(r'$'), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a zh_Hant_TW phone gets new Taiwan dollars', (tester) async {
      setDeviceLocale(
        tester,
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'TW',
        ),
      );
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openMoney(tester);

      expect(
        await tester.runAsync(() => services.prefs.read('money.currency')),
        'TWD',
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a phone in a region with no currency still gets USD', (
      tester,
    ) async {
      // AQ (Nam Cực) không có trong bảng: màn Money vẫn mở được, tiền là USD.
      setDeviceLocale(tester, const Locale('en', 'AQ'));
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openMoney(tester);

      expect(_big(tester), r'$0.00');
      expect(
        await tester.runAsync(() => services.prefs.read('money.currency')),
        'USD',
      );
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('an en_GB phone gets pounds and day-first dates', (
      tester,
    ) async {
      setDeviceLocale(tester, const Locale('en', 'GB'));
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedExpense(
        tester,
        services,
        amountMinor: 1240,
        date: LocalDate(2026, 9, 30),
      );
      await openMoney(tester);

      expect(
        await tester.runAsync(() => services.prefs.read('money.currency')),
        'GBP',
      );
      expect(_big(tester), '£0.00');
      expect(find.text('Last month: £12.40'), findsOne);
      await tester.tap(find.text('See all'));
      await settle(tester);
      expect(
        find.textContaining('30 SEP'),
        findsOne,
        reason: 'day first, upper case',
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a damaged saved value is replaced by the phone currency', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedCurrency(tester, services, 'dollars');
      await openMoney(tester);

      expect(_big(tester), r'$0.00');
      expect(
        await tester.runAsync(() => services.prefs.read('money.currency')),
        'USD',
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the tab still opens when the currency cannot be saved', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await breakWrites(tester, services, 'prefs');
      await openMoney(tester);

      expect(_big(tester), r'$0.00');
      expect(find.text("Couldn't load your expenses."), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });
  });
}
