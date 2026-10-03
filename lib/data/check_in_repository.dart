import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../core/time/local_date.dart';
import '../features/check_in/check_in_rules.dart';
import 'database.dart';

class CheckInRepository {
  CheckInRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  Future<CheckIn?> getForDate(LocalDate date) {
    return (_db.select(
      _db.checkIns,
    )..where((t) => t.date.equalsValue(date))).getSingleOrNull();
  }

  /// Mỗi ngày một bản: lưu lại cùng ngày thì ghi đè.
  Future<void> saveForDate({
    required LocalDate date,
    required Mood mood,
    String? note,
  }) async {
    final normalizedNote = note == null ? null : normalizeCheckInNote(note);
    final updatedAt = _clock.now();
    await _db
        .into(_db.checkIns)
        .insert(
          CheckInsCompanion.insert(
            date: date,
            mood: mood.value,
            note: Value(normalizedNote),
            updatedAt: updatedAt,
          ),
          onConflict: DoUpdate(
            (old) => CheckInsCompanion(
              mood: Value(mood.value),
              note: Value(normalizedNote),
              updatedAt: Value(updatedAt),
            ),
            target: [_db.checkIns.date],
          ),
        );
  }
}
