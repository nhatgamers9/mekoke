import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import 'steady_icon.dart';

enum SteadyChipTone { neutral, amber, tide, rose }

class SteadyChip extends StatelessWidget {
  const SteadyChip({
    super.key,
    required this.label,
    this.tone = SteadyChipTone.neutral,
    this.icon,
  });

  final String label;
  final SteadyChipTone tone;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final (background, foreground) = switch (tone) {
      SteadyChipTone.neutral => (c.surface2, c.inkMuted),
      SteadyChipTone.amber => (c.amberSoft, c.amber),
      SteadyChipTone.tide => (c.tideSoft, c.tide),
      SteadyChipTone.rose => (c.roseSoft, c.rose),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(
        horizontal: SteadySpace.s3,
        vertical: SteadySpace.s1,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(SteadyRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            SteadyIcon(icon!, size: 16, color: foreground),
            const SizedBox(width: SteadySpace.s1),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SteadyText.label.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
