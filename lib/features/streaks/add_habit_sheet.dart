import 'package:flutter/material.dart';

import '../../core/format/formatting.dart';
import '../../core/services.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/time/local_date.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/components/steady_button.dart';
import '../../ui/components/steady_dialogs.dart';
import '../../ui/components/steady_inline_status.dart';
import '../../ui/components/steady_text_field.dart';
import 'habit_name.dart';

Future<void> showAddHabitSheet(BuildContext context) {
  return showSteadySheet<void>(
    context,
    builder: (sheetContext) => const _AddHabitForm(),
  );
}

class _AddHabitForm extends StatefulWidget {
  const _AddHabitForm();

  @override
  State<_AddHabitForm> createState() => _AddHabitFormState();
}

class _AddHabitFormState extends State<_AddHabitForm> {
  final _name = TextEditingController();
  late final AppServices _services;
  late LocalDate _cleanSince;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _services = ServicesScope.of(context);
    _cleanSince = _services.today.value;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = _services.today.value;
    final initial = _clamped(today);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(today.year - 100),
      lastDate: today.toDateTime(),
      initialDate: initial.toDateTime(),
    );
    if (picked == null || !mounted) return;
    setState(() => _cleanSince = LocalDate.fromDateTime(picked));
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context);
    final today = _services.today.value;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _services.habits.addHabit(
        name: _name.text,
        cleanSince: _clamped(today),
        today: today,
      );
      if (!mounted) return;
      navigator.pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = l10n.saveError;
        });
      }
    }
  }

  /// "Hôm nay" có thể lùi lại khi sheet đang mở (chỉnh đồng hồ, đổi múi giờ):
  /// không để ngày bắt đầu nằm ở tương lai.
  LocalDate _clamped(LocalDate today) =>
      _cleanSince.isAfter(today) ? today : _cleanSince;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final l10n = AppLocalizations.of(context);
    final tag = formatLocaleOf(context);
    final dateShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SteadyRadius.md),
      side: BorderSide(color: c.lineStrong, width: 2),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.addHabit, style: SteadyText.title.copyWith(color: c.ink)),
        const SizedBox(height: SteadySpace.s4),
        Text(
          l10n.habitNameLabel,
          style: SteadyText.headline.copyWith(color: c.ink),
        ),
        const SizedBox(height: SteadySpace.s2),
        SteadyTextField(
          controller: _name,
          hint: l10n.habitNameHint,
          maxLength: kHabitNameMaxChars,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: SteadySpace.s4),
        Text(
          l10n.cleanSinceLabel,
          style: SteadyText.headline.copyWith(color: c.ink),
        ),
        const SizedBox(height: SteadySpace.s2),
        Semantics(
          button: true,
          child: Material(
            color: c.surface,
            shape: dateShape,
            child: InkWell(
              onTap: _pickDate,
              customBorder: dateShape,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: SteadySize.tap),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SteadySpace.s4,
                    vertical: SteadySpace.s3,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatShortDate(
                        _clamped(_services.today.value),
                        _services.today.value,
                        tag,
                      ),
                      style: SteadyText.body.copyWith(color: c.ink),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: SteadySpace.s6),
        if (_error != null) ...[
          SteadyInlineStatus(message: _error!, tone: SteadyStatusTone.error),
          const SizedBox(height: SteadySpace.s3),
        ],
        // Chỉ nút Lưu phụ thuộc vào tên: dựng lại riêng nút, không dựng lại cả sheet.
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _name,
          builder: (context, value, _) {
            final canSave = normalizeHabitName(value.text) != null && !_saving;
            return SteadyButton(
              label: l10n.saveHabit,
              onPressed: canSave ? _save : null,
              variant: SteadyButtonVariant.primary,
              block: true,
            );
          },
        ),
      ],
    );
  }
}
