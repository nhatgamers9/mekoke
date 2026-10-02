import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/format/money_format.dart';
import 'package:steady/data/money_types.dart';
import 'package:steady/features/money/amount_input.dart';

AmountInput _typed(String keys, {int decimals = 2}) {
  var input = AmountInput.empty;
  for (final ch in keys.split('')) {
    input = input.press(ch == '<' ? 'del' : ch, decimals: decimals);
  }
  return input;
}

void main() {
  group('AmountInput.press: the table of section 5.1', () {
    test('a digit with a separator and the fraction full is ignored', () {
      expect(_typed('1.25').press('7', decimals: 2).text, '1.25');
      expect(_typed('1.2').press('7', decimals: 2).text, '1.27');
    });

    test('a digit with a separator and room left is appended', () {
      expect(_typed('12.').press('4', decimals: 2).text, '12.4');
      expect(_typed('0.').press('0', decimals: 2).text, '0.0');
    });

    test('a digit on "0" replaces it; "0" then "0" stays "0"', () {
      expect(_typed('0').press('5', decimals: 2).text, '5');
      expect(_typed('0').press('0', decimals: 2).text, '0');
      expect(_typed('00000').text, '0');
    });

    test('a digit with no separator stops at nine integer digits', () {
      expect(_typed('123456789').text, '123456789');
      expect(_typed('123456789').press('0', decimals: 2).text, '123456789');
      expect(_typed('12345678').press('9', decimals: 2).text, '123456789');
    });

    test('nine integer digits still allow the separator and decimals', () {
      expect(_typed('123456789.99').text, '123456789.99');
      expect(_typed('123456789.999').text, '123456789.99');
    });

    test('a digit otherwise is appended', () {
      expect(AmountInput.empty.press('7', decimals: 2).text, '7');
      expect(_typed('12').press('3', decimals: 2).text, '123');
    });

    test('"." with decimals 0 is ignored', () {
      expect(AmountInput.empty.press('.', decimals: 0).text, '');
      expect(_typed('12', decimals: 0).press('.', decimals: 0).text, '12');
    });

    test('"." when there already is one is ignored', () {
      expect(_typed('1.2').press('.', decimals: 2).text, '1.2');
      expect(_typed('1.').press('.', decimals: 2).text, '1.');
    });

    test('"." on empty gives "0."', () {
      expect(AmountInput.empty.press('.', decimals: 2).text, '0.');
    });

    test('"." otherwise is appended', () {
      expect(_typed('12').press('.', decimals: 2).text, '12.');
      expect(_typed('0').press('.', decimals: 3).text, '0.');
    });

    test('del removes the last character; on empty it stays empty', () {
      expect(_typed('12.4').press('del', decimals: 2).text, '12.');
      expect(_typed('12.').press('del', decimals: 2).text, '12');
      expect(_typed('1').press('del', decimals: 2).text, '');
      expect(AmountInput.empty.press('del', decimals: 2).text, '');
      expect(_typed('<<<').text, '');
    });

    test('a decimals limit of 3 allows three digits after the separator', () {
      expect(_typed('1.2345', decimals: 3).text, '1.234');
    });

    test('a decimals limit of 0 never produces a separator', () {
      expect(_typed('1.2.3', decimals: 0).text, '123');
    });
  });

  group('AmountInput.press must fail on a bad key', () {
    for (final bad in ['a', '', '12', '-', ',', 'DEL', ' ']) {
      test('"$bad" throws ArgumentError', () {
        expect(
          () => AmountInput.empty.press(bad, decimals: 2),
          throwsArgumentError,
        );
      });
    }
  });

  group('AmountInput.toMinor', () {
    test('empty is 0', () {
      expect(AmountInput.empty.toMinor(2), 0);
      expect(AmountInput.empty.toMinor(0), 0);
    });

    test('"12." with 2 decimals is 1200', () {
      expect(_typed('12.').toMinor(2), 1200);
    });

    test('"12.4" with 2 decimals is 1240', () {
      expect(_typed('12.4').toMinor(2), 1240);
    });

    test('"0.05" with 2 decimals is 5', () {
      expect(_typed('0.05').toMinor(2), 5);
    });

    test('"0." and "0.00" are 0 (Save stays off)', () {
      expect(_typed('0.').toMinor(2), 0);
      expect(_typed('0.00').toMinor(2), 0);
      expect(_typed('0').toMinor(2), 0);
    });

    test('JPY (0 decimals): "1235" is 1235', () {
      expect(_typed('1235', decimals: 0).toMinor(0), 1235);
    });

    test('KWD (3 decimals): "1.5" is 1500', () {
      expect(_typed('1.5', decimals: 3).toMinor(3), 1500);
    });

    test('the biggest input of each currency fits the repository limit', () {
      // 9 chữ số phần nguyên; KWD (3 chữ số thập phân) chạm đúng kMaxAmountMinor.
      expect(_typed('999999999.99').toMinor(2), 99999999999);
      expect(_typed('999999999', decimals: 0).toMinor(0), 999999999);
      final kwd = _typed('999999999.999', decimals: 3).toMinor(3);
      expect(kwd, kMaxAmountMinor);
      expect(kwd, lessThanOrEqualTo(kMaxAmountMinor));
    });
  });

  group('AmountInput.fromMinor', () {
    test('(1240, 2) is "12.40"', () {
      expect(AmountInput.fromMinor(1240, 2).text, '12.40');
    });

    test('(5, 2) is "0.05"', () {
      expect(AmountInput.fromMinor(5, 2).text, '0.05');
    });

    test('(100, 2) is "1.00"; (1200, 0) is "1200"', () {
      expect(AmountInput.fromMinor(100, 2).text, '1.00');
      expect(AmountInput.fromMinor(1200, 0).text, '1200');
    });

    test('(1, 3) is "0.001"', () {
      expect(AmountInput.fromMinor(1, 3).text, '0.001');
    });

    test('zero and negative amounts give empty', () {
      expect(AmountInput.fromMinor(0, 2), AmountInput.empty);
      expect(AmountInput.fromMinor(-5, 2), AmountInput.empty);
      expect(AmountInput.fromMinor(0, 2).isEmpty, isTrue);
    });

    test('a value read back through toMinor round-trips', () {
      for (final minor in [1, 5, 99, 100, 1240, 123456, 99999999999]) {
        expect(AmountInput.fromMinor(minor, 2).toMinor(2), minor);
      }
      expect(AmountInput.fromMinor(4200, 0).toMinor(0), 4200);
      expect(AmountInput.fromMinor(1500, 3).toMinor(3), 1500);
    });

    test('an edited amount can be typed on: "12.40" then del', () {
      expect(
        AmountInput.fromMinor(1240, 2).press('del', decimals: 2).text,
        '12.4',
      );
    });
  });

  group('AmountInput value semantics', () {
    test('== and hashCode follow the text', () {
      expect(_typed('12.4'), _typed('12.4'));
      expect(_typed('12.4').hashCode, _typed('12.4').hashCode);
      expect(_typed('12.4'), isNot(_typed('12.40')));
    });

    test('flags describe the text', () {
      final input = _typed('12.4');
      expect(input.isEmpty, isFalse);
      expect(input.hasSeparator, isTrue);
      expect(input.fractionDigits, 1);
      expect(_typed('12').hasSeparator, isFalse);
      expect(_typed('12').fractionDigits, 0);
      expect(_typed('12.').fractionDigits, 0);
      expect(AmountInput.empty.isEmpty, isTrue);
    });
  });

  // Chuỗi phím ngẫu nhiên (hạt giống cố định): dù bấm gì, số gõ ra vẫn hợp lệ,
  // không bao giờ vượt giới hạn của repository.
  group('any key sequence stays valid', () {
    const keys = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.', 'del'];
    for (final decimals in [0, 2, 3]) {
      test('$decimals decimals, 3000 random presses', () {
        final random = Random(20261002 + decimals);
        // "", "0", "12", "12.", "12.4": không số 0 đứng đầu, tối đa 9 chữ số
        // phần nguyên, tối đa `decimals` chữ số thập phân, không có dấu '.' trần.
        final shape = decimals == 0
            ? RegExp(r'^(0|[1-9]\d{0,8})?$')
            : RegExp('^((0|[1-9]\\d{0,8})(\\.\\d{0,$decimals})?)?\$');
        var input = AmountInput.empty;
        for (var i = 0; i < 3000; i++) {
          input = input.press(
            keys[random.nextInt(keys.length)],
            decimals: decimals,
          );
          expect(
            shape.hasMatch(input.text),
            isTrue,
            reason: '"${input.text}" after $i presses',
          );
          final minor = input.toMinor(decimals);
          expect(minor, greaterThanOrEqualTo(0));
          expect(minor, lessThanOrEqualTo(kMaxAmountMinor));
        }
      });
    }
  });

  group('formatAmountInput (en_US / USD)', () {
    final usd = MoneyFormat('en_US', 'USD');

    test('empty shows "\$0"', () {
      expect(formatAmountInput(usd, AmountInput.empty), r'$0');
    });

    test('"12" shows "\$12"', () {
      expect(formatAmountInput(usd, _typed('12')), r'$12');
    });

    test('"12." shows "\$12."', () {
      expect(formatAmountInput(usd, _typed('12.')), r'$12.');
    });

    test('"12.4" shows "\$12.4"', () {
      expect(formatAmountInput(usd, _typed('12.4')), r'$12.4');
    });

    test('"12.40" shows "\$12.40"', () {
      expect(formatAmountInput(usd, _typed('12.40')), r'$12.40');
    });

    test('"0." shows "\$0."', () {
      expect(formatAmountInput(usd, _typed('0.')), r'$0.');
    });

    test('grouping separators appear as the number grows', () {
      expect(formatAmountInput(usd, _typed('1234')), r'$1,234');
      expect(
        formatAmountInput(usd, _typed('123456789.99')),
        r'$123,456,789.99',
      );
    });

    test('typing a number key by key never shows a wrong amount', () {
      final shown = [
        for (final keys in ['1', '12', '12.', '12.4', '12.40'])
          formatAmountInput(usd, _typed(keys)),
      ];
      expect(shown, [r'$1', r'$12', r'$12.', r'$12.4', r'$12.40']);
    });
  });

  group('formatAmountInput in other currencies', () {
    test(
      'de / EUR: the separator goes after the last digit, before the sign',
      () {
        final eur = MoneyFormat('de', 'EUR');
        expect(
          formatAmountInput(eur, _typed('12.')).replaceAll(' ', ' '),
          '12, €',
        );
        expect(
          formatAmountInput(eur, _typed('12.4')).replaceAll(' ', ' '),
          '12,4 €',
        );
        expect(
          formatAmountInput(eur, _typed('12.40')).replaceAll(' ', ' '),
          '12,40 €',
        );
        expect(
          formatAmountInput(eur, AmountInput.empty).replaceAll(' ', ' '),
          '0 €',
        );
      },
    );

    test('ja / JPY: no decimals at all', () {
      final jpy = MoneyFormat('en', 'JPY');
      expect(formatAmountInput(jpy, _typed('1235', decimals: 0)), '¥1,235');
      expect(formatAmountInput(jpy, AmountInput.empty), '¥0');
    });
  });
}
