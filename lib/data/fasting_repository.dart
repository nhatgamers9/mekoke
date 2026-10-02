import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../features/timer/fasting_plan.dart';
import 'database.dart';

/// Bỏ phần mili giây và micro giây: Drift chỉ lưu thời điểm đến giây.
DateTime truncateToSecond(DateTime t) => t.subtract(
  Duration(milliseconds: t.millisecond, microseconds: t.microsecond),
);

class FastingRepository {
  FastingRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  /// Lần nhịn đang chạy (chưa kết thúc), nếu có.
  Stream<Fast?> watchActive() {
    final query = _db.select(_db.fasts)
      ..where((t) => t.endedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
      ..limit(1);
    return query.watchSingleOrNull();
  }

  /// Các lần nhịn đã kết thúc, mới nhất trước.
  Stream<List<Fast>> watchEnded() {
    final query = _db.select(_db.fasts)
      ..where((t) => t.endedAt.isNotNull())
      ..orderBy([
        (t) => OrderingTerm.desc(t.endedAt),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return query.watch();
  }

  /// Mỗi lúc chỉ có một lần nhịn đang chạy: đã có thì ném [StateError].
  Future<Fast> start(FastingPlan plan) {
    return _db.transaction(() async {
      final running = await (_db.select(
        _db.fasts,
      )..where((t) => t.endedAt.isNull())).get();
      if (running.isNotEmpty) {
        throw StateError('A fast is already running');
      }
      return _db
          .into(_db.fasts)
          .insertReturning(
            FastsCompanion.insert(
              plan: plan,
              goalMinutes: plan.fastHours * 60,
              startedAt: truncateToSecond(_clock.now()),
            ),
          );
    });
  }

  /// Trả `false` khi không có [id] hoặc lần nhịn đó đã kết thúc.
  Future<bool> end(int id) {
    return _db.transaction(() async {
      final fast = await (_db.select(
        _db.fasts,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (fast == null || fast.endedAt != null) return false;
      final now = truncateToSecond(_clock.now());
      // Đồng hồ máy lùi: không để endedAt nhỏ hơn startedAt.
      final endedAt = now.isBefore(fast.startedAt) ? fast.startedAt : now;
      await (_db.update(_db.fasts)..where((t) => t.id.equals(id))).write(
        FastsCompanion(endedAt: Value(endedAt)),
      );
      return true;
    });
  }
}
