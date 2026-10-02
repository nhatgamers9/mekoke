import 'package:flutter/material.dart';

import 'tokens.dart';
import 'typography.dart';

ThemeData buildSteadyTheme(SteadyColors c, Brightness b) {
  final scheme = ColorScheme(
    brightness: b,
    primary: c.amber,
    onPrimary: c.onAmber,
    secondary: c.tide,
    onSecondary: c.onTide,
    error: c.rose,
    onError: c.onRose,
    surface: c.surface,
    onSurface: c.ink,
    onSurfaceVariant: c.inkMuted,
    outline: c.lineStrong,
    outlineVariant: c.line,
    primaryContainer: c.amberSoft,
    onPrimaryContainer: c.amber,
    secondaryContainer: c.tideSoft,
    onSecondaryContainer: c.tide,
    errorContainer: c.roseSoft,
    onErrorContainer: c.rose,
    surfaceContainerLowest: c.surface,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surface2,
    surfaceContainerHighest: c.surface2,
    // Không để sheet và dialog bị ám màu amber.
    surfaceTint: Colors.transparent,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Figtree',
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    extensions: [c],
    splashColor: c.ink.withValues(alpha: 0.08),
    highlightColor: c.ink.withValues(alpha: 0.08),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.amber,
      selectionColor: c.amber.withValues(alpha: 0.4),
      selectionHandleColor: c.amber,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SteadyRadius.lg),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.surface2,
      contentTextStyle: SteadyText.body.copyWith(color: c.ink),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
