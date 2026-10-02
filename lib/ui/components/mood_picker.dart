import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../features/check_in/check_in_rules.dart';
import '../../l10n/app_localizations.dart';

const _mouths = {
  Mood.awful: 'M8 16.5q4-4 8 0',
  Mood.low: 'M8.5 16q3.5-2 7 0',
  Mood.okay: 'M8.5 15.5h7',
  Mood.good: 'M8.5 14.5q3.5 2.5 7 0',
  Mood.great: 'M7.5 14q4.5 4.5 9 0',
};

final _faceSvgs = {
  for (final mood in Mood.values)
    mood:
        '<svg width="32" height="32" viewBox="0 0 24 24" fill="none" '
        'stroke="#000" stroke-width="1.75" stroke-linecap="round">'
        '<circle cx="12" cy="12" r="9.5"/>'
        '<circle cx="9" cy="10" r="0.6" fill="#000"/>'
        '<circle cx="15" cy="10" r="0.6" fill="#000"/>'
        '<path d="${_mouths[mood]}"/></svg>',
};

String _moodLabel(AppLocalizations l10n, Mood mood) => switch (mood) {
  Mood.awful => l10n.moodAwful,
  Mood.low => l10n.moodLow,
  Mood.okay => l10n.moodOkay,
  Mood.good => l10n.moodGood,
  Mood.great => l10n.moodGreat,
};

class MoodPicker extends StatelessWidget {
  const MoodPicker({super.key, required this.value, required this.onChanged});

  final Mood? value;
  final ValueChanged<Mood> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        for (final mood in Mood.values) ...[
          if (mood != Mood.values.first) const SizedBox(width: SteadySpace.s2),
          Expanded(
            child: _MoodItem(
              mood: mood,
              label: _moodLabel(l10n, mood),
              selected: mood == value,
              onTap: () => onChanged(mood),
            ),
          ),
        ],
      ],
    );
  }
}

class _MoodItem extends StatelessWidget {
  const _MoodItem({
    required this.mood,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Mood mood;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final foreground = selected ? c.amber : c.inkMuted;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SteadyRadius.md),
      side: BorderSide(
        width: 2,
        color: selected ? c.amber : Colors.transparent,
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: selected ? c.amberSoft : c.surface2,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: SteadySpace.s3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.string(
                  _faceSvgs[mood]!,
                  width: 32,
                  height: 32,
                  colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
                ),
                const SizedBox(height: SteadySpace.s1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: SteadyText.caption.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
