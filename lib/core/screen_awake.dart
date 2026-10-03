import 'package:wakelock_plus/wakelock_plus.dart';

/// Giữ màn hình sáng. Tách thành interface để test thay bằng bản giả.
abstract interface class ScreenAwake {
  Future<void> keepOn(bool on);
}

class WakelockScreenAwake implements ScreenAwake {
  const WakelockScreenAwake();

  @override
  Future<void> keepOn(bool on) async {
    // Giữ sáng chỉ là tiện ích: không bao giờ để lỗi lọt ra ngoài.
    try {
      await WakelockPlus.toggle(enable: on);
    } catch (_) {}
  }
}
