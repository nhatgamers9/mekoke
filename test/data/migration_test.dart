import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/time/local_date.dart';
import 'package:steady/data/database.dart';
import 'package:steady/features/timer/fasting_plan.dart';

import '../generated_migrations/schema.dart';
import '../generated_migrations/schema_v1.dart' as v1;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('schema version', () {
    test('the app database is at version 2', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, 2);
    });

    test('the generated helper knows both versions', () {
      expect(GeneratedHelper.versions, [1, 2]);
    });
  });

  group('migration from v1 to v2', () {
    // Dữ liệu của bản đã cài: chỉ có `habits` và `check_ins`.
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

    test('the migrated schema is exactly the v2 schema', () async {
      final schema = await verifier.schemaAt(1);
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 2);
    });

    test('every habit and check-in row of v1 is kept as it was', () async {
      final schema = await verifier.schemaAt(1);
      final old = schema.newConnection();
      final oldDb = v1.DatabaseAtV1(old);
      await seedV1(oldDb);
      await oldDb.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 2);

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
    });

    test('the two new tables are there, empty and usable', () async {
      final schema = await verifier.schemaAt(1);
      final oldDb = v1.DatabaseAtV1(schema.newConnection());
      await seedV1(oldDb);
      await oldDb.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 2);

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
      // Dữ liệu cũ vẫn còn sau khi ghi vào bảng mới.
      expect(await db.select(db.habits).get(), hasLength(2));
    });

    test('an empty v1 database migrates too', () async {
      final schema = await verifier.schemaAt(1);
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 2);
      expect(await db.select(db.habits).get(), isEmpty);
    });
  });

  group('a database created fresh', () {
    test(
      'is created straight at v2 with the same schema as the migration',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await verifier.migrateAndValidate(db, 2);
      },
    );

    test('has all four tables and starts empty', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%' ORDER BY name",
          )
          .get();
      expect(tables.map((r) => r.read<String>('name')), [
        'check_ins',
        'fasts',
        'habits',
        'prefs',
      ]);
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.read<int>('user_version'), 2);
    });
  });
}
