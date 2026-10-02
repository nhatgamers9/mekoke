import 'package:flutter/foundation.dart';

import '../../core/time/local_date.dart';
import '../../data/database.dart';
import '../../data/money_types.dart';

/// Hai đầu của một khoảng ngày, gồm cả hai đầu.
typedef DateRange = (LocalDate, LocalDate);

/// Ngày đầu và ngày cuối của tháng chứa [d].
DateRange monthRange(LocalDate d) {
  final lastDay = DateTime.utc(d.year, d.month + 1, 0).day;
  return (LocalDate(d.year, d.month, 1), LocalDate(d.year, d.month, lastDay));
}

/// Ngày đầu của tháng trước tháng chứa [d]. Tháng 1 thì lùi sang tháng 12
/// năm trước.
LocalDate previousMonth(LocalDate d) => d.month == 1
    ? LocalDate(d.year - 1, 12, 1)
    : LocalDate(d.year, d.month - 1, 1);

bool inRange(LocalDate d, DateRange r) => !d.isBefore(r.$1) && !d.isAfter(r.$2);

int totalOf(Iterable<MoneyEntry> entries) =>
    entries.fold(0, (sum, e) => sum + e.amountMinor);

@immutable
class CategoryTotal {
  const CategoryTotal(this.category, this.amount);

  final MoneyCategory category;
  final int amount;

  @override
  bool operator ==(Object other) =>
      other is CategoryTotal &&
      other.category == category &&
      other.amount == amount;

  @override
  int get hashCode => Object.hash(category, amount);

  @override
  String toString() => 'CategoryTotal(${category.name}, $amount)';
}

/// Chỉ gồm danh mục có tổng lớn hơn 0. Tổng giảm dần; bằng nhau thì theo thứ
/// tự khai báo của [MoneyCategory].
List<CategoryTotal> totalsByCategory(Iterable<MoneyEntry> entries) {
  final sums = <MoneyCategory, int>{};
  for (final e in entries) {
    sums[e.category] = (sums[e.category] ?? 0) + e.amountMinor;
  }
  return [
    for (final MapEntry(:key, :value) in sums.entries)
      if (value > 0) CategoryTotal(key, value),
  ]..sort((a, b) {
    final byAmount = b.amount.compareTo(a.amount);
    return byAmount != 0
        ? byAmount
        : a.category.index.compareTo(b.category.index);
  });
}

/// Các khoản của một ngày.
@immutable
class DayGroup {
  const DayGroup(this.date, this.entries);

  final LocalDate date;
  final List<MoneyEntry> entries;

  int get total => totalOf(entries);
}

/// Giữ thứ tự đầu vào, gom các dòng liền nhau cùng ngày.
List<DayGroup> groupByDay(List<MoneyEntry> sorted) {
  final groups = <DayGroup>[];
  for (final e in sorted) {
    if (groups.isNotEmpty && groups.last.date == e.date) {
      groups.last.entries.add(e);
    } else {
      groups.add(DayGroup(e.date, [e]));
    }
  }
  return groups;
}
