import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import 'steady_segmented_control.dart';

/// Hàng chip chọn một, cuộn ngang. Mục đang chọn đảo màu (`ink` / `bg`).
class SteadyFilterChips<T> extends StatelessWidget {
  const SteadyFilterChips({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final List<SteadySegment<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (i, option) in options.indexed) ...[
              if (i > 0) const SizedBox(width: SteadySpace.s2),
              _ChipItem(
                label: option.label,
                selected: option.value == value,
                onTap: () => onChanged(option.value),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChipItem extends StatelessWidget {
  const _ChipItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    const shape = StadiumBorder();
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      // Chip cao 36 nhưng vùng bấm cao 48.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: SizedBox(
            height: 36,
            child: Material(
              color: selected ? c.ink : c.surface2,
              shape: shape,
              child: InkWell(
                onTap: onTap,
                customBorder: shape,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SteadySpace.s4,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: SteadyText.label.copyWith(
                        color: selected ? c.bg : c.inkMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
