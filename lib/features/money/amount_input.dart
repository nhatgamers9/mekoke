import 'package:flutter/foundation.dart';

import '../../core/format/money_format.dart';

const kAmountMaxIntegerDigits = 9;

/// Số tiền đang gõ trên keypad, giữ dưới dạng chuỗi chuẩn: "", "0", "12",
/// "12.", "12.4". Dấu thập phân luôn là '.', dù màn hình hiện dấu của locale.
@immutable
class AmountInput {
  const AmountInput._(this.text);

  /// [minor] là số tiền theo đơn vị nhỏ nhất. Không dương thì ra [empty].
  /// Luôn đủ [decimals] chữ số thập phân: (1240, 2) ra "12.40".
  factory AmountInput.fromMinor(int minor, int decimals) {
    if (minor <= 0) return empty;
    if (decimals == 0) return AmountInput._('$minor');
    final digits = minor.toString().padLeft(decimals + 1, '0');
    final split = digits.length - decimals;
    return AmountInput._(
      '${digits.substring(0, split)}.${digits.substring(split)}',
    );
  }

  static const empty = AmountInput._('');

  final String text;

  bool get isEmpty => text.isEmpty;

  bool get hasSeparator => text.contains('.');

  int get fractionDigits =>
      hasSeparator ? text.length - text.indexOf('.') - 1 : 0;

  /// [key] là một trong '0'-'9', '.', 'del'; phím khác thì ném [ArgumentError].
  AmountInput press(String key, {required int decimals}) {
    switch (key) {
      case 'del':
        return isEmpty
            ? this
            : AmountInput._(text.substring(0, text.length - 1));
      case '.':
        if (decimals == 0 || hasSeparator) return this;
        return isEmpty ? const AmountInput._('0.') : AmountInput._('$text.');
      case '0' || '1' || '2' || '3' || '4' || '5' || '6' || '7' || '8' || '9':
        if (hasSeparator) {
          return fractionDigits >= decimals ? this : AmountInput._('$text$key');
        }
        if (text == '0') return AmountInput._(key);
        if (text.length >= kAmountMaxIntegerDigits) return this;
        return AmountInput._('$text$key');
    }
    throw ArgumentError.value(key, 'key', 'Not a keypad key');
  }

  /// Số tiền theo đơn vị nhỏ nhất của tiền tệ có [decimals] chữ số thập phân:
  /// "" ra 0; "12." với 2 ra 1200; "12.4" với 2 ra 1240. Chữ số thập phân thừa
  /// bị bỏ.
  int toMinor(int decimals) {
    if (isEmpty) return 0;
    final parts = text.split('.');
    final fraction = parts.length > 1 ? parts[1] : '';
    final padded = fraction.padRight(decimals, '0').substring(0, decimals);
    return int.parse('${parts[0]}$padded');
  }

  @override
  bool operator ==(Object other) => other is AmountInput && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'AmountInput($text)';
}

/// Chuỗi hiển thị trên màn nhập: số đang gõ kèm ký hiệu tiền, giữ nguyên số
/// chữ số thập phân đã gõ ("12" ra "$12", "12.4" ra "$12.4").
String formatAmountInput(MoneyFormat m, AmountInput input) {
  if (input.isEmpty) return m.formatScaled(0, 0);
  final k = input.fractionDigits;
  final formatted = m.formatScaled(input.toMinor(k), k);
  if (!input.text.endsWith('.')) return formatted;
  // Mới gõ dấu thập phân: chèn dấu của locale ngay sau chữ số cuối cùng, vì
  // ký hiệu tiền có thể nằm sau số ("12, €").
  for (var i = formatted.length - 1; i >= 0; i--) {
    final unit = formatted.codeUnitAt(i);
    if (unit >= 0x30 && unit <= 0x39) {
      return '${formatted.substring(0, i + 1)}${m.decimalSeparator}'
          '${formatted.substring(i + 1)}';
    }
  }
  return '$formatted${m.decimalSeparator}';
}
