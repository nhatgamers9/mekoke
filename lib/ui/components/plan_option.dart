import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import 'steady_icon.dart';

/// Thẻ chọn một gói trả phí. [price] là chuỗi đã định dạng: component không tự
/// định dạng tiền. Đang chọn: viền 2px `amber` và ô radio đặc màu `amber` có
/// dấu tích; chưa chọn: viền `lineStrong`, ô radio rỗng.
class PlanOption extends StatelessWidget {
  const PlanOption({
    super.key,
    required this.title,
    required this.price,
    required this.period,
    required this.selected,
    required this.onTap,
    this.note,
  });

  final String title;
  final String price;
  final String period;
  final bool selected;
  final VoidCallback onTap;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final note = this.note;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SteadyRadius.lg),
      side: BorderSide(width: 2, color: selected ? c.amber : c.lineStrong),
    );
    final card = Material(
      color: c.surface,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: SteadySize.tap),
          child: Padding(
            padding: const EdgeInsets.all(SteadySpace.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? c.amber : null,
                    border: Border.all(
                      color: selected ? c.amber : c.lineStrong,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Center(
                          child: SteadyIcon(
                            SteadyIcons.check,
                            size: 16,
                            color: c.onAmber,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: SteadySpace.s3),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: SteadyText.headline.copyWith(color: c.ink),
                      ),
                      if (note != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          note,
                          style: SteadyText.label.copyWith(color: c.inkMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: SteadySpace.s3),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      maxLines: 1,
                      style: SteadyText.bodyStrong.copyWith(color: c.ink),
                    ),
                    Text(
                      period,
                      maxLines: 1,
                      style: SteadyText.caption.copyWith(color: c.inkMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: [title, price, period, ?note].join(', '),
      onTap: onTap,
      excludeSemantics: true,
      child: card,
    );
  }
}
