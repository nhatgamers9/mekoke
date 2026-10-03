import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

enum SteadyBarTone { amber, tide }

class SteadyProgressBar extends StatelessWidget {
  const SteadyProgressBar({
    super.key,
    required this.value,
    required this.semanticLabel,
    this.tone = SteadyBarTone.amber,
  });

  final double value;
  final String semanticLabel;
  final SteadyBarTone tone;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final fill = tone == SteadyBarTone.tide ? c.tide : c.amber;
    final radius = BorderRadius.circular(SteadyRadius.sm);
    return Semantics(
      label: semanticLabel,
      value: '${(v * 100).round()}%',
      excludeSemantics: true,
      child: Container(
        height: 8,
        decoration: BoxDecoration(color: c.surface2, borderRadius: radius),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: v,
          child: DecoratedBox(
            decoration: BoxDecoration(color: fill, borderRadius: radius),
          ),
        ),
      ),
    );
  }
}
