import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:steady/core/format/formatting.dart';
import 'package:steady/core/format/money_format.dart';
import 'package:steady/core/format/region_currency.dart';
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

    group('the region of the phone wins over its language', () {
      const cases = <String, String>{
        // Giữ nguyên như trước khi có bảng theo vùng.
        'en_US': 'USD',
        'de_DE': 'EUR',
        'ja_JP': 'JPY',
        'vi_VN': 'VND',
        'en_GB': 'GBP',
        'bg_BG': 'EUR',
        'xx': 'USD',
        'xx_YY': 'USD',
        // Vùng thắng ngôn ngữ.
        'es_AR': 'ARS',
        'es_CO': 'COP',
        'ar_SA': 'SAR',
        'en_PH': 'PHP',
        'en_VN': 'VND',
        'fr_MA': 'MAD',
        'ru_KZ': 'KZT',
        // Có script: bỏ qua script, nhận cả "-" lẫn "_".
        'zh_Hant_TW': 'TWD',
        'zh-Hant-TW': 'TWD',
        // intl một mình ra USD hoặc EUR cho ba tag này, nên chỉ đúng khi bỏ
        // qua script để tới được vùng.
        'en_Latn_VN': 'VND',
        'es_Latn_AR': 'ARS',
        'en-Latn-PH': 'PHP',
        // Nhận "-"; vùng viết thường được đổi sang in hoa.
        'es-AR': 'ARS',
        'en_vn': 'VND',
        'en-vn': 'VND',
        // Không có vùng: dùng intl theo ngôn ngữ.
        'en': 'USD',
        'de': 'EUR',
      };

      cases.forEach((tag, currency) {
        test('$tag gives $currency', () {
          expect(MoneyFormat.currencyForLocale(tag), currency);
        });
      });
    });

    group('a region with several currencies gets its own', () {
      // Quy tắc của bảng: nếu đúng một mã bắt đầu bằng mã vùng thì lấy mã đó
      // (LS: LSL, NA: NAD; Babel trả ZAR trước, vì ZAR có `from` 1961, sớm hơn
      // LSL 1980 và NAD 1993); không mã nào bắt đầu bằng mã vùng thì lấy mã có
      // `from` sớm nhất (PS: ILS 1985, không phải JOD 1996). ZW là ngoại lệ:
      // bị ghi đè ra USD (USD 2009, ZWG 2024), xem chú thích của
      // `kRegionCurrency`.
      const cases = <String, String>{
        'en_BT': 'BTN',
        'en_HT': 'HTG',
        'en_LS': 'LSL',
        'en_NA': 'NAD',
        'en_PA': 'PAB',
        'en_PS': 'ILS',
        'en_ZW': 'USD',
      };

      cases.forEach((tag, currency) {
        test('$tag gives $currency', () {
          expect(MoneyFormat.currencyForLocale(tag), currency);
        });
      });

      test('a language that has its own region does not leak in', () {
        // ar_PS: tiếng Ả Rập, nhưng máy ở Palestine; en-ZW: ZW bị ghi đè ra
        // USD, nhận cả "-".
        expect(MoneyFormat.currencyForLocale('ar_PS'), 'ILS');
        expect(MoneyFormat.currencyForLocale('en-ZW'), 'USD');
      });
    });

    group('a region with no currency in circulation', () {
      // AQ (Nam Cực) và ZZ (vùng không xác định) không có ứng viên nên bị bỏ
      // khỏi bảng; ca này bị "từ chối" ở bước tra bảng và rơi về USD.
      for (final region in ['AQ', 'ZZ']) {
        test('$region is not in kRegionCurrency', () {
          expect(kRegionCurrency.containsKey(region), isFalse);
        });

        test('en_$region still gives USD instead of failing', () {
          expect(MoneyFormat.currencyForLocale('en_$region'), 'USD');
        });
      }

      test('a replaced region code is not in the table either', () {
        for (final region in [
          'BU',
          'CP',
          'CS',
          'DD',
          'SU',
          'TP',
          'YD',
          'YU',
          'ZR',
        ]) {
          expect(kRegionCurrency.containsKey(region), isFalse, reason: region);
          expect(
            MoneyFormat.currencyForLocale('en_$region'),
            'USD',
            reason: region,
          );
        }
      });
    });

    group('a tag without a usable region falls back to the old logic', () {
      test('the empty string gives USD, as before', () {
        expect(MoneyFormat.currencyForLocale(''), 'USD');
      });

      test('a script alone is not taken for a region', () {
        // "Latn" có 4 chữ cái: là script, không phải vùng. Kết quả là của
        // intl theo ngôn ngữ, giống hệt khi không có script.
        expect(
          MoneyFormat.currencyForLocale('sr_Latn'),
          MoneyFormat.currencyForLocale('sr'),
        );
        expect(MoneyFormat.currencyForLocale('en_Latn'), 'USD');
        expect(MoneyFormat.currencyForLocale('de_Latn'), 'EUR');
      });

      test('a tag with a suffix after the region does not throw', () {
        for (final tag in [
          'en_US.UTF-8',
          'en_US_POSIX',
          'en-u-nu-latn',
          'en_',
          'en__VN',
          '_',
          '-',
          'x',
          'toolongregion_toolongregion',
        ]) {
          expect(
            MoneyFormat.currencyForLocale(tag),
            matches(RegExp(r'^[A-Z]{3}$')),
            reason: tag,
          );
        }
      });

      test('a number region is not in the table: en_419 gives USD', () {
        expect(kRegionCurrency.containsKey('419'), isFalse);
        expect(MoneyFormat.currencyForLocale('en_419'), 'USD');
      });

      test('es_419 is left to intl, as before the table existed', () {
        // Không khẳng định USD: intl cho es_419 một đồng riêng của nó.
        expect(
          MoneyFormat.currencyForLocale('es_419'),
          NumberFormat.simpleCurrency(locale: 'es_419').currencyName,
        );
      });

      test('a lower-case key is not found: the table is upper case only', () {
        expect(kRegionCurrency['vn'], isNull);
        expect(kRegionCurrency['VN'], 'VND');
      });
    });
  });

  group('kRegionCurrency', () {
    final keyShape = RegExp(r'^[A-Z]{2}$');
    final codeShape = RegExp(r'^[A-Z]{3}$');

    test('every key is a two-letter upper-case region code', () {
      for (final region in kRegionCurrency.keys) {
        expect(region, matches(keyShape), reason: region);
      }
    });

    test('every value is a three-letter upper-case code and never XXX', () {
      // loadCurrency ghi đè giá trị không khớp ^[A-Z]{3}$; XXX là "không có
      // tiền tệ".
      for (final entry in kRegionCurrency.entries) {
        expect(entry.value, matches(codeShape), reason: entry.key);
        expect(entry.value, isNot('XXX'), reason: entry.key);
      }
    });

    test('has more than 200 entries', () {
      expect(kRegionCurrency.length, greaterThan(200));
    });

    test('has the entries the plan names', () {
      expect(kRegionCurrency['AR'], 'ARS');
      expect(kRegionCurrency['CO'], 'COP');
      expect(kRegionCurrency['SA'], 'SAR');
      expect(kRegionCurrency['PH'], 'PHP');
      expect(kRegionCurrency['VN'], 'VND');
      expect(kRegionCurrency['MA'], 'MAD');
      expect(kRegionCurrency['KZ'], 'KZT');
      expect(kRegionCurrency['TW'], 'TWD');
      expect(kRegionCurrency['US'], 'USD');
      expect(kRegionCurrency['DE'], 'EUR');
      expect(kRegionCurrency['JP'], 'JPY');
      expect(kRegionCurrency['GB'], 'GBP');
      // Hai ghi đè. Xoá hẳn dòng BG hoặc ZW thì bg_BG và en_ZW vẫn ra EUR, USD
      // nhờ intl; chỉ hai dòng này bắt được lỗi đó.
      expect(kRegionCurrency['BG'], 'EUR');
      expect(kRegionCurrency['ZW'], 'USD');
    });

    test('no code has more than 3 decimals', () {
      for (final entry in kRegionCurrency.entries) {
        expect(
          MoneyFormat.decimalsFor(entry.value),
          lessThanOrEqualTo(3),
          reason: '${entry.key} -> ${entry.value}',
        );
      }
    });

    test('every currency formats an amount without throwing', () {
      // CLDR có thể mới hơn intl 0.20.3: mỗi mã trong bảng phải định dạng được.
      for (final entry in kRegionCurrency.entries) {
        final f = MoneyFormat('en', entry.value);
        expect(
          f.format(1240),
          isNotEmpty,
          reason: '${entry.key} -> ${entry.value}',
        );
        expect(
          f.format(kMaxAmountMinor),
          isNotEmpty,
          reason: '${entry.key} -> ${entry.value}',
        );
      }
    });

    test('currencyForLocale returns the entry of en_<region>', () {
      for (final entry in kRegionCurrency.entries) {
        expect(
          MoneyFormat.currencyForLocale('en_${entry.key}'),
          entry.value,
          reason: entry.key,
        );
      }
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
