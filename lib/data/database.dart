import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../core/time/local_date.dart';
import '../features/timer/fasting_plan.dart';

part 'database.g.dart';

class LocalDateConverter extends TypeConverter<LocalDate, String> {
  const LocalDateConverter();

  @override
  LocalDate fromSql(String fromDb) => LocalDate.parse(fromDb);

  @override
  String toSql(LocalDate value) => value.toIso();
}

@DataClassName('Habit')
class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Không dùng withLength: Drift đếm theo UTF-16, sai với emoji.
  TextColumn get name => text()();

  TextColumn get cleanSince => text().map(const LocalDateConverter())();

  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('CheckIn')
class CheckIns extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get date => text().map(const LocalDateConverter()).unique()();

  // Drift cho phép cột tự tham chiếu mình trong check(); lint không hiểu mẫu này.
  // ignore: recursive_getters
  IntColumn get mood => integer().check(mood.isBetweenValues(1, 5))();

  TextColumn get note => text().nullable()();

  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('Fast')
class Fasts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get plan => textEnum<FastingPlan>()();

  // Cùng mẫu với CheckIns.mood: lint không hiểu cột tự tham chiếu trong check().
  IntColumn get goalMinutes =>
      // ignore: recursive_getters
      integer().check(goalMinutes.isBiggerThanValue(0))();

  DateTimeColumn get startedAt => dateTime()();

  DateTimeColumn get endedAt => dateTime().nullable()();
}

@DataClassName('PrefEntry')
class Prefs extends Table {
  TextColumn get name => text()();

  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {name};
}

@DriftDatabase(tables: [Habits, CheckIns, Fasts, Prefs])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  static AppDatabase openDefault() =>
      AppDatabase(driftDatabase(name: 'steady'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(fasts);
        await m.createTable(prefs);
      }
    },
  );
}
