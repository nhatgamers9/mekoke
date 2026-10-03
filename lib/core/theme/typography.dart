import 'package:flutter/painting.dart';

/// Kiểu chữ của Steady, chép từ `design/steady-ds/tokens.json`.
/// Không mang màu: nơi dùng tự chọn màu từ `SteadyColors`.
abstract final class SteadyText {
  static const TextStyle countXl = TextStyle(
    fontFamily: 'Newsreader',
    fontSize: 96,
    height: 96 / 96,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    letterSpacing: -0.03 * 96,
  );

  static const TextStyle timerXl = TextStyle(
    fontFamily: 'Newsreader',
    fontSize: 52,
    height: 56 / 52,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    letterSpacing: -0.02 * 52,
  );

  static const TextStyle display = TextStyle(
    fontFamily: 'Newsreader',
    fontSize: 34,
    height: 40 / 34,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    letterSpacing: -0.01 * 34,
  );

  static const TextStyle title = TextStyle(
    fontFamily: 'Newsreader',
    fontSize: 24,
    height: 30 / 24,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
  );

  static const TextStyle headline = TextStyle(
    fontFamily: 'Figtree',
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Figtree',
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: 'Figtree',
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'Figtree',
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Figtree',
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    letterSpacing: 0.01 * 12,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: 'Figtree',
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    letterSpacing: 0.12 * 12,
  );

  static const TextStyle moneyXl = TextStyle(
    fontFamily: 'Figtree',
    fontSize: 48,
    height: 52 / 48,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    letterSpacing: -0.02 * 48,
  );

  static const TextStyle countGym = TextStyle(
    fontFamily: 'Figtree',
    fontSize: 88,
    height: 88 / 88,
    fontWeight: FontWeight.w800,
    fontVariations: [FontVariation('wght', 800)],
    letterSpacing: -0.04 * 88,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle stat = TextStyle(
    fontFamily: 'Figtree',
    fontSize: 28,
    height: 32 / 28,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    letterSpacing: -0.01 * 28,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
