import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/time/local_date.dart';
import 'package:steady/features/streaks/streak_math.dart';

void main() {
  final today = LocalDate(2026, 10, 2);

  group('daysClean (option A: start day is 0)', () {
    test('today is 0, yesterday is 1', () {
      expect(daysClean(today, today), 0);
      expect(daysClean(today.addDays(-1), today), 1);
    });

    test('the plan example is 127', () {
      expect(daysClean(LocalDate(2026, 5, 28), today), 127);
    });

    test('a start date in the future never goes negative', () {
      expect(daysClean(today.addDays(1), today), 0);
      expect(daysClean(today.addDays(400), today), 0);
    });

    test('spans over daylight-saving switches are counted by calendar day', () {
      expect(daysClean(LocalDate(2026, 3, 8), LocalDate(2026, 3, 9)), 1);
      expect(daysClean(LocalDate(2026, 11, 1), LocalDate(2026, 11, 2)), 1);
    });

    test('increases by exactly 1 at each midnight', () {
      final since = LocalDate(2026, 5, 28);
      expect(daysClean(since, today.addDays(1)), 128);
    });
  });

  group('kStreakMilestones', () {
    test('matches the plan and is strictly increasing', () {
      expect(kStreakMilestones, [1, 3, 7, 14, 30, 60, 90, 180, 365]);
      for (var i = 1; i < kStreakMilestones.length; i++) {
        expect(kStreakMilestones[i], greaterThan(kStreakMilestones[i - 1]));
      }
    });
  });

  group('nextMilestone', () {
    test('0 days: next is 1, nothing reached yet', () {
      final m = nextMilestone(0)!;
      expect((m.next, m.remaining, m.progress), (1, 1, 0.0));
    });

    test('1 day: just reached 1, next is 3', () {
      final m = nextMilestone(1)!;
      expect(m.next, 3);
      expect(m.remaining, 2);
      expect(m.progress, 0.0);
    });

    test('2 days: halfway from 1 to 3', () {
      final m = nextMilestone(2)!;
      expect(m.next, 3);
      expect(m.remaining, 1);
      expect(m.progress, 0.5);
    });

    test('exactly on a milestone moves on to the next one', () {
      final m = nextMilestone(7)!;
      expect((m.next, m.remaining, m.progress), (14, 7, 0.0));
      final n = nextMilestone(30)!;
      expect((n.next, n.remaining, n.progress), (60, 30, 0.0));
    });

    test('127 days: next is 180, 53 to go, progress 37/90', () {
      final m = nextMilestone(127)!;
      expect(m.next, 180);
      expect(m.remaining, 53);
      expect(m.progress, closeTo(37 / 90, 1e-12));
    });

    test('364 days: one day to 365, progress just below 1', () {
      final m = nextMilestone(364)!;
      expect(m.next, 365);
      expect(m.remaining, 1);
      expect(m.progress, closeTo(184 / 185, 1e-12));
      expect(m.progress, lessThan(1.0));
    });

    test('365 and beyond hide the milestone bar', () {
      expect(nextMilestone(365), isNull);
      expect(nextMilestone(366), isNull);
      expect(nextMilestone(1000), isNull);
    });

    test('progress is always within [0, 1) and remaining positive', () {
      for (var days = 0; days < 365; days++) {
        final m = nextMilestone(days)!;
        expect(m.progress, inInclusiveRange(0.0, 1.0), reason: 'day $days');
        expect(m.progress, lessThan(1.0), reason: 'day $days');
        expect(m.remaining, greaterThan(0), reason: 'day $days');
        expect(m.next - m.remaining, days, reason: 'day $days');
        expect(kStreakMilestones, contains(m.next));
      }
    });
  });
}
