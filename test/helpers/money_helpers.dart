import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/services.dart';
import 'package:steady/core/time/local_date.dart';
import 'package:steady/data/database.dart';
import 'package:steady/data/money_types.dart';
import 'package:steady/ui/components/keypad.dart';

import 'timer_helpers.dart';
import 'widget_helpers.dart';

/// Nạp phông thật (Figtree, Newsreader) thay cho Ahem. `flutter test` không tự
/// nạp phông khai báo trong pubspec.yaml; gọi trong `setUpAll` của test nào cần
/// đo bố cục như trên máy thật.
Future<void> loadRealFonts() async {
  Future<void> load(String family, String path) async {
    final bytes = Uint8List.fromList(File(path).readAsBytesSync());
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }

  await load('Figtree', 'assets/fonts/Figtree-Variable.ttf');
  await load('Newsreader', 'assets/fonts/Newsreader-Variable.ttf');
}

/// Mở tab Money lần đầu và chờ DB (nạp tiền tệ, hai stream).
Future<void> openMoney(WidgetTester t) async {
  await tapTab(t, 'Money');
  await letDbFinish(t);
}

/// Ghi một khoản chi thẳng vào DB. [createdAt] mặc định là giờ của đồng hồ giả
/// ở thời điểm gọi hàm.
Future<MoneyEntry> seedExpense(
  WidgetTester t,
  AppServices s, {
  required int amountMinor,
  MoneyCategory category = MoneyCategory.groceries,
  required LocalDate date,
  String? note,
  DateTime? createdAt,
}) {
  return dbAction(
    t,
    () => s.db
        .into(s.db.moneyEntries)
        .insertReturning(
          MoneyEntriesCompanion.insert(
            amountMinor: amountMinor,
            category: category,
            note: Value(note),
            date: date,
            createdAt: createdAt ?? s.today.value.toDateTime(),
          ),
        ),
  );
}

/// Mọi khoản chi trong DB, mới nhất trước. Đọc một lần bằng `get()` chứ không
/// mở stream: stream Drift mở trong `runAsync` có thể làm `db.close()` treo.
Future<List<MoneyEntry>> storedExpenses(WidgetTester t, AppServices s) async {
  final rows = await t.runAsync(
    () =>
        (s.db.select(s.db.moneyEntries)..orderBy([
              (r) => OrderingTerm.desc(r.date),
              (r) => OrderingTerm.desc(r.createdAt),
              (r) => OrderingTerm.desc(r.id),
            ]))
            .get(),
  );
  return rows!;
}

/// Phím [key] ('0'-'9', '.', 'del') trên Keypad.
Finder keypadKey(String key) {
  if (key == 'del') return semLabel('Delete last digit');
  return find.descendant(of: find.byType(Keypad), matching: find.text(key));
}

/// Bấm lần lượt từng ký tự của [keys] ('1', '2', '.', '4'; '<' là phím xoá).
Future<void> pressKeys(WidgetTester t, String keys) async {
  for (final ch in keys.split('')) {
    await t.tap(keypadKey(ch == '<' ? 'del' : ch));
    await t.pump();
  }
}

/// Bấm ô danh mục có nhãn [label] trên màn nhập. Với phông Ahem của `flutter
/// test` hàng ô thứ hai có thể nằm dưới mép vùng cuộn, nên cuộn tới ô trước.
Future<void> pickCategory(WidgetTester t, String label) async {
  final tile = find.widgetWithText(InkWell, label);
  await t.ensureVisible(tile);
  await t.pump();
  await t.tap(tile);
  await t.pump();
}

/// Bấm "Add expense" trên tab Money; chờ route mở xong.
Future<void> openEditor(WidgetTester t) async {
  final add = find.widgetWithText(FilledButton, 'Add expense');
  await t.ensureVisible(add);
  await t.pump();
  await t.tap(add);
  await settle(t);
}

/// Bấm Save trên màn nhập, chờ DB và route đóng.
Future<void> tapSave(WidgetTester t) async {
  await t.tap(find.text('Save expense'));
  await afterTapDb(t);
  await settle(t);
}

/// Nhập một khoản chi qua giao diện từ tab Money: mở màn nhập, gõ [keys], chọn
/// [category], lưu.
Future<void> addExpenseThroughUi(
  WidgetTester t, {
  required String keys,
  required String category,
}) async {
  await openEditor(t);
  await pressKeys(t, keys);
  await pickCategory(t, category);
  await tapSave(t);
}

/// Chạm có thể hụt vì vùng chạm nằm ngoài khung nhìn; cuộn tới rồi mới chạm.
Future<void> tapScrolled(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f);
  await t.pump();
}

/// Đặt vùng của máy (nhớ gỡ khi test xong).
void setDeviceLocale(WidgetTester t, Locale locale) {
  t.platformDispatcher.localeTestValue = locale;
  addTearDown(t.platformDispatcher.clearLocaleTestValue);
}

/// Ghi đè prefs `money.currency` trước lần mở tab Money đầu tiên.
Future<void> seedCurrency(WidgetTester t, AppServices s, String code) =>
    seedPref(t, s, 'money.currency', code);

/// Lỗi ghi DB chung: dùng cho `money_entries`.
Future<void> breakMoneyWrites(
  WidgetTester t,
  AppServices s, {
  bool insert = true,
  bool update = true,
  bool delete = true,
}) => breakWrites(
  t,
  s,
  'money_entries',
  insert: insert,
  update: update,
  delete: delete,
);
