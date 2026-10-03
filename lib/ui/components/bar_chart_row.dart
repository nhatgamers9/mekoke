import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';

/// Một thanh ngang của biểu đồ "chi theo danh mục": nhãn ở trên, thanh `amber`
/// và số tiền ngay sau đầu thanh. [fraction] là độ dài so với thanh dài nhất
/// (0 đến 1). Thanh chỉ để trang trí; trình đọc màn hình đọc nhãn và số tiền.
class BarChartRow extends StatelessWidget {
  const BarChartRow({
    super.key,
    required this.label,
    required this.value,
    required this.fraction,
  });

  final String label;
  final String value;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    return MergeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SteadyText.label.copyWith(color: c.ink),
          ),
          const SizedBox(height: SteadySpace.s1),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              // Một phần ba bề rộng luôn chừa cho nhãn số, kể cả ở thanh dài nhất.
              final maxBar = w - w / 3 - SteadySpace.s2;
              final f = fraction.isNaN ? 0.0 : fraction.clamp(0.0, 1.0);
              // Khoản rất nhỏ vẫn có một vệt nhìn thấy được.
              final bar = f == 0 ? 0.0 : math.max(4.0, maxBar * f);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: bar,
                    height: 12,
                    decoration: BoxDecoration(
                      color: c.amber,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: SteadySpace.s2),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          value,
                          maxLines: 1,
                          style: SteadyText.label.copyWith(
                            color: c.ink,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
