import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import 'steady_icon.dart';

/// Bàn phím số để nhập số tiền. Gửi '0'-'9', '.' hoặc 'del' qua [onKey]. Phím
/// '.' hiện [decimalSeparator] của locale nhưng vẫn gửi '.'.
class Keypad extends StatelessWidget {
  const Keypad({
    super.key,
    required this.onKey,
    required this.decimalSeparator,
    required this.semanticLabel,
    required this.deleteLabel,
    this.decimalEnabled = true,
  });

  final ValueChanged<String> onKey;
  final String decimalSeparator;
  final String semanticLabel;
  final String deleteLabel;

  /// Tắt phím '.' (tiền tệ không có chữ số thập phân, như JPY).
  final bool decimalEnabled;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', 'del'],
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, row) in _rows.indexed) ...[
            if (i > 0) const SizedBox(height: SteadySpace.s2),
            Row(
              children: [
                for (final (j, key) in row.indexed) ...[
                  if (j > 0) const SizedBox(width: SteadySpace.s2),
                  Expanded(child: _keyFor(key)),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _keyFor(String key) {
    return switch (key) {
      'del' => _Key(semanticLabel: deleteLabel, onTap: () => onKey(key)),
      '.' => _Key(
        semanticLabel: decimalSeparator,
        text: decimalSeparator,
        enabled: decimalEnabled,
        onTap: () => onKey(key),
      ),
      _ => _Key(semanticLabel: key, text: key, onTap: () => onKey(key)),
    };
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.semanticLabel,
    required this.onTap,
    this.text,
    this.enabled = true,
  });

  final String semanticLabel;
  final VoidCallback onTap;

  /// `null` là phím xoá: hiện icon thay cho chữ.
  final String? text;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SteadyRadius.md),
    );
    final text = this.text;
    final key = SizedBox(
      height: 56,
      child: Material(
        color: text == null ? Colors.transparent : c.surface,
        shape: shape,
        child: InkWell(
          onTap: enabled ? onTap : null,
          customBorder: shape,
          child: Center(
            child: text == null
                ? SteadyIcon(SteadyIcons.delete, size: 24, color: c.inkMuted)
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      text,
                      maxLines: 1,
                      style: SteadyText.headline.copyWith(
                        fontSize: 24,
                        height: 28 / 24,
                        fontWeight: FontWeight.w500,
                        fontVariations: const [FontVariation('wght', 500)],
                        color: c.ink,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      onTap: enabled ? onTap : null,
      excludeSemantics: true,
      child: enabled ? key : Opacity(opacity: 0.4, child: key),
    );
  }
}
