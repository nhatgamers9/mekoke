import 'package:characters/characters.dart';

const kHabitNameMaxChars = 40;

/// Trả tên đã chuẩn hoá, hoặc `null` nếu rỗng, có xuống dòng hoặc quá dài
/// (đếm theo grapheme).
String? normalizeHabitName(String raw) {
  final name = raw.trim();
  if (name.isEmpty) return null;
  if (name.contains('\r') || name.contains('\n')) return null;
  if (name.characters.length > kHabitNameMaxChars) return null;
  return name;
}
