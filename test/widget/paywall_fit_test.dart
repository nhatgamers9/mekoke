import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/theme/tokens.dart';
import 'package:steady/features/premium/paywall_screen.dart';
import 'package:steady/ui/components/plan_option.dart';
import 'package:steady/ui/components/steady_button.dart';

import '../helpers/money_helpers.dart';
import '../helpers/test_app.dart';
import '../helpers/timer_helpers.dart';
import '../helpers/widget_helpers.dart';

// Bố cục của tab Focus (có nút "See Premium") và của paywall đo với phông thật.
// `flutter test` mặc định dùng phông Ahem, rộng 1em mỗi ký tự, nên rộng hơn
// nhiều so với máy thật (ví dụ tab Focus ở 360x560 và cỡ chữ 2.0 tràn 36px với
// Ahem nhưng vừa với Figtree). File này nạp Figtree và Newsreader thật; mỗi
// file test chạy trong tiến trình riêng nên không ảnh hưởng test khác. Các
// phép kiểm không được nới: nếu phông thật mà vẫn tràn thì test rớt thật.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadRealFonts();
  });

  const cta = 'Try 3 days free';
  Finder ctaButton() => find.widgetWithText(SteadyButton, cta);
  Finder card(String title) => find.widgetWithText(PlanOption, title);
  Finder inCard(String title, String text) =>
      find.descendant(of: card(title), matching: find.text(text));
  Finder terms() => find.textContaining('Free for 3 days');

  testWidgets('control: the real fonts are loaded (short caption)', (
    tester,
  ) async {
    final now = FakeNow(evening());
    final services = await pumpSteadyApp(tester, clock: now.clock);
    await tester.tap(find.text('See Premium'));
    await settle(tester);

    // Ahem: "per month" (9 ký tự, 12px) rộng 108px. Figtree thật chỉ khoảng
    // một nửa.
    expect(tester.getSize(find.text('per month')).width, lessThan(80));
    expect(tester.takeException(), isNull);

    await disposeSteadyApp(tester, services);
  });

  for (final (size, scale) in [
    (const Size(360, 800), 1.0),
    (const Size(360, 800), 2.0),
    (const Size(360, 560), 1.0),
    (const Size(360, 560), 1.3),
    (const Size(360, 560), 2.0),
    (const Size(320, 640), 1.0),
    (const Size(320, 640), 2.0),
  ]) {
    testWidgets('Focus, See Premium and the paywall fit at '
        '${size.width.toInt()}x${size.height.toInt()}, text scale $scale', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(
        tester,
        clock: now.clock,
        size: size,
        textScale: scale,
      );

      // Tab Focus: không tràn, nút nằm trên thanh tab nên bấm được.
      expect(tester.takeException(), isNull, reason: 'Focus tab');
      final seePremium = tester.getRect(find.text('See Premium'));
      expect(
        seePremium.bottom,
        lessThanOrEqualTo(size.height - SteadySize.tabbar),
        reason: 'the button is above the tab bar',
      );
      await tester.tap(find.text('See Premium'));
      await settle(tester);

      // Paywall: mở được, không tràn.
      expect(find.byType(PaywallScreen), findsOne);
      expect(tester.takeException(), isNull, reason: 'paywall opened');

      // Giá và kỳ nằm trọn trong thẻ, thẻ cao ít nhất 48.
      for (final (title, price, period) in [
        ('Monthly', r'$9.99', 'per month'),
        ('Weekly', r'$4.99', 'per week'),
      ]) {
        final cardRect = tester.getRect(card(title));
        expect(cardRect.height, greaterThanOrEqualTo(SteadySize.tap));
        final priceRect = tester.getRect(inCard(title, price));
        final periodRect = tester.getRect(inCard(title, period));
        expect(cardRect.contains(priceRect.topLeft), isTrue, reason: price);
        expect(cardRect.contains(priceRect.bottomRight), isTrue);
        expect(cardRect.contains(periodRect.bottomRight), isTrue);
      }

      // Cuộn tới nút chính và dòng điều khoản, rồi bấm nút chính.
      await tester.ensureVisible(ctaButton());
      await tester.pump();
      final button = tester.getRect(ctaButton());
      expect(button.top, greaterThanOrEqualTo(0));
      expect(button.bottom, lessThanOrEqualTo(size.height));
      await tester.ensureVisible(terms());
      await tester.pump();
      final termsRect = tester.getRect(terms());
      expect(termsRect.top, greaterThanOrEqualTo(0));
      expect(termsRect.bottom, lessThanOrEqualTo(size.height));
      await tapScrolled(tester, ctaButton());
      expect(
        find.text("Purchases aren't available yet."),
        findsOne,
        reason: 'the unavailable line',
      );
      expect(tester.takeException(), isNull, reason: 'after pressing');

      // Đổi gói, rồi đóng bằng nút X.
      await tapScrolled(tester, inCard('Weekly', 'Weekly'));
      expect(
        find.text(
          r'Free for 3 days, then $4.99 per week. '
          'Cancel anytime in Google Play.',
        ),
        findsOne,
      );
      await tapScrolled(tester, semLabel('Close'));
      await settle(tester);
      expect(find.byType(PaywallScreen), findsNothing);
      expect(tester.takeException(), isNull, reason: 'closed');

      await disposeSteadyApp(tester, services);
    });
  }
}
