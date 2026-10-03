import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/components/steady_segmented_control.dart';
import 'fasting_view.dart';
import 'interval_setup_view.dart';

enum TimerMode { fasting, interval }

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key, required this.isActive});

  /// Tab Timer đang được chọn.
  final bool isActive;

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  TimerMode _mode = TimerMode.fasting;

  // Chỉ dựng nội dung (và mở stream DB) sau lần đầu tiên tab được chọn.
  late bool _opened = widget.isActive;

  @override
  void didUpdateWidget(TimerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive) _opened = true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_opened) return const SizedBox.shrink();
    final c = SteadyColors.of(context);
    final l10n = AppLocalizations.of(context);
    // Phần đầu nằm trong vùng cuộn của từng chế độ.
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.tabTimer, style: SteadyText.display.copyWith(color: c.ink)),
        const SizedBox(height: SteadySpace.s5),
        SteadySegmentedControl<TimerMode>(
          options: [
            SteadySegment(TimerMode.fasting, l10n.timerModeFasting),
            SteadySegment(TimerMode.interval, l10n.timerModeInterval),
          ],
          value: _mode,
          onChanged: (mode) => setState(() => _mode = mode),
          semanticLabel: l10n.timerTypeLabel,
        ),
      ],
    );
    return IndexedStack(
      index: _mode.index,
      children: [
        FastingView(
          header: header,
          ticking: widget.isActive && _mode == TimerMode.fasting,
        ),
        IntervalSetupView(header: header),
      ],
    );
  }
}
