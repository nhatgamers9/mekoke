import 'package:flutter_test/flutter_test.dart';
import 'package:steady/data/money_types.dart';

void main() {
  group('MoneyCategory', () {
    test(
      'the 12 names are stored in the database, so they must not change',
      () {
        expect(MoneyCategory.values.map((c) => c.name), [
          'groceries',
          'eatingOut',
          'transport',
          'bills',
          'shopping',
          'health',
          'gifts',
          'housing',
          'travel',
          'phone',
          'education',
          'other',
        ]);
      },
    );
  });

  group('limits', () {
    test('the biggest amount and the note length', () {
      expect(kMaxAmountMinor, 999999999999);
      expect(kMoneyNoteMaxChars, 60);
    });
  });

  group('normalizeMoneyNote', () {
    test('a plain note is kept', () {
      expect(normalizeMoneyNote('Weekly shop'), 'Weekly shop');
    });

    test('is trimmed', () {
      expect(normalizeMoneyNote('  Weekly shop \t'), 'Weekly shop');
    });

    test('line breaks become single spaces', () {
      expect(normalizeMoneyNote('a\nb'), 'a b');
      expect(normalizeMoneyNote('a\r\nb'), 'a b');
      expect(normalizeMoneyNote('a\rb'), 'a b');
      expect(normalizeMoneyNote('line one\nline two\n'), 'line one line two');
    });

    test('empty and blank notes are null', () {
      expect(normalizeMoneyNote(''), isNull);
      expect(normalizeMoneyNote('   '), isNull);
      expect(normalizeMoneyNote('\n'), isNull);
      expect(normalizeMoneyNote(' \r\n \n '), isNull);
    });

    test('exactly 60 characters is allowed', () {
      final sixty = 'x' * 60;
      expect(normalizeMoneyNote(sixty), sixty);
    });

    test('61 characters throws ArgumentError', () {
      expect(() => normalizeMoneyNote('x' * 61), throwsArgumentError);
    });

    test('is counted in graphemes: 60 emoji families are fine, 61 are not', () {
      const family = '👨‍👩‍👧';
      expect(normalizeMoneyNote(family * 60), family * 60);
      expect(() => normalizeMoneyNote(family * 61), throwsArgumentError);
    });

    test('the length is checked after trimming and joining lines', () {
      // 60 ký tự cộng khoảng trắng hai đầu: vẫn hợp lệ.
      expect(normalizeMoneyNote('  ${'y' * 60}  '), 'y' * 60);
      // Hai dòng 30 + 30 ký tự thành 61 ký tự sau khi nối bằng dấu cách.
      expect(
        () => normalizeMoneyNote('${'a' * 30}\n${'b' * 30}'),
        throwsArgumentError,
      );
    });

    test('keeps unicode text intact', () {
      expect(normalizeMoneyNote('Cà phê sáng ☕'), 'Cà phê sáng ☕');
    });
  });
}
