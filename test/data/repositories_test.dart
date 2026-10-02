import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/time/local_date.dart';
import 'package:steady/data/check_in_repository.dart';
import 'package:steady/data/database.dart';
import 'package:steady/data/habit_repository.dart';
import 'package:steady/features/check_in/check_in_rules.dart';

const _family = '👨‍👩‍👧';

void main() {
  late AppDatabase db;
  late DateTime now;
  late Clock clock;
  late HabitRepository habits;
  late CheckInRepository checkIns;
  final today = LocalDate(2026, 10, 2);

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime(2026, 10, 2, 21);
    clock = Clock(() => now);
    habits = HabitRepository(db, clock);
    checkIns = CheckInRepository(db, clock);
  });

  tearDown(() async {
    await db.close();
  });

  Future<List<Habit>> allHabits() => habits.watchHabits().first;
  Future<List<CheckIn>> allCheckIns() => db.select(db.checkIns).get();

  group('HabitRepository.addHabit', () {
    test('stores the normalized name and returns the saved row', () async {
      final habit = await habits.addHabit(
        name: '  No sugar  ',
        cleanSince: LocalDate(2026, 5, 28),
        today: today,
      );
      expect(habit.id, isPositive);
      expect(habit.name, 'No sugar');
      expect(habit.cleanSince, LocalDate(2026, 5, 28));
      expect(habit.createdAt, now);
      final stored = await allHabits();
      expect(stored, hasLength(1));
      expect(stored.single.name, 'No sugar');
      expect(stored.single.cleanSince, LocalDate(2026, 5, 28));
    });

    test('a start date of today is allowed', () async {
      final habit = await habits.addHabit(
        name: 'Today',
        cleanSince: today,
        today: today,
      );
      expect(habit.cleanSince, today);
    });

    test('a 40-grapheme emoji name round-trips intact', () async {
      final name = _family * 40;
      final habit = await habits.addHabit(
        name: name,
        cleanSince: today,
        today: today,
      );
      expect(habit.name, name);
      expect((await allHabits()).single.name, name);
    });

    // Case bắt buộc phải thất bại: đầu vào sai thì repository ném lỗi và
    // không ghi gì xuống DB.
    group('must fail', () {
      for (final entry in {
        'empty name': '',
        'whitespace-only name': '   ',
        'name with a line break': 'a\nb',
        'name with a carriage return': 'a\rb',
        'name longer than 40 graphemes': 'a' * 41,
        'emoji name longer than 40 graphemes': _family * 41,
      }.entries) {
        test('rejects ${entry.key}', () async {
          await expectLater(
            habits.addHabit(name: entry.value, cleanSince: today, today: today),
            throwsArgumentError,
          );
          expect(await allHabits(), isEmpty);
        });
      }

      test('rejects a start date in the future', () async {
        await expectLater(
          habits.addHabit(
            name: 'Future',
            cleanSince: today.addDays(1),
            today: today,
          ),
          throwsArgumentError,
        );
        expect(await allHabits(), isEmpty);
      });
    });
  });

  group('HabitRepository.watchHabits ordering', () {
    test('most days first, i.e. earliest start date first', () async {
      await habits.addHabit(
        name: 'Middle',
        cleanSince: LocalDate(2026, 5, 1),
        today: today,
      );
      await habits.addHabit(
        name: 'Newest',
        cleanSince: LocalDate(2026, 9, 1),
        today: today,
      );
      await habits.addHabit(
        name: 'Oldest',
        cleanSince: LocalDate(2025, 12, 31),
        today: today,
      );
      expect((await allHabits()).map((h) => h.name), [
        'Oldest',
        'Middle',
        'Newest',
      ]);
    });

    test('equal days: the habit created first comes first', () async {
      now = DateTime(2026, 10, 2, 21);
      await habits.addHabit(name: 'Second', cleanSince: today, today: today);
      // Đồng hồ lùi lại nên "First" có createdAt sớm hơn dù id lớn hơn.
      now = DateTime(2026, 10, 2, 20);
      await habits.addHabit(name: 'First', cleanSince: today, today: today);
      expect((await allHabits()).map((h) => h.name), ['First', 'Second']);
    });

    test('equal days and creation time: lower id first', () async {
      await habits.addHabit(name: 'A', cleanSince: today, today: today);
      await habits.addHabit(name: 'B', cleanSince: today, today: today);
      await habits.addHabit(name: 'C', cleanSince: today, today: today);
      expect((await allHabits()).map((h) => h.name), ['A', 'B', 'C']);
    });

    test('the stream emits again after add, reset and delete', () async {
      final emissions = <List<String>>[];
      final sub = habits.watchHabits().listen(
        (list) => emissions.add(list.map((h) => h.name).toList()),
      );
      addTearDown(sub.cancel);
      await pumpEventQueue();
      expect(emissions.last, isEmpty);

      final a = await habits.addHabit(
        name: 'A',
        cleanSince: LocalDate(2026, 1, 1),
        today: today,
      );
      await pumpEventQueue();
      expect(emissions.last, ['A']);

      final b = await habits.addHabit(
        name: 'B',
        cleanSince: LocalDate(2026, 2, 1),
        today: today,
      );
      await pumpEventQueue();
      expect(emissions.last, ['A', 'B']);

      // B đặt lại về hôm nay: vẫn sau A.
      await habits.resetStreak(b.id, today);
      await pumpEventQueue();
      expect(emissions.last, ['A', 'B']);
      // A đặt lại về hôm nay thì B (cùng ngày, tạo sau) vẫn đứng sau A.
      await habits.resetStreak(a.id, today);
      await pumpEventQueue();
      expect(emissions.last, ['A', 'B']);

      await habits.deleteHabit(a.id);
      await pumpEventQueue();
      expect(emissions.last, ['B']);
    });
  });

  group('HabitRepository.resetStreak', () {
    test('moves the start date to today and returns true', () async {
      final habit = await habits.addHabit(
        name: 'No smoking',
        cleanSince: LocalDate(2026, 5, 28),
        today: today,
      );
      final done = await habits.resetStreak(habit.id, today);
      expect(done, isTrue);
      expect((await allHabits()).single.cleanSince, today);
    });

    test('only touches the targeted habit', () async {
      final a = await habits.addHabit(
        name: 'A',
        cleanSince: LocalDate(2026, 1, 1),
        today: today,
      );
      await habits.addHabit(
        name: 'B',
        cleanSince: LocalDate(2026, 2, 1),
        today: today,
      );
      await habits.resetStreak(a.id, today);
      final byName = {for (final h in await allHabits()) h.name: h};
      expect(byName['A']!.cleanSince, today);
      expect(byName['B']!.cleanSince, LocalDate(2026, 2, 1));
    });

    test('an unknown id returns false and does not throw', () async {
      expect(await habits.resetStreak(999, today), isFalse);
    });
  });

  group('HabitRepository.deleteHabit', () {
    test(
      'removes the habit and returns true, then false the second time',
      () async {
        final habit = await habits.addHabit(
          name: 'Gone',
          cleanSince: today,
          today: today,
        );
        expect(await habits.deleteHabit(habit.id), isTrue);
        expect(await allHabits(), isEmpty);
        expect(await habits.deleteHabit(habit.id), isFalse);
      },
    );

    test('an unknown id returns false and keeps other habits', () async {
      await habits.addHabit(name: 'Stays', cleanSince: today, today: today);
      expect(await habits.deleteHabit(999), isFalse);
      expect(await allHabits(), hasLength(1));
    });
  });

  group('CheckInRepository', () {
    final date = LocalDate(2026, 10, 2);

    test('getForDate is null when nothing was saved', () async {
      expect(await checkIns.getForDate(date), isNull);
    });

    test('saves and reads back mood, note and updatedAt', () async {
      await checkIns.saveForDate(
        date: date,
        mood: Mood.good,
        note: '  A calm day  ',
      );
      final saved = (await checkIns.getForDate(date))!;
      expect(saved.date, date);
      expect(saved.mood, 4);
      expect(saved.note, 'A calm day');
      expect(saved.updatedAt, now);
    });

    test('a null, empty or blank note is stored as null', () async {
      await checkIns.saveForDate(date: date, mood: Mood.okay);
      expect((await checkIns.getForDate(date))!.note, isNull);
      await checkIns.saveForDate(date: date, mood: Mood.okay, note: '   ');
      expect((await checkIns.getForDate(date))!.note, isNull);
      await checkIns.saveForDate(date: date, mood: Mood.okay, note: '');
      expect((await checkIns.getForDate(date))!.note, isNull);
    });

    test('a note with line breaks is stored on one line', () async {
      await checkIns.saveForDate(date: date, mood: Mood.low, note: 'a\nb');
      expect((await checkIns.getForDate(date))!.note, 'a b');
    });

    test(
      'saving twice on the same day leaves one row with the new values',
      () async {
        await checkIns.saveForDate(date: date, mood: Mood.low, note: 'first');
        now = DateTime(2026, 10, 2, 22);
        await checkIns.saveForDate(
          date: date,
          mood: Mood.great,
          note: 'second',
        );
        final rows = await allCheckIns();
        expect(rows, hasLength(1));
        expect(rows.single.mood, 5);
        expect(rows.single.note, 'second');
        expect(rows.single.updatedAt, DateTime(2026, 10, 2, 22));
      },
    );

    test('overwriting with no note clears the old note', () async {
      await checkIns.saveForDate(date: date, mood: Mood.low, note: 'first');
      await checkIns.saveForDate(date: date, mood: Mood.low);
      expect((await checkIns.getForDate(date))!.note, isNull);
    });

    test('different days produce separate rows', () async {
      await checkIns.saveForDate(date: date, mood: Mood.low);
      await checkIns.saveForDate(date: date.addDays(1), mood: Mood.great);
      expect(await allCheckIns(), hasLength(2));
      expect((await checkIns.getForDate(date))!.mood, 2);
      expect((await checkIns.getForDate(date.addDays(1)))!.mood, 5);
    });

    test('rapid back-to-back saves still give a single row', () async {
      await Future.wait([
        for (var i = 0; i < 5; i++)
          checkIns.saveForDate(date: date, mood: Mood.good, note: 'n$i'),
      ]);
      expect(await allCheckIns(), hasLength(1));
    });

    test('a 140-grapheme note is accepted', () async {
      await checkIns.saveForDate(
        date: date,
        mood: Mood.good,
        note: _family * 140,
      );
      expect((await checkIns.getForDate(date))!.note, _family * 140);
    });

    // Case bắt buộc phải thất bại.
    group('must fail', () {
      test('a 141-grapheme note throws and writes nothing', () async {
        await expectLater(
          checkIns.saveForDate(date: date, mood: Mood.good, note: 'a' * 141),
          throwsArgumentError,
        );
        expect(await allCheckIns(), isEmpty);
      });

      test('an over-long note does not clobber the existing entry', () async {
        await checkIns.saveForDate(date: date, mood: Mood.low, note: 'keep');
        await expectLater(
          checkIns.saveForDate(date: date, mood: Mood.great, note: 'a' * 141),
          throwsArgumentError,
        );
        final saved = (await checkIns.getForDate(date))!;
        expect(saved.mood, 2);
        expect(saved.note, 'keep');
      });

      test('Mood.fromValue(6) cannot even be built', () {
        expect(() => Mood.fromValue(6), throwsArgumentError);
      });

      test('the DB CHECK constraint rejects mood 6 in raw SQL', () async {
        await expectLater(
          db.customStatement(
            'INSERT INTO check_ins (date, mood, note, updated_at) '
            "VALUES ('2026-10-02', 6, NULL, 0)",
          ),
          throwsA(
            predicate(
              (e) => e.toString().toUpperCase().contains('CHECK'),
              'is a CHECK constraint failure',
            ),
          ),
        );
        expect(await allCheckIns(), isEmpty);
      });

      test('the DB CHECK constraint rejects mood 0 in raw SQL', () async {
        await expectLater(
          db.customStatement(
            'INSERT INTO check_ins (date, mood, note, updated_at) '
            "VALUES ('2026-10-02', 0, NULL, 0)",
          ),
          throwsA(isA<Object>()),
        );
        expect(await allCheckIns(), isEmpty);
      });

      test('raw SQL accepts the boundary moods 1 and 5 (control)', () async {
        await db.customStatement(
          'INSERT INTO check_ins (date, mood, note, updated_at) '
          "VALUES ('2026-10-01', 1, NULL, 0)",
        );
        await db.customStatement(
          'INSERT INTO check_ins (date, mood, note, updated_at) '
          "VALUES ('2026-10-02', 5, NULL, 0)",
        );
        expect(await allCheckIns(), hasLength(2));
      });

      test(
        'the DB rejects a second row for the same date in raw SQL',
        () async {
          await checkIns.saveForDate(date: date, mood: Mood.good);
          await expectLater(
            db.customStatement(
              'INSERT INTO check_ins (date, mood, note, updated_at) '
              "VALUES ('2026-10-02', 3, NULL, 0)",
            ),
            throwsA(isA<Object>()),
          );
          expect(await allCheckIns(), hasLength(1));
        },
      );
    });
  });
}
