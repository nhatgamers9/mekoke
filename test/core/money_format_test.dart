import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:steady/core/format/formatting.dart';
import 'package:steady/core/format/money_format.dart';
import 'package:steady/core/time/local_date.dart';
import 'package:steady/data/money_types.dart';

import '../helpers/timer_helpers.dart' show plain;

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('MoneyFormat en_US / USD', () {
    final usd = MoneyFormat('en_US', 'USD');

    test('has 2 decimals and a "." separator', () {
      expect(usd.decimals, 2);
      expect(usd.decimalSeparator, '.');
      expect(usd.currencyCode, 'USD');
    });

    test('format shows the symbol and exactly 2 decimals', () {
      expect(usd.format(1240), r'$12.40');
      expect(usd.format(0), r'$0.00');
      expect(usd.format(5), r'$0.05');
      expect(usd.format(100), r'$1.00');
      expect(usd.format(99999999999), r'$999,999,999.99');
    });

    test('the repository limit still formats cleanly', () {
      expect(usd.format(kMaxAmountMinor), r'$9,999,999,999.99');
    });

    test('never adds a sign', () {
      expect(usd.format(1240), isNot(contains('-')));
      expect(usd.format(1240), isNot(contains('−')));
    });

    test('formatScaled keeps exactly the digits asked for', () {
      expect(usd.formatScaled(0, 0), r'$0');
      expect(usd.formatScaled(12, 0), r'$12');
      expect(usd.formatScaled(124, 1), r'$12.4');
      expect(usd.formatScaled(1240, 2), r'$12.40');
      expect(usd.formatScaled(1234, 0), r'$1,234');
    });
  });

  group('MoneyFormat JPY', () {
    final jpy = MoneyFormat('en_US', 'JPY');

    test('decimalsFor is 0 and the amount is whole yen', () {
      expect(MoneyFormat.decimalsFor('JPY'), 0);
      expect(jpy.decimals, 0);
      expect(jpy.format(1235), '¥1,235');
      expect(jpy.format(0), '¥0');
      expect(jpy.format(1), '¥1');
    });

    test('a very large amount does not lose digits', () {
      expect(jpy.format(kMaxAmountMinor), '¥999,999,999,999');
    });
  });

  group('MoneyFormat de / EUR', () {
    final eur = MoneyFormat('de', 'EUR');

    test('writes "12,40 €" (after the no-break space is normalized)', () {
      expect(plain(eur.format(1240)), '12,40 €');
      expect(plain(eur.format(0)), '0,00 €');
      expect(plain(eur.format(123456)), '1.234,56 €');
    });

    test('the decimal separator is a comma', () {
      expect(eur.decimalSeparator, ',');
      expect(eur.decimals, 2);
    });

    test('the same amount in en_US / EUR keeps the euro sign in front', () {
      expect(MoneyFormat('en_US', 'EUR').format(1240), '€12.40');
    });
  });

  group('MoneyFormat decimals and fallbacks', () {
    test('decimalsFor: USD 2, EUR 2, JPY 0, KWD 3', () {
      expect(MoneyFormat.decimalsFor('USD'), 2);
      expect(MoneyFormat.decimalsFor('EUR'), 2);
      expect(MoneyFormat.decimalsFor('JPY'), 0);
      expect(MoneyFormat.decimalsFor('KWD'), 3);
    });

    test('KWD formats 3 decimals', () {
      final kwd = MoneyFormat('en_US', 'KWD');
      expect(kwd.decimals, 3);
      expect(plain(kwd.format(1500)), contains('1.500'));
      expect(kwd.format(kMaxAmountMinor), contains('999,999,999.999'));
    });

    test('an unknown locale tag falls back to English numbers', () {
      final f = MoneyFormat('xx_YY', 'USD');
      expect(f.format(123456), r'$1,234.56');
      expect(f.decimalSeparator, '.');
    });

    test('the same (locale, currency) gives the same object', () {
      expect(
        identical(MoneyFormat('en_US', 'USD'), MoneyFormat('en_US', 'USD')),
        isTrue,
      );
      expect(
        identical(MoneyFormat('en_US', 'USD'), MoneyFormat('en_US', 'EUR')),
        isFalse,
      );
      expect(
        identical(MoneyFormat('en_US', 'USD'), MoneyFormat('de', 'USD')),
        isFalse,
      );
    });
  });

  group('MoneyFormat.currencyForLocale', () {
    test('en_US gives USD', () {
      expect(MoneyFormat.currencyForLocale('en_US'), 'USD');
    });

    test('de_DE gives EUR', () {
      expect(MoneyFormat.currencyForLocale('de_DE'), 'EUR');
    });

    test('ja_JP gives JPY', () {
      expect(MoneyFormat.currencyForLocale('ja_JP'), 'JPY');
    });

    test('an unknown locale gives USD', () {
      expect(MoneyFormat.currencyForLocale('xx'), 'USD');
      expect(MoneyFormat.currencyForLocale('xx_YY'), 'USD');
    });

    test('a locale the app has no texts for still gets its own currency', () {
      // vi_VN: app chỉ có `en`, nhưng đồng của máy vẫn là VND, không phải USD.
      expect(MoneyFormat.currencyForLocale('vi_VN'), 'VND');
    });
  });

  group('formatMonth', () {
    test('English month names', () {
      expect(formatMonth(LocalDate(2026, 10, 2), 'en'), 'October');
      expect(formatMonth(LocalDate(2026, 1, 31), 'en'), 'January');
      expect(formatMonth(LocalDate(2026, 12, 1), 'en'), 'December');
      expect(formatMonth(LocalDate(2028, 2, 29), 'en'), 'February');
    });

    test('follows the locale tag', () {
      expect(formatMonth(LocalDate(2026, 10, 2), 'de'), 'Oktober');
      expect(formatMonth(LocalDate(2026, 10, 2), 'en_GB'), 'October');
    });

    test('does not depend on the day of the month', () {
      for (var day = 1; day <= 31; day++) {
        expect(formatMonth(LocalDate(2026, 10, day), 'en'), 'October');
      }
    });
  });
}
