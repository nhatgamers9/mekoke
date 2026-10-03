import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/format/formatting.dart';
import '../../core/format/money_format.dart';
import '../../core/services.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/time/local_date.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/components/bar_chart_row.dart';
import '../../ui/components/steady_button.dart';
import '../../ui/components/steady_chip.dart';
import '../../ui/components/steady_icon.dart';
import '../../ui/components/steady_inline_status.dart';
import 'entries_screen.dart';
import 'entry_actions_sheet.dart';
import 'entry_editor_screen.dart';
import 'entry_row.dart';
import 'money_labels.dart';
import 'money_math.dart';

class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key, required this.isActive});

  /// Tab Money đang được chọn.
  final bool isActive;

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  // Chỉ dựng nội dung (và mở stream DB) sau lần đầu tiên tab được chọn.
  late bool _opened = widget.isActive;

  @override
  void didUpdateWidget(MoneyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive) _opened = true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_opened) return const SizedBox.shrink();
    return const _MoneyHome();
  }
}

class _MoneyHome extends StatefulWidget {
  const _MoneyHome();

  @override
  State<_MoneyHome> createState() => _MoneyHomeState();
}

class _MoneyHomeState extends State<_MoneyHome> {
  late final AppServices _services;
  StreamSubscription<List<MoneyEntry>>? _recentSub;
  StreamSubscription<List<MoneyEntry>>? _monthsSub;
  String? _currency;
  List<MoneyEntry>? _recent;

  /// Các khoản của tháng trước và tháng này, từ một stream.
  List<MoneyEntry>? _months;

  /// Ngày đầu của tháng mà [_monthsSub] đang nghe.
  late LocalDate _listenedMonth;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _services = ServicesScope.of(context);
    _services.today.addListener(_onTodayChanged);
    unawaited(_loadCurrency());
    _recentSub = _services.money.watchRecent().listen((entries) {
      if (mounted) setState(() => _recent = entries);
    }, onError: _onStreamError);
    _listenMonths();
  }

  @override
  void dispose() {
    _services.today.removeListener(_onTodayChanged);
    _recentSub?.cancel();
    _monthsSub?.cancel();
    super.dispose();
  }

  /// Tiền tệ chọn theo vùng của máy ở lần mở đầu rồi lưu cố định. Không lấy
  /// từ `formatLocaleOf`: máy `vi_VN` sẽ bị đổi về 'en' và ra USD sai.
  Future<void> _loadCurrency() async {
    final deviceTag = WidgetsBinding.instance.platformDispatcher.locale
        .toString();
    final currency = await _services.prefs.loadCurrency(
      fallback: MoneyFormat.currencyForLocale(deviceTag),
    );
    if (mounted) setState(() => _currency = currency);
  }

  void _listenMonths() {
    final today = _services.today.value;
    _listenedMonth = monthRange(today).$1;
    _monthsSub = _services.money
        .watchBetween(previousMonth(today), monthRange(today).$2)
        .listen((entries) {
          if (mounted) setState(() => _months = entries);
        }, onError: _onStreamError);
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    if (mounted) setState(() => _loadFailed = true);
  }

  void _onTodayChanged() {
    if (!mounted) return;
    // Sang tháng mới: nghe lại khoảng hai tháng mới, không giữ số của tháng cũ.
    if (monthRange(_services.today.value).$1 != _listenedMonth) {
      _monthsSub?.cancel();
      _months = null;
      _listenMonths();
    }
    setState(() {});
  }

  void _openEditor(String currency) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EntryEditorScreen(currency: currency),
      ),
    );
  }

  void _openEntries(String currency) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EntriesScreen(currency: currency),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final l10n = AppLocalizations.of(context);
    final tag = formatLocaleOf(context);
    final today = _services.today.value;
    final currency = _currency;
    final months = _months;
    final recent = _recent;
    final children = <Widget>[
      Text(l10n.tabMoney, style: SteadyText.display.copyWith(color: c.ink)),
    ];
    if (_loadFailed) {
      children
        ..add(const SizedBox(height: SteadySpace.s4))
        ..add(
          SteadyInlineStatus(
            message: l10n.moneyLoadError,
            tone: SteadyStatusTone.error,
          ),
        );
    } else if (currency != null && months != null && recent != null) {
      final money = MoneyFormat(tag, currency);
      final thisMonth = [
        for (final e in months)
          if (inRange(e.date, monthRange(today))) e,
      ];
      final lastMonth = [
        for (final e in months)
          if (inRange(e.date, monthRange(previousMonth(today)))) e,
      ];
      final spent = totalOf(thisMonth);
      final last = totalOf(lastMonth);
      final cats = totalsByCategory(thisMonth);
      children
        ..add(const SizedBox(height: SteadySpace.s4))
        ..add(
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: SteadySpace.s2,
            runSpacing: SteadySpace.s2,
            children: [
              Text(
                formatMonth(today, tag),
                style: SteadyText.label.copyWith(color: c.inkMuted),
              ),
              SteadyChip(label: l10n.moneyOffline, icon: SteadyIcons.lock),
            ],
          ),
        )
        ..add(const SizedBox(height: SteadySpace.s4))
        ..add(
          Text(
            l10n.spentThisMonth,
            style: SteadyText.label.copyWith(color: c.inkMuted),
          ),
        )
        ..add(
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              money.format(spent),
              maxLines: 1,
              style: SteadyText.moneyXl.copyWith(color: c.ink),
            ),
          ),
        );
      if (last > 0) {
        children.add(
          Text(
            l10n.spentLastMonth(money.format(last)),
            style: SteadyText.label.copyWith(color: c.inkMuted),
          ),
        );
      }
      children
        ..add(const SizedBox(height: SteadySpace.s4))
        ..add(
          SteadyButton(
            label: l10n.addExpense,
            onPressed: () => _openEditor(currency),
            variant: SteadyButtonVariant.primary,
            block: true,
            icon: SteadyIcons.plus,
          ),
        );
      if (cats.isNotEmpty) {
        children
          ..add(const SizedBox(height: SteadySpace.s6))
          ..add(
            Text(
              l10n.byCategoryHeader,
              style: SteadyText.overline.copyWith(color: c.inkMuted),
            ),
          )
          ..add(const SizedBox(height: SteadySpace.s2))
          ..add(
            Container(
              padding: const EdgeInsets.all(SteadySpace.s4),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(SteadyRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, total) in cats.indexed) ...[
                    if (i > 0) const SizedBox(height: SteadySpace.s3),
                    BarChartRow(
                      label: categoryLabel(l10n, total.category),
                      value: money.format(total.amount),
                      fraction: total.amount / cats.first.amount,
                    ),
                  ],
                ],
              ),
            ),
          );
      }
      children
        ..add(const SizedBox(height: SteadySpace.s6))
        ..add(
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.recentHeader,
                  style: SteadyText.overline.copyWith(color: c.inkMuted),
                ),
              ),
              if (recent.isNotEmpty)
                SteadyButton(
                  label: l10n.seeAll,
                  onPressed: () => _openEntries(currency),
                  variant: SteadyButtonVariant.ghost,
                  size: SteadyButtonSize.md,
                ),
            ],
          ),
        )
        ..add(const SizedBox(height: SteadySpace.s2));
      if (recent.isEmpty) {
        children.add(
          Text(
            l10n.moneyEmpty,
            style: SteadyText.body.copyWith(color: c.inkMuted),
          ),
        );
      } else {
        children.add(
          ClipRRect(
            borderRadius: BorderRadius.circular(SteadyRadius.lg),
            child: Column(
              children: [
                for (final (i, entry) in recent.indexed)
                  EntryRow(
                    entry: entry,
                    money: money,
                    divider: i < recent.length - 1,
                    onTap: () => showEntryActionsSheet(
                      context,
                      entry: entry,
                      currency: currency,
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        SteadySpace.s5,
        SteadySpace.s8,
        SteadySpace.s5,
        SteadySpace.s6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
