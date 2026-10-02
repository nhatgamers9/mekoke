import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/services.dart';
import 'package:steady/data/money_types.dart';
import 'package:steady/features/money/entry_editor_screen.dart';
import 'package:steady/features/money/entry_row.dart';
import 'package:steady/ui/components/icon_tile.dart';
import 'package:steady/ui/components/keypad.dart';

import '../helpers/money_helpers.dart';
import '../helpers/test_app.dart';
import '../helpers/widget_helpers.dart';

// Ràng buộc "màn nhập không phải cuộn ở 360x800, cỡ chữ 1.0" (kế hoạch §7.2)
// chỉ đo được với phông thật: `flutter test` mặc định dùng phông Ahem, rộng
// hơn, làm nhãn ô danh mục xuống hai dòng. File này nạp Figtree và Newsreader
// thật; vì mỗi file test chạy trong tiến trình riêng nên việc nạp phông không
// ảnh hưởng các test khác. Ràng buộc KHÔNG được nới: nếu nạp phông thật mà vẫn
// phải cuộn thì test này rớt thật.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadRealFonts();
  });

  Finder scrollArea() => find.descendant(
    of: find.byType(EntryEditorScreen),
    matching: find.byType(SingleChildScrollView),
  );

  ScrollPosition position(WidgetTester t) => t
      .state<ScrollableState>(
        find.descendant(of: scrollArea(), matching: find.byType(Scrollable)),
      )
      .position;

  Rect rectOf(WidgetTester t, Finder f) => t.getRect(f);

  Finder buttonText(String label) =>
      find.widgetWithText(FilledButton, label, skipOffstage: false);

  Future<AppServices> openAdd(WidgetTester t, {double scale = 1.0}) async {
    final now = FakeNow(evening());
    final services = await pumpSteadyApp(t, clock: now.clock, textScale: scale);
    await openMoney(t);
    await openEditor(t);
    return services;
  }

  testWidgets('control: the real fonts are loaded (labels stay on one line)', (
    tester,
  ) async {
    final services = await openAdd(tester);

    // Ahem rộng 1em mỗi ký tự: "Groceries" (9 ký tự, 12px) sẽ rộng hơn 100px
    // và xuống hai dòng trong ô 77px. Phông thật chỉ rộng khoảng một nửa.
    final groceries = tester.getSize(find.text('Groceries'));
    expect(groceries.width, lessThan(70), reason: 'real Figtree, not Ahem');
    expect(groceries.height, lessThan(20), reason: 'one line of 16px');
    for (final label in ['Eating out', 'Transport', 'Shopping']) {
      expect(
        tester.getSize(find.text(label)).height,
        lessThan(20),
        reason: '$label is on one line',
      );
    }

    await disposeSteadyApp(tester, services);
  });

  testWidgets('Add expense at 360x800, text scale 1.0: no scrolling needed', (
    tester,
  ) async {
    final services = await openAdd(tester);

    final pos = position(tester);
    expect(
      pos.maxScrollExtent,
      0,
      reason:
          'content ${pos.maxScrollExtent + pos.viewportDimension} '
          'in a viewport of ${pos.viewportDimension}',
    );
    expect(tester.takeException(), isNull);

    await disposeSteadyApp(tester, services);
  });

  testWidgets('Add expense: all four blocks are on screen without scrolling', (
    tester,
  ) async {
    final services = await openAdd(tester);
    final screen = rectOf(tester, find.byType(EntryEditorScreen));
    final viewport = rectOf(tester, scrollArea());

    // 1. Số tiền.
    final amount = rectOf(tester, find.text(r'$0'));
    expect(amount.top, greaterThanOrEqualTo(viewport.top));
    expect(amount.bottom, lessThanOrEqualTo(viewport.bottom));

    // 2. Hai hàng danh mục: ô đầu và ô cuối (More) đều thấy trọn.
    final tiles = find.byType(IconTile);
    expect(tiles, findsNWidgets(8));
    final firstTile = rectOf(tester, tiles.first);
    final lastTile = rectOf(tester, tiles.last);
    expect(firstTile.top, greaterThanOrEqualTo(viewport.top));
    expect(lastTile.bottom, lessThanOrEqualTo(viewport.bottom));
    expect(
      lastTile.top,
      greaterThan(firstTile.bottom - 1),
      reason: 'second row',
    );

    // 3. Hàng Date / Note.
    final date = rectOf(tester, buttonText('Today'));
    final note = rectOf(tester, buttonText('Note'));
    for (final r in [date, note]) {
      expect(r.top, greaterThanOrEqualTo(lastTile.bottom - 1));
      expect(r.bottom, lessThanOrEqualTo(viewport.bottom));
    }

    // 4. Keypad và nút Save, dưới vùng cuộn và trong màn hình.
    final keypad = rectOf(tester, find.byType(Keypad));
    final save = rectOf(tester, buttonText('Save expense'));
    expect(keypad.top, greaterThanOrEqualTo(viewport.bottom - 1));
    expect(save.top, greaterThanOrEqualTo(keypad.bottom - 1));
    expect(save.bottom, lessThanOrEqualTo(screen.bottom));
    expect(save.bottom, lessThanOrEqualTo(800));

    await disposeSteadyApp(tester, services);
  });

  testWidgets('Add expense: dragging the form does not move it', (
    tester,
  ) async {
    final services = await openAdd(tester);

    await tester.drag(scrollArea(), const Offset(0, -300), warnIfMissed: false);
    await tester.pump();

    expect(position(tester).pixels, 0);
    expect(find.text(r'$0'), findsOne);

    await disposeSteadyApp(tester, services);
  });

  testWidgets(
    'Add expense: still no scrolling after typing and picking a category',
    (tester) async {
      final services = await openAdd(tester);

      await pressKeys(tester, '999999999.99');
      await pickCategory(tester, 'Eating out');

      expect(position(tester).maxScrollExtent, 0);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    },
  );

  testWidgets(
    'Edit screen of a Groceries expense with a note: no scrolling either',
    (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedExpense(
        tester,
        services,
        amountMinor: 1240,
        date: today,
        note: 'N' * 60,
        createdAt: evening(),
      );
      await openMoney(tester);
      await tester.tap(find.byType(EntryRow).first);
      await settle(tester);
      await tester.tap(find.text('Edit expense'));
      await settle(tester);

      expect(find.byType(IconTile), findsNWidgets(8), reason: 'More is closed');
      expect(position(tester).maxScrollExtent, 0);

      await disposeSteadyApp(tester, services);
    },
  );

  testWidgets(
    'with a status bar and a navigation bar the form scrolls and stays usable',
    (tester) async {
      // Trên máy thật vùng nhìn thấy nhỏ hơn: màn phải cuộn được (đó là chủ đích
      // của SingleChildScrollView), không tràn, và vẫn tới được mọi nút.
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
      addTearDown(tester.view.resetPadding);
      final services = await openAdd(tester);

      expect(position(tester).maxScrollExtent, greaterThan(0));
      for (final f in [buttonText('Today'), buttonText('Note')]) {
        await tester.ensureVisible(f);
        await tester.pump();
        final r = rectOf(tester, f);
        expect(r.top, greaterThanOrEqualTo(24));
        expect(r.bottom, lessThanOrEqualTo(800 - 48));
      }
      final save = rectOf(tester, buttonText('Save expense'));
      expect(
        save.bottom,
        lessThanOrEqualTo(800 - 48),
        reason: 'above the nav bar',
      );
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    },
  );

  testWidgets('More opened (12 tiles) at 1.0 scrolls instead of overflowing', (
    tester,
  ) async {
    final services = await openAdd(tester);

    await tester.tap(find.text('More'));
    await tester.pump();

    expect(find.byType(IconTile), findsNWidgets(12));
    expect(tester.takeException(), isNull);
    // Mọi ô vẫn tới được bằng cách cuộn.
    for (final c in MoneyCategory.values) {
      await pickCategory(tester, switch (c) {
        MoneyCategory.groceries => 'Groceries',
        MoneyCategory.eatingOut => 'Eating out',
        MoneyCategory.transport => 'Transport',
        MoneyCategory.bills => 'Bills',
        MoneyCategory.shopping => 'Shopping',
        MoneyCategory.health => 'Health',
        MoneyCategory.gifts => 'Gifts',
        MoneyCategory.housing => 'Housing',
        MoneyCategory.travel => 'Travel',
        MoneyCategory.phone => 'Phone',
        MoneyCategory.education => 'Education',
        MoneyCategory.other => 'Other',
      });
    }
    expect(tester.takeException(), isNull);

    await disposeSteadyApp(tester, services);
  });

  testWidgets(
    'at text scale 2.0 the form scrolls, nothing overflows, Save is reachable',
    (tester) async {
      final services = await openAdd(tester, scale: 2.0);

      expect(position(tester).maxScrollExtent, greaterThan(0));
      await tester.ensureVisible(buttonText('Note'));
      await tester.pump();
      expect(rectOf(tester, buttonText('Note')).bottom, lessThanOrEqualTo(800));
      expect(
        rectOf(tester, buttonText('Save expense')).bottom,
        lessThanOrEqualTo(800),
      );
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    },
  );
}
