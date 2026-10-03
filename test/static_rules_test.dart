import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Các quy tắc ở mục 5.1 của kế hoạch, kiểm bằng cách quét mã nguồn trong lib/.
List<File> _dartFiles() =>
    Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

/// Đường dẫn dùng `/` trên mọi máy: Windows trả về `\`, làm các phép so bên dưới trượt.
String _posixPath(File f) => f.path.replaceAll(r'\', '/');

void main() {
  test('lib/ never reads the wall clock directly', () {
    for (final f in _dartFiles()) {
      expect(
        f.readAsStringSync(),
        isNot(contains('DateTime.now()')),
        reason: f.path,
      );
    }
  });

  test('raw Color(0x...) literals only live in tokens.dart', () {
    final literal = RegExp(r'Color\(\s*0x');
    for (final f in _dartFiles()) {
      if (_posixPath(f).endsWith('core/theme/tokens.dart')) continue;
      expect(literal.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
    }
  });

  test('UI code has no hard-coded user-visible string literals', () {
    // Text('Literal') hoặc Text("Literal"); chuỗi nội suy kiểu '$days' thì được.
    final literal = RegExp(r'''Text\(\s*['"][^'"$]*[A-Za-z]''');
    for (final f in _dartFiles()) {
      if (_posixPath(f).contains('/l10n/')) continue;
      expect(literal.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
    }
  });
}
