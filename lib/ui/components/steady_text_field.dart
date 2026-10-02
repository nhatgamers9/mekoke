import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';

class SteadyTextField extends StatelessWidget {
  const SteadyTextField({
    super.key,
    required this.controller,
    this.hint,
    this.maxLength,
    this.minLines = 1,
    this.maxLines = 1,
    this.inputFormatters,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? hint;
  final int? maxLength;
  final int minLines;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(SteadyRadius.md),
      borderSide: BorderSide(color: color, width: 2),
    );
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLength: maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      minLines: minLines,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: SteadyText.body.copyWith(color: c.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: SteadyText.body.copyWith(color: c.inkMuted),
        counterText: '',
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SteadySpace.s4,
          vertical: SteadySpace.s3,
        ),
        border: border(c.lineStrong),
        enabledBorder: border(c.lineStrong),
        focusedBorder: border(c.amber),
      ),
    );
  }
}
