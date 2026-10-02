import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../time/local_date.dart';

/// Chọn tag locale để định dạng ngày: giữ vùng của máy (ví dụ `en_GB`) khi
/// cùng ngôn ngữ với app và intl có dữ liệu cho vùng đó.
String formatLocaleTag(Locale appLocale, Locale deviceLocale) {
  if (appLocale.languageCode == deviceLocale.languageCode) {
    final tag = deviceLocale.toString();
    if (DateFormat.localeExists(tag)) return tag;
  }
  return appLocale.languageCode;
}

String formatLocaleOf(BuildContext c) => formatLocaleTag(
  Localizations.localeOf(c),
  View.of(c).platformDispatcher.locale,
);

// DateFormat phải phân tích mẫu mỗi lần tạo, nên giữ lại theo từng tag.
final _monthDay = <String, DateFormat>{};
final _yearMonthDay = <String, DateFormat>{};
final _weekdayMonthDay = <String, DateFormat>{};
final _clock24 = <String, DateFormat>{};
final _clock12 = <String, DateFormat>{};

String formatShortDate(LocalDate d, LocalDate today, String tag) {
  final format = d.year == today.year
      ? _monthDay.putIfAbsent(tag, () => DateFormat.MMMd(tag))
      : _yearMonthDay.putIfAbsent(tag, () => DateFormat.yMMMd(tag));
  return format.format(d.toDateTime());
}

String formatLongDate(LocalDate d, String tag) => _weekdayMonthDay
    .putIfAbsent(tag, () => DateFormat.MMMMEEEEd(tag))
    .format(d.toDateTime());

/// Giờ trong ngày: "20:00" khi [use24h], ngược lại "8:00 PM" (tuỳ locale).
String formatClockTime(DateTime t, String tag, {required bool use24h}) {
  final format = use24h
      ? _clock24.putIfAbsent(tag, () => DateFormat.Hm(tag))
      : _clock12.putIfAbsent(tag, () => DateFormat.jm(tag));
  return format.format(t);
}
