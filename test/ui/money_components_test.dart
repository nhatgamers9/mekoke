import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/theme/app_theme.dart';
import 'package:steady/core/theme/tokens.dart';
import 'package:steady/l10n/app_localizations.dart';
import 'package:steady/ui/components/bar_chart_row.dart';
import 'package:steady/ui/components/icon_tile.dart';
import 'package:steady/ui/components/keypad.dart';
import 'package:steady/ui/components/steady_icon.dart';
import 'package:steady/ui/components/transaction_row.dart';

const _c = SteadyColors.dark;

Widget _host(Widget child, {double width = 360, double textScale = 1.0}) {
  return MaterialApp(
    theme: buildSteadyTheme(_c, Brightness.dark),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: app!,
    ),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

Future<void> _size(WidgetTester t, [Size size = const Size(360, 800)]) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

void main() {
  group('IconTile', () {
    Widget tile({bool? selected = false, VoidCallback? onTap, String? label}) =>
        IconTile(
          icon: SteadyIcons.coffee,
          label: label ?? 'Eating out',
          selected: selected,
          onTap: onTap ?? () {},
        );

    BoxDecoration disc(WidgetTester t) {
      final box = t.widget<Container>(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      );
      return box.decoration! as BoxDecoration;
    }

    testWidgets('not selected: surface disc, ink icon, muted label', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(_host(tile(selected: false), width: 80));
      expect(disc(tester).color, _c.surface);
      expect(disc(tester).border, isNull);
      expect(tester.widget<SteadyIcon>(find.byType(SteadyIcon)).color, _c.ink);
      expect(
        tester.widget<Text>(find.text('Eating out')).style!.color,
        _c.inkMuted,
      );
    });

    testWidgets('selected: amberSoft disc, 2px amber ring, amber icon', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(_host(tile(selected: true), width: 80));
      final deco = disc(tester);
      expect(deco.color, _c.amberSoft);
      final border = deco.border! as Border;
      expect(border.top.color, _c.amber);
      expect(border.top.width, 2);
      expect(
        tester.widget<SteadyIcon>(find.byType(SteadyIcon)).color,
        _c.amber,
      );
      expect(tester.widget<Text>(find.text('Eating out')).style!.color, _c.ink);
    });

    testWidgets('the disc is 64 and the icon is 26', (tester) async {
      await _size(tester);
      await tester.pumpWidget(_host(tile(), width: 80));
      final circle = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).shape == BoxShape.circle,
      );
      expect(tester.getSize(circle), const Size(64, 64));
      expect(tester.widget<SteadyIcon>(find.byType(SteadyIcon)).size, 26);
    });

    testWidgets('a tap anywhere on the tile calls onTap', (tester) async {
      await _size(tester);
      var taps = 0;
      await tester.pumpWidget(_host(tile(onTap: () => taps++), width: 80));
      await tester.tap(find.text('Eating out'));
      await tester.tap(find.byType(SteadyIcon));
      final rect = tester.getRect(find.byType(IconTile));
      await tester.tapAt(rect.topLeft + const Offset(2, 2));
      expect(taps, 3);
    });

    testWidgets('is at least 48 x 48 and uses the width it is given', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(_host(tile(), width: 80));
      final size = tester.getSize(find.byType(IconTile));
      expect(size.width, 80);
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('a selected tile is a button in a one-of-many group', (
      tester,
    ) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(tile(selected: true), width: 80));
      expect(
        tester.getSemantics(find.byType(IconTile)),
        isSemantics(
          label: 'Eating out',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('an unselected tile says it is not selected', (tester) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(tile(selected: false), width: 80));
      expect(
        tester.getSemantics(find.byType(IconTile)),
        isSemantics(
          label: 'Eating out',
          isButton: true,
          hasSelectedState: true,
          isSelected: false,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('an action tile (selected: null) is a plain button', (
      tester,
    ) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(
          tile(selected: null, label: 'More', onTap: () => taps++),
          width: 80,
        ),
      );
      expect(
        tester.getSemantics(find.byType(IconTile)),
        isSemantics(
          label: 'More',
          isButton: true,
          hasSelectedState: false,
          isInMutuallyExclusiveGroup: false,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.byType(IconTile));
      expect(taps, 1);
      // Ô hành động không bao giờ được vẽ như đang chọn.
      expect(disc(tester).color, _c.surface);
      handle.dispose();
    });

    testWidgets('a long label wraps to two lines, then is cut with ellipsis', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(
        _host(tile(label: 'Education and training courses'), width: 80),
      );
      final text = tester.widget<Text>(
        find.text('Education and training courses'),
      );
      expect(text.maxLines, 2);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.textAlign, TextAlign.center);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow at text scale 2.0', (tester) async {
      await _size(tester);
      await tester.pumpWidget(
        _host(tile(label: 'Eating out'), width: 80, textScale: 2.0),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Keypad', () {
    Widget pad({
      required ValueChanged<String> onKey,
      String separator = '.',
      bool decimalEnabled = true,
    }) => Keypad(
      onKey: onKey,
      decimalSeparator: separator,
      semanticLabel: 'Amount keypad',
      deleteLabel: 'Delete last digit',
      decimalEnabled: decimalEnabled,
    );

    Finder key(String text) =>
        find.descendant(of: find.byType(Keypad), matching: find.text(text));

    Finder deleteKey() => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.label == 'Delete last digit',
    );

    testWidgets('keys are in the order 1 2 3 / 4 5 6 / 7 8 9 / . 0 del', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(_host(pad(onKey: (_) {})));
      final order = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0'];
      final centres = [for (final k in order) tester.getCenter(key(k))];
      for (var i = 0; i < 9; i++) {
        expect(
          centres[i].dx,
          centres[i % 3].dx,
          reason: 'column of ${order[i]}',
        );
        expect(
          centres[i].dy,
          centres[(i ~/ 3) * 3].dy,
          reason: 'row of ${order[i]}',
        );
      }
      for (var row = 1; row < 3; row++) {
        expect(centres[row * 3].dy, greaterThan(centres[(row - 1) * 3].dy));
      }
      // Hàng cuối: '.' '0' del.
      final del = tester.getCenter(deleteKey());
      expect(centres[9].dy, centres[10].dy);
      expect(del.dy, centres[10].dy);
      expect(centres[9].dx, lessThan(centres[10].dx));
      expect(centres[10].dx, lessThan(del.dx));
      expect(centres[9].dy, greaterThan(centres[8].dy));
    });

    testWidgets('each key sends its own character', (tester) async {
      await _size(tester);
      final sent = <String>[];
      await tester.pumpWidget(_host(pad(onKey: sent.add)));
      for (final k in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '.']) {
        await tester.tap(key(k));
      }
      await tester.tap(deleteKey());
      expect(sent, [
        '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '.', 'del', //
      ]);
    });

    testWidgets('the "." key shows the locale separator but still sends "."', (
      tester,
    ) async {
      await _size(tester);
      final sent = <String>[];
      await tester.pumpWidget(_host(pad(onKey: sent.add, separator: ',')));
      expect(key('.'), findsNothing);
      await tester.tap(key(','));
      expect(sent, ['.']);
    });

    testWidgets('a disabled "." does nothing and looks dimmed', (tester) async {
      await _size(tester);
      final sent = <String>[];
      await tester.pumpWidget(
        _host(pad(onKey: sent.add, decimalEnabled: false)),
      );
      await tester.tap(key('.'), warnIfMissed: false);
      expect(sent, isEmpty);
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: key('.'), matching: find.byType(Opacity)).first,
      );
      expect(opacity.opacity, 0.4);
      // Các phím khác vẫn nhận chạm.
      await tester.tap(key('5'));
      expect(sent, ['5']);
    });

    testWidgets('an enabled "." is not dimmed', (tester) async {
      await _size(tester);
      await tester.pumpWidget(_host(pad(onKey: (_) {})));
      expect(
        find.ancestor(of: key('.'), matching: find.byType(Opacity)),
        findsNothing,
      );
    });

    testWidgets('every key is at least 48 x 48 and 56 tall', (tester) async {
      await _size(tester);
      await tester.pumpWidget(_host(pad(onKey: (_) {})));
      final targets = [
        for (final k in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0'])
          find.ancestor(of: key(k), matching: find.byType(InkWell)).first,
        find.descendant(of: deleteKey(), matching: find.byType(InkWell)),
      ];
      expect(targets, hasLength(12));
      for (final target in targets) {
        final size = tester.getSize(target);
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
        expect(size.height, 56);
      }
    });

    testWidgets('the delete key has an icon, no digit, and a spoken label', (
      tester,
    ) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(pad(onKey: (_) {})));
      expect(
        find.descendant(of: deleteKey(), matching: find.byType(SteadyIcon)),
        findsOne,
      );
      expect(
        tester.getSemantics(deleteKey()),
        isSemantics(
          label: 'Delete last digit',
          isButton: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('the pad itself is labelled, and keys are buttons', (
      tester,
    ) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(pad(onKey: (_) {})));
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Amount keypad',
        ),
        findsOne,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('7')),
        isSemantics(label: '7', isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets('a disabled "." is announced as disabled', (tester) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(pad(onKey: (_) {}, decimalEnabled: false)));
      expect(
        tester.getSemantics(find.bySemanticsLabel('.')),
        isSemantics(
          label: '.',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('does not overflow at text scale 2.0', (tester) async {
      await _size(tester);
      await tester.pumpWidget(_host(pad(onKey: (_) {}), textScale: 2.0));
      expect(tester.takeException(), isNull);
    });
  });

  group('TransactionRow', () {
    Widget row({
      String title = 'Groceries',
      String? detail = '9:00 PM',
      String amount = '−\$12.40',
      VoidCallback? onTap,
      bool divider = true,
    }) => TransactionRow(
      icon: SteadyIcons.shoppingCart,
      title: title,
      detail: detail,
      amount: amount,
      onTap: onTap,
      divider: divider,
    );

    testWidgets('shows title, detail and amount; at least 64 tall', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(_host(row()));
      expect(find.text('Groceries'), findsOne);
      expect(find.text('9:00 PM'), findsOne);
      expect(find.text('−\$12.40'), findsOne);
      expect(
        tester.getSize(find.byType(TransactionRow)).height,
        greaterThanOrEqualTo(64),
      );
    });

    testWidgets('the amount is ink, not red and not green', (tester) async {
      await _size(tester);
      await tester.pumpWidget(_host(row()));
      final style = tester.widget<Text>(find.text('−\$12.40')).style!;
      expect(style.color, _c.ink);
      expect(style.color, isNot(_c.rose));
      expect(style.color, isNot(_c.tide));
    });

    testWidgets('title is ink, detail is muted', (tester) async {
      await _size(tester);
      await tester.pumpWidget(_host(row()));
      expect(tester.widget<Text>(find.text('Groceries')).style!.color, _c.ink);
      expect(
        tester.widget<Text>(find.text('9:00 PM')).style!.color,
        _c.inkMuted,
      );
    });

    testWidgets('no detail line when detail is null', (tester) async {
      await _size(tester);
      await tester.pumpWidget(_host(row(detail: null)));
      expect(find.text('9:00 PM'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long title is cut with an ellipsis on one line', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(_host(row(title: 'A very long note ' * 12)));
      final text = tester.widget<Text>(find.textContaining('A very long note'));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'a huge amount at text scale 2.0 shrinks and does not overflow',
      (tester) async {
        await _size(tester);
        const huge = '−\$9,999,999,999.99';
        await tester.pumpWidget(
          _host(
            row(amount: huge, title: 'W' * 60, detail: 'D' * 60),
            textScale: 2.0,
          ),
        );
        expect(tester.takeException(), isNull);
        final rowWidth = tester.getSize(find.byType(TransactionRow)).width;
        // Chữ nằm trong FittedBox: getSize cho kích thước bố cục trước khi thu
        // nhỏ, nên đo bằng hai góc đã qua phép biến đổi khi vẽ.
        final amountWidth =
            tester.getBottomRight(find.text(huge)).dx -
            tester.getTopLeft(find.text(huge)).dx;
        expect(
          amountWidth,
          lessThanOrEqualTo(rowWidth / 2 + 0.5),
          reason: 'the amount may take at most half of the row',
        );
        expect(
          tester.getBottomRight(find.text(huge)).dx,
          lessThanOrEqualTo(tester.getRect(find.byType(TransactionRow)).right),
          reason: 'and stays inside the row',
        );
      },
    );

    testWidgets('a huge amount at 1.0 also fits', (tester) async {
      await _size(tester);
      await tester.pumpWidget(_host(row(amount: '−\$9,999,999,999.99')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a tap calls onTap', (tester) async {
      await _size(tester);
      var taps = 0;
      await tester.pumpWidget(_host(row(onTap: () => taps++)));
      await tester.tap(find.byType(TransactionRow));
      expect(taps, 1);
    });

    testWidgets('the divider is a 1px line under the row, only when asked', (
      tester,
    ) async {
      await _size(tester);
      BoxDecoration? decoration() => tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(TransactionRow),
              matching: find.byType(Container),
            ),
          )
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.border != null && d.shape != BoxShape.circle)
          .firstOrNull;

      await tester.pumpWidget(_host(row(divider: true)));
      final border = decoration()!.border! as Border;
      expect(border.bottom.color, _c.line);
      expect(border.bottom.width, 1);

      await tester.pumpWidget(_host(row(divider: false)));
      expect(decoration(), isNull);
    });

    testWidgets('one merged node reads title, detail and amount', (
      tester,
    ) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(row(onTap: () {})));
      final node = tester.getSemantics(find.byType(TransactionRow));
      expect(node.label, contains('Groceries'));
      expect(node.label, contains('9:00 PM'));
      expect(node.label, contains('12.40'));
      expect(node, isSemantics(isButton: true, hasTapAction: true));
      handle.dispose();
    });

    testWidgets('without onTap it is not announced as a button', (
      tester,
    ) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(row()));
      final node = tester.getSemantics(find.byType(TransactionRow));
      expect(node, isSemantics(isButton: false, hasTapAction: false));
      expect(node.label, contains('Groceries'));
      expect(node.label, contains('9:00 PM'));
      expect(node.label, contains('12.40'));
      handle.dispose();
    });
  });

  group('BarChartRow', () {
    // Khung thử rộng 300: thanh dài nhất = 300 - 300/3 - 8 = 192.
    const width = 300.0;
    const maxBar = width - width / 3 - 8;

    Finder barFinder() => find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).color == _c.amber,
    );

    Widget chart(double fraction, {String value = r'$320.00', double? w}) =>
        _host(
          BarChartRow(label: 'Groceries', value: value, fraction: fraction),
          width: w ?? width,
        );

    testWidgets('fraction 1 is exactly w - w/3 - 8 wide', (tester) async {
      await _size(tester);
      await tester.pumpWidget(chart(1));
      expect(tester.getSize(barFinder()).width, closeTo(maxBar, 0.01));
    });

    testWidgets('fraction 0.5 is half of that', (tester) async {
      await _size(tester);
      await tester.pumpWidget(chart(0.5));
      expect(tester.getSize(barFinder()).width, closeTo(maxBar / 2, 0.01));
    });

    testWidgets('fraction 0.001 still shows a 4px stub', (tester) async {
      await _size(tester);
      await tester.pumpWidget(chart(0.001));
      expect(tester.getSize(barFinder()).width, 4);
    });

    testWidgets('fraction 0 shows no bar at all', (tester) async {
      await _size(tester);
      await tester.pumpWidget(chart(0));
      expect(tester.getSize(barFinder()).width, 0);
    });

    testWidgets('NaN is treated as 0 and does not crash', (tester) async {
      await _size(tester);
      await tester.pumpWidget(chart(double.nan));
      expect(tester.getSize(barFinder()).width, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a fraction above 1 is clamped to the longest bar', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(chart(7));
      expect(tester.getSize(barFinder()).width, closeTo(maxBar, 0.01));
    });

    testWidgets('a negative fraction is clamped to 0', (tester) async {
      await _size(tester);
      await tester.pumpWidget(chart(-2));
      expect(tester.getSize(barFinder()).width, 0);
    });

    testWidgets('the bar is 12 tall and amber with a round right end', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(chart(0.6));
      expect(tester.getSize(barFinder()).height, 12);
      final deco =
          tester.widget<Container>(barFinder()).decoration! as BoxDecoration;
      expect(deco.color, _c.amber);
      expect(
        deco.borderRadius,
        const BorderRadius.horizontal(right: Radius.circular(4)),
      );
    });

    testWidgets('the bar follows the width it is given', (tester) async {
      await _size(tester);
      await tester.pumpWidget(chart(1, w: 200));
      expect(
        tester.getSize(barFinder()).width,
        closeTo(200 - 200 / 3 - 8, 0.01),
      );
    });

    testWidgets('the value is ink and sits right after the bar', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(chart(0.5));
      final value = tester.widget<Text>(find.text(r'$320.00'));
      expect(value.style!.color, _c.ink);
      final barRight = tester.getRect(barFinder()).right;
      final valueLeft = tester.getTopLeft(find.text(r'$320.00')).dx;
      expect(valueLeft, closeTo(barRight + 8, 0.5));
    });

    testWidgets('the longest bar still leaves room for the value', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(chart(1));
      final rowRight = tester.getRect(find.byType(BarChartRow)).right;
      final valueRight = tester.getBottomRight(find.text(r'$320.00')).dx;
      expect(valueRight, lessThanOrEqualTo(rowRight + 0.01));
    });

    testWidgets('the label is ink above the bar', (tester) async {
      await _size(tester);
      await tester.pumpWidget(chart(0.5));
      final label = tester.widget<Text>(find.text('Groceries'));
      expect(label.style!.color, _c.ink);
      expect(label.maxLines, 1);
      expect(
        tester.getBottomLeft(find.text('Groceries')).dy,
        lessThanOrEqualTo(tester.getTopLeft(barFinder()).dy),
      );
    });

    testWidgets('semantics merge the category and the amount', (tester) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(chart(0.5));
      final node = tester.getSemantics(find.byType(BarChartRow));
      expect(node.label, contains('Groceries'));
      expect(node.label, contains(r'$320.00'));
      handle.dispose();
    });

    testWidgets('a huge value at text scale 2.0 does not overflow', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(
        _host(
          const BarChartRow(
            label: 'Eating out and a lot of other words together',
            value: r'$9,999,999,999.99',
            fraction: 1,
          ),
          width: 296,
          textScale: 2.0,
        ),
      );
      expect(tester.takeException(), isNull);
      final rowRight = tester.getRect(find.byType(BarChartRow)).right;
      expect(
        tester.getBottomRight(find.text(r'$9,999,999,999.99')).dx,
        lessThanOrEqualTo(rowRight + 0.01),
      );
    });
  });
}
