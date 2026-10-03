import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/time/local_date.dart';
import 'package:steady/data/database.dart';
import 'package:steady/data/money_types.dart';
import 'package:steady/features/money/money_math.dart';

var _nextId = 1;

MoneyEntry _entry(
  int amount, {
  MoneyCategory category = MoneyCategory.groceries,
  LocalDate? date,
  String? note,
}) => MoneyEntry(
  id: _nextId++,
  amountMinor: amount,
  category: category,
  note: note,
  date: date ?? LocalDate(2026, 10, 2),
  createdAt: DateTime(2026, 10, 2, 21),
);

void main() {
  group('monthRange', () {
    test('2026-10: the 1st to the 31st', () {
      expect(monthRange(LocalDate(2026, 10, 2)), (
        LocalDate(2026, 10, 1),
        LocalDate(2026, 10, 31),
      ));
    });

    test('2028-02 (leap year): the 1st to the 29th', () {
      expect(monthRange(LocalDate(2028, 2, 10)), (
        LocalDate(2028, 2, 1),
        LocalDate(2028, 2, 29),
      ));
    });

    test('2026-02 (not a leap year): ends on the 28th', () {
      expect(monthRange(LocalDate(2026, 2, 28)).$2, LocalDate(2026, 2, 28));
    });

    test('2100-02 (century, not a leap year): ends on the 28th', () {
      expect(monthRange(LocalDate(2100, 2, 1)).$2, LocalDate(2100, 2, 28));
    });

    test('2026-12: the 1st to the 31st, without crossing the year', () {
      expect(monthRange(LocalDate(2026, 12, 15)), (
        LocalDate(2026, 12, 1),
        LocalDate(2026, 12, 31),
      ));
    });

    test('any day of a month gives the same range', () {
      final expected = monthRange(LocalDate(2026, 4, 1));
      for (var day = 1; day <= 30; day++) {
        expect(monthRange(LocalDate(2026, 4, day)), expected);
      }
      expect(expected.$2, LocalDate(2026, 4, 30));
    });

    test('the day count of all 12 months of 2026', () {
      final ends = [
        for (var m = 1; m <= 12; m++) monthRange(LocalDate(2026, m, 1)).$2.day,
      ];
      expect(ends, [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]);
    });
  });

  group('previousMonth', () {
    test('January goes back to December of the year before', () {
      expect(previousMonth(LocalDate(2026, 1, 15)), LocalDate(2025, 12, 1));
      expect(previousMonth(LocalDate(2026, 1, 1)), LocalDate(2025, 12, 1));
      expect(previousMonth(LocalDate(2026, 1, 31)), LocalDate(2025, 12, 1));
    });

    test('2026-03-31 gives 2026-02-01 (a shorter month)', () {
      expect(previousMonth(LocalDate(2026, 3, 31)), LocalDate(2026, 2, 1));
    });

    test('a middle month gives the 1st of the month before', () {
      expect(previousMonth(LocalDate(2026, 10, 2)), LocalDate(2026, 9, 1));
      expect(previousMonth(LocalDate(2026, 12, 31)), LocalDate(2026, 11, 1));
    });

    test('March of a leap year gives February', () {
      expect(previousMonth(LocalDate(2028, 3, 1)), LocalDate(2028, 2, 1));
    });

    test('always the 1st, and always exactly one month earlier', () {
      for (var m = 1; m <= 12; m++) {
        final prev = previousMonth(LocalDate(2026, m, 1));
        expect(prev.day, 1);
        expect(prev.month, m == 1 ? 12 : m - 1);
        expect(prev.year, m == 1 ? 2025 : 2026);
      }
    });

    test('the previous month of a January range ends on 31 December', () {
      final prev = monthRange(previousMonth(LocalDate(2026, 1, 20)));
      expect(prev, (LocalDate(2025, 12, 1), LocalDate(2025, 12, 31)));
    });
  });

  group('inRange', () {
    final october = monthRange(LocalDate(2026, 10, 2));

    test('includes both ends', () {
      expect(inRange(LocalDate(2026, 10, 1), october), isTrue);
      expect(inRange(LocalDate(2026, 10, 31), october), isTrue);
    });

    test('includes the middle', () {
      expect(inRange(LocalDate(2026, 10, 15), october), isTrue);
    });

    test('excludes the day before and the day after', () {
      expect(inRange(LocalDate(2026, 9, 30), october), isFalse);
      expect(inRange(LocalDate(2026, 11, 1), october), isFalse);
    });

    test('excludes the same month of another year', () {
      expect(inRange(LocalDate(2025, 10, 15), october), isFalse);
      expect(inRange(LocalDate(2027, 10, 15), october), isFalse);
    });

    test('a one-day range holds only that day', () {
      final day = (LocalDate(2026, 10, 2), LocalDate(2026, 10, 2));
      expect(inRange(LocalDate(2026, 10, 2), day), isTrue);
      expect(inRange(LocalDate(2026, 10, 1), day), isFalse);
      expect(inRange(LocalDate(2026, 10, 3), day), isFalse);
    });
  });

  group('totalOf', () {
    test('an empty list is 0', () {
      expect(totalOf(const []), 0);
    });

    test('sums the amounts', () {
      expect(totalOf([_entry(4820), _entry(450), _entry(1)]), 5271);
    });

    test('does not overflow near the repository limit', () {
      expect(
        totalOf([_entry(kMaxAmountMinor), _entry(kMaxAmountMinor)]),
        2 * kMaxAmountMinor,
      );
    });
  });

  group('totalsByCategory', () {
    test('largest first', () {
      final totals = totalsByCategory([
        _entry(18400, category: MoneyCategory.eatingOut),
        _entry(32000, category: MoneyCategory.groceries),
        _entry(21000, category: MoneyCategory.bills),
      ]);
      expect(totals, [
        const CategoryTotal(MoneyCategory.groceries, 32000),
        const CategoryTotal(MoneyCategory.bills, 21000),
        const CategoryTotal(MoneyCategory.eatingOut, 18400),
      ]);
    });

    test('adds up the entries of one category', () {
      final totals = totalsByCategory([
        _entry(100, category: MoneyCategory.health),
        _entry(250, category: MoneyCategory.health),
        _entry(50, category: MoneyCategory.health),
      ]);
      expect(totals, [const CategoryTotal(MoneyCategory.health, 400)]);
    });

    test('a tie is broken by the order the categories are declared', () {
      final totals = totalsByCategory([
        _entry(500, category: MoneyCategory.other),
        _entry(500, category: MoneyCategory.gifts),
        _entry(500, category: MoneyCategory.groceries),
        _entry(500, category: MoneyCategory.housing),
      ]);
      expect(totals.map((t) => t.category), [
        MoneyCategory.groceries,
        MoneyCategory.gifts,
        MoneyCategory.housing,
        MoneyCategory.other,
      ]);
    });

    test('the tie-break does not depend on the order of the input', () {
      final a = totalsByCategory([
        _entry(5, category: MoneyCategory.bills),
        _entry(5, category: MoneyCategory.transport),
      ]);
      final b = totalsByCategory([
        _entry(5, category: MoneyCategory.transport),
        _entry(5, category: MoneyCategory.bills),
      ]);
      expect(a, b);
      expect(a.first.category, MoneyCategory.transport);
    });

    test('has no row for a category with nothing spent', () {
      final totals = totalsByCategory([
        _entry(100, category: MoneyCategory.travel),
      ]);
      expect(totals, hasLength(1));
      expect(
        totals.map((t) => t.category),
        isNot(contains(MoneyCategory.groceries)),
      );
    });

    test('nothing in gives nothing out', () {
      expect(totalsByCategory(const []), isEmpty);
    });

    test('all twelve categories can appear', () {
      final totals = totalsByCategory([
        for (final (i, c) in MoneyCategory.values.indexed)
          _entry(1000 + i, category: c),
      ]);
      expect(totals, hasLength(12));
      expect(totals.first.category, MoneyCategory.other);
      expect(totals.last.category, MoneyCategory.groceries);
    });
  });

  group('groupByDay and DayGroup.total', () {
    test('groups neighbours of the same day and keeps the order', () {
      final entries = [
        _entry(4820, date: LocalDate(2026, 10, 2)),
        _entry(450, date: LocalDate(2026, 10, 2)),
        _entry(1200, date: LocalDate(2026, 10, 1)),
        _entry(300, date: LocalDate(2026, 9, 30)),
        _entry(700, date: LocalDate(2026, 9, 30)),
      ];
      final groups = groupByDay(entries);
      expect(groups.map((g) => g.date), [
        LocalDate(2026, 10, 2),
        LocalDate(2026, 10, 1),
        LocalDate(2026, 9, 30),
      ]);
      expect(groups.map((g) => g.entries.length), [2, 1, 2]);
      expect(groups.map((g) => g.total), [5270, 1200, 1000]);
      expect(groups.first.entries.map((e) => e.amountMinor), [4820, 450]);
    });

    test('a day that comes back later is a new group (input is sorted)', () {
      final groups = groupByDay([
        _entry(1, date: LocalDate(2026, 10, 2)),
        _entry(2, date: LocalDate(2026, 10, 1)),
        _entry(3, date: LocalDate(2026, 10, 2)),
      ]);
      expect(groups, hasLength(3));
    });

    test('empty gives no groups', () {
      expect(groupByDay(const []), isEmpty);
    });

    test('one entry gives one group whose total is its amount', () {
      final groups = groupByDay([_entry(999)]);
      expect(groups, hasLength(1));
      expect(groups.single.total, 999);
    });

    test('the day total equals the sum of its rows', () {
      final groups = groupByDay([
        for (var i = 1; i <= 10; i++) _entry(i * 111),
      ]);
      expect(groups.single.total, 111 * 55);
      expect(groups.single.total, totalOf(groups.single.entries));
    });
  });

  group('CategoryTotal', () {
    test('== and hashCode compare category and amount', () {
      expect(
        const CategoryTotal(MoneyCategory.bills, 5),
        const CategoryTotal(MoneyCategory.bills, 5),
      );
      expect(
        const CategoryTotal(MoneyCategory.bills, 5).hashCode,
        const CategoryTotal(MoneyCategory.bills, 5).hashCode,
      );
      expect(
        const CategoryTotal(MoneyCategory.bills, 5),
        isNot(const CategoryTotal(MoneyCategory.bills, 6)),
      );
      expect(
        const CategoryTotal(MoneyCategory.bills, 5),
        isNot(const CategoryTotal(MoneyCategory.gifts, 5)),
      );
    });
  });
}
