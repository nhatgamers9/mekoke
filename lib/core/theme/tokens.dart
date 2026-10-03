import 'package:flutter/material.dart';

/// Màu của Steady, chép từ `design/steady-ds/tokens.json`.
@immutable
class SteadyColors extends ThemeExtension<SteadyColors> {
  const SteadyColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.inkMuted,
    required this.amber,
    required this.onAmber,
    required this.amberSoft,
    required this.tide,
    required this.onTide,
    required this.tideSoft,
    required this.rose,
    required this.onRose,
    required this.roseSoft,
    required this.sheetShadow,
  });

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color line;
  final Color lineStrong;
  final Color ink;
  final Color inkMuted;
  final Color amber;
  final Color onAmber;
  final Color amberSoft;
  final Color tide;
  final Color onTide;
  final Color tideSoft;
  final Color rose;
  final Color onRose;
  final Color roseSoft;
  final Color sheetShadow;

  static const dark = SteadyColors(
    bg: Color(0xFF121110),
    surface: Color(0xFF1B1917),
    surface2: Color(0xFF262320),
    line: Color(0xFF36312C),
    lineStrong: Color(0xFF7A7268),
    ink: Color(0xFFF3EEE7),
    inkMuted: Color(0xFFAAA298),
    amber: Color(0xFFF2A649),
    onAmber: Color(0xFF1C1206),
    amberSoft: Color(0xFF3A2A15),
    tide: Color(0xFF7CC3C8),
    onTide: Color(0xFF0B1A1B),
    tideSoft: Color(0xFF16302F),
    rose: Color(0xFFF2899A),
    onRose: Color(0xFF22090D),
    roseSoft: Color(0xFF3B1B21),
    sheetShadow: Color(0xB3000000),
  );

  static const light = SteadyColors(
    bg: Color(0xFFF6F3EE),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFECE6DD),
    line: Color(0xFFE0D8CD),
    lineStrong: Color(0xFF8C8277),
    ink: Color(0xFF1C1916),
    inkMuted: Color(0xFF655D54),
    amber: Color(0xFF9A5200),
    onAmber: Color(0xFFFFFFFF),
    amberSoft: Color(0xFFFBE9D2),
    tide: Color(0xFF1B6970),
    onTide: Color(0xFFFFFFFF),
    tideSoft: Color(0xFFD9EEF0),
    rose: Color(0xFFAD2540),
    onRose: Color(0xFFFFFFFF),
    roseSoft: Color(0xFFFBE2E6),
    sheetShadow: Color(0x241C1916),
  );

  static const bedtime = SteadyColors(
    bg: Color(0xFF000000),
    surface: Color(0xFF0B0907),
    surface2: Color(0xFF15100B),
    line: Color(0xFF241A10),
    lineStrong: Color(0xFF7D6040),
    ink: Color(0xFFD9B48A),
    inkMuted: Color(0xFFA5835F),
    amber: Color(0xFFD98B3A),
    onAmber: Color(0xFF000000),
    amberSoft: Color(0xFF21150A),
    tide: Color(0xFF6F9E9B),
    onTide: Color(0xFF000000),
    tideSoft: Color(0xFF0B1615),
    rose: Color(0xFFC97A80),
    onRose: Color(0xFF000000),
    roseSoft: Color(0xFF1E0D0F),
    sheetShadow: Color(0xFF000000),
  );

  static SteadyColors of(BuildContext context) =>
      Theme.of(context).extension<SteadyColors>()!;

  @override
  SteadyColors copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? line,
    Color? lineStrong,
    Color? ink,
    Color? inkMuted,
    Color? amber,
    Color? onAmber,
    Color? amberSoft,
    Color? tide,
    Color? onTide,
    Color? tideSoft,
    Color? rose,
    Color? onRose,
    Color? roseSoft,
    Color? sheetShadow,
  }) {
    return SteadyColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      amber: amber ?? this.amber,
      onAmber: onAmber ?? this.onAmber,
      amberSoft: amberSoft ?? this.amberSoft,
      tide: tide ?? this.tide,
      onTide: onTide ?? this.onTide,
      tideSoft: tideSoft ?? this.tideSoft,
      rose: rose ?? this.rose,
      onRose: onRose ?? this.onRose,
      roseSoft: roseSoft ?? this.roseSoft,
      sheetShadow: sheetShadow ?? this.sheetShadow,
    );
  }

  @override
  SteadyColors lerp(ThemeExtension<SteadyColors>? other, double t) {
    if (other is! SteadyColors) return this;
    return SteadyColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      line: Color.lerp(line, other.line, t)!,
      lineStrong: Color.lerp(lineStrong, other.lineStrong, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      onAmber: Color.lerp(onAmber, other.onAmber, t)!,
      amberSoft: Color.lerp(amberSoft, other.amberSoft, t)!,
      tide: Color.lerp(tide, other.tide, t)!,
      onTide: Color.lerp(onTide, other.onTide, t)!,
      tideSoft: Color.lerp(tideSoft, other.tideSoft, t)!,
      rose: Color.lerp(rose, other.rose, t)!,
      onRose: Color.lerp(onRose, other.onRose, t)!,
      roseSoft: Color.lerp(roseSoft, other.roseSoft, t)!,
      sheetShadow: Color.lerp(sheetShadow, other.sheetShadow, t)!,
    );
  }
}

abstract final class SteadySpace {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s12 = 48;
}

abstract final class SteadyRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 22;
  static const double xl = 30;
  static const double full = 9999;
}

abstract final class SteadySize {
  static const double tap = 48;
  static const double button = 52;
  static const double buttonMd = 44;
  static const double play = 72;
  static const double ring = 264;
  static const double ringStroke = 14;
  static const double tabbar = 72;
}
