import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:steady/core/format/money_format.dart';
import 'package:steady/core/time/local_date.dart';
import 'package:steady/data/database.dart';
import 'package:steady/data/money_types.dart';
import 'package:steady/features/money/money_labels.dart';
import 'package:steady/l10n/app_localizations_en.dart';
import 'package:steady/ui/components/steady_icon.dart';

import '../helpers/timer_helpers.dart' show plain;

final _today = LocalDate(2026, 10, 2);

MoneyEntry _entry({
  int amount = 1240,
  MoneyCategory category = MoneyCategory.groceries,
  String? note,
  LocalDate? date,
  DateTime? createdAt,
}) => MoneyEntry(
  id: 1,
  amountMinor: amount,
  category: category,
  note: note,
  date: date ?? _today,
  createdAt: createdAt ?? DateTime(2026, 10, 2, 21),
);

void main() {
  final l10n = AppLocalizationsEn();

  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('categoryLabel and categoryIcon', () {
    test('every category has the label of the plan table', () {
      expect(
        {for (final c in MoneyCategory.values) c: categoryLabel(l10n, c)},
        {
          MoneyCategory.groceries: 'Groceries',
          MoneyCategory.eatingOut: 'Eating out',
          MoneyCategory.transport: 'Transport',
          MoneyCategory.bills: 'Bills',
          MoneyCategory.shopping: 'Shopping',
          MoneyCategory.health: 'Health',
          MoneyCategory.gifts: 'Gifts',
          MoneyCategory.housing: 'Housing',
          MoneyCategory.travel: 'Travel',
          MoneyCategory.phone: 'Phone',
          MoneyCategory.education: 'Education',
          MoneyCategory.other: 'Other',
        },
      );
    });

    test('every category has the icon of the plan table', () {
      expect(
        {for (final c in MoneyCategory.values) c: categoryIcon(c)},
        {
          MoneyCategory.groceries: 'shopping-cart',
          MoneyCategory.eatingOut: 'coffee',
          MoneyCategory.transport: 'car',
          MoneyCategory.bills: 'zap',
          MoneyCategory.shopping: 'shirt',
          MoneyCategory.health: 'heart-pulse',
          MoneyCategory.gifts: 'gift',
          MoneyCategory.housing: 'house',
          MoneyCategory.travel: 'plane',
          MoneyCategory.phone: 'smartphone',
          MoneyCategory.education: 'graduation-cap',
          MoneyCategory.other: 'receipt',
        },
      );
    });

    test('the labels and the icons are all different', () {
      final labels = {
        for (final c in MoneyCategory.values) categoryLabel(l10n, c),
      };
      final icons = {for (final c in MoneyCategory.values) categoryIcon(c)};
      expect(labels, hasLength(12));
      expect(icons, hasLength(12));
      expect(icons, isNot(contains(SteadyIcons.wallet)));
    });
  });

  group('expenseAmount', () {
    final usd = MoneyFormat('en_US', 'USD');

    test('puts a minus sign (U+2212) in front of the formatted amount', () {
      expect(expenseAmount(l10n, usd, 1240), '−\$12.40');
      expect(expenseAmount(l10n, usd, 5), '−\$0.05');
    });

    test('does not use a hyphen', () {
      expect(expenseAmount(l10n, usd, 1240).contains('-'), isFalse);
    });

    test('works in yen and euro too', () {
      expect(expenseAmount(l10n, MoneyFormat('en', 'JPY'), 1235), '−¥1,235');
      expect(
        plain(expenseAmount(l10n, MoneyFormat('de', 'EUR'), 1240)),
        '−12,40 €',
      );
    });
  });

  group('entryTitle', () {
    test('is the note when there is one', () {
      expect(entryTitle(l10n, _entry(note: 'Weekly shop')), 'Weekly shop');
    });

    test('is the category label when there is no note', () {
      expect(entryTitle(l10n, _entry(category: MoneyCategory.bills)), 'Bills');
    });
  });

  group('entryDetail', () {
    String? detail(MoneyEntry e, {bool use24h = false, String tag = 'en'}) =>
        entryDetail(l10n, e, tag: tag, use24h: use24h);
    String? p(String? s) => s == null ? null : plain(s);

    test('no note, created on its own day: just the time', () {
      expect(p(detail(_entry())), '9:00 PM');
    });

    test('a note, created on its own day: "Category · time"', () {
      expect(p(detail(_entry(note: 'Weekly shop'))), 'Groceries · 9:00 PM');
    });

    test('24-hour clock shows 21:00', () {
      expect(detail(_entry(), use24h: true), '21:00');
      expect(
        detail(
          _entry(note: 'x', category: MoneyCategory.transport),
          use24h: true,
        ),
        'Transport · 21:00',
      );
    });

    test(
      'a different day than createdAt: no time. Note gives the category',
      () {
        final yesterday = _entry(
          date: LocalDate(2026, 10, 1),
          note: 'Weekly shop',
        );
        expect(detail(yesterday), 'Groceries');
      },
    );

    test('a different day and no note: nothing to show', () {
      expect(detail(_entry(date: LocalDate(2026, 10, 1))), isNull);
    });

    test('a date after createdAt (clock moved back) also has no time', () {
      expect(detail(_entry(date: LocalDate(2026, 10, 9))), isNull);
    });

    test('just after midnight still counts as its own day', () {
      final e = _entry(
        createdAt: DateTime(2026, 10, 2, 0, 0, 5),
        date: LocalDate(2026, 10, 2),
      );
      expect(p(detail(e)), '12:00 AM');
    });

    test('just before midnight: the time is kept; the next day it is not', () {
      final late = _entry(createdAt: DateTime(2026, 10, 2, 23, 59, 59));
      expect(p(detail(late)), '11:59 PM');
      final next = _entry(
        createdAt: DateTime(2026, 10, 2, 23, 59, 59),
        date: LocalDate(2026, 10, 3),
      );
      expect(detail(next), isNull);
    });
  });

  group('dayHeader', () {
    String header(LocalDate d) => dayHeader(l10n, d, _today, 'en');

    test('today and yesterday', () {
      expect(header(_today), 'TODAY');
      expect(header(LocalDate(2026, 10, 1)), 'YESTERDAY');
    });

    test('another day this year is upper-case "MMM d"', () {
      expect(header(LocalDate(2026, 9, 30)), 'SEP 30');
      expect(header(LocalDate(2026, 1, 1)), 'JAN 1');
    });

    test('another year adds the year', () {
      expect(header(LocalDate(2025, 12, 31)), 'DEC 31, 2025');
    });

    test('tomorrow (clock moved back) is a plain date, not TODAY', () {
      expect(header(LocalDate(2026, 10, 3)), 'OCT 3');
    });

    test('yesterday follows the month boundary', () {
      final first = LocalDate(2026, 11, 1);
      expect(
        dayHeader(l10n, LocalDate(2026, 10, 31), first, 'en'),
        'YESTERDAY',
      );
      final newYear = LocalDate(2027, 1, 1);
      expect(
        dayHeader(l10n, LocalDate(2026, 12, 31), newYear, 'en'),
        'YESTERDAY',
      );
    });
  });

  group('dateLabel', () {
    String label(LocalDate d) => dateLabel(l10n, d, _today, 'en');

    test('Today and Yesterday', () {
      expect(label(_today), 'Today');
      expect(label(LocalDate(2026, 10, 1)), 'Yesterday');
    });

    test('another day keeps the case of the date format', () {
      expect(label(LocalDate(2026, 9, 30)), 'Sep 30');
      expect(label(LocalDate(2025, 12, 31)), 'Dec 31, 2025');
    });

    test('follows the English-GB day-first order', () {
      expect(
        dateLabel(l10n, LocalDate(2026, 9, 30), _today, 'en_GB'),
        matches(RegExp(r'^30 Sep')),
        reason: 'day before month',
      );
    });
  });
}
