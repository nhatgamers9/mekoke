import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/format/duration_format.dart';

void main() {
  group('formatHms', () {
    test('zero is 0:00:00', () {
      expect(formatHms(Duration.zero), '0:00:00');
    });

    test('rounds down to the second (59.9 s shows 59)', () {
      expect(formatHms(const Duration(milliseconds: 59900)), '0:00:59');
      expect(formatHms(const Duration(microseconds: 999999)), '0:00:00');
      expect(
        formatHms(const Duration(minutes: 59, seconds: 59, milliseconds: 999)),
        '0:59:59',
      );
    });

    test('the hour has no leading zero and has no upper limit', () {
      expect(formatHms(const Duration(hours: 1)), '1:00:00');
      expect(
        formatHms(const Duration(hours: 9, minutes: 58, seconds: 12)),
        '9:58:12',
      );
      expect(formatHms(const Duration(hours: 25)), '25:00:00');
      expect(
        formatHms(const Duration(hours: 31, minutes: 12, seconds: 5)),
        '31:12:05',
      );
      expect(formatHms(const Duration(hours: 100)), '100:00:00');
    });

    test('a negative value counts as zero', () {
      expect(formatHms(const Duration(seconds: -1)), '0:00:00');
      expect(formatHms(const Duration(hours: -5)), '0:00:00');
    });
  });

  group('formatClock', () {
    test('under one hour it is M:SS', () {
      expect(formatClock(Duration.zero), '0:00');
      expect(formatClock(const Duration(seconds: 10)), '0:10');
      expect(formatClock(const Duration(minutes: 4)), '4:00');
      expect(formatClock(const Duration(minutes: 10)), '10:00');
      expect(formatClock(const Duration(minutes: 59, seconds: 59)), '59:59');
    });

    test('59.9 seconds rounds down', () {
      expect(formatClock(const Duration(milliseconds: 59900)), '0:59');
    });

    test('from one hour on it falls back to H:MM:SS', () {
      expect(formatClock(const Duration(hours: 1)), '1:00:00');
      expect(
        formatClock(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
      expect(formatClock(const Duration(hours: 25)), '25:00:00');
    });

    test('a negative value counts as zero', () {
      expect(formatClock(const Duration(seconds: -30)), '0:00');
      expect(formatClock(const Duration(hours: -2)), '0:00');
    });
  });

  group('ceilSeconds', () {
    test('rounds up: 13.4 s is 14', () {
      expect(ceilSeconds(const Duration(milliseconds: 13400)), 14);
      expect(ceilSeconds(const Duration(milliseconds: 13999)), 14);
      expect(ceilSeconds(const Duration(microseconds: 1)), 1);
      expect(ceilSeconds(const Duration(milliseconds: 59900)), 60);
    });

    test('whole seconds stay as they are', () {
      expect(ceilSeconds(Duration.zero), 0);
      expect(ceilSeconds(const Duration(seconds: 14)), 14);
      expect(ceilSeconds(const Duration(hours: 1)), 3600);
    });

    test('a negative value counts as zero', () {
      expect(ceilSeconds(const Duration(seconds: -5)), 0);
      expect(ceilSeconds(const Duration(milliseconds: -1)), 0);
    });
  });

  group('splitHm', () {
    test('hours, then minutes rounded down and always two digits', () {
      expect(splitHm(const Duration(hours: 6, minutes: 1)), (6, '01'));
      expect(splitHm(const Duration(hours: 16)), (16, '00'));
      expect(splitHm(const Duration(hours: 1, minutes: 59, seconds: 59)), (
        1,
        '59',
      ));
      expect(splitHm(const Duration(milliseconds: 59900)), (0, '00'));
      expect(splitHm(Duration.zero), (0, '00'));
    });

    test('more than a day keeps counting the hours', () {
      expect(splitHm(const Duration(hours: 25, minutes: 5)), (25, '05'));
    });

    test('a negative value counts as zero', () {
      expect(splitHm(const Duration(hours: -3)), (0, '00'));
      expect(splitHm(const Duration(minutes: -1)), (0, '00'));
    });
  });
}
