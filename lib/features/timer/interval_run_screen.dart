import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format/duration_format.dart';
import '../../core/services.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/components/steady_button.dart';
import '../../ui/components/steady_chip.dart';
import '../../ui/components/steady_dialogs.dart';
import '../../ui/components/steady_icon.dart';
import '../../ui/components/steady_icon_button.dart';
import '../../ui/components/steady_progress_bar.dart';
import '../../ui/components/timer_ring.dart';
import 'interval_config.dart';
import 'interval_run.dart';
import 'interval_timeline.dart';

class IntervalRunScreen extends StatefulWidget {
  const IntervalRunScreen({
    super.key,
    required this.config,
    required this.title,
  });

  final IntervalConfig config;
  final String title;

  @override
  State<IntervalRunScreen> createState() => _IntervalRunScreenState();
}

class _IntervalRunScreenState extends State<IntervalRunScreen>
    with WidgetsBindingObserver {
  late final AppServices _services;
  late final IntervalRun _run;
  late IntervalSnapshot _snap;
  Timer? _tick;
  bool _resumed = true;
  bool _finished = false;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _services = ServicesScope.of(context);
    _run = IntervalRun(
      IntervalTimeline.fromConfig(widget.config),
      _services.clock,
    )..start();
    _snap = _run.snapshot();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _resumed = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_services.screenAwake.keepOn(true));
    _scheduleTick();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    unawaited(_services.screenAwake.keepOn(false));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    if (!mounted) return;
    // Bài vẫn chạy theo đồng hồ khi ở nền: quay lại thì cập nhật ngay.
    if (_resumed) _refresh();
    _scheduleTick();
  }

  /// Hẹn tới giây tròn kế tiếp của thời gian đã tập, để các pha đổi đúng nhịp.
  void _scheduleTick() {
    _tick?.cancel();
    _tick = null;
    if (!mounted || !_resumed || !_run.isRunning) return;
    final remainder =
        _run.elapsed.inMicroseconds % Duration.microsecondsPerSecond;
    _tick = Timer(
      Duration(microseconds: Duration.microsecondsPerSecond - remainder),
      () {
        _tick = null;
        if (!mounted) return;
        _refresh();
        _scheduleTick();
      },
    );
  }

  /// Lấy ảnh chụp mới; rung mỗi khi sang pha khác và tắt giữ sáng khi xong.
  void _refresh() {
    final snap = _run.snapshot();
    final changed = snap.index != _snap.index;
    setState(() => _snap = snap);
    if (changed) unawaited(_buzz(done: snap.done));
    if (snap.done && !_finished) {
      _finished = true;
      unawaited(_services.screenAwake.keepOn(false));
    }
  }

  Future<void> _buzz({required bool done}) async {
    try {
      if (done) {
        await HapticFeedback.vibrate();
      } else {
        await HapticFeedback.heavyImpact();
      }
    } catch (_) {
      // Rung chỉ là phần thêm: lỗi thì bỏ qua.
    }
  }

  void _pause() {
    _run.pause();
    unawaited(_services.screenAwake.keepOn(false));
    _refresh();
    _scheduleTick();
  }

  void _resume() {
    _run.resume();
    unawaited(_services.screenAwake.keepOn(true));
    _refresh();
    _scheduleTick();
  }

  void _restartRound() {
    _run.restartRound();
    _refresh();
    _scheduleTick();
  }

  void _skipRound() {
    _run.skipRound();
    _refresh();
    _scheduleTick();
  }

  Future<void> _confirmExit() async {
    if (_confirming) return;
    _confirming = true;
    try {
      final navigator = Navigator.of(context);
      final l10n = AppLocalizations.of(context);
      _pause();
      final confirmed = await showSteadyConfirmDialog(
        context,
        destructive: false,
        title: l10n.endWorkoutTitle,
        body: l10n.endWorkoutBody,
        confirmLabel: l10n.endWorkout,
        cancelLabel: l10n.keepGoing,
      );
      if (confirmed && mounted) navigator.pop();
    } finally {
      _confirming = false;
    }
  }

  String _phaseName(AppLocalizations l10n, IntervalPhase? phase) {
    return switch (phase?.kind) {
      null => l10n.phaseDone,
      IntervalPhaseKind.prepare => l10n.phasePrepare,
      IntervalPhaseKind.work => l10n.phaseWork,
      IntervalPhaseKind.rest || IntervalPhaseKind.setRest => l10n.phaseRest,
    };
  }

  /// "20 s" dưới 1 phút, "1:30" từ 1 phút trở lên.
  String _short(AppLocalizations l10n, int seconds) => seconds < 60
      ? l10n.secondsShort(seconds)
      : formatClock(Duration(seconds: seconds));

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final l10n = AppLocalizations.of(context);
    final config = widget.config;
    final snap = _snap;
    final phase = snap.phase;
    final next = snap.next;
    final timeline = _run.timeline;
    final summary = l10n.intervalSummary(
      timeline.intervalCount,
      config.rounds * config.sets,
    );
    final round = phase?.round ?? config.rounds;
    final set = phase?.set ?? config.sets;
    final ringSize = math.min(
      300.0,
      MediaQuery.sizeOf(context).width - 2 * SteadySpace.s5,
    );
    final running = _run.isRunning;
    final phaseName = _phaseName(l10n, phase);
    return PopScope(
      canPop: snap.done,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SteadySpace.s5,
                    SteadySpace.s3,
                    SteadySpace.s5,
                    40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // TalkBack đọc tên pha mỗi khi nhãn này đổi. Cao 1 px vì
                      // Flutter loại node có khung rỗng khỏi cây semantics.
                      Semantics(
                        liveRegion: true,
                        label: phaseName,
                        child: const SizedBox(height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SteadyIconButton(
                            variant: SteadyIconButtonVariant.plain,
                            icon: SteadyIcons.x,
                            semanticLabel: l10n.endWorkout,
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SteadySpace.s2,
                              ),
                              child: Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: SteadyText.headline.copyWith(
                                  color: c.ink,
                                ),
                              ),
                            ),
                          ),
                          SteadyChip(
                            label: l10n.roundChip(round, config.rounds),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Center(
                        child: TimerRing(
                          size: ringSize,
                          numerals: TimerRingNumerals.gym,
                          progress: phase == null ? 1 : snap.phaseProgress,
                          time: phase == null
                              ? formatClock(timeline.workoutTotal)
                              : formatClock(
                                  Duration(
                                    seconds: ceilSeconds(snap.phaseRemaining),
                                  ),
                                ),
                          phase: phaseName,
                          caption: phase == null
                              ? summary
                              : l10n.intervalRingCaption(
                                  _short(l10n, config.work),
                                  _short(l10n, config.rest),
                                ),
                          tone: phase?.kind == IntervalPhaseKind.work
                              ? TimerRingTone.amber
                              : TimerRingTone.tide,
                        ),
                      ),
                      if (next != null) ...[
                        const SizedBox(height: SteadySpace.s6),
                        Center(
                          child: SteadyChip(
                            label: l10n.nextPhase(
                              next.kind == IntervalPhaseKind.work
                                  ? l10n.stepWork
                                  : l10n.stepRest,
                              formatClock(next.duration),
                            ),
                            tone: next.kind == IntervalPhaseKind.work
                                ? SteadyChipTone.amber
                                : SteadyChipTone.tide,
                          ),
                        ),
                      ],
                      const Spacer(),
                      SteadyProgressBar(
                        value: snap.workoutProgress,
                        semanticLabel: l10n.workoutProgressLabel,
                      ),
                      const SizedBox(height: SteadySpace.s2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              config.sets > 1
                                  ? l10n.setRoundOf(
                                      set,
                                      config.sets,
                                      round,
                                      config.rounds,
                                    )
                                  : l10n.roundOf(round, config.rounds),
                              style: SteadyText.caption.copyWith(
                                color: c.inkMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: SteadySpace.s3),
                          Flexible(
                            child: Text(
                              l10n.timeLeft(
                                formatClock(
                                  Duration(
                                    seconds: ceilSeconds(snap.workoutRemaining),
                                  ),
                                ),
                              ),
                              textAlign: TextAlign.right,
                              style: SteadyText.caption.copyWith(
                                color: c.inkMuted,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: SteadySpace.s8),
                      if (snap.done)
                        SteadyButton(
                          label: l10n.close,
                          onPressed: () => Navigator.of(context).pop(),
                          variant: SteadyButtonVariant.primary,
                          block: true,
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SteadyIconButton(
                              icon: SteadyIcons.rotateCcw,
                              semanticLabel: l10n.restartRound,
                              onPressed: _restartRound,
                            ),
                            const SizedBox(width: SteadySpace.s6),
                            SteadyIconButton(
                              variant: SteadyIconButtonVariant.play,
                              icon: running
                                  ? SteadyIcons.pause
                                  : SteadyIcons.play,
                              semanticLabel: running ? l10n.pause : l10n.resume,
                              onPressed: running ? _pause : _resume,
                            ),
                            const SizedBox(width: SteadySpace.s6),
                            SteadyIconButton(
                              icon: SteadyIcons.skipForward,
                              semanticLabel: l10n.skipRound,
                              onPressed: _skipRound,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
