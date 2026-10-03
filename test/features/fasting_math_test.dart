import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/time/local_date.dart';
import 'package:steady/data/database.dart';
import 'package:steady/features/timer/fasting_math.dart';
import 'package:steady/features/timer/fasting_plan.dart';

int _nextId = 1;

Fast _fast({
  FastingPlan plan = FastingPlan.h16,
  int? goalMinutes,
  required DateTime startedAt,
  DateTime? endedAt,
}) => Fast(
  id: _nextId++,
  plan: plan,
  goalMinutes: goalMinutes ?? plan.fastHours * 60,
  startedAt: startedAt,
  endedAt: endedAt,
);

/// Một lần nhịn đã kết thúc, đủ 16 giờ, kết thúc lúc [endedAt].
Fast _reached(DateTime endedAt, {FastingPlan plan = FastingPlan.h16}) => _fast(
  plan: plan,
  startedAt: endedAt.subtract(Duration(hours: plan.fastHours)),
  endedAt: endedAt,
);

/// Một lần nhịn kết thúc sớm (chỉ 2 giờ).
Fast _early(DateTime endedAt) => _fast(
  startedAt: endedAt.subtract(const Duration(hours: 2)),
  endedAt: endedAt,
);

void main() {
  final start = DateTime(2026, 10, 2, 21);

  group('FastingPlan', () {
    test('16:8, 18:6, 20:4 and OMAD (23 hours of fasting)', () {
      expect(FastingPlan.values, [
        FastingPlan.h16,
        FastingPlan.h18,
        FastingPlan.h20,
        FastingPlan.omad,
      ]);
      expect(FastingPlan.values.map((p) => p.fastHours), [16, 18, 20, 23]);
    });
  });

  group('fastingStatusAt: active', () {
    test('a running fast counts up from startedAt', () {
      final active = _fast(startedAt: start);
      final status = fastingStatusAt(
        start.add(const Duration(hours: 10)),
        active: active,
      );
      expect(status, isA<FastActive>());
      status as FastActive;
      expect(status.fast, active);
      expect(status.elapsed, const Duration(hours: 10));
      expect(status.goal, const Duration(hours: 16));
      expect(status.goalAt, DateTime(2026, 10, 3, 13));
      expect(status.goalReached, isFalse);
      expect(status.left, const Duration(hours: 6));
      expect(status.over, Duration.zero);
      expect(status.progress, closeTo(10 / 16, 1e-12));
    });

    test('the instant before the goal is not reached yet', () {
      final active = _fast(startedAt: start);
      final status = fastingStatusAt(
        start.add(const Duration(hours: 16) - const Duration(seconds: 1)),
        active: active,
      ) as FastActive;
      expect(status.goalReached, isFalse);
      expect(status.left, const Duration(seconds: 1));
      expect(status.over, Duration.zero);
      expect(status.progress, lessThan(1));
    });

    test('exactly at the goal it counts as reached, nothing left or over', () {
      final active = _fast(startedAt: start);
      final status = fastingStatusAt(
        start.add(const Duration(hours: 16)),
        active: active,
      ) as FastActive;
      expect(status.goalReached, isTrue);
      expect(status.left, Duration.zero);
      expect(status.over, Duration.zero);
      expect(status.progress, 1);
    });

    test('after the goal it keeps counting and reports time past the goal', () {
      final active = _fast(startedAt: start);
      final status = fastingStatusAt(
        start.add(const Duration(hours: 31, minutes: 12, seconds: 5)),
        active: active,
      ) as FastActive;
      expect(
        status.elapsed,
        const Duration(hours: 31, minutes: 12, seconds: 5),
      );
      expect(status.goalReached, isTrue);
      expect(status.left, Duration.zero);
      expect(status.over, const Duration(hours: 15, minutes: 12, seconds: 5));
      expect(status.progress, 1, reason: 'the ring stays full');
    });

    test('a clock set before startedAt gives zero, never a negative', () {
      final active = _fast(startedAt: start);
      final status = fastingStatusAt(
        start.subtract(const Duration(hours: 1)),
        active: active,
      ) as FastActive;
      expect(status.elapsed, Duration.zero);
      expect(status.progress, 0);
      expect(status.left, const Duration(hours: 16));
      expect(status.goalReached, isFalse);
    });

    test('an active fast wins over a recently ended one', () {
      final ended = _reached(start);
      final active = _fast(startedAt: start.add(const Duration(hours: 1)));
      final status = fastingStatusAt(
        start.add(const Duration(hours: 2)),
        active: active,
        lastEnded: ended,
      );
      expect(status, isA<FastActive>());
    });

    test('OMAD has a 23-hour goal', () {
      final active = _fast(plan: FastingPlan.omad, startedAt: start);
      final status = fastingStatusAt(
        start.add(const Duration(hours: 22)),
        active: active,
      ) as FastActive;
      expect(status.goal, const Duration(hours: 23));
      expect(status.left, const Duration(hours: 1));
    });
  });

  group('fastingStatusAt: eating window and idle', () {
    final endedAt = DateTime(2026, 10, 3, 7); // sau 16 giờ nhịn

    test('right at the end of the fast it is EATING', () {
      final last = _reached(endedAt);
      final status = fastingStatusAt(endedAt, lastEnded: last);
      expect(status, isA<FastEating>());
      status as FastEating;
      expect(status.last, last);
      expect(status.sinceEnd, Duration.zero);
      expect(status.window, const Duration(hours: 8));
      expect(status.windowEndsAt, DateTime(2026, 10, 3, 15));
      expect(status.progress, 0);
    });

    test('the window is 24 hours minus the goal of that fast', () {
      for (final (plan, hours) in [
        (FastingPlan.h16, 8),
        (FastingPlan.h18, 6),
        (FastingPlan.h20, 4),
        (FastingPlan.omad, 1),
      ]) {
        final last = _reached(endedAt, plan: plan);
        final status = fastingStatusAt(endedAt, lastEnded: last) as FastEating;
        expect(status.window, Duration(hours: hours), reason: '$plan');
        expect(status.windowEndsAt, endedAt.add(Duration(hours: hours)));
      }
    });

    test('the window follows the goal, not the time actually fasted', () {
      // Đặt mục tiêu 16 giờ nhưng nhịn tới 20 giờ: cửa sổ vẫn là 8 giờ.
      final last = _fast(
        startedAt: endedAt.subtract(const Duration(hours: 20)),
        endedAt: endedAt,
      );
      final status = fastingStatusAt(endedAt, lastEnded: last) as FastEating;
      expect(status.window, const Duration(hours: 8));
    });

    test('progress runs from 0 to 1 across the window', () {
      final last = _reached(endedAt);
      final half = fastingStatusAt(
        endedAt.add(const Duration(hours: 4)),
        lastEnded: last,
      ) as FastEating;
      expect(half.progress, closeTo(0.5, 1e-12));
      expect(half.sinceEnd, const Duration(hours: 4));
    });

    test('one second before the window ends it is still EATING', () {
      final last = _reached(endedAt);
      final status = fastingStatusAt(
        endedAt.add(const Duration(hours: 8) - const Duration(seconds: 1)),
        lastEnded: last,
      );
      expect(status, isA<FastEating>());
    });

    test('exactly at the end of the window it is idle', () {
      final last = _reached(endedAt);
      final status = fastingStatusAt(
        endedAt.add(const Duration(hours: 8)),
        lastEnded: last,
      );
      expect(status, isA<FastIdle>());
      expect((status as FastIdle).last, last);
    });

    test('a long time later it is idle and remembers the last fast', () {
      final last = _reached(endedAt);
      final status = fastingStatusAt(
        endedAt.add(const Duration(days: 30)),
        lastEnded: last,
      );
      expect(status, isA<FastIdle>());
      expect((status as FastIdle).last, last);
    });

    test('a clock set before endedAt is idle, not a negative eating time', () {
      final last = _reached(endedAt);
      final status = fastingStatusAt(
        endedAt.subtract(const Duration(minutes: 5)),
        lastEnded: last,
      );
      expect(status, isA<FastIdle>());
    });

    test('a 24-hour goal leaves no eating window', () {
      final last = _fast(
        goalMinutes: 24 * 60,
        startedAt: endedAt.subtract(const Duration(hours: 24)),
        endedAt: endedAt,
      );
      expect(fastingStatusAt(endedAt, lastEnded: last), isA<FastIdle>());
    });

    test('no fasts at all is idle with nothing to show', () {
      final status = fastingStatusAt(start);
      expect(status, isA<FastIdle>());
      expect((status as FastIdle).last, isNull);
    });
  });

  group('fastDuration and fastReachedGoal', () {
    test('duration is endedAt minus startedAt', () {
      final f = _fast(
        startedAt: start,
        endedAt: start.add(const Duration(hours: 10, minutes: 30)),
      );
      expect(fastDuration(f), const Duration(hours: 10, minutes: 30));
    });

    test('a fast that has not ended has no duration and no goal reached', () {
      final f = _fast(startedAt: start);
      expect(fastDuration(f), Duration.zero);
      expect(fastReachedGoal(f), isFalse);
    });

    test('endedAt before startedAt gives zero, never a negative', () {
      final f = _fast(
        startedAt: start,
        endedAt: start.subtract(const Duration(minutes: 1)),
      );
      expect(fastDuration(f), Duration.zero);
      expect(fastReachedGoal(f), isFalse);
    });

    test('the goal counts when the fast lasted at least the goal', () {
      final exactly = _fast(
        startedAt: start,
        endedAt: start.add(const Duration(hours: 16)),
      );
      final oneSecondShort = _fast(
        startedAt: start,
        endedAt: start.add(
          const Duration(hours: 16) - const Duration(seconds: 1),
        ),
      );
      final over = _fast(
        startedAt: start,
        endedAt: start.add(const Duration(hours: 30)),
      );
      expect(fastReachedGoal(exactly), isTrue);
      expect(fastReachedGoal(oneSecondShort), isFalse);
      expect(fastReachedGoal(over), isTrue);
    });
  });

  group('fastingStreak', () {
    final today = LocalDate(2026, 10, 2);
    DateTime at(int month, int day, [int hour = 12]) =>
        DateTime(2026, month, day, hour);

    test('no fasts means no streak', () {
      expect(fastingStreak(const [], today), 0);
    });

    test('a fast that reached its goal and ended today counts as 1', () {
      expect(fastingStreak([_reached(at(10, 2))], today), 1);
    });

    test('nothing today yet: count back from yesterday', () {
      expect(fastingStreak([_reached(at(10, 1))], today), 1);
      expect(
        fastingStreak([_reached(at(10, 1)), _reached(at(9, 30))], today),
        2,
      );
    });

    test('the last fast two days ago breaks the streak: back to 0', () {
      expect(fastingStreak([_reached(at(9, 30))], today), 0);
    });

    test('consecutive days add up, a gap ends the run', () {
      expect(
        fastingStreak([
          _reached(at(10, 2)),
          _reached(at(10, 1)),
          _reached(at(9, 30)),
        ], today),
        3,
      );
      expect(
        fastingStreak([
          _reached(at(10, 2)),
          _reached(at(9, 30)),
          _reached(at(9, 29)),
        ], today),
        1,
        reason: 'Oct 1 is missing',
      );
    });

    test('two fasts on the same day count once', () {
      expect(
        fastingStreak([_reached(at(10, 2, 8)), _reached(at(10, 2, 23))], today),
        1,
      );
    });

    test('a fast belongs to the day it ENDED on', () {
      // Bắt đầu 1/10 lúc 20:00, kết thúc 2/10 lúc 12:00: tính cho ngày 2/10.
      final overnight = _fast(
        startedAt: DateTime(2026, 10, 1, 20),
        endedAt: DateTime(2026, 10, 2, 12),
      );
      expect(fastingStreak([overnight], today), 1);
      expect(
        fastingStreak([overnight], LocalDate(2026, 10, 3)),
        1,
        reason: 'ended yesterday, counted from yesterday',
      );
      expect(fastingStreak([overnight], LocalDate(2026, 10, 4)), 0);
    });

    test('a fast that ended early is not counted', () {
      expect(fastingStreak([_early(at(10, 2))], today), 0);
      expect(
        fastingStreak([_reached(at(10, 1)), _early(at(10, 2))], today),
        1,
        reason: 'the early fast today does not erase yesterday',
      );
    });

    test('an early fast on a day does not remove a goal fast the same day', () {
      expect(
        fastingStreak([_early(at(10, 2, 20)), _reached(at(10, 2, 12))], today),
        1,
      );
    });

    test('a day with only an early fast leaves a gap in the run', () {
      expect(
        fastingStreak([
          _reached(at(10, 2)),
          _early(at(10, 1)),
          _reached(at(9, 30)),
        ], today),
        1,
      );
    });

    test('a fast that is still running is ignored', () {
      expect(fastingStreak([_fast(startedAt: at(10, 1))], today), 0);
    });

    test('a streak crossing the end of a month and a year', () {
      expect(
        fastingStreak([
          _reached(DateTime(2026, 1, 1, 12)),
          _reached(DateTime(2025, 12, 31, 12)),
          _reached(DateTime(2025, 12, 30, 12)),
        ], LocalDate(2026, 1, 1)),
        3,
      );
    });

    test('input order does not matter', () {
      final fasts = [
        _reached(at(9, 30)),
        _reached(at(10, 2)),
        _reached(at(10, 1)),
      ];
      expect(fastingStreak(fasts, today), 3);
      expect(fastingStreak(fasts.reversed, today), 3);
    });
  });

  group('daylight saving (uses absolute time, not wall-clock time)', () {
    // Trên máy ở múi giờ không đổi giờ (như UTC) các nhánh `hasGap` và
    // `hasOverlap` là false; chạy lại với `TZ=America/New_York` để thấy cả hai.
    final hasGap =
        DateTime(2026, 3, 7, 21).timeZoneOffset !=
        DateTime(2026, 3, 8, 13).timeZoneOffset;
    final hasOverlap =
        DateTime(2026, 10, 31, 21).timeZoneOffset !=
        DateTime(2026, 11, 1, 12).timeZoneOffset;

    test('the night the clocks go forward is one hour shorter', () {
      final f = _fast(
        startedAt: DateTime(2026, 3, 7, 21),
        endedAt: DateTime(2026, 3, 8, 13),
      );
      // 21:00 -> 13:00 là 16 giờ trên đồng hồ treo tường.
      expect(
        fastDuration(f),
        hasGap ? const Duration(hours: 15) : const Duration(hours: 16),
      );
      expect(fastReachedGoal(f), !hasGap);
    });

    test('the night the clocks go back is one hour longer', () {
      final f = _fast(
        startedAt: DateTime(2026, 10, 31, 21),
        endedAt: DateTime(2026, 11, 1, 12),
      );
      // 21:00 -> 12:00 là 15 giờ trên đồng hồ treo tường.
      expect(
        fastDuration(f),
        hasOverlap ? const Duration(hours: 16) : const Duration(hours: 15),
      );
      expect(fastReachedGoal(f), hasOverlap);
    });

    test('the goal time of a fast started before the change', () {
      final active = _fast(startedAt: DateTime(2026, 3, 7, 20));
      final status = fastingStatusAt(
        DateTime(2026, 3, 8, 6),
        active: active,
      ) as FastActive;
      // 16 giờ thật sau 20:00 ngày 7/3.
      expect(status.goalAt.hour, hasGap ? 13 : 12);
      expect(status.goalAt.day, 8);
      // Từ 20:00 tới 06:00 là 10 giờ treo tường; thật sự 9 giờ nếu mất một giờ.
      expect(
        status.elapsed,
        hasGap ? const Duration(hours: 9) : const Duration(hours: 10),
      );
    });

    test('a streak over the change has no missing or doubled day', () {
      final fasts = [
        _fast(
          startedAt: DateTime(2026, 3, 7, 6),
          endedAt: DateTime(2026, 3, 7, 23),
        ),
        _fast(
          startedAt: DateTime(2026, 3, 8, 6),
          endedAt: DateTime(2026, 3, 8, 23),
        ),
        _fast(
          startedAt: DateTime(2026, 3, 9, 6),
          endedAt: DateTime(2026, 3, 9, 23),
        ),
      ];
      expect(fastingStreak(fasts, LocalDate(2026, 3, 9)), 3);
      expect(fastingStreak(fasts, LocalDate(2026, 3, 10)), 3);
    });
  });
}
