import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';

enum SteadyStatusTone { info, error }

/// Một dòng báo trạng thái ngay tại chỗ (không nổi lên như snackbar), nên
/// không bao giờ nằm dưới sheet hay che nút bên cạnh. Lỗi dùng màu `ink`,
/// không dùng `rose`: rose chỉ dành cho xoá dữ liệu và vượt ngân sách.
class SteadyInlineStatus extends StatelessWidget {
  const SteadyInlineStatus({
    super.key,
    required this.message,
    this.tone = SteadyStatusTone.info,
  });

  final String message;
  final SteadyStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: SteadyText.label.copyWith(
          color: tone == SteadyStatusTone.error ? c.ink : c.inkMuted,
        ),
      ),
    );
  }
}
