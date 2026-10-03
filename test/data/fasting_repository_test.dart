import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/data/database.dart';
import 'package:steady/data/fasting_repository.dart';
import 'package:steady/features/timer/fasting_plan.dart';

void main() {
  late AppDatabase db;
  late DateTime now;
  late Clock clock;
  late FastingRepository fasts;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime(2026, 10, 2, 21);
    clock = Clock(() => now);
    fasts = FastingRepository(db, clock);
  });

  tearDown(() async {
    await db.close();
  });

  Future<List<Fast>> allRows() => db.select(db.fasts).get();

  group('truncateToSecond', () {
    test('drops milliseconds and microseconds, keeps everything else', () {
      expect(
        truncateToSecond(DateTime(2026, 10, 2, 21, 5, 7, 999, 999)),
        DateTime(2026, 10, 2, 21, 5, 7),
      );
      expect(
        truncateToSecond(DateTime(2026, 10, 2, 21, 5, 7, 1)),
        DateTime(2026, 10, 2, 21, 5, 7),
      );
    });

    test('a whole second stays as it is', () {
      final t = DateTime(2026, 10, 2, 21);
      expect(truncateToSecond(t), t);
    });
  });

  group('FastingRepository.start', () {
    test('stores the plan, the goal in minutes and the start time', () async {
      final fast = await fasts.start(FastingPlan.h16);
      expect(fast.id, isPositive);
      expect(fast.plan, FastingPlan.h16);
      expect(fast.goalMinutes, 960);
      expect(fast.startedAt, now);
      expect(fast.endedAt, isNull);
      expect(await allRows(), [fast]);
    });

    test('the goal follows the plan: 16, 18, 20 hours and OMAD 23', () async {
      for (final (plan, minutes) in [
        (FastingPlan.h16, 960),
        (FastingPlan.h18, 1080),
        (FastingPlan.h20, 1200),
        (FastingPlan.omad, 1380),
      ]) {
        final fast = await fasts.start(plan);
        expect(fast.goalMinutes, minutes, reason: '$plan');
        expect((await fasts.end(fast.id)), isTrue);
      }
    });

    test('the start time drops the milliseconds', () async {
      now = DateTime(2026, 10, 2, 21, 0, 0, 789, 123);
      final fast = await fasts.start(FastingPlan.h16);
      expect(fast.startedAt, DateTime(2026, 10, 2, 21));
      expect((await allRows()).single.startedAt, DateTime(2026, 10, 2, 21));
    });

    test('the plan is stored by name (the saved format)', () async {
      await fasts.start(FastingPlan.omad);
      final rows = await db.customSelect('SELECT plan FROM fasts').get();
      expect(rows.single.read<String>('plan'), 'omad');
    });

    // Case bắt buộc phải thất bại: đang có lần nhịn chạy thì không bắt đầu
    // thêm được.
    group('must fail', () {
      test('start while a fast is running throws StateError', () async {
        final first = await fasts.start(FastingPlan.h16);

        await expectLater(
          fasts.start(FastingPlan.h16),
          throwsA(isA<StateError>()),
        );
        await expectLater(
          fasts.start(FastingPlan.omad),
          throwsStateError,
          reason: 'a different plan does not get around it',
        );

        // Không ghi gì thêm, lần nhịn đầu vẫn nguyên.
        expect(await allRows(), [first]);
      });

      test(
        'two starts at the same moment: one wins, one gets StateError',
        () async {
          final results = await Future.wait([
            fasts
                .start(FastingPlan.h16)
                .then<Object>((f) => f, onError: (Object e) => e),
            fasts
                .start(FastingPlan.h18)
                .then<Object>((f) => f, onError: (Object e) => e),
          ]);

          expect(results.whereType<Fast>(), hasLength(1));
          expect(results.whereType<StateError>(), hasLength(1));
          expect(await allRows(), hasLength(1));
        },
      );

      test('a goal of zero minutes is refused by the database', () async {
        await expectLater(
          db
              .into(db.fasts)
              .insert(
                FastsCompanion.insert(
                  plan: FastingPlan.h16,
                  goalMinutes: 0,
                  startedAt: now,
                ),
              ),
          throwsA(anything),
        );
        expect(await allRows(), isEmpty);
      });
    });

    test('after the running fast ends a new one can start', () async {
      final first = await fasts.start(FastingPlan.h16);
      expect(await fasts.end(first.id), isTrue);
      now = now.add(const Duration(hours: 1));
      final second = await fasts.start(FastingPlan.h18);
      expect(second.id, isNot(first.id));
      expect(await allRows(), hasLength(2));
    });
  });

  group('FastingRepository.end', () {
    test('sets endedAt to now and returns true', () async {
      final fast = await fasts.start(FastingPlan.h16);
      now = DateTime(2026, 10, 3, 13, 0, 0, 456);

      expect(await fasts.end(fast.id), isTrue);

      final stored = (await allRows()).single;
      expect(stored.endedAt, DateTime(2026, 10, 3, 13));
      expect(stored.startedAt, fast.startedAt);
      expect(stored.plan, fast.plan);
      expect(stored.goalMinutes, fast.goalMinutes);
    });

    test('a second end returns false and changes nothing', () async {
      final fast = await fasts.start(FastingPlan.h16);
      now = DateTime(2026, 10, 3, 13);
      expect(await fasts.end(fast.id), isTrue);
      final before = (await allRows()).single;

      now = DateTime(2026, 10, 3, 15);
      expect(await fasts.end(fast.id), isFalse);

      expect((await allRows()).single, before);
      expect(before.endedAt, DateTime(2026, 10, 3, 13));
    });

    test(
      'an id that does not exist returns false and does not throw',
      () async {
        expect(await fasts.end(999), isFalse);
        final fast = await fasts.start(FastingPlan.h16);
        expect(await fasts.end(fast.id + 1), isFalse);
        expect((await allRows()).single.endedAt, isNull);
      },
    );

    test('a clock set before startedAt cannot end before it started', () async {
      final fast = await fasts.start(FastingPlan.h16);
      now = fast.startedAt.subtract(const Duration(hours: 3));

      expect(await fasts.end(fast.id), isTrue);

      final stored = (await allRows()).single;
      expect(stored.endedAt, fast.startedAt);
      expect(stored.endedAt!.isBefore(stored.startedAt), isFalse);
    });

    test('ending at the same second it started is allowed', () async {
      final fast = await fasts.start(FastingPlan.h16);
      expect(await fasts.end(fast.id), isTrue);
      expect((await allRows()).single.endedAt, fast.startedAt);
    });

    test('only the fast with that id is ended', () async {
      final first = await fasts.start(FastingPlan.h16);
      now = now.add(const Duration(hours: 17));
      await fasts.end(first.id);
      final second = await fasts.start(FastingPlan.h18);

      expect(await fasts.end(first.id), isFalse);
      final rows = {for (final r in await allRows()) r.id: r};
      expect(rows[first.id]!.endedAt, isNotNull);
      expect(rows[second.id]!.endedAt, isNull);
    });
  });

  group('FastingRepository.watchActive', () {
    test('emits null when nothing is running', () async {
      expect(await fasts.watchActive().first, isNull);
    });

    test('follows start and end', () async {
      final emitted = <Fast?>[];
      final sub = fasts.watchActive().listen(emitted.add);
      await pumpEventQueue();
      expect(emitted, [null]);

      final fast = await fasts.start(FastingPlan.h16);
      await pumpEventQueue();
      expect(emitted.last, fast);

      now = now.add(const Duration(hours: 16));
      await fasts.end(fast.id);
      await pumpEventQueue();
      expect(emitted.last, isNull);
      await sub.cancel();
    });

    test('ignores fasts that have already ended', () async {
      final fast = await fasts.start(FastingPlan.h16);
      await fasts.end(fast.id);
      expect(await fasts.watchActive().first, isNull);
    });
  });

  group('FastingRepository.watchEnded', () {
    Future<Fast> fastEndedAt(DateTime start, DateTime end) async {
      now = start;
      final fast = await fasts.start(FastingPlan.h16);
      now = end;
      await fasts.end(fast.id);
      return fast;
    }

    test('is empty with no fasts or only a running one', () async {
      expect(await fasts.watchEnded().first, isEmpty);
      await fasts.start(FastingPlan.h16);
      expect(await fasts.watchEnded().first, isEmpty);
    });

    test('lists the ended fasts, the one that ended last first', () async {
      final a = await fastEndedAt(
        DateTime(2026, 9, 28, 20),
        DateTime(2026, 9, 29, 12),
      );
      final b = await fastEndedAt(
        DateTime(2026, 9, 30, 20),
        DateTime(2026, 10, 1, 12),
      );
      final c = await fastEndedAt(
        DateTime(2026, 9, 29, 20),
        DateTime(2026, 9, 30, 12),
      );

      final ended = await fasts.watchEnded().first;
      expect(ended.map((f) => f.id), [b.id, c.id, a.id]);
    });

    test('equal end times: the newer row comes first', () async {
      final end = DateTime(2026, 10, 1, 12);
      final a = await fastEndedAt(DateTime(2026, 9, 30, 20), end);
      final b = await fastEndedAt(DateTime(2026, 9, 30, 21), end);

      final ended = await fasts.watchEnded().first;
      expect(ended.map((f) => f.id), [b.id, a.id]);
    });

    test('does not include the running fast', () async {
      final done = await fastEndedAt(
        DateTime(2026, 9, 30, 20),
        DateTime(2026, 10, 1, 12),
      );
      now = DateTime(2026, 10, 2, 21);
      await fasts.start(FastingPlan.h16);

      final ended = await fasts.watchEnded().first;
      expect(ended.map((f) => f.id), [done.id]);
    });

    test('is not limited to a few rows', () async {
      for (var i = 0; i < 40; i++) {
        await fastEndedAt(
          DateTime(2026, 8, 1, 20).add(Duration(days: i)),
          DateTime(2026, 8, 2, 12).add(Duration(days: i)),
        );
      }
      expect(await fasts.watchEnded().first, hasLength(40));
    });
  });
}
