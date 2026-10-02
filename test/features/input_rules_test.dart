import 'package:flutter_test/flutter_test.dart';
import 'package:steady/features/check_in/check_in_rules.dart';
import 'package:steady/features/streaks/habit_name.dart';

const _family = '👨‍👩‍👧'; // 1 grapheme, 8 code units (ZWJ sequence).
const _flag = '🇻🇳'; // 1 grapheme made of two regional indicators.
// "ế" ở dạng tổ hợp: e + dấu mũ + dấu sắc (1 grapheme, 3 code point).
const _viet = 'ế';

void main() {
  group('normalizeHabitName', () {
    test('trims the surrounding whitespace and keeps the inside', () {
      expect(normalizeHabitName('  No sugar  '), 'No sugar');
      expect(normalizeHabitName('\tNo  sugar\t'), 'No  sugar');
    });

    test('empty or whitespace-only is null', () {
      expect(normalizeHabitName(''), isNull);
      expect(normalizeHabitName('   '), isNull);
      expect(normalizeHabitName('\t \t'), isNull);
      expect(normalizeHabitName('\n'), isNull);
      expect(normalizeHabitName(' \r\n '), isNull);
    });

    test('a line break inside the name is rejected', () {
      expect(normalizeHabitName('a\nb'), isNull);
      expect(normalizeHabitName('a\r\nb'), isNull);
      expect(normalizeHabitName('a\rb'), isNull);
    });

    test('exactly 40 characters is valid, 41 is not', () {
      expect(normalizeHabitName('a' * 40), 'a' * 40);
      expect(normalizeHabitName('a' * 41), isNull);
    });

    test('the limit is measured after trimming', () {
      expect(normalizeHabitName('  ${'a' * 40}  '), 'a' * 40);
    });

    test('a ZWJ family emoji counts as one character', () {
      final ok = 'a' * 39 + _family;
      expect(normalizeHabitName(ok), ok);
      expect(normalizeHabitName(_family * 40), _family * 40);
      expect(normalizeHabitName(_family * 41), isNull);
      expect(normalizeHabitName('a' * 40 + _family), isNull);
    });

    test('a flag emoji counts as one character', () {
      expect(normalizeHabitName(_flag * 40), _flag * 40);
      expect(normalizeHabitName(_flag * 41), isNull);
    });

    test('Vietnamese text counts composed and decomposed forms equally', () {
      expect(normalizeHabitName(_viet * 40), _viet * 40);
      expect(normalizeHabitName(_viet * 41), isNull);
      expect(normalizeHabitName('ế' * 40), 'ế' * 40);
      expect(normalizeHabitName('ế' * 41), isNull);
      expect(normalizeHabitName('Không hút thuốc'), 'Không hút thuốc');
    });

    test('kHabitNameMaxChars is 40', () {
      expect(kHabitNameMaxChars, 40);
    });
  });

  group('normalizeCheckInNote', () {
    test('trims and returns the text', () {
      expect(normalizeCheckInNote('  A calm day  '), 'A calm day');
    });

    test('empty or whitespace-only is null', () {
      expect(normalizeCheckInNote(''), isNull);
      expect(normalizeCheckInNote('    '), isNull);
      expect(normalizeCheckInNote('\n'), isNull);
      expect(normalizeCheckInNote('\r\n  \n'), isNull);
    });

    test('each line break becomes one space', () {
      expect(normalizeCheckInNote('a\nb'), 'a b');
      expect(normalizeCheckInNote('a\r\nb'), 'a b');
      expect(normalizeCheckInNote('a\rb'), 'a b');
      expect(normalizeCheckInNote('a\n\nb'), 'a  b');
    });

    test('line breaks at the edges are trimmed away', () {
      expect(normalizeCheckInNote('\nhello\n'), 'hello');
    });

    test('the result never contains a line break', () {
      final result = normalizeCheckInNote('one\ntwo\r\nthree\rfour');
      expect(result, 'one two three four');
      expect(result!.contains(RegExp(r'[\r\n]')), isFalse);
    });

    test('140 characters is valid, 141 throws', () {
      expect(normalizeCheckInNote('a' * 140), 'a' * 140);
      expect(() => normalizeCheckInNote('a' * 141), throwsArgumentError);
    });

    test('the limit is measured after trimming', () {
      expect(normalizeCheckInNote('${'a' * 140}   '), 'a' * 140);
    });

    test('140 grapheme clusters with ZWJ emoji are valid, 141 throws', () {
      expect(normalizeCheckInNote(_family * 140), _family * 140);
      expect(() => normalizeCheckInNote(_family * 141), throwsArgumentError);
      expect(normalizeCheckInNote(_viet * 140), _viet * 140);
      expect(() => normalizeCheckInNote(_viet * 141), throwsArgumentError);
    });

    test('kCheckInNoteMaxChars is 140', () {
      expect(kCheckInNoteMaxChars, 140);
    });
  });

  group('Mood', () {
    test('fromValue maps 1..5 to the moods in order', () {
      expect(Mood.fromValue(1), Mood.awful);
      expect(Mood.fromValue(2), Mood.low);
      expect(Mood.fromValue(3), Mood.okay);
      expect(Mood.fromValue(4), Mood.good);
      expect(Mood.fromValue(5), Mood.great);
      for (final m in Mood.values) {
        expect(Mood.fromValue(m.value), m);
      }
      expect(Mood.values.map((m) => m.value), [1, 2, 3, 4, 5]);
    });

    test('values outside 1..5 throw ArgumentError', () {
      for (final bad in [0, 6, -1, 100]) {
        expect(
          () => Mood.fromValue(bad),
          throwsArgumentError,
          reason: 'Mood.fromValue($bad)',
        );
      }
    });
  });

  group('greetingFor', () {
    Greeting at(int h, int m) => greetingFor(DateTime(2026, 10, 2, h, m));

    test('boundaries from Q9', () {
      expect(at(4, 59), Greeting.evening);
      expect(at(5, 0), Greeting.morning);
      expect(at(11, 59), Greeting.morning);
      expect(at(12, 0), Greeting.afternoon);
      expect(at(17, 59), Greeting.afternoon);
      expect(at(18, 0), Greeting.evening);
    });

    test('midnight and late night are evening', () {
      expect(at(0, 0), Greeting.evening);
      expect(at(23, 59), Greeting.evening);
      expect(at(3, 30), Greeting.evening);
    });
  });
}
