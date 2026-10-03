import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../l10n/app_localizations.dart';
import 'steady_progress_bar.dart';

enum StreakCardSize { lg, sm }

class StreakMilestoneView {
  const StreakMilestoneView({required this.label, required this.progress});

  final String label;
  final double progress;
}

class StreakCard extends StatelessWidget {
  const StreakCard({
    super.key,
    required this.habit,
    required this.days,
    required this.since,
    this.size = StreakCardSize.lg,
    this.milestone,
    this.onTap,
  });

  final String habit;
  final int days;
  final String since;
  final StreakCardSize size;
  final StreakMilestoneView? milestone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final l10n = AppLocalizations.of(context);
    final lg = size == StreakCardSize.lg;
    final radius = BorderRadius.circular(SteadyRadius.lg);
    final count = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '$days',
            style: (lg ? SteadyText.countXl : SteadyText.stat).copyWith(
              color: c.ink,
            ),
          ),
          const SizedBox(width: SteadySpace.s2),
          Text(
            l10n.streakDayUnit(days),
            style: SteadyText.body.copyWith(color: c.inkMuted),
          ),
        ],
      ),
    );
    final m = milestone;
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        child: Material(
          color: c.surface,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.all(SteadySpace.s5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: SteadySpace.s3,
                    children: [
                      Text(
                        habit,
                        style: SteadyText.headline.copyWith(color: c.ink),
                      ),
                      Text(
                        since,
                        style: SteadyText.label.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: SteadySpace.s2),
                  if (lg)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: SteadySpace.s2,
                      ),
                      child: count,
                    )
                  else
                    count,
                  if (m != null) ...[
                    const SizedBox(height: SteadySpace.s2),
                    SteadyProgressBar(
                      value: m.progress,
                      semanticLabel: m.label,
                      tone: SteadyBarTone.tide,
                    ),
                    const SizedBox(height: SteadySpace.s2),
                    Text(
                      m.label,
                      style: SteadyText.caption.copyWith(color: c.inkMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
