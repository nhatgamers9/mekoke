import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';

class SteadySegment<T> {
  const SteadySegment(this.value, this.label);

  final T value;
  final String label;
}

/// Chọn một trong vài lựa chọn loại trừ nhau. Mục đang chọn đảo màu
/// (`ink` / `bg`), không dùng amber: amber dành cho hành động chính.
class SteadySegmentedControl<T> extends StatelessWidget {
  const SteadySegmentedControl({
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
    final c = SteadyColors.of(context);
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: SteadySpace.s1),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(SteadyRadius.full),
        ),
        child: Row(
          children: [
            for (final (i, option) in options.indexed) ...[
              if (i > 0) const SizedBox(width: SteadySpace.s1),
              Expanded(
                child: _SegmentItem(
                  label: option.label,
                  selected: option.value == value,
                  onTap: () => onChanged(option.value),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  const _SegmentItem({
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
      // Vùng bấm phủ hết chiều cao 48, dù viên chỉ cao 40.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: SteadySpace.s1),
          child: SizedBox(
            height: 40,
            child: Material(
              color: selected ? c.ink : Colors.transparent,
              shape: shape,
              child: InkWell(
                onTap: onTap,
                customBorder: shape,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SteadySpace.s3,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
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
      ),
    );
  }
}
