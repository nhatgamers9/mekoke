import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/time/local_date.dart';
import 'package:steady/data/database.dart';
import 'package:steady/data/money_types.dart';
import 'package:steady/features/timer/fasting_plan.dart';

import '../generated_migrations/schema.dart';
import '../generated_migrations/schema_v1.dart' as v1;
import '../generated_migrations/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  Future<List<String>> tableNames(GeneratedDatabase db) async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .get();
    return rows.map((r) => r.read<String>('name')).toList();
  }

  Future<int> userVersion(GeneratedDatabase db) async {
    final row = await db.customSelect('PRAGMA user_version').getSingle();
    return row.read<int>('user_version');
  }

  group('schema version', () {
    test('the app database is at version 3', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, 3);
    });

    test('the generated helper knows all three versions', () {
      expect(GeneratedHelper.versions, [1, 2, 3]);
    });
  });

  // Dữ liệu của bản đã cài ở v1: chỉ có `habits` và `check_ins`.
  Future<void> seedV1(DatabaseConnectionUser old) async {
    await old.customStatement(
      "INSERT INTO habits (name, clean_since, created_at) "
      "VALUES ('No smoking', '2026-05-28', 1780000000), "
      "('No sugar', '2026-09-01', 1790000000)",
    );
    await old.customStatement(
      "INSERT INTO check_ins (date, mood, note, updated_at) "
      "VALUES ('2026-10-01', 4, 'Long walk', 1791000000), "
      "('2026-10-02', 2, NULL, 1791086400)",
    );
  }

  // Dữ liệu của bản đã cài ở v2: thêm `fasts` và `prefs`.
  Future<void> seedV2(DatabaseConnectionUser old) async {
    await seedV1(old);
    await old.customStatement(
      "INSERT INTO fasts (plan, goal_minutes, started_at, ended_at) "
      "VALUES ('h16', 960, 1791000000, 1791057600), "
      "('omad', 1380, 1791100000, NULL)",
    );
    await old.customStatement(
      "INSERT INTO prefs (name, value) "
      "VALUES ('interval.preset', 'hiit3030'), ('theme.note', 'keep me')",
    );
  }

  /// Mọi dòng `habits` và `check_ins` của [seedV1] còn nguyên, từng cột.
  Future<void> expectHabitsAndCheckInsKept(AppDatabase db) async {
    final habits = await (db.select(
      db.habits,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    expect(habits.map((h) => h.name), ['No smoking', 'No sugar']);
    expect(habits.map((h) => h.cleanSince), [
      LocalDate(2026, 5, 28),
      LocalDate(2026, 9, 1),
    ]);
    expect(habits.map((h) => h.id), [1, 2]);
    expect(habits.first.createdAt.millisecondsSinceEpoch, 1780000000 * 1000);
    expect(habits.last.createdAt.millisecondsSinceEpoch, 1790000000 * 1000);

    final checkIns = await (db.select(
      db.checkIns,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    expect(checkIns, hasLength(2));
    expect(checkIns.first.date, LocalDate(2026, 10, 1));
    expect(checkIns.first.mood, 4);
    expect(checkIns.first.note, 'Long walk');
    expect(checkIns.last.date, LocalDate(2026, 10, 2));
    expect(checkIns.last.mood, 2);
    expect(checkIns.last.note, isNull);
  }

  /// `money_entries` có sẵn, rỗng và ghi được; ghi xong thì dữ liệu cũ vẫn
  /// còn (các bảng khác không bị đụng tới).
  Future<void> expectMoneyEntriesEmptyAndUsable(AppDatabase db) async {
    expect(await db.select(db.moneyEntries).get(), isEmpty);
    final entry = await db
        .into(db.moneyEntries)
        .insertReturning(
          MoneyEntriesCompanion.insert(
            amountMinor: 1240,
            category: MoneyCategory.eatingOut,
            note: const Value('Lunch'),
            date: LocalDate(2026, 10, 2),
            createdAt: DateTime(2026, 10, 2, 12, 30),
          ),
        );
    expect(entry.id, 1);
    expect(entry.category, MoneyCategory.eatingOut);
    expect(entry.date, LocalDate(2026, 10, 2));
    final stored = (await db.select(db.moneyEntries).get()).single;
    expect(stored.amountMinor, 1240);
    expect(stored.note, 'Lunch');
  }

  group('migration from v1 to v3', () {
    test('the migrated schema is exactly the v3 schema', () async {
      final schema = await verifier.schemaAt(1);
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 3);
    });

    test('the database ends at user_version 3 with five tables', () async {
      final schema = await verifier.schemaAt(1);
      final oldDb = v1.DatabaseAtV1(schema.newConnection());
      await seedV1(oldDb);
      await oldDb.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 3);

      expect(await userVersion(db), 3);
      expect(await tableNames(db), [
        'check_ins',
        'fasts',
        'habits',
        'money_entries',
        'prefs',
      ]);
    });

    test('every habit and check-in row of v1 is kept as it was', () async {
      final schema = await verifier.schemaAt(1);
      final oldDb = v1.DatabaseAtV1(schema.newConnection());
      await seedV1(oldDb);
      await oldDb.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 3);

      await expectHabitsAndCheckInsKept(db);
    });

    test('the three new tables are there, empty and usable', () async {
      final schema = await verifier.schemaAt(1);
      final oldDb = v1.DatabaseAtV1(schema.newConnection());
      await seedV1(oldDb);
      await oldDb.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 3);

      expect(await db.select(db.fasts).get(), isEmpty);
      expect(await db.select(db.prefs).get(), isEmpty);
      final fast = await db
          .into(db.fasts)
          .insertReturning(
            FastsCompanion.insert(
              plan: FastingPlan.h18,
              goalMinutes: 1080,
              startedAt: DateTime(2026, 10, 2, 21),
            ),
          );
      expect(fast.plan, FastingPlan.h18);
      await db
          .into(db.prefs)
          .insert(PrefsCompanion.insert(name: 'k', value: 'v'));
      expect((await db.select(db.prefs).get()).single.value, 'v');

      await expectMoneyEntriesEmptyAndUsable(db);
      // Dữ liệu cũ vẫn còn sau khi ghi vào các bảng mới.
      expect(await db.select(db.habits).get(), hasLength(2));
      expect(await db.select(db.checkIns).get(), hasLength(2));
    });

    test('an empty v1 database migrates too', () async {
      final schema = await verifier.schemaAt(1);
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 3);
      expect(await db.select(db.habits).get(), isEmpty);
      expect(await db.select(db.moneyEntries).get(), isEmpty);
    });
  });

  group('migration from v2 to v3', () {
    test('the migrated schema is exactly the v3 schema', () async {
      final schema = await verifier.schemaAt(2);
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 3);
    });

    test('the database ends at user_version 3 with five tables', () async {
      final schema = await verifier.schemaAt(2);
      final oldDb = v2.DatabaseAtV2(schema.newConnection());
      await seedV2(oldDb);
      await oldDb.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 3);

      expect(await userVersion(db), 3);
      expect(await tableNames(db), [
        'check_ins',
        'fasts',
        'habits',
        'money_entries',
        'prefs',
      ]);
    });

    test(
      'habits, check-ins, fasts and prefs of v2 are kept as they were',
      () async {
        final schema = await verifier.schemaAt(2);
        final oldDb = v2.DatabaseAtV2(schema.newConnection());
        await seedV2(oldDb);
        await oldDb.close();

        final db = AppDatabase(schema.newConnection());
        addTearDown(db.close);
        await verifier.migrateAndValidate(db, 3);

        await expectHabitsAndCheckInsKept(db);

        final fasts = await (db.select(
          db.fasts,
        )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
        expect(fasts, hasLength(2));
        expect(fasts.map((f) => f.id), [1, 2]);
        expect(fasts.map((f) => f.plan), [FastingPlan.h16, FastingPlan.omad]);
        expect(fasts.map((f) => f.goalMinutes), [960, 1380]);
        expect(fasts.first.startedAt.millisecondsSinceEpoch, 1791000000 * 1000);
        expect(fasts.first.endedAt?.millisecondsSinceEpoch, 1791057600 * 1000);
        expect(fasts.last.startedAt.millisecondsSinceEpoch, 1791100000 * 1000);
        expect(fasts.last.endedAt, isNull);

        final prefs = await (db.select(
          db.prefs,
        )..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
        expect(prefs.map((p) => (p.name, p.value)), [
          ('interval.preset', 'hiit3030'),
          ('theme.note', 'keep me'),
        ]);
      },
    );

    test('money_entries is there, empty and usable; old rows stay', () async {
      final schema = await verifier.schemaAt(2);
      final oldDb = v2.DatabaseAtV2(schema.newConnection());
      await seedV2(oldDb);
      await oldDb.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 3);

      await expectMoneyEntriesEmptyAndUsable(db);
      expect(await db.select(db.habits).get(), hasLength(2));
      expect(await db.select(db.checkIns).get(), hasLength(2));
      expect(await db.select(db.fasts).get(), hasLength(2));
      expect(await db.select(db.prefs).get(), hasLength(2));
    });

    test('an empty v2 database migrates too', () async {
      final schema = await verifier.schemaAt(2);
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 3);
      expect(await db.select(db.fasts).get(), isEmpty);
      expect(await db.select(db.moneyEntries).get(), isEmpty);
    });

    // Case phải thất bại: CHECK của bảng mới đã có sau khi nâng cấp.
    test('after the upgrade the CHECK on amount_minor is in force', () async {
      final schema = await verifier.schemaAt(2);
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 3);

      await expectLater(
        db.customStatement(
          "INSERT INTO money_entries (amount_minor, category, date, created_at) "
          "VALUES (0, 'groceries', '2026-10-02', 1791000000)",
        ),
        throwsA(anything),
      );
      expect(await db.select(db.moneyEntries).get(), isEmpty);
    });
  });

  group('a database created fresh', () {
    test(
      'is created straight at v3 with the same schema as the migration',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await verifier.migrateAndValidate(db, 3);
      },
    );

    test('has all five tables and starts empty', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      expect(await tableNames(db), [
        'check_ins',
        'fasts',
        'habits',
        'money_entries',
        'prefs',
      ]);
      expect(await userVersion(db), 3);
      expect(await db.select(db.habits).get(), isEmpty);
      expect(await db.select(db.checkIns).get(), isEmpty);
      expect(await db.select(db.fasts).get(), isEmpty);
      expect(await db.select(db.prefs).get(), isEmpty);
      expect(await db.select(db.moneyEntries).get(), isEmpty);
    });

    test('money_entries is usable', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await expectMoneyEntriesEmptyAndUsable(db);
    });

    // Cases phải thất bại: CHECK 1..kMaxAmountMinor của cột amount_minor.
    group('the CHECK on amount_minor', () {
      Future<void> insertRaw(AppDatabase db, int amountMinor) {
        return db.customStatement(
          "INSERT INTO money_entries (amount_minor, category, date, created_at) "
          "VALUES ($amountMinor, 'groceries', '2026-10-02', 1791000000)",
        );
      }

      for (final bad in [0, -1, kMaxAmountMinor + 1]) {
        test('rejects amount_minor = $bad', () async {
          final db = AppDatabase(NativeDatabase.memory());
          addTearDown(db.close);
          await expectLater(insertRaw(db, bad), throwsA(anything));
          expect(
            await db.select(db.moneyEntries).get(),
            isEmpty,
            reason: 'a rejected row must not be stored',
          );
        });
      }

      for (final good in [1, kMaxAmountMinor]) {
        test('accepts the boundary amount_minor = $good', () async {
          final db = AppDatabase(NativeDatabase.memory());
          addTearDown(db.close);
          await insertRaw(db, good);
          expect(
            (await db.select(db.moneyEntries).get()).single.amountMinor,
            good,
          );
        });
      }

      test('rejects 0 through the Drift API too', () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await expectLater(
          db
              .into(db.moneyEntries)
              .insert(
                MoneyEntriesCompanion.insert(
                  amountMinor: 0,
                  category: MoneyCategory.other,
                  date: LocalDate(2026, 10, 2),
                  createdAt: DateTime(2026, 10, 2, 21),
                ),
              ),
          throwsA(anything),
        );
      });
    });
  });
}
