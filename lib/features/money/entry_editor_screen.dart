import 'package:flutter/material.dart';

import '../../core/format/formatting.dart';
import '../../core/format/money_format.dart';
import '../../core/services.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/time/local_date.dart';
import '../../data/database.dart';
import '../../data/money_types.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/components/icon_tile.dart';
import '../../ui/components/keypad.dart';
import '../../ui/components/steady_button.dart';
import '../../ui/components/steady_icon.dart';
import '../../ui/components/steady_icon_button.dart';
import '../../ui/components/steady_inline_status.dart';
import 'amount_input.dart';
import 'money_labels.dart';
import 'note_sheet.dart';

/// Số danh mục hiện sẵn trên lưới; các mục còn lại nằm sau ô "More".
const _kVisibleCategories = 7;

/// Màn nhập một khoản chi mới, hoặc sửa [entry] nếu có.
class EntryEditorScreen extends StatefulWidget {
  const EntryEditorScreen({super.key, required this.currency, this.entry});

  final String currency;
  final MoneyEntry? entry;

  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  late final AppServices _services;
  late final int _decimals;
  late AmountInput _amount;
  MoneyCategory? _category;
  late LocalDate _date;
  String? _note;
  late bool _showAll;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _services = ServicesScope.of(context);
    _decimals = MoneyFormat.decimalsFor(widget.currency);
    final entry = widget.entry;
    if (entry == null) {
      _amount = AmountInput.empty;
      _date = _services.today.value;
    } else {
      _amount = AmountInput.fromMinor(entry.amountMinor, _decimals);
      _category = entry.category;
      _date = entry.date;
      _note = entry.note;
    }
    final category = _category;
    _showAll =
        category != null &&
        MoneyCategory.values.indexOf(category) >= _kVisibleCategories;
  }

  void _onKey(String key) {
    setState(() {
      _amount = _amount.press(key, decimals: _decimals);
      _error = null;
    });
  }

  Future<void> _pickDate() async {
    if (_busy) return;
    final today = _services.today.value;
    // Không chọn được ngày sau hôm nay. Khoản đã có ngày sau hôm nay (đồng hồ
    // máy bị lùi) vẫn mở được: ngày cuối của lịch là ngày lớn hơn trong hai.
    final last = _date.isAfter(today) ? _date : today;
    setState(() => _busy = true);
    try {
      final picked = await showDatePicker(
        context: context,
        firstDate: DateTime(today.year - 100),
        lastDate: last.toDateTime(),
        initialDate: _date.toDateTime(),
      );
      if (picked == null || !mounted) return;
      setState(() => _date = LocalDate.fromDateTime(picked));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editNote() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await showNoteSheet(context, initial: _note);
      if (result == null || !mounted) return;
      setState(() => _note = normalizeMoneyNote(result));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    final category = _category;
    final amountMinor = _amount.toMinor(_decimals);
    if (category == null || amountMinor <= 0) return;
    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final entry = widget.entry;
      if (entry == null) {
        await _services.money.add(
          amountMinor: amountMinor,
          category: category,
          date: _date,
          note: _note,
        );
      } else {
        final found = await _services.money.update(
          entry.id,
          amountMinor: amountMinor,
          category: category,
          date: _date,
          note: _note,
        );
        // Khoản đã bị xoá ở nơi khác: báo lỗi, không đóng màn như thể đã lưu.
        if (!found) throw StateError('Expense ${entry.id} no longer exists');
      }
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
    final tag = formatLocaleOf(context);
    final money = MoneyFormat(tag, widget.currency);
    final category = _category;
    final canSave =
        !_busy && category != null && _amount.toMinor(_decimals) > 0;
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
                      widget.entry == null ? l10n.addExpense : l10n.editExpense,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SteadyText.title.copyWith(color: c.ink),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  SteadySpace.s5,
                  SteadySpace.s3,
                  SteadySpace.s5,
                  SteadySpace.s3,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Semantics(
                          liveRegion: true,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatAmountInput(money, _amount),
                              maxLines: 1,
                              style: SteadyText.moneyXl.copyWith(color: c.ink),
                            ),
                          ),
                        ),
                        const SizedBox(height: SteadySpace.s1),
                        Text(
                          category == null
                              ? l10n.chooseCategory
                              : categoryLabel(l10n, category),
                          style: SteadyText.label.copyWith(color: c.inkMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: SteadySpace.s3),
                    Semantics(
                      container: true,
                      label: l10n.categoryLabel,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final tileWidth =
                              (constraints.maxWidth - 3 * SteadySpace.s1) / 4;
                          final shown = _showAll
                              ? MoneyCategory.values
                              : MoneyCategory.values.take(_kVisibleCategories);
                          return Wrap(
                            spacing: SteadySpace.s1,
                            runSpacing: SteadySpace.s1,
                            children: [
                              for (final item in shown)
                                SizedBox(
                                  width: tileWidth,
                                  child: IconTile(
                                    icon: categoryIcon(item),
                                    label: categoryLabel(l10n, item),
                                    selected: item == category,
                                    onTap: () => setState(() {
                                      _category = item;
                                      _error = null;
                                    }),
                                  ),
                                ),
                              if (!_showAll)
                                SizedBox(
                                  width: tileWidth,
                                  child: IconTile(
                                    icon: SteadyIcons.plus,
                                    label: l10n.categoryMore,
                                    selected: null,
                                    onTap: () =>
                                        setState(() => _showAll = true),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: SteadySpace.s3),
                    Row(
                      children: [
                        Expanded(
                          // Nhãn ngày ("Today") dựng lại khi "hôm nay" đổi.
                          child: ValueListenableBuilder<LocalDate>(
                            valueListenable: _services.today,
                            builder: (context, today, _) => SteadyButton(
                              label: dateLabel(l10n, _date, today, tag),
                              onPressed: _pickDate,
                              size: SteadyButtonSize.md,
                              block: true,
                              icon: SteadyIcons.calendar,
                            ),
                          ),
                        ),
                        const SizedBox(width: SteadySpace.s2),
                        Expanded(
                          child: SteadyButton(
                            label: _note ?? l10n.noteButton,
                            onPressed: _editNote,
                            size: SteadyButtonSize.md,
                            block: true,
                            icon: SteadyIcons.notebookPen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SteadySpace.s5,
                SteadySpace.s3,
                SteadySpace.s5,
                SteadySpace.s6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Keypad(
                    onKey: _onKey,
                    decimalEnabled: _decimals > 0,
                    decimalSeparator: money.decimalSeparator,
                    semanticLabel: l10n.keypadLabel,
                    deleteLabel: l10n.keypadBackspace,
                  ),
                  const SizedBox(height: SteadySpace.s3),
                  if (_error != null) ...[
                    SteadyInlineStatus(
                      message: _error!,
                      tone: SteadyStatusTone.error,
                    ),
                    const SizedBox(height: SteadySpace.s3),
                  ],
                  SteadyButton(
                    label: l10n.saveExpense,
                    onPressed: canSave ? _save : null,
                    variant: SteadyButtonVariant.primary,
                    block: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
