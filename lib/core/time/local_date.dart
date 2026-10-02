import 'package:flutter/foundation.dart';

/// Một ngày theo lịch (năm, tháng, ngày), không có giờ và múi giờ.
/// Mọi phép đếm ngày đi qua [epochDay] để không bị lệch bởi giờ mùa hè.
@immutable
class LocalDate implements Comparable<LocalDate> {
  LocalDate(this.year, this.month, this.day) {
    final check = DateTime.utc(year, month, day);
    if (check.year != year || check.month != month || check.day != day) {
      throw ArgumentError('Not a real date: $year-$month-$day');
    }
  }

  factory LocalDate.fromDateTime(DateTime dt) {
    final local = dt.isUtc ? dt.toLocal() : dt;
    return LocalDate(local.year, local.month, local.day);
  }

  factory LocalDate.parse(String iso) {
    final match = _isoPattern.firstMatch(iso);
    if (match == null) {
      throw FormatException('Expected YYYY-MM-DD', iso);
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    try {
      return LocalDate(year, month, day);
    } on ArgumentError {
      throw FormatException('Not a real date', iso);
    }
  }

  static final _isoPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final int year;
  final int month;
  final int day;

  int get epochDay =>
      DateTime.utc(year, month, day).millisecondsSinceEpoch ~/ 86400000;

  int daysUntil(LocalDate other) => other.epochDay - epochDay;

  LocalDate addDays(int days) {
    final moved = DateTime.utc(year, month, day + days);
    return LocalDate(moved.year, moved.month, moved.day);
  }

  DateTime toDateTime() => DateTime(year, month, day);

  String toIso() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  bool isBefore(LocalDate other) => compareTo(other) < 0;

  bool isAfter(LocalDate other) => compareTo(other) > 0;

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}
