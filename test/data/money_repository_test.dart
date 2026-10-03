import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/time/local_date.dart';
import 'package:steady/data/database.dart';
import 'package:steady/data/money_repository.dart';
import 'package:steady/data/money_types.dart';

const _family = '👨‍👩‍👧';

void main() {
  late AppDatabase db;
  late DateTime now;
  late MoneyRepository money;
  final today = LocalDate(2026, 10, 2);

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime(2026, 10, 2, 21);
    money = MoneyRepository(db, Clock(() => now));
  });

  tearDown(() async {
    await db.close();
  });

  Future<List<MoneyEntry>> all() => money.watchAll().first;

  Future<MoneyEntry> addOn(
    LocalDate date, {
    int amount = 100,
    MoneyCategory category = MoneyCategory.groceries,
    String? note,
  }) => money.add(
    amountMinor: amount,
    category: category,
    date: date,
    note: note,
  );

  group('add', () {
    test('stores the row and returns it', () async {
      final entry = await money.add(
        amountMinor: 1240,
        category: MoneyCategory.eatingOut,
        date: today,
        note: 'Lunch',
      );
      expect(entry.id, isPositive);
      expect(entry.amountMinor, 1240);
      expect(entry.category, MoneyCategory.eatingOut);
      expect(entry.date, today);
      expect(entry.note, 'Lunch');
      expect(entry.createdAt, now);
      final stored = await all();
      expect(stored, [entry]);
    });

    test('createdAt is the clock at the moment of saving', () async {
      final first = await addOn(today);
      now = DateTime(2026, 10, 2, 22, 15, 30);
      final second = await addOn(today);
      expect(first.createdAt, DateTime(2026, 10, 2, 21));
      expect(second.createdAt, DateTime(2026, 10, 2, 22, 15, 30));
    });

    test('a note of null stays null', () async {
      final entry = await addOn(today);
      expect(entry.note, isNull);
      expect((await all()).single.note, isNull);
    });

    test('the note is stored normalized', () async {
      final entry = await addOn(today, note: '  Weekly\nshop  ');
      expect(entry.note, 'Weekly shop');
      expect((await all()).single.note, 'Weekly shop');
    });

    test('a blank note is stored as null', () async {
      expect((await addOn(today, note: '   ')).note, isNull);
      expect((await addOn(today, note: '\n')).note, isNull);
      expect((await all()).map((e) => e.note), [null, null]);
    });

    test('a note of exactly 60 characters is kept', () async {
      final note = 'n' * 60;
      expect((await addOn(today, note: note)).note, note);
    });

    test('a 60-grapheme emoji note round-trips intact', () async {
      final note = _family * 60;
      expect((await addOn(today, note: note)).note, note);
      expect((await all()).single.note, note);
    });

    test('the amount limits are accepted: 1 and kMaxAmountMinor', () async {
      expect((await addOn(today, amount: 1)).amountMinor, 1);
      expect(
        (await addOn(today, amount: kMaxAmountMinor)).amountMinor,
        kMaxAmountMinor,
      );
      expect(await all(), hasLength(2));
    });

    test('every category survives a round trip', () async {
      for (final c in MoneyCategory.values) {
        await addOn(today, category: c);
      }
      final stored = await all();
      expect(
        stored.map((e) => e.category).toSet(),
        MoneyCategory.values.toSet(),
      );
    });

    test('the category is saved by name and the date as ISO text', () async {
      await addOn(LocalDate(2026, 3, 5), category: MoneyCategory.eatingOut);
      final row = await db
          .customSelect('SELECT category, date FROM money_entries')
          .getSingle();
      expect(row.read<String>('category'), 'eatingOut');
      expect(row.read<String>('date'), '2026-03-05');
    });

    test('a date in the past and the leap day are kept', () async {
      expect(
        (await addOn(LocalDate(2025, 12, 31))).date,
        LocalDate(2025, 12, 31),
      );
      expect(
        (await addOn(LocalDate(2028, 2, 29))).date,
        LocalDate(2028, 2, 29),
      );
    });

    test('two quick adds make two rows with different ids', () async {
      final both = await Future.wait([addOn(today), addOn(today)]);
      expect(both[0].id, isNot(both[1].id));
      expect(await all(), hasLength(2));
    });

    // Cases phải thất bại: đầu vào sai thì ném lỗi và không ghi gì.
    group('must fail', () {
      for (final (name, amount) in [
        ('zero', 0),
        ('negative', -1),
        ('very negative', -999999),
        ('one over kMaxAmountMinor', kMaxAmountMinor + 1),
        ('far over kMaxAmountMinor', kMaxAmountMinor * 10),
      ]) {
        test(
          'an amount that is $name throws ArgumentError, nothing stored',
          () async {
            await expectLater(
              addOn(today, amount: amount),
              throwsArgumentError,
            );
            expect(await all(), isEmpty);
          },
        );
      }

      test(
        'a note of 61 characters throws ArgumentError, nothing stored',
        () async {
          await expectLater(addOn(today, note: 'n' * 61), throwsArgumentError);
          expect(await all(), isEmpty);
        },
      );

      test('61 emoji graphemes throw even though 60 are fine', () async {
        await expectLater(
          addOn(today, note: _family * 61),
          throwsArgumentError,
        );
        expect(await all(), isEmpty);
      });

      test('a bad add does not disturb the rows already saved', () async {
        final good = await addOn(today, amount: 500);
        await expectLater(addOn(today, amount: 0), throwsArgumentError);
        expect(await all(), [good]);
      });

      test(
        'a database that rejects the write throws and stores nothing',
        () async {
          await db.customStatement(
            'CREATE TRIGGER fail_insert BEFORE INSERT ON money_entries '
            "BEGIN SELECT RAISE(ABORT, 'simulated write failure'); END;",
          );
          await expectLater(addOn(today), throwsA(anything));
          expect(await all(), isEmpty);
        },
      );
    });
  });

  group('update', () {
    test('rewrites the four fields and returns true', () async {
      final entry = await addOn(
        today,
        amount: 1240,
        category: MoneyCategory.groceries,
        note: 'Old',
      );
      final ok = await money.update(
        entry.id,
        amountMinor: 999,
        category: MoneyCategory.transport,
        date: LocalDate(2026, 10, 1),
        note: 'New',
      );
      expect(ok, isTrue);
      final stored = (await all()).single;
      expect(stored.id, entry.id);
      expect(stored.amountMinor, 999);
      expect(stored.category, MoneyCategory.transport);
      expect(stored.date, LocalDate(2026, 10, 1));
      expect(stored.note, 'New');
    });

    test('keeps createdAt even when the clock has moved on', () async {
      final entry = await addOn(today);
      now = DateTime(2026, 11, 20, 8);
      await money.update(
        entry.id,
        amountMinor: 200,
        category: MoneyCategory.bills,
        date: today,
      );
      expect((await all()).single.createdAt, DateTime(2026, 10, 2, 21));
    });

    test('a null note clears the note', () async {
      final entry = await addOn(today, note: 'Something');
      await money.update(
        entry.id,
        amountMinor: 100,
        category: MoneyCategory.groceries,
        date: today,
      );
      expect((await all()).single.note, isNull);
    });

    test('the note is normalized here too', () async {
      final entry = await addOn(today);
      await money.update(
        entry.id,
        amountMinor: 100,
        category: MoneyCategory.groceries,
        date: today,
        note: '  a\nb ',
      );
      expect((await all()).single.note, 'a b');
    });

    test('only the asked row changes', () async {
      final a = await addOn(today, amount: 100);
      final b = await addOn(today, amount: 200);
      await money.update(
        a.id,
        amountMinor: 111,
        category: MoneyCategory.groceries,
        date: today,
      );
      final byId = {for (final e in await all()) e.id: e};
      expect(byId[a.id]!.amountMinor, 111);
      expect(byId[b.id], b);
    });

    test('an id that does not exist gives false and writes nothing', () async {
      final entry = await addOn(today);
      final ok = await money.update(
        entry.id + 100,
        amountMinor: 5,
        category: MoneyCategory.gifts,
        date: today,
      );
      expect(ok, isFalse);
      expect(await all(), [entry]);
    });

    test('updating a row that was deleted gives false', () async {
      final entry = await addOn(today);
      await money.delete(entry.id);
      final ok = await money.update(
        entry.id,
        amountMinor: 5,
        category: MoneyCategory.gifts,
        date: today,
      );
      expect(ok, isFalse);
      expect(await all(), isEmpty);
    });

    group('must fail', () {
      for (final (name, amount) in [
        ('zero', 0),
        ('negative', -50),
        ('over kMaxAmountMinor', kMaxAmountMinor + 1),
      ]) {
        test(
          'an amount that is $name throws and the row is unchanged',
          () async {
            final entry = await addOn(today, amount: 777, note: 'keep');
            await expectLater(
              money.update(
                entry.id,
                amountMinor: amount,
                category: MoneyCategory.other,
                date: LocalDate(2026, 1, 1),
                note: 'changed',
              ),
              throwsArgumentError,
            );
            expect(await all(), [entry]);
          },
        );
      }

      test('a note of 61 characters throws and the row is unchanged', () async {
        final entry = await addOn(today, amount: 777);
        await expectLater(
          money.update(
            entry.id,
            amountMinor: 1,
            category: MoneyCategory.other,
            date: today,
            note: 'n' * 61,
          ),
          throwsArgumentError,
        );
        expect(await all(), [entry]);
      });

      test(
        'a bad amount on a missing id still throws, it does not say false',
        () async {
          await expectLater(
            money.update(
              999,
              amountMinor: 0,
              category: MoneyCategory.other,
              date: today,
            ),
            throwsArgumentError,
          );
        },
      );

      test(
        'a database that rejects the write throws and the row is unchanged',
        () async {
          final entry = await addOn(today, amount: 321);
          await db.customStatement(
            'CREATE TRIGGER fail_update BEFORE UPDATE ON money_entries '
            "BEGIN SELECT RAISE(ABORT, 'simulated write failure'); END;",
          );
          await expectLater(
            money.update(
              entry.id,
              amountMinor: 1,
              category: MoneyCategory.other,
              date: today,
            ),
            throwsA(anything),
          );
          expect(await all(), [entry]);
        },
      );
    });
  });

  group('delete', () {
    test('removes the row and returns true', () async {
      final entry = await addOn(today);
      expect(await money.delete(entry.id), isTrue);
      expect(await all(), isEmpty);
    });

    test('leaves the other rows alone', () async {
      final a = await addOn(today, amount: 1);
      final b = await addOn(today, amount: 2);
      await money.delete(a.id);
      expect(await all(), [b]);
    });

    test('an id that does not exist gives false', () async {
      final entry = await addOn(today);
      expect(await money.delete(entry.id + 5), isFalse);
      expect(await all(), [entry]);
    });

    test('deleting twice: true, then false', () async {
      final entry = await addOn(today);
      expect(await money.delete(entry.id), isTrue);
      expect(await money.delete(entry.id), isFalse);
    });

    test(
      'a database that rejects the delete throws and keeps the row',
      () async {
        final entry = await addOn(today);
        await db.customStatement(
          'CREATE TRIGGER fail_delete BEFORE DELETE ON money_entries '
          "BEGIN SELECT RAISE(ABORT, 'simulated write failure'); END;",
        );
        await expectLater(money.delete(entry.id), throwsA(anything));
        expect(await all(), [entry]);
      },
    );
  });

  group(
    'order of the streams: date, then createdAt, then id (all newest first)',
    () {
      test('a later date comes first even if it was saved earlier', () async {
        final older = await addOn(LocalDate(2026, 10, 1));
        now = DateTime(2026, 10, 2, 22);
        final newer = await addOn(LocalDate(2026, 9, 1));
        final first = await addOn(LocalDate(2026, 10, 2));
        expect((await all()).map((e) => e.id), [first.id, older.id, newer.id]);
      });

      test('the same date: the later createdAt comes first', () async {
        final a = await addOn(today);
        now = DateTime(2026, 10, 2, 22);
        final b = await addOn(today);
        now = DateTime(2026, 10, 2, 23);
        final c = await addOn(today);
        expect((await all()).map((e) => e.id), [c.id, b.id, a.id]);
      });

      test(
        'the same date and the same createdAt: the higher id comes first',
        () async {
          final a = await addOn(today);
          final b = await addOn(today);
          final c = await addOn(today);
          expect((await all()).map((e) => e.id), [c.id, b.id, a.id]);
        },
      );

      test(
        'a createdAt that is earlier but the date is later: the date wins',
        () async {
          now = DateTime(2026, 10, 2, 23);
          final lateSaveOldDate = await addOn(LocalDate(2026, 9, 30));
          now = DateTime(2026, 10, 2, 8);
          final earlySaveNewDate = await addOn(LocalDate(2026, 10, 1));
          expect((await all()).map((e) => e.id), [
            earlySaveNewDate.id,
            lateSaveOldDate.id,
          ]);
        },
      );

      test(
        'dates compare as dates, not as numbers: Oct 9 after Oct 10 is older',
        () async {
          final nine = await addOn(LocalDate(2026, 10, 9));
          final ten = await addOn(LocalDate(2026, 10, 10));
          expect((await all()).map((e) => e.id), [ten.id, nine.id]);
        },
      );

      test('a later year wins over a later month', () async {
        final y2025 = await addOn(LocalDate(2025, 12, 31));
        final y2026 = await addOn(LocalDate(2026, 1, 1));
        expect((await all()).map((e) => e.id), [y2026.id, y2025.id]);
      });

      test('watchBetween and watchRecent use the same order', () async {
        final a = await addOn(LocalDate(2026, 10, 1));
        final b = await addOn(LocalDate(2026, 10, 2));
        final c = await addOn(LocalDate(2026, 10, 2));
        final want = [c.id, b.id, a.id];
        expect((await money.watchRecent().first).map((e) => e.id), want);
        expect(
          (await money
                  .watchBetween(LocalDate(2026, 10, 1), LocalDate(2026, 10, 31))
                  .first)
              .map((e) => e.id),
          want,
        );
      });
    },
  );

  group('watchRecent', () {
    test('gives five by default, newest first', () async {
      for (var d = 1; d <= 8; d++) {
        await addOn(LocalDate(2026, 9, d), amount: d);
      }
      final recent = await money.watchRecent().first;
      expect(recent, hasLength(5));
      expect(recent.map((e) => e.amountMinor), [8, 7, 6, 5, 4]);
    });

    test('gives what there is when there are fewer than the limit', () async {
      await addOn(today);
      await addOn(today);
      expect(await money.watchRecent().first, hasLength(2));
    });

    test('empty when there is nothing', () async {
      expect(await money.watchRecent().first, isEmpty);
    });

    test('a custom limit is honoured', () async {
      for (var i = 0; i < 4; i++) {
        await addOn(today);
      }
      expect(await money.watchRecent(limit: 2).first, hasLength(2));
      expect(await money.watchRecent(limit: 10).first, hasLength(4));
    });

    test(
      'a row saved last but dated long ago is not among the recent five',
      () async {
        for (var d = 1; d <= 5; d++) {
          await addOn(LocalDate(2026, 10, d));
        }
        // Một khoản nhập sau cùng nhưng ngày rất cũ: không vào 5 dòng gần nhất.
        final old = await addOn(LocalDate(2020, 1, 1));
        expect(
          (await money.watchRecent().first).map((e) => e.id),
          isNot(contains(old.id)),
        );
      },
    );
  });

  group('watchBetween', () {
    final from = LocalDate(2026, 10, 1);
    final to = LocalDate(2026, 10, 31);

    test('includes both ends', () async {
      final first = await addOn(from);
      final last = await addOn(to);
      final rows = await money.watchBetween(from, to).first;
      expect(rows.map((e) => e.id), containsAll([first.id, last.id]));
    });

    test('excludes the day before and the day after', () async {
      await addOn(LocalDate(2026, 9, 30));
      await addOn(LocalDate(2026, 11, 1));
      final inside = await addOn(LocalDate(2026, 10, 15));
      final rows = await money.watchBetween(from, to).first;
      expect(rows.map((e) => e.id), [inside.id]);
    });

    test('a one-day range gives only that day', () async {
      await addOn(LocalDate(2026, 10, 1));
      final hit = await addOn(LocalDate(2026, 10, 2));
      await addOn(LocalDate(2026, 10, 3));
      final rows = await money.watchBetween(today, today).first;
      expect(rows.map((e) => e.id), [hit.id]);
    });

    test('a range across the new year works', () async {
      await addOn(LocalDate(2025, 11, 30));
      final dec = await addOn(LocalDate(2025, 12, 1));
      final jan = await addOn(LocalDate(2026, 1, 31));
      await addOn(LocalDate(2026, 2, 1));
      final rows = await money
          .watchBetween(LocalDate(2025, 12, 1), LocalDate(2026, 1, 31))
          .first;
      expect(rows.map((e) => e.id), [jan.id, dec.id]);
    });

    test('two months at once, the way the Money tab asks for them', () async {
      final sep1 = await addOn(LocalDate(2026, 9, 1));
      final oct31 = await addOn(LocalDate(2026, 10, 31));
      await addOn(LocalDate(2026, 8, 31));
      await addOn(LocalDate(2026, 11, 1));
      final rows = await money
          .watchBetween(LocalDate(2026, 9, 1), LocalDate(2026, 10, 31))
          .first;
      expect(rows.map((e) => e.id), [oct31.id, sep1.id]);
    });

    test('a leap-day end is included', () async {
      final leap = await addOn(LocalDate(2028, 2, 29));
      await addOn(LocalDate(2028, 3, 1));
      final rows = await money
          .watchBetween(LocalDate(2028, 2, 1), LocalDate(2028, 2, 29))
          .first;
      expect(rows.map((e) => e.id), [leap.id]);
    });

    test('an empty range (from after to) gives nothing', () async {
      await addOn(today);
      final rows = await money.watchBetween(to, from).first;
      expect(rows, isEmpty);
    });

    test('it is not fooled by a single-digit month or day', () async {
      // So chuỗi ISO có đệm số 0: 2026-02-09 phải nằm trong [2026-02-01, 2026-02-28].
      final hit = await addOn(LocalDate(2026, 2, 9));
      final rows = await money
          .watchBetween(LocalDate(2026, 2, 1), LocalDate(2026, 2, 28))
          .first;
      expect(rows.map((e) => e.id), [hit.id]);
    });
  });

  group('streams react to changes', () {
    test('watchAll emits again after add, update and delete', () async {
      final seen = <List<int>>[];
      final sub = money.watchAll().listen(
        (rows) => seen.add([for (final r in rows) r.amountMinor]),
      );
      addTearDown(sub.cancel);
      Future<void> settleStream() => Future<void>.delayed(Duration.zero);

      await settleStream();
      final entry = await addOn(today, amount: 100);
      await settleStream();
      await money.update(
        entry.id,
        amountMinor: 250,
        category: MoneyCategory.groceries,
        date: today,
      );
      await settleStream();
      await money.delete(entry.id);
      await settleStream();

      expect(seen.first, isEmpty);
      expect(seen.where((s) => s.isNotEmpty), contains(equals([100])));
      expect(seen.where((s) => s.isNotEmpty), contains(equals([250])));
      expect(seen.last, isEmpty);
    });

    test(
      'watchBetween ignores rows outside its range but sees those inside',
      () async {
        final seen = <int>[];
        final sub = money
            .watchBetween(LocalDate(2026, 10, 1), LocalDate(2026, 10, 31))
            .listen((rows) => seen.add(rows.length));
        addTearDown(sub.cancel);
        await Future<void>.delayed(Duration.zero);

        await addOn(LocalDate(2026, 8, 1));
        await Future<void>.delayed(Duration.zero);
        expect(seen.last, 0);

        await addOn(LocalDate(2026, 10, 5));
        await Future<void>.delayed(Duration.zero);
        expect(seen.last, 1);
      },
    );
  });
}
