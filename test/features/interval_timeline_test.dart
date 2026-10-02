import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/format/duration_format.dart';
import 'package:steady/features/timer/interval_config.dart';
import 'package:steady/features/timer/interval_timeline.dart';

Duration _s(int seconds) => Duration(seconds: seconds);

IntervalConfig _cfg({
  int prepare = 10,
  int work = 20,
  int rest = 10,
  int rounds = 8,
  int sets = 1,
  int setRest = 60,
}) => IntervalConfig(
  prepare: prepare,
  work: work,
  rest: rest,
  rounds: rounds,
  sets: sets,
  setRest: setRest,
);

/// Các điều bất biến phải đúng với mọi cấu hình.
void _expectInvariants(IntervalConfig c, IntervalTimeline t, String reason) {
  // Các pha nối liền nhau, bắt đầu từ 0.
  var cursor = Duration.zero;
  var lastGroup = -1;
  for (final p in t.phases) {
    expect(p.start, cursor, reason: '$reason: phases are contiguous');
    expect(p.duration, greaterThan(Duration.zero), reason: reason);
    expect(p.group, greaterThanOrEqualTo(lastGroup), reason: reason);
    cursor = p.end;
    lastGroup = p.group;
  }
  expect(t.total, cursor, reason: reason);
  // Công thức tổng.
  expect(
    t.workoutTotal,
    _s(c.sets * c.rounds * (c.work + c.rest) + (c.sets - 1) * c.setRest),
    reason: '$reason: workoutTotal = sets*rounds*(work+rest)+(sets-1)*setRest',
  );
  // Khi sets = 1 hoặc setRest = 0 thì công thức trên không có số hạng nghỉ set.
  expect(t.prepare, _s(c.prepare), reason: reason);
  expect(t.total, t.prepare + t.workoutTotal, reason: reason);
  expect(
    t.intervalCount,
    c.sets * c.rounds * (c.rest > 0 ? 2 : 1),
    reason: '$reason: intervalCount',
  );
}

void main() {
  group('Tabata (the mockup numbers)', () {
    final t = IntervalTimeline.fromConfig(IntervalConfig.tabata);

    test('240 seconds of workout, 16 intervals, 10 seconds of prepare', () {
      expect(t.workoutTotal, _s(240));
      expect(formatClock(t.workoutTotal), '4:00');
      expect(t.intervalCount, 16);
      expect(t.prepare, _s(10));
      expect(t.total, _s(250));
    });

    test('phases: prepare, then work and rest eight times', () {
      expect(t.phases, hasLength(17));
      expect(t.phases.map((p) => p.kind).take(5), [
        IntervalPhaseKind.prepare,
        IntervalPhaseKind.work,
        IntervalPhaseKind.rest,
        IntervalPhaseKind.work,
        IntervalPhaseKind.rest,
      ]);
      expect(t.phases[0].start, Duration.zero);
      expect(t.phases[0].duration, _s(10));
      expect(t.phases[1].start, _s(10));
      expect(t.phases[1].duration, _s(20));
      expect(t.phases[2].start, _s(30));
      expect(t.phases[2].duration, _s(10));
      expect(t.phases.last.kind, IntervalPhaseKind.rest);
      expect(t.phases.last.end, _s(250));
    });

    test('rounds are numbered from 1; prepare counts as round 1', () {
      expect(t.phases[0].round, 1);
      expect(t.phases[0].set, 1);
      expect(t.phases[1].round, 1);
      expect(t.phases[2].round, 1);
      expect(t.phases[3].round, 2);
      expect(t.phases.last.round, 8);
      expect(t.phases.every((p) => p.set == 1), isTrue);
    });

    test('work and rest of one round share a group; every round differs', () {
      expect(t.phases[0].group, isNot(t.phases[1].group));
      expect(t.phases[1].group, t.phases[2].group);
      expect(t.phases[2].group, isNot(t.phases[3].group));
      expect(t.phases[3].group, t.phases[4].group);
      expect(t.phases.map((p) => p.group).toSet(), hasLength(9));
    });

    test('snapshot at 76 s: 27.5%, 2:54 left; phase 30%, 0:14 left', () {
      final snap = t.at(_s(10 + 66));
      expect(snap.done, isFalse);
      expect(snap.workoutProgress, closeTo(0.275, 1e-9));
      expect(snap.workoutRemaining, _s(174));
      expect(formatClock(snap.workoutRemaining), '2:54');
      expect(snap.phase!.kind, IntervalPhaseKind.work);
      expect(snap.phase!.round, 3);
      expect(snap.phaseProgress, closeTo(0.3, 1e-9));
      expect(snap.phaseRemaining, _s(14));
      expect(formatClock(snap.phaseRemaining), '0:14');
      expect(snap.next!.kind, IntervalPhaseKind.rest);
      expect(snap.index, 5);
    });

    test('at 0 it is the start of prepare: nothing done, the whole workout '
        'left', () {
      final snap = t.at(Duration.zero);
      expect(snap.phase!.kind, IntervalPhaseKind.prepare);
      expect(snap.index, 0);
      expect(snap.phaseProgress, 0);
      expect(snap.phaseRemaining, _s(10));
      expect(snap.workoutProgress, 0);
      expect(snap.workoutRemaining, _s(240));
      expect(snap.next!.kind, IntervalPhaseKind.work);
      expect(snap.done, isFalse);
    });

    test('while preparing, the workout has not started', () {
      final snap = t.at(_s(7));
      expect(snap.phase!.kind, IntervalPhaseKind.prepare);
      expect(snap.workoutProgress, 0);
      expect(snap.workoutRemaining, _s(240));
      expect(snap.phaseRemaining, _s(3));
      expect(snap.phaseProgress, closeTo(0.7, 1e-9));
    });

    test(
      'a phase starts exactly at its start time and ends before its end',
      () {
        expect(t.at(_s(10)).phase!.kind, IntervalPhaseKind.work);
        expect(t.at(_s(10)).index, 1);
        expect(t.at(_s(10)).phaseProgress, 0);
        expect(t.at(_s(10)).workoutProgress, 0);
        expect(
          t.at(_s(30) - const Duration(microseconds: 1)).phase!.kind,
          IntervalPhaseKind.work,
        );
        expect(t.at(_s(30)).phase!.kind, IntervalPhaseKind.rest);
        expect(t.at(_s(40)).phase!.kind, IntervalPhaseKind.work);
        expect(t.at(_s(40)).phase!.round, 2);
      },
    );

    test('the last instant before the end is still the last rest', () {
      final snap = t.at(_s(250) - const Duration(milliseconds: 1));
      expect(snap.done, isFalse);
      expect(snap.phase!.kind, IntervalPhaseKind.rest);
      expect(snap.phase!.round, 8);
      expect(snap.next, isNull, reason: 'nothing after the last phase');
      expect(snap.phaseRemaining, const Duration(milliseconds: 1));
    });

    test('at the total and beyond it is done with every measure full', () {
      for (final e in [_s(250), _s(251), _s(100000)]) {
        final snap = t.at(e);
        expect(snap.done, isTrue, reason: '$e');
        expect(snap.phase, isNull);
        expect(snap.next, isNull);
        expect(snap.index, t.phases.length);
        expect(snap.phaseProgress, 1);
        expect(snap.workoutProgress, 1);
        expect(snap.workoutRemaining, Duration.zero);
        expect(snap.phaseRemaining, Duration.zero);
      }
    });

    test('a negative time counts as 0', () {
      final snap = t.at(_s(-5));
      expect(snap.index, 0);
      expect(snap.phase!.kind, IntervalPhaseKind.prepare);
      expect(snap.workoutProgress, 0);
      expect(snap.phaseRemaining, _s(10));
    });

    test('progress never goes down and stays between 0 and 1', () {
      var lastWorkout = -1.0;
      var lastIndex = -1;
      for (var ms = 0; ms <= 252000; ms += 250) {
        final snap = t.at(Duration(milliseconds: ms));
        expect(snap.workoutProgress, inInclusiveRange(0, 1));
        expect(snap.phaseProgress, inInclusiveRange(0, 1));
        expect(snap.workoutProgress, greaterThanOrEqualTo(lastWorkout));
        expect(snap.index, greaterThanOrEqualTo(lastIndex));
        expect(snap.workoutRemaining.isNegative, isFalse);
        expect(snap.phaseRemaining.isNegative, isFalse);
        lastWorkout = snap.workoutProgress;
        lastIndex = snap.index;
      }
    });
  });

  group('variants (section 11, item 13)', () {
    test('rest = 0: work phases only, intervals = rounds', () {
      final c = _cfg(rest: 0);
      final t = IntervalTimeline.fromConfig(c);
      expect(t.phases.map((p) => p.kind).toSet(), {
        IntervalPhaseKind.prepare,
        IntervalPhaseKind.work,
      });
      expect(t.phases, hasLength(9));
      expect(t.intervalCount, 8);
      expect(t.workoutTotal, _s(160));
      expect(t.total, _s(170));
      // Mỗi hiệp là một nhóm riêng, kể cả khi không có nghỉ.
      expect(t.phases.map((p) => p.group).toSet(), hasLength(9));
      _expectInvariants(c, t, 'rest = 0');
    });

    test('prepare = 0: the workout starts at 0', () {
      final c = _cfg(prepare: 0);
      final t = IntervalTimeline.fromConfig(c);
      expect(t.prepare, Duration.zero);
      expect(t.phases.first.kind, IntervalPhaseKind.work);
      expect(t.phases.first.start, Duration.zero);
      expect(t.phases.any((p) => p.kind == IntervalPhaseKind.prepare), isFalse);
      expect(t.total, t.workoutTotal);
      expect(t.total, _s(240));
      final snap = t.at(Duration.zero);
      expect(snap.phase!.kind, IntervalPhaseKind.work);
      expect(snap.workoutProgress, 0);
      expect(snap.workoutRemaining, _s(240));
      expect(t.at(_s(120)).workoutProgress, closeTo(0.5, 1e-9));
      _expectInvariants(c, t, 'prepare = 0');
    });

    test('two sets with a rest between them', () {
      final c = _cfg(sets: 2, setRest: 60);
      final t = IntervalTimeline.fromConfig(c);
      expect(t.phases, hasLength(1 + 16 + 1 + 16));
      expect(t.total, _s(10 + 240 + 60 + 240));
      expect(t.workoutTotal, _s(540));
      expect(t.intervalCount, 32, reason: 'the set rest is not an interval');
      final setRests = t.phases
          .where((p) => p.kind == IntervalPhaseKind.setRest)
          .toList();
      expect(setRests, hasLength(1));
      final rest = setRests.single;
      expect(rest.duration, _s(60));
      expect(rest.start, _s(10 + 240));
      expect(rest.set, 1, reason: 'the set that has just finished');
      expect(rest.round, 8, reason: 'its last round');
      // Nghỉ giữa set là một nhóm riêng.
      final sameGroup = t.phases.where((p) => p.group == rest.group);
      expect(sameGroup, [rest]);
      // Set thứ hai bắt đầu lại từ hiệp 1.
      final after = t.phases[t.phases.indexOf(rest) + 1];
      expect(after.kind, IntervalPhaseKind.work);
      expect(after.set, 2);
      expect(after.round, 1);
      _expectInvariants(c, t, 'sets = 2');
    });

    test('two sets and no set rest: the sets run back to back', () {
      final c = _cfg(sets: 2, setRest: 0);
      final t = IntervalTimeline.fromConfig(c);
      expect(t.phases.any((p) => p.kind == IntervalPhaseKind.setRest), isFalse);
      expect(t.workoutTotal, _s(480));
      expect(t.total, _s(490));
      expect(t.intervalCount, 32);
      _expectInvariants(c, t, 'sets = 2, setRest = 0');
    });

    test('one set ignores setRest: it only goes between sets', () {
      final c = _cfg(sets: 1, setRest: 300);
      final t = IntervalTimeline.fromConfig(c);
      expect(t.phases.any((p) => p.kind == IntervalPhaseKind.setRest), isFalse);
      expect(t.workoutTotal, _s(240));
      _expectInvariants(c, t, 'sets = 1');
    });

    test('no rest at all and several sets with no set rest', () {
      final c = _cfg(prepare: 0, rest: 0, sets: 3, setRest: 0, rounds: 4);
      final t = IntervalTimeline.fromConfig(c);
      expect(t.phases, hasLength(12));
      expect(t.phases.every((p) => p.kind == IntervalPhaseKind.work), isTrue);
      expect(t.intervalCount, 12);
      expect(t.total, _s(12 * 20));
      _expectInvariants(c, t, 'everything off');
    });

    test('no rest, with a set rest: set rest is the only REST phase', () {
      final c = _cfg(rest: 0, sets: 2, setRest: 30, rounds: 3);
      final t = IntervalTimeline.fromConfig(c);
      expect(t.phases.map((p) => p.kind).toList(), [
        IntervalPhaseKind.prepare,
        IntervalPhaseKind.work,
        IntervalPhaseKind.work,
        IntervalPhaseKind.work,
        IntervalPhaseKind.setRest,
        IntervalPhaseKind.work,
        IntervalPhaseKind.work,
        IntervalPhaseKind.work,
      ]);
      expect(t.intervalCount, 6);
      _expectInvariants(c, t, 'rest = 0, setRest > 0');
    });

    test('a single round with nothing else is one work phase', () {
      final c = _cfg(prepare: 0, rest: 0, rounds: 1);
      final t = IntervalTimeline.fromConfig(c);
      expect(t.phases, hasLength(1));
      expect(t.total, _s(20));
      expect(t.at(_s(5)).next, isNull);
      expect(t.at(_s(20)).done, isTrue);
      _expectInvariants(c, t, 'single round');
    });

    test('the formulas hold across a grid of settings', () {
      for (final prepare in [0, 10, 60]) {
        for (final rest in [0, 10, 600]) {
          for (final sets in [1, 2, 10]) {
            for (final setRest in [0, 60]) {
              for (final rounds in [1, 5, 50]) {
                final c = _cfg(
                  prepare: prepare,
                  rest: rest,
                  sets: sets,
                  setRest: setRest,
                  rounds: rounds,
                );
                final t = IntervalTimeline.fromConfig(c);
                final reason =
                    'prepare=$prepare rest=$rest sets=$sets '
                    'setRest=$setRest rounds=$rounds';
                _expectInvariants(c, t, reason);
                // Nửa bài: tiến độ nằm giữa 0 và 1.
                final mid = t.at(
                  Duration(microseconds: t.total.inMicroseconds ~/ 2),
                );
                expect(mid.done, isFalse, reason: reason);
                expect(mid.workoutProgress, inInclusiveRange(0, 1));
                // Cuối bài: xong.
                expect(t.at(t.total).done, isTrue, reason: reason);
                expect(
                  t.at(t.total - const Duration(microseconds: 1)).done,
                  isFalse,
                  reason: reason,
                );
              }
            }
          }
        }
      }
    });
  });
}
