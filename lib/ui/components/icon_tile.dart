import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import 'steady_icon.dart';

/// Một ô icon có nhãn trong lưới chọn (danh mục chi). [selected] là `null` cho
/// ô hành động (ví dụ "More"): ô đó không thuộc nhóm chọn một. Đang chọn: đĩa
/// nền `amberSoft`, viền trong 2px `amber`, icon `amber`.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool? selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final on = selected ?? false;
    final radius = BorderRadius.circular(SteadyRadius.md);
    final tile = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: SteadySpace.s2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on ? c.amberSoft : c.surface,
                  border: on ? Border.all(color: c.amber, width: 2) : null,
                ),
                child: Center(
                  child: SteadyIcon(
                    icon,
                    size: 26,
                    color: on ? c.amber : c.ink,
                  ),
                ),
              ),
              const SizedBox(height: SteadySpace.s2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: SteadyText.caption.copyWith(
                  color: on ? c.ink : c.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: selected == null ? null : true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: tile,
    );
  }
}
