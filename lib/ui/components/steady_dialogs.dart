import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import 'steady_button.dart';

Future<T?> showSteadySheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final c = SteadyColors.of(sheetContext);
      // useSafeArea không chừa mép dưới, nên cộng cả vùng hệ thống phía dưới.
      final bottom =
          MediaQuery.viewInsetsOf(sheetContext).bottom +
          MediaQuery.paddingOf(sheetContext).bottom;
      return Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(SteadyRadius.xl),
          ),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, -12),
              blurRadius: 40,
              color: c.sheetShadow,
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          SteadySpace.s5,
          SteadySpace.s6,
          SteadySpace.s5,
          SteadySpace.s5 + bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [builder(sheetContext)],
          ),
        ),
      );
    },
  );
}

Future<bool> showSteadyConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = true,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final c = SteadyColors.of(dialogContext);
      return AlertDialog(
        scrollable: true,
        title: Text(title, style: SteadyText.title.copyWith(color: c.ink)),
        content: Text(body, style: SteadyText.body.copyWith(color: c.inkMuted)),
        actions: [
          SteadyButton(
            label: cancelLabel,
            variant: SteadyButtonVariant.ghost,
            size: SteadyButtonSize.md,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          SteadyButton(
            label: confirmLabel,
            variant: destructive
                ? SteadyButtonVariant.danger
                : SteadyButtonVariant.primary,
            size: SteadyButtonSize.md,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

void showSteadySnackBar(ScaffoldMessengerState m, String message) {
  if (!m.mounted) return;
  m
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
