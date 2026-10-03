import 'package:flutter/material.dart';

import '../../core/services.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/components/steady_button.dart';
import '../../ui/components/steady_dialogs.dart';
import '../../ui/components/steady_inline_status.dart';

Future<void> showHabitActionsSheet(BuildContext context, Habit habit) {
  return showSteadySheet<void>(
    context,
    builder: (sheetContext) => _HabitActions(habit: habit),
  );
}

class _HabitActions extends StatefulWidget {
  const _HabitActions({required this.habit});

  final Habit habit;

  @override
  State<_HabitActions> createState() => _HabitActionsState();
}

class _HabitActionsState extends State<_HabitActions> {
  late final AppServices _services;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _services = ServicesScope.of(context);
  }

  Future<void> _reset() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final done = await _services.habits.resetStreak(
        widget.habit.id,
        _services.today.value,
      );
      if (mounted) navigator.pop();
      if (done) showSteadySnackBar(messenger, l10n.resetDone);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l10n.saveError;
        });
      }
    }
  }

  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context);
    final confirmed = await showSteadyConfirmDialog(
      context,
      title: l10n.deleteHabitTitle(widget.habit.name),
      body: l10n.deleteHabitBody,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _services.habits.deleteHabit(widget.habit.id);
      if (mounted) navigator.pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l10n.saveError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.habit.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: SteadyText.title.copyWith(color: c.ink),
        ),
        const SizedBox(height: SteadySpace.s4),
        if (_error != null) ...[
          SteadyInlineStatus(message: _error!, tone: SteadyStatusTone.error),
          const SizedBox(height: SteadySpace.s3),
        ],
        SteadyButton(
          label: l10n.resetStreak,
          onPressed: _busy ? null : _reset,
          size: SteadyButtonSize.md,
          block: true,
        ),
        const SizedBox(height: SteadySpace.s3),
        SteadyButton(
          label: l10n.deleteHabit,
          onPressed: _busy ? null : _delete,
          variant: SteadyButtonVariant.danger,
          size: SteadyButtonSize.md,
          block: true,
        ),
      ],
    );
  }
}
