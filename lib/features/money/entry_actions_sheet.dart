import 'package:flutter/material.dart';

import '../../core/format/formatting.dart';
import '../../core/format/money_format.dart';
import '../../core/services.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/components/steady_button.dart';
import '../../ui/components/steady_dialogs.dart';
import '../../ui/components/steady_inline_status.dart';
import 'entry_editor_screen.dart';
import 'money_labels.dart';

/// Sheet của một khoản chi: sửa hoặc xoá.
Future<void> showEntryActionsSheet(
  BuildContext context, {
  required MoneyEntry entry,
  required String currency,
}) {
  return showSteadySheet<void>(
    context,
    builder: (sheetContext) => _EntryActions(entry: entry, currency: currency),
  );
}

class _EntryActions extends StatefulWidget {
  const _EntryActions({required this.entry, required this.currency});

  final MoneyEntry entry;
  final String currency;

  @override
  State<_EntryActions> createState() => _EntryActionsState();
}

class _EntryActionsState extends State<_EntryActions> {
  late final AppServices _services;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _services = ServicesScope.of(context);
  }

  void _edit() {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            EntryEditorScreen(currency: widget.currency, entry: widget.entry),
      ),
    );
  }

  Future<void> _delete() async {
    if (_busy) return;
    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context);
    // Bật trước hộp thoại: bấm lần hai trong lúc hộp thoại đang mở không làm gì.
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final confirmed = await showSteadyConfirmDialog(
        context,
        title: l10n.deleteExpenseTitle,
        body: l10n.deleteExpenseBody,
        confirmLabel: l10n.delete,
        cancelLabel: l10n.cancel,
      );
      if (!confirmed || !mounted) return;
      // Khoản đã mất (trả false) cũng đóng sheet: không còn gì để xoá.
      await _services.money.delete(widget.entry.id);
      if (mounted) navigator.pop();
    } catch (_) {
      if (mounted) setState(() => _error = l10n.saveError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final l10n = AppLocalizations.of(context);
    final money = MoneyFormat(formatLocaleOf(context), widget.currency);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          entryTitle(l10n, widget.entry),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: SteadyText.title.copyWith(color: c.ink),
        ),
        const SizedBox(height: SteadySpace.s1),
        Text(
          expenseAmount(l10n, money, widget.entry.amountMinor),
          style: SteadyText.label.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: SteadySpace.s4),
        if (_error != null) ...[
          SteadyInlineStatus(message: _error!, tone: SteadyStatusTone.error),
          const SizedBox(height: SteadySpace.s3),
        ],
        SteadyButton(
          label: l10n.editExpense,
          onPressed: _busy ? null : _edit,
          size: SteadyButtonSize.md,
          block: true,
        ),
        const SizedBox(height: SteadySpace.s3),
        SteadyButton(
          label: l10n.deleteExpense,
          onPressed: _busy ? null : _delete,
          variant: SteadyButtonVariant.danger,
          size: SteadyButtonSize.md,
          block: true,
        ),
      ],
    );
  }
}
