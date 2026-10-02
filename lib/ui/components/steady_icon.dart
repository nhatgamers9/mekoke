import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/tokens.dart';

/// Tên icon (file trong `assets/icons/`) mà app đang dùng.
abstract final class SteadyIcons {
  static const audioWaveform = 'audio-waveform';
  static const timer = 'timer';
  static const sprout = 'sprout';
  static const wallet = 'wallet';
  static const notebookPen = 'notebook-pen';
  static const plus = 'plus';
  static const x = 'x';
  static const play = 'play';
  static const pause = 'pause';
  static const rotateCcw = 'rotate-ccw';
  static const skipForward = 'skip-forward';
  static const hourglass = 'hourglass';
  static const dumbbell = 'dumbbell';
  static const repeat = 'repeat';
  static const layers = 'layers';
  static const armchair = 'armchair';
  static const minus = 'minus';
}

class SteadyIcon extends StatelessWidget {
  const SteadyIcon(
    this.name, {
    super.key,
    this.size = 24,
    this.color,
    this.semanticLabel,
  });

  final String name;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? SteadyColors.of(context).ink,
        BlendMode.srcIn,
      ),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
