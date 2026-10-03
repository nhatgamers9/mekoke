import '../../core/time/local_date.dart';
import '../../data/database.dart';

sealed class FastingStatus {
  const FastingStatus();
}

/// Đang nhịn: vẫn đếm tiếp sau giờ mục tiêu cho tới khi người dùng kết thúc.
final class FastActive extends FastingStatus {
  const FastActive({required this.fast, required this.elapsed});

  final Fast fast;

  /// Không âm.
  final Duration elapsed;

  Duration get goal => Duration(minutes: fast.goalMinutes);

  DateTime get goalAt => fast.startedAt.add(goal);

  bool get goalReached => elapsed >= goal;

  Duration get left => goalReached ? Duration.zero : goal - elapsed;

  Duration get over => goalReached ? elapsed - goal : Duration.zero;

  double get progress => _ratio(elapsed, goal);
}

/// Cửa sổ ăn ngay sau một lần nhịn: (24 giờ - mục tiêu) kể từ lúc kết thúc.
final class FastEating extends FastingStatus {
  const FastEating({required this.last, required this.sinceEnd});

  final Fast last;
  final Duration sinceEnd;

  Duration get window => _day - Duration(minutes: last.goalMinutes);

  DateTime get windowEndsAt => last.endedAt!.add(window);

  double get progress => _ratio(sinceEnd, window);
}

final class FastIdle extends FastingStatus {
  const FastIdle({this.last});

  final Fast? last;
}

const _day = Duration(hours: 24);

double _ratio(Duration part, Duration whole) {
  if (whole <= Duration.zero) return 1;
  return (part.inMicroseconds / whole.inMicroseconds).clamp(0.0, 1.0);
}

/// Mọi phép trừ dùng [DateTime.difference] (thời gian tuyệt đối) nên giờ mùa
/// hè không làm lệch kết quả.
FastingStatus fastingStatusAt(DateTime now, {Fast? active, Fast? lastEnded}) {
  if (active != null) {
    final elapsed = now.difference(active.startedAt);
    return FastActive(
      fast: active,
      elapsed: elapsed.isNegative ? Duration.zero : elapsed,
    );
  }
  final endedAt = lastEnded?.endedAt;
  if (lastEnded != null && endedAt != null) {
    final sinceEnd = now.difference(endedAt);
    final eating = FastEating(last: lastEnded, sinceEnd: sinceEnd);
    if (!sinceEnd.isNegative && sinceEnd < eating.window) return eating;
  }
  return FastIdle(last: lastEnded);
}

/// Thời gian đã nhịn của một lần đã kết thúc, không âm.
Duration fastDuration(Fast f) {
  final endedAt = f.endedAt;
  if (endedAt == null) return Duration.zero;
  final d = endedAt.difference(f.startedAt);
  return d.isNegative ? Duration.zero : d;
}

bool fastReachedGoal(Fast f) =>
    f.endedAt != null && fastDuration(f) >= Duration(minutes: f.goalMinutes);

/// Số ngày liên tiếp, tính lùi từ [today] (hoặc từ hôm qua nếu hôm nay chưa
/// có), mà mỗi ngày có ít nhất một lần nhịn đạt mục tiêu. Ngày của một lần
/// nhịn là ngày nó kết thúc. Lần kết thúc sớm không được tính nhưng cũng
/// không làm mất một ngày đã có lần đạt mục tiêu.
int fastingStreak(Iterable<Fast> ended, LocalDate today) {
  final days = <int>{
    for (final f in ended)
      if (fastReachedGoal(f)) LocalDate.fromDateTime(f.endedAt!).epochDay,
  };
  var day = today.epochDay;
  if (!days.contains(day)) day--;
  var count = 0;
  while (days.contains(day)) {
    count++;
    day--;
  }
  return count;
}
