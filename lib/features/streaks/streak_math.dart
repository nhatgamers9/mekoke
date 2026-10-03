import 'dart:math';

import '../../core/time/local_date.dart';

const kStreakMilestones = [1, 3, 7, 14, 30, 60, 90, 180, 365];

/// Số ngày "sạch": ngày bắt đầu là 0, mỗi nửa đêm thêm 1. Ngày bắt đầu ở
/// tương lai thì là 0.
int daysClean(LocalDate cleanSince, LocalDate today) =>
    max(0, cleanSince.daysUntil(today));

class MilestoneProgress {
  const MilestoneProgress({
    required this.next,
    required this.remaining,
    required this.progress,
  });

  final int next;
  final int remaining;
  final double progress;
}

/// Mốc tiếp theo sau [days]; `null` khi đã qua mốc cuối (365).
MilestoneProgress? nextMilestone(int days) {
  int? next;
  var prev = 0;
  for (final milestone in kStreakMilestones) {
    if (milestone > days) {
      next = milestone;
      break;
    }
    prev = milestone;
  }
  if (next == null) return null;
  return MilestoneProgress(
    next: next,
    remaining: next - days,
    progress: (days - prev) / (next - prev),
  );
}
