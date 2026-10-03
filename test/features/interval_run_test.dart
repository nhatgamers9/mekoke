import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/features/timer/interval_config.dart';
import 'package:steady/features/timer/interval_run.dart';
import 'package:steady/features/timer/interval_timeline.dart';

Duration _s(int seconds) => Duration(seconds: seconds);

void main() {
  late DateTime now;
  late Clock clock;

  void tick(int seconds) => now = now.add(_s(seconds));

  IntervalRun makeRun([IntervalConfig config = IntervalConfig.tabata]) =>
      IntervalRun(IntervalTimeline.fromConfig(config), clock);

  setUp(() {
    now = DateTime(2026, 10, 2, 21);
    clock = Clock(() => now);
  });

  group('running', () {
    test('before start nothing runs and no time has passed', () {
      final run = makeRun();
      tick(30);
      expect(run.isRunning, isFalse);
      expect(run.isDone, isFalse);
      expect(run.elapsed, Duration.zero);
      expect(run.snapshot().index, 0);
    });

    test('start begins at prepare and follows the clock', () {
      final run = makeRun()..start();
      expect(run.isRunning, isTrue);
      expect(run.elapsed, Duration.zero);
      expect(run.snapshot().phase!.kind, IntervalPhaseKind.prepare);

      tick(5);
      expect(run.elapsed, _s(5));
      expect(run.snapshot().phase!.kind, IntervalPhaseKind.prepare);

      tick(5);
      expect(run.elapsed, _s(10));
      expect(run.snapshot().phase!.kind, IntervalPhaseKind.work);
      expect(run.snapshot().phase!.round, 1);

      tick(66); // 76 giây vào bài
      final snap = run.snapshot();
      expect(snap.phase!.kind, IntervalPhaseKind.work);
      expect(snap.phase!.round, 3);
      expect(snap.workoutProgress, closeTo(0.275, 1e-9));
    });

    test('start again goes back to the beginning', () {
      final run = makeRun()..start();
      tick(100);
      expect(run.elapsed, _s(100));
      run.start();
      expect(run.elapsed, Duration.zero);
      expect(run.isRunning, isTrue);
      tick(3);
      expect(run.elapsed, _s(3));
    });
  });

  group('pause and resume', () {
    test('a paused run keeps its time while the clock moves on', () {
      final run = makeRun()..start();
      tick(15);
      run.pause();
      expect(run.isRunning, isFalse);
      expect(run.elapsed, _s(15));
      tick(600);
      expect(run.elapsed, _s(15));
      expect(run.snapshot().phase!.kind, IntervalPhaseKind.work);
      expect(run.isDone, isFalse);
    });

    test('resume continues from where it stopped, not from the clock', () {
      final run = makeRun()..start();
      tick(15);
      run.pause();
      tick(600);
      run.resume();
      expect(run.isRunning, isTrue);
      expect(run.elapsed, _s(15));
      tick(10);
      expect(run.elapsed, _s(25));
    });

    test('pausing twice or resuming twice changes nothing', () {
      final run = makeRun()..start();
      tick(15);
      run.pause();
      run.pause();
      tick(60);
      expect(run.elapsed, _s(15));
      run.resume();
      tick(5);
      run.resume();
      tick(5);
      expect(run.elapsed, _s(25));
      expect(run.isRunning, isTrue);
    });

    test('several pauses add up only the time spent running', () {
      final run = makeRun()..start();
      tick(10);
      run.pause();
      tick(100);
      run.resume();
      tick(10);
      run.pause();
      tick(100);
      run.resume();
      tick(10);
      expect(run.elapsed, _s(30));
    });
  });

  group('finishing', () {
    test('the run ends at the total and stays there', () {
      final run = makeRun()..start();
      tick(249);
      expect(run.isDone, isFalse);
      expect(run.isRunning, isTrue);
      tick(1);
      expect(run.isDone, isTrue);
      expect(run.isRunning, isFalse);
      expect(run.elapsed, _s(250));
      tick(100000);
      expect(run.elapsed, _s(250), reason: 'clamped to the total');
      final snap = run.snapshot();
      expect(snap.done, isTrue);
      expect(snap.workoutProgress, 1);
    });

    test('a long time in the background lands on done in one read', () {
      final run = makeRun()..start();
      tick(3 * 3600);
      expect(run.snapshot().done, isTrue);
      expect(run.elapsed, _s(250));
    });

    test('pause and resume after the end do nothing', () {
      final run = makeRun()..start();
      tick(300);
      run.pause();
      expect(run.isDone, isTrue);
      expect(run.elapsed, _s(250));
      run.resume();
      expect(run.isRunning, isFalse);
      expect(run.isDone, isTrue);
      expect(run.elapsed, _s(250));
    });

    test('restart and skip after the end do nothing', () {
      final run = makeRun()..start();
      tick(300);
      run.restartRound();
      expect(run.elapsed, _s(250));
      run.skipRound();
      expect(run.elapsed, _s(250));
      expect(run.isDone, isTrue);
      expect(run.isRunning, isFalse);
    });
  });

  group('restartRound', () {
    test('in prepare it goes back to the start of prepare', () {
      final run = makeRun()..start();
      tick(7);
      run.restartRound();
      expect(run.elapsed, Duration.zero);
      expect(run.snapshot().phase!.kind, IntervalPhaseKind.prepare);
    });

    test('in work it goes back to the start of that round', () {
      final run = makeRun()..start();
      tick(10 + 30 + 15); // hiệp 2, đang tập 15 giây
      expect(run.snapshot().phase!.round, 2);
      run.restartRound();
      expect(run.elapsed, _s(40));
      expect(run.snapshot().phase!.kind, IntervalPhaseKind.work);
      expect(run.snapshot().phase!.round, 2);
      expect(run.snapshot().phaseProgress, 0);
    });

    test('in the rest of a round it goes back to the work of that round', () {
      final run = makeRun()..start();
      tick(10 + 20 + 5); // nghỉ của hiệp 1
      expect(run.snapshot().phase!.kind, IntervalPhaseKind.rest);
      run.restartRound();
      expect(run.elapsed, _s(10));
      expect(run.snapshot().phase!.kind, IntervalPhaseKind.work);
      expect(run.snapshot().phase!.round, 1);
    });

    test('it keeps running and keeps counting from the new position', () {
      final run = makeRun()..start();
      tick(10 + 20 + 5);
      run.restartRound();
      expect(run.isRunning, isTrue);
      tick(4);
      expect(run.elapsed, _s(14));
    });

    test('while paused it stays paused', () {
      final run = makeRun()..start();
      tick(10 + 20 + 5);
      run.pause();
      run.restartRound();
      expect(run.isRunning, isFalse);
      expect(run.elapsed, _s(10));
      tick(60);
      expect(run.elapsed, _s(10));
      run.resume();
      tick(2);
      expect(run.elapsed, _s(12));
    });

    test('in a rest between sets it goes back to the start of the rest', () {
      final run = makeRun(
        const IntervalConfig(
          prepare: 10,
          work: 20,
          rest: 10,
          rounds: 2,
          sets: 2,
          setRest: 60,
        ),
      )..start();
      tick(10 + 60 + 25); // nghỉ giữa set, đã qua 25 giây
      expect(run.snapshot().phase!.kind, IntervalPhaseKind.setRest);
      run.restartRound();
      expect(run.elapsed, _s(70));
      expect(run.snapshot().phase!.kind, IntervalPhaseKind.setRest);
    });
  });

  group('skipRound', () {
    test('in prepare it jumps to the first work', () {
      final run = makeRun()..start();
      tick(3);
      run.skipRound();
      expect(run.elapsed, _s(10));
      expect(run.snapshot().phase!.kind, IntervalPhaseKind.work);
      expect(run.snapshot().phase!.round, 1);
    });

    test('in work it jumps to the work of the next round', () {
      final run = makeRun()..start();
      tick(10 + 5);
      run.skipRound();
      expect(run.elapsed, _s(40));
      expect(run.snapshot().phase!.kind, IntervalPhaseKind.work);
      expect(run.snapshot().phase!.round, 2);
    });

    test('in rest it also jumps to the next round', () {
      final run = makeRun()..start();
      tick(10 + 25);
      expect(run.snapshot().phase!.kind, IntervalPhaseKind.rest);
      run.skipRound();
      expect(run.elapsed, _s(40));
      expect(run.snapshot().phase!.round, 2);
    });

    test('in the last round it finishes the workout', () {
      final run = makeRun()..start();
      tick(10 + 7 * 30 + 5);
      expect(run.snapshot().phase!.round, 8);
      run.skipRound();
      expect(run.isDone, isTrue);
      expect(run.isRunning, isFalse);
      expect(run.elapsed, _s(250));
    });

    test('skipping from the start visits every round, then ends', () {
      final run = makeRun()..start();
      final rounds = <int>[];
      for (var i = 0; i < 20 && !run.isDone; i++) {
        run.skipRound();
        final phase = run.snapshot().phase;
        if (phase != null) rounds.add(phase.round);
      }
      expect(rounds, [1, 2, 3, 4, 5, 6, 7, 8]);
      expect(run.isDone, isTrue);
    });

    test('while paused it stays paused', () {
      final run = makeRun()..start();
      tick(15);
      run.pause();
      run.skipRound();
      expect(run.isRunning, isFalse);
      expect(run.elapsed, _s(40));
      tick(100);
      expect(run.elapsed, _s(40));
      run.resume();
      tick(1);
      expect(run.elapsed, _s(41));
    });

    test('at the end of a set it goes through the set rest, then set 2', () {
      final run = makeRun(
        const IntervalConfig(
          prepare: 10,
          work: 20,
          rest: 10,
          rounds: 2,
          sets: 2,
          setRest: 60,
        ),
      )..start();
      tick(10 + 30 + 5); // hiệp 2 của set 1
      run.skipRound();
      expect(run.snapshot().phase!.kind, IntervalPhaseKind.setRest);
      expect(run.snapshot().phase!.set, 1);
      run.skipRound();
      final phase = run.snapshot().phase!;
      expect(phase.kind, IntervalPhaseKind.work);
      expect(phase.set, 2);
      expect(phase.round, 1);
    });

    test('with no prepare the first skip goes to round 2', () {
      final run = makeRun(
        const IntervalConfig(
          prepare: 0,
          work: 20,
          rest: 0,
          rounds: 3,
          sets: 1,
          setRest: 0,
        ),
      )..start();
      expect(run.snapshot().phase!.round, 1);
      run.skipRound();
      expect(run.snapshot().phase!.round, 2);
      expect(run.elapsed, _s(20));
    });
  });

  group('the device clock going backwards', () {
    test('elapsed never goes down', () {
      final run = makeRun()..start();
      tick(20);
      expect(run.elapsed, _s(20));
      now = now.subtract(const Duration(hours: 1));
      expect(run.elapsed, _s(20), reason: 'no loss, no jump');
      expect(run.isRunning, isTrue);
      expect(run.snapshot().phase!.kind, IntervalPhaseKind.work);
    });

    test('after going back, time keeps moving forward', () {
      final run = makeRun()..start();
      tick(20);
      now = now.subtract(const Duration(hours: 1));
      final before = run.elapsed;
      tick(5);
      expect(run.elapsed, greaterThanOrEqualTo(before));
      tick(5);
      expect(run.elapsed, greaterThan(before));
    });

    test('a clock set back while paused changes nothing on resume', () {
      final run = makeRun()..start();
      tick(20);
      run.pause();
      now = now.subtract(const Duration(days: 1));
      run.resume();
      expect(run.elapsed, _s(20));
    });
  });
}
