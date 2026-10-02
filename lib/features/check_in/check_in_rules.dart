import 'package:characters/characters.dart';

enum Mood {
  awful(1),
  low(2),
  okay(3),
  good(4),
  great(5);

  const Mood(this.value);

  final int value;

  static Mood fromValue(int v) {
    for (final mood in values) {
      if (mood.value == v) return mood;
    }
    throw ArgumentError.value(v, 'v', 'Mood must be between 1 and 5');
  }
}

const kCheckInNoteMaxChars = 140;

final _newlines = RegExp(r'\r\n|\r|\n');

/// Đổi xuống dòng thành dấu cách, trim; rỗng thì `null`. Quá dài (đếm theo
/// grapheme) thì ném [ArgumentError].
String? normalizeCheckInNote(String raw) {
  final note = raw.replaceAll(_newlines, ' ').trim();
  if (note.isEmpty) return null;
  if (note.characters.length > kCheckInNoteMaxChars) {
    throw ArgumentError.value(raw, 'raw', 'Note is too long');
  }
  return note;
}

enum Greeting { morning, afternoon, evening }

/// Q9: 05:00-11:59 sáng, 12:00-17:59 chiều, còn lại (18:00-04:59) tối.
Greeting greetingFor(DateTime localNow) {
  final hour = localNow.hour;
  if (hour >= 5 && hour < 12) return Greeting.morning;
  if (hour >= 12 && hour < 18) return Greeting.afternoon;
  return Greeting.evening;
}
