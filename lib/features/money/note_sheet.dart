import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../data/money_types.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/components/steady_button.dart';
import '../../ui/components/steady_dialogs.dart';
import '../../ui/components/steady_text_field.dart';

/// Hỏi ghi chú của một khoản chi. Bấm Done thì trả chuỗi đang gõ (rỗng nghĩa
/// là xoá ghi chú). Đóng sheet bằng cách khác thì trả `null`: ghi chú không đổi.
Future<String?> showNoteSheet(BuildContext context, {String? initial}) {
  return showSteadySheet<String>(
    context,
    builder: (sheetContext) => _NoteForm(initial: initial),
  );
}

class _NoteForm extends StatefulWidget {
  const _NoteForm({this.initial});

  final String? initial;

  @override
  State<_NoteForm> createState() => _NoteFormState();
}

class _NoteFormState extends State<_NoteForm> {
  late final TextEditingController _note = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.noteButton, style: SteadyText.title.copyWith(color: c.ink)),
        const SizedBox(height: SteadySpace.s4),
        SteadyTextField(
          controller: _note,
          hint: l10n.noteHint,
          maxLength: kMoneyNoteMaxChars,
          autofocus: true,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: SteadySpace.s4),
        SteadyButton(
          label: l10n.done,
          onPressed: () => Navigator.of(context).pop(_note.text),
          variant: SteadyButtonVariant.primary,
          block: true,
        ),
      ],
    );
  }
}
