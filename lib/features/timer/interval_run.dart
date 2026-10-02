import 'package:clock/clock.dart';

import 'interval_timeline.dart';

/// Một lần chạy bài tập theo đồng hồ. Thời gian đã trôi qua được cộng dồn mỗi
/// lần đọc nên không bao giờ giảm, kể cả khi đồng hồ máy bị chỉnh lùi.
class IntervalRun {
  IntervalRun(this.timeline, this._clock);

  final IntervalTimeline timeline;
  final Clock _clock;

  Duration _elapsed = Duration.zero;
  DateTime? _runningSince;

  /// Cộng phần thời gian vừa trôi qua vào [_elapsed]. Dừng chạy khi đến cuối.
  void _sync() {
    final since = _runningSince;
    if (since == null) return;
    final now = _clock.now();
    final delta = now.difference(since);
    // Đồng hồ máy lùi: neo lại tại bây giờ, không trừ vào phần đã trôi qua.
    if (delta.isNegative) {
      _runningSince = now;
      return;
    }
    _elapsed += delta;
    if (_elapsed >= timeline.total) {
      _elapsed = timeline.total;
      _runningSince = null;
    } else {
      _runningSince = now;
    }
  }

  bool get isRunning {
    _sync();
    return _runningSince != null;
  }

  bool get isDone {
    _sync();
    return _elapsed >= timeline.total;
  }

  Duration get elapsed {
    _sync();
    return _elapsed;
  }

  /// Bắt đầu từ đầu bài.
  void start() {
    _elapsed = Duration.zero;
    _runningSince = _clock.now();
  }

  void pause() {
    _sync();
    if (isDone) return;
    _runningSince = null;
  }

  void resume() {
    _sync();
    if (isDone || _runningSince != null) return;
    _runningSince = _clock.now();
  }

  /// Về đầu hiệp hiện tại (nhóm pha hiện tại).
  void restartRound() {
    final snap = snapshot();
    if (snap.done) return;
    _jumpTo(_groupStart(snap.index));
  }

  /// Sang đầu hiệp kế tiếp; không còn thì kết thúc bài.
  void skipRound() {
    final snap = snapshot();
    if (snap.done) return;
    final phases = timeline.phases;
    final group = phases[snap.index].group;
    var i = snap.index;
    while (i < phases.length && phases[i].group == group) {
      i++;
    }
    _jumpTo(i < phases.length ? phases[i].start : timeline.total);
  }

  IntervalSnapshot snapshot() => timeline.at(elapsed);

  Duration _groupStart(int index) {
    final phases = timeline.phases;
    final group = phases[index].group;
    var i = index;
    while (i > 0 && phases[i - 1].group == group) {
      i--;
    }
    return phases[i].start;
  }

  /// Nhảy tới [position] nhưng giữ nguyên trạng thái chạy hay tạm dừng.
  void _jumpTo(Duration position) {
    final wasRunning = _runningSince != null;
    _elapsed = position;
    if (_elapsed >= timeline.total) {
      _runningSince = null;
    } else if (wasRunning) {
      _runningSince = _clock.now();
    }
  }
}
