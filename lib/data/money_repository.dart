import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../core/time/local_date.dart';
import 'database.dart';
import 'money_types.dart';

class MoneyRepository {
  MoneyRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  // Mới nhất trước: ngày, rồi lúc tạo, rồi id.
  List<OrderingTerm Function($MoneyEntriesTable)> get _newestFirst => [
    (t) => OrderingTerm.desc(t.date),
    (t) => OrderingTerm.desc(t.createdAt),
    (t) => OrderingTerm.desc(t.id),
  ];

  Stream<List<MoneyEntry>> watchAll() {
    final query = _db.select(_db.moneyEntries)..orderBy(_newestFirst);
    return query.watch();
  }

  Stream<List<MoneyEntry>> watchRecent({int limit = 5}) {
    final query = _db.select(_db.moneyEntries)
      ..orderBy(_newestFirst)
      ..limit(limit);
    return query.watch();
  }

  /// Các khoản có ngày từ [from] đến [to], gồm cả hai đầu.
  Stream<List<MoneyEntry>> watchBetween(LocalDate from, LocalDate to) {
    // Ngày lưu dạng chuỗi ISO nên so chuỗi cũng đúng thứ tự thời gian.
    final query = _db.select(_db.moneyEntries)
      ..where((t) => t.date.isBetweenValues(from.toIso(), to.toIso()))
      ..orderBy(_newestFirst);
    return query.watch();
  }

  /// Số tiền ngoài [1, [kMaxAmountMinor]] hoặc ghi chú quá dài thì ném
  /// [ArgumentError]. Ghi chú luôn được lưu ở dạng đã chuẩn hoá. Việc "ngày
  /// không ở tương lai" do giao diện chặn, không kiểm ở đây.
  Future<MoneyEntry> add({
    required int amountMinor,
    required MoneyCategory category,
    required LocalDate date,
    String? note,
  }) async {
    final normalizedNote = _validate(amountMinor, note);
    return _db
        .into(_db.moneyEntries)
        .insertReturning(
          MoneyEntriesCompanion.insert(
            amountMinor: amountMinor,
            category: category,
            note: Value(normalizedNote),
            date: date,
            createdAt: _clock.now(),
          ),
        );
  }

  /// Không đổi `createdAt`. Trả `false` khi không có [id].
  Future<bool> update(
    int id, {
    required int amountMinor,
    required MoneyCategory category,
    required LocalDate date,
    String? note,
  }) async {
    final normalizedNote = _validate(amountMinor, note);
    final updated =
        await (_db.update(
          _db.moneyEntries,
        )..where((t) => t.id.equals(id))).write(
          MoneyEntriesCompanion(
            amountMinor: Value(amountMinor),
            category: Value(category),
            note: Value(normalizedNote),
            date: Value(date),
          ),
        );
    return updated > 0;
  }

  Future<bool> delete(int id) async {
    final deleted = await (_db.delete(
      _db.moneyEntries,
    )..where((t) => t.id.equals(id))).go();
    return deleted > 0;
  }

  /// Trả ghi chú đã chuẩn hoá.
  String? _validate(int amountMinor, String? note) {
    if (amountMinor < 1 || amountMinor > kMaxAmountMinor) {
      throw ArgumentError.value(
        amountMinor,
        'amountMinor',
        'Must be between 1 and $kMaxAmountMinor',
      );
    }
    return note == null ? null : normalizeMoneyNote(note);
  }
}
