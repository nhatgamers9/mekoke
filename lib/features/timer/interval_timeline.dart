import 'interval_config.dart';

enum IntervalPhaseKind { prepare, work, rest, setRest }

class IntervalPhase {
  const IntervalPhase({
    required this.kind,
    required this.set,
    required this.round,
    required this.group,
    required this.start,
    required this.duration,
  });

  final IntervalPhaseKind kind;

  /// Số thứ tự set và hiệp, tính từ 1. Pha prepare tính là set 1, hiệp 1;
  /// pha nghỉ giữa các set mang số của hiệp cuối set vừa xong.
  final int set;
  final int round;

  /// Các pha đi liền nhau thuộc cùng một hiệp (work + rest) có chung `group`;
  /// prepare và mỗi lượt nghỉ giữa set mỗi cái một nhóm riêng.
  final int group;

  final Duration start;
  final Duration duration;

  Duration get end => start + duration;
}

class IntervalSnapshot {
  const IntervalSnapshot({
    required this.phase,
    required this.next,
    required this.index,
    required this.done,
    required this.phaseRemaining,
    required this.phaseProgress,
    required this.workoutProgress,
    required this.workoutRemaining,
  });

  /// `null` khi bài đã xong.
  final IntervalPhase? phase;

  /// Pha kế tiếp, `null` ở pha cuối hoặc khi đã xong.
  final IntervalPhase? next;

  /// Vị trí của [phase] trong danh sách pha; bằng số pha khi đã xong.
  final int index;
  final bool done;
  final Duration phaseRemaining;
  final double phaseProgress;
  final double workoutProgress;
  final Duration workoutRemaining;
}

class IntervalTimeline {
  IntervalTimeline._(this.phases);

  factory IntervalTimeline.fromConfig(IntervalConfig c) {
    final phases = <IntervalPhase>[];
    var cursor = Duration.zero;
    var group = 0;

    void add(IntervalPhaseKind kind, int set, int round, int seconds) {
      final duration = Duration(seconds: seconds);
      phases.add(
        IntervalPhase(
          kind: kind,
          set: set,
          round: round,
          group: group,
          start: cursor,
          duration: duration,
        ),
      );
      cursor += duration;
    }

    if (c.prepare > 0) {
      add(IntervalPhaseKind.prepare, 1, 1, c.prepare);
      group++;
    }
    for (var set = 1; set <= c.sets; set++) {
      for (var round = 1; round <= c.rounds; round++) {
        add(IntervalPhaseKind.work, set, round, c.work);
        if (c.rest > 0) add(IntervalPhaseKind.rest, set, round, c.rest);
        group++;
      }
      if (set < c.sets && c.setRest > 0) {
        add(IntervalPhaseKind.setRest, set, c.rounds, c.setRest);
        group++;
      }
    }
    return IntervalTimeline._(List.unmodifiable(phases));
  }

  final List<IntervalPhase> phases;

  /// Tất cả các pha, gồm cả prepare.
  Duration get total => phases.isEmpty ? Duration.zero : phases.last.end;

  /// 0 nếu không có pha prepare.
  Duration get prepare =>
      phases.isNotEmpty && phases.first.kind == IntervalPhaseKind.prepare
      ? phases.first.duration
      : Duration.zero;

  /// Phần bài tập không tính prepare, gồm cả lượt nghỉ sau hiệp cuối.
  Duration get workoutTotal => total - prepare;

  int get intervalCount => phases
      .where(
        (p) =>
            p.kind == IntervalPhaseKind.work ||
            p.kind == IntervalPhaseKind.rest,
      )
      .length;

  IntervalSnapshot at(Duration elapsed) {
    final e = elapsed.isNegative ? Duration.zero : elapsed;
    final workout = workoutTotal;
    if (e >= total) {
      return IntervalSnapshot(
        phase: null,
        next: null,
        index: phases.length,
        done: true,
        phaseRemaining: Duration.zero,
        phaseProgress: 1,
        workoutProgress: 1,
        workoutRemaining: Duration.zero,
      );
    }
    // Pha có start <= e < end: tìm nhị phân pha cuối cùng có start <= e.
    var lo = 0;
    var hi = phases.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (phases[mid].start <= e) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    final phase = phases[lo];
    final intoWorkout = e > prepare ? e - prepare : Duration.zero;
    return IntervalSnapshot(
      phase: phase,
      next: lo + 1 < phases.length ? phases[lo + 1] : null,
      index: lo,
      done: false,
      phaseRemaining: phase.end - e,
      phaseProgress: _ratio(e - phase.start, phase.duration),
      workoutProgress: _ratio(intoWorkout, workout),
      workoutRemaining: workout - intoWorkout,
    );
  }
}

double _ratio(Duration part, Duration whole) {
  if (whole <= Duration.zero) return 1;
  return (part.inMicroseconds / whole.inMicroseconds).clamp(0.0, 1.0);
}
