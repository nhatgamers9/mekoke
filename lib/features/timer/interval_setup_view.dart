import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/format/duration_format.dart';
import '../../core/services.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/components/steady_button.dart';
import '../../ui/components/steady_filter_chips.dart';
import '../../ui/components/steady_icon.dart';
import '../../ui/components/steady_segmented_control.dart';
import '../../ui/components/steady_stepper.dart';
import 'interval_config.dart';
import 'interval_run_screen.dart';
import 'interval_timeline.dart';

class IntervalSetupView extends StatefulWidget {
  const IntervalSetupView({super.key, required this.header});

  /// Tiêu đề và bộ chọn chế độ, nằm đầu vùng cuộn.
  final Widget header;

  @override
  State<IntervalSetupView> createState() => _IntervalSetupViewState();
}

class _IntervalSetupViewState extends State<IntervalSetupView> {
  late final AppServices _services;
  IntervalSetup? _setup;

  @override
  void initState() {
    super.initState();
    _services = ServicesScope.of(context);
    _services.prefs.loadIntervalSetup().then((setup) {
      if (mounted) setState(() => _setup = setup);
    });
  }

  void _update(IntervalSetup setup) {
    setState(() => _setup = setup);
    unawaited(_save(setup));
  }

  Future<void> _save(IntervalSetup setup) async {
    try {
      await _services.prefs.saveIntervalSetup(setup);
    } catch (_) {
      // Không lưu được thì bài vẫn dùng được trong lần mở này.
    }
  }

  void _selectPreset(IntervalSetup setup, IntervalPresetId preset) {
    _update(IntervalSetup(preset: preset, custom: setup.custom));
  }

  /// Chỉnh một số: giá trị đang hiển thị được chép sang Custom và Custom được chọn.
  void _step(IntervalSetup setup, IntervalField field, {required bool up}) {
    final active = setup.active;
    final value = active.valueOf(field);
    _update(
      IntervalSetup(
        preset: IntervalPresetId.custom,
        custom: active.withValue(
          field,
          up ? stepUp(field, value) : stepDown(field, value),
        ),
      ),
    );
  }

  String _presetTitle(AppLocalizations l10n, IntervalPresetId preset) =>
      switch (preset) {
        IntervalPresetId.tabata => l10n.presetTabata,
        IntervalPresetId.hiit3030 => l10n.presetHiit,
        IntervalPresetId.custom => l10n.presetCustom,
      };

  void _startWorkout(IntervalSetup setup, AppLocalizations l10n) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IntervalRunScreen(
          config: setup.active,
          title: _presetTitle(l10n, setup.preset),
        ),
      ),
    );
  }

  Widget _stepperRow(
    IntervalSetup setup,
    IntervalField field, {
    required String label,
    required String icon,
    String? detail,
    bool divider = true,
  }) {
    final value = setup.active.valueOf(field);
    return SteadyStepper(
      label: label,
      value: field.isTime ? formatClock(Duration(seconds: value)) : '$value',
      icon: icon,
      detail: detail,
      onDecrement: value > field.min
          ? () => _step(setup, field, up: false)
          : null,
      onIncrement: value < field.max
          ? () => _step(setup, field, up: true)
          : null,
      divider: divider,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final l10n = AppLocalizations.of(context);
    final setup = _setup;
    final children = <Widget>[widget.header];
    Widget? bottom;
    if (setup != null) {
      final config = setup.active;
      final timeline = IntervalTimeline.fromConfig(config);
      final rows = <(IntervalField, String, String, String?)>[
        (IntervalField.prepare, l10n.stepPrepare, SteadyIcons.hourglass, null),
        (IntervalField.work, l10n.stepWork, SteadyIcons.dumbbell, null),
        (IntervalField.rest, l10n.stepRest, SteadyIcons.pause, null),
        (
          IntervalField.rounds,
          l10n.stepRounds,
          SteadyIcons.repeat,
          l10n.stepRoundsDetail,
        ),
        (IntervalField.sets, l10n.stepSets, SteadyIcons.layers, null),
        if (config.sets > 1)
          (IntervalField.setRest, l10n.stepSetRest, SteadyIcons.armchair, null),
      ];
      children
        ..add(const SizedBox(height: SteadySpace.s4))
        ..add(
          SteadyFilterChips<IntervalPresetId>(
            options: [
              for (final preset in IntervalPresetId.values)
                SteadySegment(preset, _presetTitle(l10n, preset)),
            ],
            value: setup.preset,
            onChanged: (preset) => _selectPreset(setup, preset),
            semanticLabel: l10n.savedWorkoutsLabel,
          ),
        )
        ..add(const SizedBox(height: SteadySpace.s4))
        ..add(
          Wrap(
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                formatClock(timeline.workoutTotal),
                style: SteadyText.stat.copyWith(color: c.ink),
              ),
              Text(
                l10n.intervalSummary(
                  timeline.intervalCount,
                  config.rounds * config.sets,
                ),
                style: SteadyText.label.copyWith(color: c.inkMuted),
              ),
            ],
          ),
        )
        ..add(const SizedBox(height: SteadySpace.s4))
        ..add(
          ClipRRect(
            borderRadius: BorderRadius.circular(SteadyRadius.lg),
            child: Column(
              children: [
                for (final (i, row) in rows.indexed)
                  _stepperRow(
                    setup,
                    row.$1,
                    label: row.$2,
                    icon: row.$3,
                    detail: row.$4,
                    divider: i < rows.length - 1,
                  ),
              ],
            ),
          ),
        );
      bottom = Padding(
        padding: const EdgeInsets.all(SteadySpace.s5),
        child: SteadyButton(
          label: l10n.startWorkout,
          onPressed: () => _startWorkout(setup, l10n),
          variant: SteadyButtonVariant.primary,
          block: true,
          icon: SteadyIcons.play,
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              SteadySpace.s5,
              SteadySpace.s8,
              SteadySpace.s5,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
        ?bottom,
      ],
    );
  }
}
