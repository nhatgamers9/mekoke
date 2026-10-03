import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import 'steady_icon.dart';

enum SteadyIconButtonVariant { play, filled, plain }

/// Nút tròn chỉ có icon; [semanticLabel] bắt buộc để trình đọc màn hình đọc được.
class SteadyIconButton extends StatelessWidget {
  const SteadyIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.variant = SteadyIconButtonVariant.filled,
  });

  final String icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final SteadyIconButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final (background, foreground) = switch (variant) {
      SteadyIconButtonVariant.play => (c.amber, c.onAmber),
      SteadyIconButtonVariant.filled => (c.surface2, c.ink),
      SteadyIconButtonVariant.plain => (Colors.transparent, c.inkMuted),
    };
    final play = variant == SteadyIconButtonVariant.play;
    final size = play ? SteadySize.play : SteadySize.tap;
    const shape = CircleBorder();
    final button = Material(
      color: background,
      shape: shape,
      child: InkWell(
        onTap: onPressed,
        customBorder: shape,
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: SteadyIcon(icon, size: play ? 32 : 22, color: foreground),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      onTap: onPressed,
      excludeSemantics: true,
      child: onPressed == null ? Opacity(opacity: 0.4, child: button) : button,
    );
  }
}
