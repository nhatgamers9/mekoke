import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:steady/core/format/formatting.dart';
import 'package:steady/core/time/local_date.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('formatLocaleTag', () {
    test('keeps the device region when the language matches', () {
      expect(
        formatLocaleTag(const Locale('en'), const Locale('en', 'GB')),
        'en_GB',
      );
      expect(
        formatLocaleTag(const Locale('en'), const Locale('en', 'US')),
        'en_US',
      );
    });

    test('falls back to the app language for another language', () {
      expect(
        formatLocaleTag(const Locale('en'), const Locale('de', 'DE')),
        'en',
      );
      expect(
        formatLocaleTag(const Locale('en'), const Locale('vi', 'VN')),
        'en',
      );
    });

    test('falls back when intl has no data for the device region', () {
      expect(
        formatLocaleTag(const Locale('en'), const Locale('en', 'ZZ')),
        'en',
      );
    });

    test('same bare language gives the language code', () {
      expect(formatLocaleTag(const Locale('en'), const Locale('en')), 'en');
    });
  });

  group('formatShortDate', () {
    final today = LocalDate(2026, 10, 2);

    test('same year omits the year', () {
      expect(formatShortDate(LocalDate(2026, 5, 28), today, 'en'), 'May 28');
      expect(formatShortDate(LocalDate(2026, 1, 1), today, 'en'), 'Jan 1');
      expect(formatShortDate(today, today, 'en'), 'Oct 2');
    });

    test('a different year includes the year', () {
      expect(
        formatShortDate(LocalDate(2025, 5, 28), today, 'en'),
        'May 28, 2025',
      );
      expect(
        formatShortDate(LocalDate(2025, 12, 31), LocalDate(2026, 1, 1), 'en'),
        'Dec 31, 2025',
      );
    });

    test('follows the device region order for en_GB', () {
      expect(formatShortDate(LocalDate(2026, 5, 28), today, 'en_GB'), '28 May');
      expect(
        formatShortDate(LocalDate(2025, 5, 28), today, 'en_GB'),
        '28 May 2025',
      );
    });
  });

  group('formatLongDate', () {
    test('2026-10-02 is "Friday, October 2"', () {
      expect(formatLongDate(LocalDate(2026, 10, 2), 'en'), 'Friday, October 2');
    });

    test('other weekdays and months', () {
      expect(
        formatLongDate(LocalDate(2026, 10, 3), 'en'),
        'Saturday, October 3',
      );
      expect(
        formatLongDate(LocalDate(2028, 2, 29), 'en'),
        'Tuesday, February 29',
      );
    });
  });

  group('formatClockTime', () {
    // intl chèn U+202F (khoảng trắng hẹp) trước "AM"/"PM": so sau khi đổi về
    // dấu cách thường.
    String plain(String s) => s.replaceAll(RegExp('[\u202f\u00a0]'), ' ');

    test('12-hour clock: 9:00 PM', () {
      expect(
        plain(formatClockTime(DateTime(2026, 10, 2, 21), 'en', use24h: false)),
        '9:00 PM',
      );
      expect(
        plain(
          formatClockTime(DateTime(2026, 10, 3, 7, 5), 'en', use24h: false),
        ),
        '7:05 AM',
      );
    });

    test('12-hour clock: midnight is 12:00 AM and noon is 12:00 PM', () {
      expect(
        plain(formatClockTime(DateTime(2026, 10, 3), 'en', use24h: false)),
        '12:00 AM',
      );
      expect(
        plain(formatClockTime(DateTime(2026, 10, 3, 12), 'en', use24h: false)),
        '12:00 PM',
      );
    });

    test('24-hour clock: 21:00 with two digits for the hour', () {
      expect(
        formatClockTime(DateTime(2026, 10, 2, 21), 'en', use24h: true),
        '21:00',
      );
      expect(
        formatClockTime(DateTime(2026, 10, 3, 7, 5), 'en', use24h: true),
        '07:05',
      );
      expect(
        formatClockTime(DateTime(2026, 10, 3), 'en', use24h: true),
        '00:00',
      );
    });

    test('the same time can be asked in both styles one after the other', () {
      // Hai kiểu định dạng được giữ riêng theo từng tag, không lẫn vào nhau.
      final t = DateTime(2026, 10, 2, 13);
      expect(formatClockTime(t, 'en', use24h: true), '13:00');
      expect(plain(formatClockTime(t, 'en', use24h: false)), '1:00 PM');
      expect(formatClockTime(t, 'en', use24h: true), '13:00');
    });

    test('seconds are not shown', () {
      expect(
        formatClockTime(DateTime(2026, 10, 2, 21, 0, 59), 'en', use24h: true),
        '21:00',
      );
    });
  });
}
