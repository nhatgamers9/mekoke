Duration _nonNegative(Duration d) => d.isNegative ? Duration.zero : d;

String _two(int n) => n.toString().padLeft(2, '0');

/// `H:MM:SS`, làm tròn xuống tới giây, giờ không đệm số 0 và không giới hạn
/// ("0:00:00", "9:58:12", "31:12:05"). Giá trị âm tính là 0.
String formatHms(Duration d) {
  final seconds = _nonNegative(d).inSeconds;
  final h = seconds ~/ 3600;
  final m = seconds % 3600 ~/ 60;
  final s = seconds % 60;
  return '$h:${_two(m)}:${_two(s)}';
}

/// `M:SS` khi dưới 1 giờ ("0:10", "4:00", "10:00"), từ 1 giờ trở lên dùng
/// [formatHms]. Giá trị âm tính là 0.
String formatClock(Duration d) {
  final clamped = _nonNegative(d);
  if (clamped.inHours >= 1) return formatHms(clamped);
  final seconds = clamped.inSeconds;
  return '${seconds ~/ 60}:${_two(seconds % 60)}';
}

/// Làm tròn lên tới giây: còn 13,4 giây thì ra 14. Giá trị âm tính là 0.
int ceilSeconds(Duration d) {
  final micros = _nonNegative(d).inMicroseconds;
  return (micros + Duration.microsecondsPerSecond - 1) ~/
      Duration.microsecondsPerSecond;
}

/// (số giờ, số phút làm tròn xuống đủ 2 chữ số), ví dụ (6, "01").
/// Giá trị âm tính là 0.
(int, String) splitHm(Duration d) {
  final clamped = _nonNegative(d);
  return (clamped.inHours, _two(clamped.inMinutes % 60));
}
