import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/theme/app_theme.dart';
import 'package:steady/core/theme/tokens.dart';
import 'package:steady/l10n/app_localizations.dart';
import 'package:steady/ui/components/plan_option.dart';
import 'package:steady/ui/components/steady_icon.dart';

const _c = SteadyColors.dark;

// Đúng các chuỗi mà màn paywall truyền vào.
const _monthly = 'Monthly';
const _weekly = 'Weekly';
const _monthlyPrice = r'$9.99';
const _weeklyPrice = r'$4.99';
const _perMonth = 'per month';
const _perWeek = 'per week';
const _trial = '3-day free trial';

Widget _wrap(Widget home, {double textScale = 1.0}) {
  return MaterialApp(
    theme: buildSteadyTheme(_c, Brightness.dark),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: app!,
    ),
    home: home,
  );
}

/// Chiều cao không bị chặn (như trong thân cuộn của paywall): ở cỡ chữ 2.0 thẻ
/// có thể cao hơn màn hình mà không phải là lỗi tràn.
Widget _host(Widget child, {double width = 360, double textScale = 1.0}) {
  return _wrap(
    Scaffold(
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
    textScale: textScale,
  );
}

Future<void> _size(WidgetTester t, [Size size = const Size(360, 800)]) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

PlanOption _option({
  String title = _monthly,
  String price = _monthlyPrice,
  String period = _perMonth,
  bool selected = false,
  VoidCallback? onTap,
  String? note = _trial,
}) => PlanOption(
  title: title,
  price: price,
  period: period,
  selected: selected,
  onTap: onTap ?? () {},
  note: note,
);

Finder get _radio => find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).shape == BoxShape.circle,
);

BoxDecoration _radioDecoration(WidgetTester t) =>
    t.widget<Container>(_radio).decoration! as BoxDecoration;

RoundedRectangleBorder _cardShape(WidgetTester t) {
  final material = t.widget<Material>(
    find
        .descendant(
          of: find.byType(PlanOption),
          matching: find.byType(Material),
        )
        .first,
  );
  return material.shape! as RoundedRectangleBorder;
}

Color? _textColor(WidgetTester t, String text) =>
    t.widget<Text>(find.text(text)).style?.color;

void main() {
  group('PlanOption: border', () {
    testWidgets('not selected: 2px lineStrong border, surface fill', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(_host(_option(selected: false)));

      final shape = _cardShape(tester);
      expect(shape.side.color, _c.lineStrong);
      expect(shape.side.width, 2);
      expect(shape.borderRadius, BorderRadius.circular(SteadyRadius.lg));
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(PlanOption),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, _c.surface);
    });

    testWidgets('selected: 2px amber border', (tester) async {
      await _size(tester);
      await tester.pumpWidget(_host(_option(selected: true)));

      final shape = _cardShape(tester);
      expect(shape.side.color, _c.amber);
      expect(shape.side.width, 2);
      expect(shape.borderRadius, BorderRadius.circular(SteadyRadius.lg));
    });

    testWidgets('the border follows the selected flag when it changes', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(_host(_option(selected: false)));
      expect(_cardShape(tester).side.color, _c.lineStrong);

      await tester.pumpWidget(_host(_option(selected: true)));
      expect(_cardShape(tester).side.color, _c.amber);

      await tester.pumpWidget(_host(_option(selected: false)));
      expect(_cardShape(tester).side.color, _c.lineStrong);
    });
  });

  group('PlanOption: radio', () {
    testWidgets('not selected: empty 24x24 ring in lineStrong, no tick', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(_host(_option(selected: false)));

      expect(tester.getSize(_radio), const Size(24, 24));
      final deco = _radioDecoration(tester);
      expect(deco.color, isNull);
      final border = deco.border! as Border;
      expect(border.top.color, _c.lineStrong);
      expect(border.top.width, 2);
      expect(find.byType(SteadyIcon), findsNothing);
    });

    testWidgets('selected: solid amber disc with a 16px onAmber tick', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(_host(_option(selected: true)));

      expect(tester.getSize(_radio), const Size(24, 24));
      final deco = _radioDecoration(tester);
      expect(deco.color, _c.amber);
      final border = deco.border! as Border;
      expect(border.top.color, _c.amber);
      expect(border.top.width, 2);

      final tick = tester.widget<SteadyIcon>(find.byType(SteadyIcon));
      expect(tick.name, SteadyIcons.check);
      expect(tick.size, 16);
      expect(tick.color, _c.onAmber);
      // Dấu tích nằm trong ô radio.
      expect(
        find.descendant(of: _radio, matching: find.byType(SteadyIcon)),
        findsOne,
      );
    });
  });

  group('PlanOption: content', () {
    testWidgets('title, price, period and note are all shown', (tester) async {
      await _size(tester);
      await tester.pumpWidget(_host(_option()));

      expect(find.text(_monthly), findsOne);
      expect(find.text(_monthlyPrice), findsOne);
      expect(find.text(_perMonth), findsOne);
      expect(find.text(_trial), findsOne);
    });

    testWidgets('text colors: ink for title and price, muted for the rest', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(_host(_option()));

      expect(_textColor(tester, _monthly), _c.ink);
      expect(_textColor(tester, _monthlyPrice), _c.ink);
      expect(_textColor(tester, _trial), _c.inkMuted);
      expect(_textColor(tester, _perMonth), _c.inkMuted);
    });

    testWidgets('without a note, no note text is drawn', (tester) async {
      await _size(tester);
      await tester.pumpWidget(_host(_option(note: null)));

      expect(find.text(_monthly), findsOne);
      expect(find.text(_monthlyPrice), findsOne);
      expect(find.text(_perMonth), findsOne);
      expect(find.text(_trial), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the note sits under the title, left-aligned with it', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(_host(_option()));

      final title = tester.getRect(find.text(_monthly));
      final note = tester.getRect(find.text(_trial));
      expect(note.top, greaterThanOrEqualTo(title.bottom));
      expect(note.left, title.left);
    });

    testWidgets('the price column is right-aligned: period ends with price', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(_host(_option()));

      final price = tester.getRect(find.text(_monthlyPrice));
      final period = tester.getRect(find.text(_perMonth));
      expect(period.top, greaterThanOrEqualTo(price.bottom));
      expect(period.right, closeTo(price.right, 0.5));
    });

    testWidgets('uses the whole width it is given', (tester) async {
      await _size(tester);
      await tester.pumpWidget(_host(_option()));
      expect(tester.getSize(find.byType(PlanOption)).width, 360);
    });
  });

  group('PlanOption: tapping', () {
    testWidgets('a tap anywhere on the card calls onTap', (tester) async {
      await _size(tester);
      var taps = 0;
      await tester.pumpWidget(_host(_option(onTap: () => taps++)));

      await tester.tap(find.text(_monthly));
      await tester.tap(find.text(_trial));
      await tester.tap(find.text(_monthlyPrice));
      await tester.tap(find.text(_perMonth));
      await tester.tap(_radio);
      final rect = tester.getRect(find.byType(PlanOption));
      // Hai góc trong (cách góc 8px, vẫn nằm trong đường bo) và chính giữa.
      await tester.tapAt(rect.topLeft + const Offset(8, 8));
      await tester.tapAt(rect.bottomRight - const Offset(8, 8));
      await tester.tapAt(rect.center);
      expect(taps, 8);
    });

    testWidgets('a selected card still calls onTap when tapped again', (
      tester,
    ) async {
      await _size(tester);
      var taps = 0;
      await tester.pumpWidget(
        _host(_option(selected: true, onTap: () => taps++)),
      );
      await tester.tap(find.byType(PlanOption));
      await tester.tap(find.byType(PlanOption));
      expect(taps, 2);
    });

    testWidgets('FAILURE PATH: a tap outside the card does not call onTap', (
      tester,
    ) async {
      await _size(tester);
      var taps = 0;
      await tester.pumpWidget(_host(_option(onTap: () => taps++), width: 300));

      final rect = tester.getRect(find.byType(PlanOption));
      // Bên phải mép thẻ và bên dưới thẻ.
      await tester.tapAt(Offset(rect.right + 20, rect.center.dy));
      await tester.tapAt(Offset(rect.center.dx, rect.bottom + 20));
      expect(taps, 0);
    });
  });

  group('PlanOption: size', () {
    testWidgets('is at least 48 tall with a note', (tester) async {
      await _size(tester);
      await tester.pumpWidget(_host(_option()));
      expect(
        tester.getSize(find.byType(PlanOption)).height,
        greaterThanOrEqualTo(SteadySize.tap),
      );
    });

    testWidgets('is at least 48 tall without a note', (tester) async {
      await _size(tester);
      await tester.pumpWidget(_host(_option(note: null)));
      expect(
        tester.getSize(find.byType(PlanOption)).height,
        greaterThanOrEqualTo(SteadySize.tap),
      );
    });

    testWidgets('is at least 48 tall even with the shortest strings', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(
        _host(_option(title: 'A', price: r'$1', period: 'p', note: null)),
      );
      expect(
        tester.getSize(find.byType(PlanOption)).height,
        greaterThanOrEqualTo(SteadySize.tap),
      );
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('is at least 48 tall at text scale $scale', (tester) async {
        await _size(tester);
        await tester.pumpWidget(_host(_option(), textScale: scale));
        expect(
          tester.getSize(find.byType(PlanOption)).height,
          greaterThanOrEqualTo(SteadySize.tap),
        );
      });
    }
  });

  group('PlanOption: semantics', () {
    testWidgets('a selected card is a button in a one-of-many group', (
      tester,
    ) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_option(selected: true)));

      expect(
        tester.getSemantics(find.byType(PlanOption)),
        isSemantics(
          label: 'Monthly, \$9.99, per month, 3-day free trial',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('an unselected card says it is not selected', (tester) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          _option(
            title: _weekly,
            price: _weeklyPrice,
            period: _perWeek,
            selected: false,
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(PlanOption)),
        isSemantics(
          label: 'Weekly, \$4.99, per week, 3-day free trial',
          isButton: true,
          hasSelectedState: true,
          isSelected: false,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('without a note the label has no trailing comma', (
      tester,
    ) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_option(note: null)));

      final node = tester.getSemantics(find.byType(PlanOption));
      expect(
        node,
        isSemantics(
          label: 'Monthly, \$9.99, per month',
          isButton: true,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('the semantic tap action calls onTap', (tester) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(_host(_option(onTap: () => taps++)));

      tester.semantics.tap(find.semantics.byLabel(RegExp('^Monthly')));
      await tester.pump();
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('the card reads as one node: no separate child labels', (
      tester,
    ) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_option(selected: true)));

      expect(find.bySemanticsLabel(_trial), findsNothing);
      expect(find.bySemanticsLabel(_perMonth), findsNothing);
      handle.dispose();
    });
  });

  group('PlanOption: layout with the strings of the paywall', () {
    for (final scale in [1.0, 2.0]) {
      for (final width in [320.0, 360.0]) {
        testWidgets('no overflow at width $width, text scale $scale', (
          tester,
        ) async {
          await _size(tester, Size(width, 800));
          await tester.pumpWidget(
            _host(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _option(selected: true),
                  const SizedBox(height: SteadySpace.s3),
                  _option(
                    title: _weekly,
                    price: _weeklyPrice,
                    period: _perWeek,
                  ),
                ],
              ),
              width: width,
              textScale: scale,
            ),
          );

          expect(tester.takeException(), isNull);
          for (final option in find.byType(PlanOption).evaluate()) {
            final size = tester.getSize(find.byWidget(option.widget));
            expect(size.width, width);
            expect(size.height, greaterThanOrEqualTo(SteadySize.tap));
          }
        });
      }
    }

    testWidgets('at 320 wide and scale 2.0 the price and period stay whole', (
      tester,
    ) async {
      await _size(tester, const Size(320, 800));
      await tester.pumpWidget(
        _host(_option(selected: true), width: 320, textScale: 2.0),
      );
      expect(tester.takeException(), isNull);

      // Giá và kỳ không bị bẻ thành hai dòng: chiều cao bằng khi có chỗ rộng.
      final narrowPrice = tester.getSize(find.text(_monthlyPrice));
      final narrowPeriod = tester.getSize(find.text(_perMonth));
      final card = tester.getRect(find.byType(PlanOption));
      expect(
        card.contains(tester.getRect(find.text(_monthlyPrice)).topLeft),
        isTrue,
      );
      expect(
        card.contains(tester.getRect(find.text(_perMonth)).bottomRight),
        isTrue,
        reason: 'the period stays inside the card',
      );

      await _size(tester, const Size(2000, 800));
      await tester.pumpWidget(
        _host(_option(selected: true), width: 2000, textScale: 2.0),
      );
      expect(tester.getSize(find.text(_monthlyPrice)), narrowPrice);
      expect(tester.getSize(find.text(_perMonth)), narrowPeriod);
    });

    testWidgets('a very long title wraps instead of overflowing', (
      tester,
    ) async {
      await _size(tester, const Size(320, 800));
      await tester.pumpWidget(
        _host(
          _option(title: 'Monthly plan with a really long name'),
          width: 320,
          textScale: 2.0,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(_monthlyPrice), findsOne);
    });

    testWidgets('works inside SliverFillRemaining(hasScrollBody: false)', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      _option(selected: true),
                      const SizedBox(height: SteadySpace.s3),
                      _option(
                        title: _weekly,
                        price: _weeklyPrice,
                        period: _perWeek,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          textScale: 2.0,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(PlanOption), findsNWidgets(2));
    });
  });
}
