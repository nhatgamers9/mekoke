import 'package:drift/drift.dart';

import '../features/timer/interval_config.dart';
import 'database.dart';

class PrefsRepository {
  PrefsRepository(this._db);

  static const _presetKey = 'interval.preset';
  static const _customKey = 'interval.custom';
  static const _currencyKey = 'money.currency';
  static final _currencyPattern = RegExp(r'^[A-Z]{3}$');

  final AppDatabase _db;

  Future<String?> read(String name) async {
    final row = await (_db.select(
      _db.prefs,
    )..where((t) => t.name.equals(name))).getSingleOrNull();
    return row?.value;
  }

  /// Ghi đè theo [name].
  Future<void> write(String name, String value) async {
    await _db
        .into(_db.prefs)
        .insert(
          PrefsCompanion.insert(name: name, value: value),
          onConflict: DoUpdate(
            (old) => PrefsCompanion(value: Value(value)),
            target: [_db.prefs.name],
          ),
        );
  }

  /// Lỗi đọc hoặc dữ liệu hỏng thì trả [IntervalSetup.initial].
  Future<IntervalSetup> loadIntervalSetup() async {
    try {
      final rawPreset = await read(_presetKey);
      final rawCustom = await read(_customKey);
      var preset = IntervalSetup.initial.preset;
      var custom = IntervalSetup.initial.custom;
      if (rawPreset != null) {
        final parsed = IntervalPresetId.values.asNameMap()[rawPreset];
        if (parsed == null) return IntervalSetup.initial;
        preset = parsed;
      }
      if (rawCustom != null) {
        final parsed = IntervalConfig.tryFromJson(rawCustom);
        if (parsed == null) return IntervalSetup.initial;
        custom = parsed;
      }
      return IntervalSetup(preset: preset, custom: custom);
    } catch (_) {
      return IntervalSetup.initial;
    }
  }

  Future<void> saveIntervalSetup(IntervalSetup s) async {
    await write(_presetKey, s.preset.name);
    await write(_customKey, s.custom.toJson());
  }

  /// Có giá trị hợp lệ (mã ba chữ in hoa) thì trả về giá trị đó. Không có hoặc
  /// không hợp lệ thì ghi [fallback] (lỗi ghi thì bỏ qua) rồi trả [fallback].
  /// Lỗi đọc thì trả [fallback] và không ghi. Không bao giờ ném lỗi.
  Future<String> loadCurrency({required String fallback}) async {
    final String? saved;
    try {
      saved = await read(_currencyKey);
    } catch (_) {
      return fallback;
    }
    if (saved != null && _currencyPattern.hasMatch(saved)) return saved;
    try {
      await write(_currencyKey, fallback);
    } catch (_) {
      // Chưa lưu được thì lần mở sau tính lại theo vùng của máy.
    }
    return fallback;
  }
}
