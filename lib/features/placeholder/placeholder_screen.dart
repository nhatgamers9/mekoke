import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../l10n/app_localizations.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SteadySpace.s5,
        SteadySpace.s8,
        SteadySpace.s5,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: SteadyText.display.copyWith(color: c.ink)),
          const SizedBox(height: SteadySpace.s4),
          Text(
            l10n.placeholderBody,
            style: SteadyText.body.copyWith(color: c.inkMuted),
          ),
        ],
      ),
    );
  }
}
