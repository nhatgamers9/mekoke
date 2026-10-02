import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import 'steady_icon.dart';

enum SteadyButtonVariant { primary, secondary, ghost, danger }

enum SteadyButtonSize { lg, md }

class SteadyButton extends StatelessWidget {
  const SteadyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SteadyButtonVariant.secondary,
    this.size = SteadyButtonSize.lg,
    this.block = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final SteadyButtonVariant variant;
  final SteadyButtonSize size;
  final bool block;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final (background, foreground) = switch (variant) {
      SteadyButtonVariant.primary => (c.amber, c.onAmber),
      SteadyButtonVariant.secondary => (c.surface2, c.ink),
      SteadyButtonVariant.ghost => (Colors.transparent, c.amber),
      SteadyButtonVariant.danger => (c.roseSoft, c.rose),
    };
    final md = size == SteadyButtonSize.md;
    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background,
        disabledForegroundColor: foreground,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: Size(0, md ? SteadySize.buttonMd : SteadySize.button),
        padding: EdgeInsets.symmetric(
          horizontal: md ? SteadySpace.s5 : SteadySpace.s6,
        ),
        shape: const StadiumBorder(),
        tapTargetSize: MaterialTapTargetSize.padded,
        textStyle: SteadyText.bodyStrong,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            SteadyIcon(icon!, size: 20, color: foreground),
            const SizedBox(width: SteadySpace.s2),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SteadyText.bodyStrong.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
    final result = onPressed == null
        ? Opacity(opacity: 0.4, child: button)
        : button;
    return block ? SizedBox(width: double.infinity, child: result) : result;
  }
}
