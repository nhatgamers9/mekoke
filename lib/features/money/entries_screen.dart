import 'package:flutter/material.dart';

import '../../core/format/formatting.dart';
import '../../core/format/money_format.dart';
import '../../core/services.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/time/local_date.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/components/steady_icon.dart';
import '../../ui/components/steady_icon_button.dart';
import 'entry_actions_sheet.dart';
import 'entry_row.dart';
import 'money_labels.dart';
import 'money_math.dart';

/// Mọi khoản chi, gom theo ngày, mỗi ngày có tổng.
class EntriesScreen extends StatefulWidget {
  const EntriesScreen({super.key, required this.currency});

  final String currency;

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  late final AppServices _services;
  late final Stream<List<MoneyEntry>> _entries;

  @override
  void initState() {
    super.initState();
    _services = ServicesScope.of(context);
    _entries = _services.money.watchAll();
  }

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final l10n = AppLocalizations.of(context);
    final tag = formatLocaleOf(context);
    final money = MoneyFormat(tag, widget.currency);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SteadySpace.s5,
                SteadySpace.s3,
                SteadySpace.s5,
                0,
              ),
              child: Row(
                children: [
                  SteadyIconButton(
                    variant: SteadyIconButtonVariant.plain,
                    icon: SteadyIcons.x,
                    semanticLabel: l10n.close,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: SteadySpace.s2),
                  Expanded(
                    child: Text(
                      l10n.expensesTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SteadyText.title.copyWith(color: c.ink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SteadySpace.s4),
            Expanded(
              child: StreamBuilder<List<MoneyEntry>>(
                stream: _entries,
                builder: (context, snapshot) {
                  const padding = EdgeInsets.symmetric(
                    horizontal: SteadySpace.s5,
                  );
                  if (snapshot.hasError) {
                    return Padding(
                      padding: padding,
                      child: Text(
                        l10n.moneyLoadError,
                        style: SteadyText.body.copyWith(color: c.inkMuted),
                      ),
                    );
                  }
                  final entries = snapshot.data;
                  if (entries == null) return const SizedBox.shrink();
                  if (entries.isEmpty) {
                    return Padding(
                      padding: padding,
                      child: Text(
                        l10n.moneyEmpty,
                        style: SteadyText.body.copyWith(color: c.inkMuted),
                      ),
                    );
                  }
                  // Nhãn ngày ("TODAY") dựng lại khi "hôm nay" đổi.
                  return ValueListenableBuilder<LocalDate>(
                    valueListenable: _services.today,
                    builder: (context, today, _) {
                      final groups = groupByDay(entries);
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          SteadySpace.s5,
                          0,
                          SteadySpace.s5,
                          SteadySpace.s6,
                        ),
                        itemCount: groups.length,
                        itemBuilder: (context, index) => Padding(
                          padding: EdgeInsets.only(
                            top: index == 0 ? 0 : SteadySpace.s4,
                          ),
                          child: _DayGroupView(
                            group: groups[index],
                            header: dayHeader(
                              l10n,
                              groups[index].date,
                              today,
                              tag,
                            ),
                            money: money,
                            currency: widget.currency,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayGroupView extends StatelessWidget {
  const _DayGroupView({
    required this.group,
    required this.header,
    required this.money,
    required this.currency,
  });

  final DayGroup group;
  final String header;
  final MoneyFormat money;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final l10n = AppLocalizations.of(context);
    final entries = group.entries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              Expanded(
                child: Text(
                  header,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SteadyText.overline.copyWith(color: c.inkMuted),
                ),
              ),
              const SizedBox(width: SteadySpace.s2),
              // Tổng của một ngày có thể rất lớn: thu nhỏ, không quá nửa hàng.
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth / 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    expenseAmount(l10n, money, group.total),
                    maxLines: 1,
                    style: SteadyText.label.copyWith(
                      color: c.inkMuted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: SteadySpace.s2),
        ClipRRect(
          borderRadius: BorderRadius.circular(SteadyRadius.lg),
          child: Column(
            children: [
              for (final (i, entry) in entries.indexed)
                EntryRow(
                  entry: entry,
                  money: money,
                  divider: i < entries.length - 1,
                  onTap: () => showEntryActionsSheet(
                    context,
                    entry: entry,
                    currency: currency,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
