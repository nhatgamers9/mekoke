import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';

import 'local_date.dart';

/// Giữ "hôm nay" theo giờ máy và tự cập nhật khi qua nửa đêm hoặc khi app
/// quay lại từ nền.
class TodayNotifier extends ValueNotifier<LocalDate>
    with WidgetsBindingObserver {
  TodayNotifier(this._clock) : super(LocalDate.fromDateTime(_clock.now()));

  final Clock _clock;
  Timer? _timer;
  bool _started = false;

  void refresh() {
    value = LocalDate.fromDateTime(_clock.now());
  }

  void start() {
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addObserver(this);
    }
    _schedule();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    if (_started) {
      _started = false;
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  void _schedule() {
    _timer?.cancel();
    final now = _clock.now();
    final next = DateTime(now.year, now.month, now.day + 1, 0, 0, 1);
    _timer = Timer(next.difference(now), () {
      refresh();
      _schedule();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh();
      _schedule();
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
