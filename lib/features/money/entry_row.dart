import 'package:flutter/material.dart';

import '../../core/format/formatting.dart';
import '../../core/format/money_format.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/components/transaction_row.dart';
import 'money_labels.dart';

/// Một khoản chi trong danh sách: danh mục, ghi chú hoặc giờ, số tiền.
class EntryRow extends StatelessWidget {
  const EntryRow({
    super.key,
    required this.entry,
    required this.money,
    this.onTap,
    this.divider = true,
  });

  final MoneyEntry entry;
  final MoneyFormat money;
  final VoidCallback? onTap;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TransactionRow(
      icon: categoryIcon(entry.category),
      title: entryTitle(l10n, entry),
      detail: entryDetail(
        l10n,
        entry,
        tag: formatLocaleOf(context),
        use24h: MediaQuery.alwaysUse24HourFormatOf(context),
      ),
      amount: expenseAmount(l10n, money, entry.amountMinor),
      onTap: onTap,
      divider: divider,
    );
  }
}
