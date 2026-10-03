import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../core/time/local_date.dart';
import '../features/streaks/habit_name.dart';
import 'database.dart';

class HabitRepository {
  HabitRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  Stream<List<Habit>> watchHabits() {
    final query = _db.select(_db.habits)
      ..orderBy([
        (t) => OrderingTerm.asc(t.cleanSince),
        (t) => OrderingTerm.asc(t.createdAt),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.watch();
  }

  Future<Habit> addHabit({
    required String name,
    required LocalDate cleanSince,
    required LocalDate today,
  }) async {
    final normalized = normalizeHabitName(name);
    if (normalized == null) {
      throw ArgumentError.value(name, 'name', 'Invalid habit name');
    }
    if (cleanSince.isAfter(today)) {
      throw ArgumentError.value(
        cleanSince,
        'cleanSince',
        'Must not be after today',
      );
    }
    return _db
        .into(_db.habits)
        .insertReturning(
          HabitsCompanion.insert(
            name: normalized,
            cleanSince: cleanSince,
            createdAt: _clock.now(),
          ),
        );
  }

  Future<bool> resetStreak(int id, LocalDate today) async {
    final updated =
        await (_db.update(_db.habits)..where((t) => t.id.equals(id))).write(
          HabitsCompanion(cleanSince: Value(today)),
        );
    return updated > 0;
  }

  Future<bool> deleteHabit(int id) async {
    final deleted = await (_db.delete(
      _db.habits,
    )..where((t) => t.id.equals(id))).go();
    return deleted > 0;
  }
}
