import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/time/local_date.dart';

void main() {
  group('LocalDate.parse', () {
    test('accepts valid ISO dates', () {
      final d = LocalDate.parse('2026-10-02');
      expect((d.year, d.month, d.day), (2026, 10, 2));
      expect(LocalDate.parse('2026-01-01'), LocalDate(2026, 1, 1));
      expect(LocalDate.parse('2026-12-31'), LocalDate(2026, 12, 31));
    });

    test('leap years are computed correctly', () {
      expect(LocalDate.parse('2028-02-29'), LocalDate(2028, 2, 29));
      expect(LocalDate.parse('2000-02-29'), LocalDate(2000, 2, 29));
      expect(() => LocalDate.parse('2026-02-29'), throwsFormatException);
      expect(() => LocalDate.parse('2100-02-29'), throwsFormatException);
      expect(() => LocalDate.parse('1900-02-29'), throwsFormatException);
    });

    test('rejects the invalid strings named in the plan', () {
      for (final bad in ['2026-02-30', '2026-13-01', '26-1-1', '']) {
        expect(
          () => LocalDate.parse(bad),
          throwsFormatException,
          reason: 'should reject "$bad"',
        );
      }
    });

    test('rejects other malformed strings', () {
      for (final bad in [
        '2026-1-1',
        '2026-10-2',
        '2026-00-10',
        '2026-10-00',
        '2026-10-32',
        '2026-04-31',
        '2026/10/02',
        '20261002',
        ' 2026-10-02',
        '2026-10-02 ',
        '2026-10-02\n',
        '2026-10-02T00:00:00',
        '+2026-10-02',
        'abcd-ef-gh',
      ]) {
        expect(
          () => LocalDate.parse(bad),
          throwsFormatException,
          reason: 'should reject "$bad"',
        );
      }
    });

    test('toIso round-trips through parse and pads with zeros', () {
      expect(LocalDate(2026, 1, 2).toIso(), '2026-01-02');
      expect(LocalDate(2026, 10, 2).toString(), '2026-10-02');
      for (final d in [
        LocalDate(2026, 10, 2),
        LocalDate(2028, 2, 29),
        LocalDate(1999, 12, 31),
        LocalDate(2026, 1, 1),
      ]) {
        expect(LocalDate.parse(d.toIso()), d);
      }
    });
  });

  group('LocalDate constructor', () {
    test('rejects dates that do not exist', () {
      expect(() => LocalDate(2026, 2, 30), throwsArgumentError);
      expect(() => LocalDate(2026, 2, 29), throwsArgumentError);
      expect(() => LocalDate(2026, 4, 31), throwsArgumentError);
      expect(() => LocalDate(2026, 13, 1), throwsArgumentError);
      expect(() => LocalDate(2026, 0, 1), throwsArgumentError);
      expect(() => LocalDate(2026, 1, 0), throwsArgumentError);
      expect(() => LocalDate(2026, 1, 32), throwsArgumentError);
    });

    test('accepts the last day of each month', () {
      expect(LocalDate(2026, 1, 31).day, 31);
      expect(LocalDate(2026, 4, 30).day, 30);
      expect(LocalDate(2028, 2, 29).day, 29);
      expect(LocalDate(2026, 2, 28).day, 28);
    });
  });

  group('LocalDate day counting', () {
    test('2028-02-28 to 2028-03-01 is 2 days (leap year)', () {
      expect(LocalDate(2028, 2, 28).daysUntil(LocalDate(2028, 3, 1)), 2);
    });

    test('2026-02-28 to 2026-03-01 is 1 day (non-leap year)', () {
      expect(LocalDate(2026, 2, 28).daysUntil(LocalDate(2026, 3, 1)), 1);
    });

    test('daylight-saving switches still count as exactly 1 day', () {
      // Mỹ: giờ mùa hè bắt đầu 2026-03-08, kết thúc 2026-11-01.
      expect(LocalDate(2026, 3, 8).daysUntil(LocalDate(2026, 3, 9)), 1);
      expect(LocalDate(2026, 11, 1).daysUntil(LocalDate(2026, 11, 2)), 1);
      // Châu Âu: 2026-03-29 và 2026-10-25.
      expect(LocalDate(2026, 3, 29).daysUntil(LocalDate(2026, 3, 30)), 1);
      expect(LocalDate(2026, 10, 25).daysUntil(LocalDate(2026, 10, 26)), 1);
      // Cả quãng dài đi qua cả hai lần đổi giờ.
      expect(LocalDate(2026, 3, 1).daysUntil(LocalDate(2026, 12, 1)), 275);
    });

    test('the plan example: 2026-05-28 to 2026-10-02 is 127 days', () {
      expect(LocalDate(2026, 5, 28).daysUntil(LocalDate(2026, 10, 2)), 127);
    });

    test('daysUntil is zero for the same day and negative backwards', () {
      final d = LocalDate(2026, 10, 2);
      expect(d.daysUntil(d), 0);
      expect(LocalDate(2026, 10, 3).daysUntil(d), -1);
    });

    test('crossing a year boundary', () {
      expect(LocalDate(2025, 12, 31).daysUntil(LocalDate(2026, 1, 1)), 1);
    });

    test('epochDay is anchored on 1970-01-01', () {
      expect(LocalDate(1970, 1, 1).epochDay, 0);
      expect(LocalDate(1970, 1, 2).epochDay, 1);
      expect(LocalDate(1969, 12, 31).epochDay, -1);
    });

    test('addDays handles month, year, leap day and negative offsets', () {
      expect(LocalDate(2028, 2, 28).addDays(1), LocalDate(2028, 2, 29));
      expect(LocalDate(2028, 2, 28).addDays(2), LocalDate(2028, 3, 1));
      expect(LocalDate(2026, 12, 31).addDays(1), LocalDate(2027, 1, 1));
      expect(LocalDate(2026, 3, 1).addDays(-1), LocalDate(2026, 2, 28));
      expect(LocalDate(2026, 3, 8).addDays(1), LocalDate(2026, 3, 9));
      expect(LocalDate(2026, 10, 2).addDays(0), LocalDate(2026, 10, 2));
      final start = LocalDate(2026, 10, 2);
      expect(start.daysUntil(start.addDays(365)), 365);
      expect(start.daysUntil(start.addDays(-400)), -400);
    });
  });

  group('LocalDate.fromDateTime', () {
    test('uses the calendar date at 23:59:59 and at 00:00:00', () {
      expect(
        LocalDate.fromDateTime(DateTime(2026, 10, 2, 23, 59, 59)),
        LocalDate(2026, 10, 2),
      );
      expect(
        LocalDate.fromDateTime(DateTime(2026, 10, 2, 23, 59, 59, 999, 999)),
        LocalDate(2026, 10, 2),
      );
      expect(
        LocalDate.fromDateTime(DateTime(2026, 10, 3, 0, 0, 0)),
        LocalDate(2026, 10, 3),
      );
      expect(
        LocalDate.fromDateTime(DateTime(2026, 10, 2, 0, 0, 0)),
        LocalDate(2026, 10, 2),
      );
    });

    test('a UTC DateTime is converted to local time first', () {
      final utc = DateTime.utc(2026, 10, 2, 23, 30);
      final local = utc.toLocal();
      expect(
        LocalDate.fromDateTime(utc),
        LocalDate(local.year, local.month, local.day),
      );
    });

    test('toDateTime and fromDateTime round-trip every day of a year', () {
      var d = LocalDate(2026, 1, 1);
      for (var i = 0; i < 365; i++) {
        expect(LocalDate.fromDateTime(d.toDateTime()), d);
        d = d.addDays(1);
      }
      expect(d, LocalDate(2027, 1, 1));
    });

    test('toDateTime is local midnight', () {
      final dt = LocalDate(2026, 10, 2).toDateTime();
      expect(dt.isUtc, isFalse);
      expect((dt.year, dt.month, dt.day), (2026, 10, 2));
    });
  });

  group('LocalDate ordering and equality', () {
    test('isBefore, isAfter and compareTo agree', () {
      final a = LocalDate(2026, 10, 2);
      final b = LocalDate(2026, 10, 3);
      expect(a.isBefore(b), isTrue);
      expect(b.isAfter(a), isTrue);
      expect(a.isAfter(b), isFalse);
      expect(a.isBefore(a), isFalse);
      expect(a.isAfter(a), isFalse);
      expect(a.compareTo(b), isNegative);
      expect(b.compareTo(a), isPositive);
      expect(a.compareTo(LocalDate(2026, 10, 2)), 0);
      expect(LocalDate(2025, 12, 31).isBefore(LocalDate(2026, 1, 1)), isTrue);
    });

    test('equal dates have equal hash codes and can key a set', () {
      expect(LocalDate(2026, 10, 2), LocalDate(2026, 10, 2));
      expect(LocalDate(2026, 10, 2).hashCode, LocalDate(2026, 10, 2).hashCode);
      expect(LocalDate(2026, 10, 2) == LocalDate(2026, 10, 3), isFalse);
      expect({LocalDate(2026, 10, 2), LocalDate(2026, 10, 2)}.length, 1);
    });

    test('sorting a list orders chronologically', () {
      final dates = [
        LocalDate(2026, 10, 2),
        LocalDate(2025, 1, 1),
        LocalDate(2026, 2, 28),
      ]..sort();
      expect(dates, [
        LocalDate(2025, 1, 1),
        LocalDate(2026, 2, 28),
        LocalDate(2026, 10, 2),
      ]);
    });
  });
}
