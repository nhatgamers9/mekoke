import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/format/duration_format.dart';
import '../../core/format/formatting.dart';
import '../../core/services.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/time/local_date.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/components/steady_button.dart';
import '../../ui/components/steady_chip.dart';
import '../../ui/components/steady_dialogs.dart';
import '../../ui/components/steady_inline_status.dart';
import '../../ui/components/steady_segmented_control.dart';
import '../../ui/components/timer_ring.dart';
import 'fasting_math.dart';
import 'fasting_plan.dart';

String _planName(AppLocalizations l10n, FastingPlan plan) => switch (plan) {
  FastingPlan.h16 => l10n.fastPlan16,
  FastingPlan.h18 => l10n.fastPlan18,
  FastingPlan.h20 => l10n.fastPlan20,
  FastingPlan.omad => l10n.fastPlanOmad,
};

String _durationHm(AppLocalizations l10n, Duration d) {
  final (hours, minutes) = splitHm(d);
  return l10n.durationHm(hours, minutes);
}

class FastingView extends StatefulWidget {
  const FastingView({super.key, required this.header, required this.ticking});

  /// Tiêu đề và bộ chọn chế độ, nằm đầu vùng cuộn.
  final Widget header;

  /// Cho phép đếm từng giây (tab Timer đang mở và đang ở chế độ Fasting).
  final bool ticking;

  @override
  State<FastingView> createState() => _FastingViewState();
}

class _FastingViewState extends State<FastingView> with WidgetsBindingObserver {
  late final AppServices _services;
  StreamSubscription<Fast?>? _activeSub;
  StreamSubscription<List<Fast>>? _endedSub;
  Fast? _active;
  List<Fast> _ended = const [];
  bool _activeLoaded = false;
  bool _endedLoaded = false;
  FastingPlan? _chosen;
  bool _busy = false;
  String? _error;
  Timer? _tick;
  bool _resumed = true;

  bool get _loaded => _activeLoaded && _endedLoaded;

  @override
  void initState() {
    super.initState();
    _services = ServicesScope.of(context);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _resumed = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _services.today.addListener(_onTodayChanged);
    _activeSub = _services.fasts.watchActive().listen((fast) {
      if (!mounted) return;
      setState(() {
        _active = fast;
        _activeLoaded = true;
      });
      _syncTicker();
    }, onError: (_) {});
    _endedSub = _services.fasts.watchEnded().listen((fasts) {
      if (!mounted) return;
      setState(() {
        _ended = fasts;
        _endedLoaded = true;
      });
      _syncTicker();
    }, onError: (_) {});
  }

  @override
  void didUpdateWidget(FastingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ticking != widget.ticking) _syncTicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _services.today.removeListener(_onTodayChanged);
    _activeSub?.cancel();
    _endedSub?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    if (!mounted) return;
    if (_resumed) setState(() {});
    _syncTicker();
  }

  void _onTodayChanged() {
    if (mounted) setState(() {});
  }

  FastingStatus _statusAt(DateTime now) => fastingStatusAt(
    now,
    active: _active,
    lastEnded: _ended.isEmpty ? null : _ended.first,
  );

  /// Chỉ giữ nhịp đếm khi có gì đang chạy: đang nhịn hoặc đang trong cửa sổ ăn.
  void _syncTicker() {
    final needed =
        mounted &&
        widget.ticking &&
        _resumed &&
        _loaded &&
        _statusAt(_services.clock.now()) is! FastIdle;
    if (!needed) {
      _tick?.cancel();
      _tick = null;
      return;
    }
    if (_tick != null) return;
    // Hẹn tới giây tròn kế tiếp của đồng hồ để các con số nhảy đúng nhịp.
    final now = _services.clock.now();
    final delay =
        const Duration(seconds: 1) -
        Duration(milliseconds: now.millisecond, microseconds: now.microsecond);
    _tick = Timer(delay, () {
      _tick = null;
      if (!mounted) return;
      setState(() {});
      _syncTicker();
    });
  }

  Future<void> _start(FastingPlan plan) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _services.fasts.start(plan);
    } catch (_) {
      if (mounted) setState(() => _error = l10n.saveError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _end(FastActive status) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      if (!status.goalReached) {
        final confirmed = await showSteadyConfirmDialog(
          context,
          destructive: false,
          title: l10n.endFastEarlyTitle,
          body: l10n.endFastEarlyBody(_durationHm(l10n, status.left)),
          confirmLabel: l10n.endFast,
          cancelLabel: l10n.keepFasting,
        );
        if (!confirmed || !mounted) return;
      }
      setState(() => _error = null);
      await _services.fasts.end(status.fast.id);
    } catch (_) {
      if (mounted) setState(() => _error = l10n.saveError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _startedLabel(
    AppLocalizations l10n,
    Fast fast,
    LocalDate today,
    String tag,
    bool use24h,
  ) {
    final time = formatClockTime(fast.startedAt, tag, use24h: use24h);
    final day = LocalDate.fromDateTime(fast.startedAt);
    if (day == today) return l10n.fastStartedToday(time);
    if (day == today.addDays(-1)) return l10n.fastStartedYesterday(time);
    return l10n.fastStartedOn(formatShortDate(day, today, tag), time);
  }

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final l10n = AppLocalizations.of(context);
    final tag = formatLocaleOf(context);
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
    final scrollChildren = <Widget>[widget.header];
    Widget? bottom;
    if (_loaded) {
      final now = _services.clock.now();
      final today = LocalDate.fromDateTime(now);
      final status = _statusAt(now);
      final plan =
          _chosen ??
          (_ended.isEmpty ? null : _ended.first.plan) ??
          FastingPlan.h16;
      String clockTime(DateTime t) => formatClockTime(t, tag, use24h: use24h);

      final String? phase;
      final String time;
      final String caption;
      final double progress;
      final TimerRingTone tone;
      final String statLabel;
      final String statValue;
      switch (status) {
        case FastActive():
          phase = l10n.phaseFasting;
          time = formatHms(status.elapsed);
          caption = status.goalReached
              ? l10n.fastGoalReachedAt(clockTime(status.goalAt))
              : l10n.fastEndsAt(clockTime(status.goalAt));
          progress = status.progress;
          tone = TimerRingTone.amber;
          statLabel = status.goalReached
              ? l10n.statPastGoal
              : l10n.statLeftInFast;
          statValue = _durationHm(
            l10n,
            status.goalReached ? status.over : status.left,
          );
        case FastEating():
          phase = l10n.phaseEating;
          time = formatHms(status.sinceEnd);
          caption = l10n.eatingWindowEndsAt(clockTime(status.windowEndsAt));
          progress = status.progress;
          tone = TimerRingTone.tide;
          statLabel = l10n.statLastFast;
          statValue = _durationHm(l10n, fastDuration(status.last));
        case FastIdle():
          phase = null;
          time = formatHms(Duration.zero);
          caption = l10n.fastGoalHours(plan.fastHours);
          progress = 0;
          tone = TimerRingTone.amber;
          statLabel = l10n.statLastFast;
          final last = status.last;
          statValue = last == null
              ? l10n.statEmpty
              : _durationHm(l10n, fastDuration(last));
      }

      scrollChildren
        ..add(const SizedBox(height: SteadySpace.s5))
        ..add(
          status is FastActive
              ? Wrap(
                  spacing: SteadySpace.s2,
                  runSpacing: SteadySpace.s1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SteadyChip(label: _planName(l10n, status.fast.plan)),
                    Text(
                      _startedLabel(l10n, status.fast, today, tag, use24h),
                      style: SteadyText.label.copyWith(color: c.inkMuted),
                    ),
                  ],
                )
              : SteadySegmentedControl<FastingPlan>(
                  options: [
                    for (final p in FastingPlan.values)
                      SteadySegment(p, _planName(l10n, p)),
                  ],
                  value: plan,
                  onChanged: (p) => setState(() => _chosen = p),
                  semanticLabel: l10n.fastingPlanLabel,
                ),
        )
        ..add(const SizedBox(height: SteadySpace.s5))
        ..add(
          LayoutBuilder(
            builder: (context, constraints) => Center(
              child: TimerRing(
                size: math.min(SteadySize.ring, constraints.maxWidth),
                progress: progress,
                time: time,
                phase: phase,
                caption: caption,
                tone: tone,
              ),
            ),
          ),
        )
        ..add(const SizedBox(height: SteadySpace.s5))
        ..add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _StatTile(value: statValue, label: statLabel),
              ),
              const SizedBox(width: SteadySpace.s3),
              Expanded(
                child: _StatTile(
                  value: l10n.daysCount(fastingStreak(_ended, today)),
                  label: l10n.statFastingStreak,
                ),
              ),
            ],
          ),
        );

      bottom = Padding(
        padding: const EdgeInsets.all(SteadySpace.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              SteadyInlineStatus(
                message: _error!,
                tone: SteadyStatusTone.error,
              ),
              const SizedBox(height: SteadySpace.s3),
            ],
            if (status is FastActive)
              SteadyButton(
                label: l10n.endFast,
                onPressed: _busy ? null : () => _end(status),
                variant: SteadyButtonVariant.secondary,
                block: true,
              )
            else
              SteadyButton(
                label: l10n.startFasting,
                onPressed: _busy ? null : () => _start(plan),
                variant: SteadyButtonVariant.primary,
                block: true,
              ),
            const SizedBox(height: SteadySpace.s3),
            Text(
              l10n.fastingDisclaimer,
              textAlign: TextAlign.center,
              style: SteadyText.caption.copyWith(color: c.inkMuted),
            ),
          ],
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
              children: scrollChildren,
            ),
          ),
        ),
        ?bottom,
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SteadySpace.s4,
        vertical: SteadySpace.s3,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(SteadyRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: SteadyText.stat.copyWith(color: c.ink),
            ),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: SteadyText.caption.copyWith(color: c.inkMuted),
          ),
        ],
      ),
    );
  }
}
