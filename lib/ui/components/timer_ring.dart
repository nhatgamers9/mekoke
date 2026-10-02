import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';

enum TimerRingTone { amber, tide }

enum TimerRingNumerals { serif, gym }

/// Vòng đếm giờ: [progress] (0..1) là phần đã trôi qua. Pha luôn có chữ ở
/// [phase], không chỉ đổi màu.
class TimerRing extends StatelessWidget {
  const TimerRing({
    super.key,
    required this.progress,
    required this.time,
    this.phase,
    this.caption,
    this.tone = TimerRingTone.amber,
    this.numerals = TimerRingNumerals.serif,
    this.size = SteadySize.ring,
  });

  final double progress;
  final String time;
  final String? phase;
  final String? caption;
  final TimerRingTone tone;
  final TimerRingNumerals numerals;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final toneColor = tone == TimerRingTone.tide ? c.tide : c.amber;
    final timeStyle = numerals == TimerRingNumerals.gym
        ? SteadyText.countGym
        : SteadyText.timerXl;
    final inner = size - 2 * SteadySize.ringStroke - 2 * SteadySpace.s4;
    return Semantics(
      label: [phase, time, caption].whereType<String>().join(', '),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: progress,
            track: c.surface2,
            arc: toneColor,
          ),
          child: Center(
            child: SizedBox.square(
              dimension: inner > 0 ? inner : 0,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (phase != null) ...[
                        Text(
                          phase!,
                          maxLines: 1,
                          style: SteadyText.overline.copyWith(color: toneColor),
                        ),
                        const SizedBox(height: SteadySpace.s1),
                      ],
                      Text(
                        time,
                        maxLines: 1,
                        style: timeStyle.copyWith(
                          color: c.ink,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (caption != null) ...[
                        const SizedBox(height: SteadySpace.s1),
                        Text(
                          caption!,
                          maxLines: 1,
                          style: SteadyText.label.copyWith(color: c.inkMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.track,
    required this.arc,
  });

  final double progress;
  final Color track;
  final Color arc;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = SteadySize.ringStroke;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - stroke) / 2,
    );
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    final p = progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0);
    if (p == 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * p,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.arc != arc;
}
