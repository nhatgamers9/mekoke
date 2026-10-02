import 'dart:convert';

import 'package:flutter/foundation.dart';

enum IntervalField {
  prepare(0, 60),
  work(5, 600),
  rest(0, 600),
  rounds(1, 50),
  sets(1, 10),
  setRest(0, 600);

  const IntervalField(this.min, this.max);

  final int min;
  final int max;

  /// `false` với số lần (rounds, sets); các trường còn lại tính bằng giây.
  bool get isTime => this != rounds && this != sets;
}

/// Bước tăng: thời gian dưới 1 phút +5 giây, từ 1 phút trở lên +15 giây;
/// số lần +1. Kết quả luôn nằm trong [IntervalField.min, IntervalField.max].
int stepUp(IntervalField f, int v) {
  final step = f.isTime ? (v < 60 ? 5 : 15) : 1;
  return (v + step).clamp(f.min, f.max);
}

/// Bước giảm: thời gian đến 1 phút -5 giây, trên 1 phút -15 giây; số lần -1.
int stepDown(IntervalField f, int v) {
  final step = f.isTime ? (v <= 60 ? 5 : 15) : 1;
  return (v - step).clamp(f.min, f.max);
}

/// Cấu hình một bài tập ngắt quãng, đơn vị giây.
@immutable
class IntervalConfig {
  const IntervalConfig({
    required this.prepare,
    required this.work,
    required this.rest,
    required this.rounds,
    required this.sets,
    required this.setRest,
  });

  final int prepare;
  final int work;
  final int rest;
  final int rounds;
  final int sets;
  final int setRest;

  static const tabata = IntervalConfig(
    prepare: 10,
    work: 20,
    rest: 10,
    rounds: 8,
    sets: 1,
    setRest: 60,
  );

  static const hiit3030 = IntervalConfig(
    prepare: 10,
    work: 30,
    rest: 30,
    rounds: 10,
    sets: 1,
    setRest: 60,
  );

  int valueOf(IntervalField f) => switch (f) {
    IntervalField.prepare => prepare,
    IntervalField.work => work,
    IntervalField.rest => rest,
    IntervalField.rounds => rounds,
    IntervalField.sets => sets,
    IntervalField.setRest => setRest,
  };

  IntervalConfig withValue(IntervalField f, int v) => IntervalConfig(
    prepare: f == IntervalField.prepare ? v : prepare,
    work: f == IntervalField.work ? v : work,
    rest: f == IntervalField.rest ? v : rest,
    rounds: f == IntervalField.rounds ? v : rounds,
    sets: f == IntervalField.sets ? v : sets,
    setRest: f == IntervalField.setRest ? v : setRest,
  );

  /// Mọi trường nằm trong [IntervalField.min, IntervalField.max].
  bool get isValid => IntervalField.values.every((f) {
    final v = valueOf(f);
    return v >= f.min && v <= f.max;
  });

  String toJson() =>
      jsonEncode({for (final f in IntervalField.values) f.name: valueOf(f)});

  /// Hỏng, thiếu khoá hoặc ngoài khoảng thì trả `null`.
  static IntervalConfig? tryFromJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final values = <IntervalField, int>{};
      for (final f in IntervalField.values) {
        final v = decoded[f.name];
        if (v is! int) return null;
        values[f] = v;
      }
      final config = IntervalConfig(
        prepare: values[IntervalField.prepare]!,
        work: values[IntervalField.work]!,
        rest: values[IntervalField.rest]!,
        rounds: values[IntervalField.rounds]!,
        sets: values[IntervalField.sets]!,
        setRest: values[IntervalField.setRest]!,
      );
      return config.isValid ? config : null;
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is IntervalConfig &&
      other.prepare == prepare &&
      other.work == work &&
      other.rest == rest &&
      other.rounds == rounds &&
      other.sets == sets &&
      other.setRest == setRest;

  @override
  int get hashCode => Object.hash(prepare, work, rest, rounds, sets, setRest);
}

enum IntervalPresetId { tabata, hiit3030, custom }

@immutable
class IntervalSetup {
  const IntervalSetup({required this.preset, required this.custom});

  final IntervalPresetId preset;
  final IntervalConfig custom;

  static const initial = IntervalSetup(
    preset: IntervalPresetId.tabata,
    custom: IntervalConfig.tabata,
  );

  IntervalConfig get active => switch (preset) {
    IntervalPresetId.tabata => IntervalConfig.tabata,
    IntervalPresetId.hiit3030 => IntervalConfig.hiit3030,
    IntervalPresetId.custom => custom,
  };

  @override
  bool operator ==(Object other) =>
      other is IntervalSetup &&
      other.preset == preset &&
      other.custom == custom;

  @override
  int get hashCode => Object.hash(preset, custom);
}
