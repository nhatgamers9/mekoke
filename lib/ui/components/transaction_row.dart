import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import 'steady_icon.dart';

/// Một khoản chi trong danh sách. [amount] đã định dạng sẵn kèm dấu và ký
/// hiệu tiền. Xếp các hàng liền nhau trong `ClipRRect(lg)` và đặt
/// `divider: false` cho hàng cuối. Chi tiêu là chuyện bình thường nên số tiền
/// luôn màu `ink`, không tô đỏ.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.icon,
    required this.title,
    this.detail,
    required this.amount,
    this.onTap,
    this.divider = true,
  });

  final String icon;
  final String title;
  final String? detail;
  final String amount;
  final VoidCallback? onTap;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    return MergeSemantics(
      child: Material(
        color: c.surface,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(
              horizontal: SteadySpace.s4,
              vertical: SteadySpace.s3,
            ),
            decoration: divider
                ? BoxDecoration(
                    border: Border(bottom: BorderSide(color: c.line)),
                  )
                : null,
            child: LayoutBuilder(
              builder: (context, constraints) => Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c.surface2,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SteadyIcon(icon, size: 20, color: c.ink),
                    ),
                  ),
                  const SizedBox(width: SteadySpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SteadyText.body.copyWith(color: c.ink),
                        ),
                        if (detail != null)
                          Text(
                            detail!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SteadyText.label.copyWith(color: c.inkMuted),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: SteadySpace.s3),
                  // Số tiền lớn thì thu nhỏ lại, không chiếm quá nửa hàng.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth / 2,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        amount,
                        maxLines: 1,
                        style: SteadyText.bodyStrong.copyWith(
                          color: c.ink,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
