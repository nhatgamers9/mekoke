import 'package:characters/characters.dart';

/// Thứ tự khai báo là thứ tự trên lưới chọn; 7 mục đầu hiện sẵn. Danh mục lưu
/// vào DB bằng `name`, nên không được đổi tên giá trị nào.
enum MoneyCategory {
  groceries,
  eatingOut,
  transport,
  bills,
  shopping,
  health,
  gifts,
  housing,
  travel,
  phone,
  education,
  other,
}

/// Số tiền lớn nhất theo đơn vị nhỏ nhất: đủ cho 9 chữ số phần nguyên với tiền
/// tệ có tới 3 chữ số thập phân. Màn nhập còn chặt hơn (9 chữ số phần nguyên:
/// 999,999,999.99 với USD).
const kMaxAmountMinor = 999999999999;

const kMoneyNoteMaxChars = 60;

final _newlines = RegExp(r'\r\n|\r|\n');

/// Đổi xuống dòng thành dấu cách, trim; rỗng thì `null`. Quá dài (đếm theo
/// grapheme) thì ném [ArgumentError].
String? normalizeMoneyNote(String raw) {
  final note = raw.replaceAll(_newlines, ' ').trim();
  if (note.isEmpty) return null;
  if (note.characters.length > kMoneyNoteMaxChars) {
    throw ArgumentError.value(raw, 'raw', 'Note is too long');
  }
  return note;
}
