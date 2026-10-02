import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/theme/app_theme.dart';
import 'package:steady/core/theme/tokens.dart';
import 'package:steady/l10n/app_localizations.dart';
import 'package:steady/ui/components/steady_button.dart';
import 'package:steady/ui/components/steady_dialogs.dart';
import 'package:steady/ui/components/steady_filter_chips.dart';
import 'package:steady/ui/components/steady_icon.dart';
import 'package:steady/ui/components/steady_icon_button.dart';
import 'package:steady/ui/components/steady_inline_status.dart';
import 'package:steady/ui/components/steady_segmented_control.dart';
import 'package:steady/ui/components/steady_stepper.dart';
import 'package:steady/ui/components/timer_ring.dart';

import '../helpers/timer_helpers.dart';
import '../helpers/widget_helpers.dart';

const _c = SteadyColors.dark;

Widget _host(
  Widget child, {
  double width = 360,
  double textScale = 1.0,
  bool scaffold = true,
}) {
  return MaterialApp(
    theme: buildSteadyTheme(_c, Brightness.dark),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: app!,
    ),
    home: scaffold
        ? Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: width, child: child),
            ),
          )
        : child,
  );
}

Future<void> _size(WidgetTester t, [Size size = const Size(360, 800)]) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

/// Màu nền của `Material` gần nhất nằm trong [of].
Color? _materialColor(WidgetTester t, Finder of) => t
    .widget<Material>(
      find.descendant(of: of, matching: find.byType(Material)).first,
    )
    .color;

Color? _textColor(WidgetTester t, Finder text) =>
    t.widget<Text>(text).style?.color;

void main() {
  group('SteadyInlineStatus', () {
    testWidgets('an error uses ink, never rose; info uses ink-muted', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              SteadyInlineStatus(
                message: 'Broke',
                tone: SteadyStatusTone.error,
              ),
              SteadyInlineStatus(message: 'Fine'),
            ],
          ),
        ),
      );

      expect(_textColor(tester, find.text('Broke')), _c.ink);
      expect(_textColor(tester, find.text('Fine')), _c.inkMuted);
      expect(_textColor(tester, find.text('Broke')), isNot(_c.rose));
    });

    testWidgets('is announced as a live region', (tester) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const SteadyInlineStatus(message: 'Check-in saved.')),
      );

      final node = tester.getSemantics(find.text('Check-in saved.'));
      expect(node.label, 'Check-in saved.');
      expect(node.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });
  });

  group('SteadySegmentedControl', () {
    Widget control({
      String value = 'a',
      ValueChanged<String>? onChanged,
      double textScale = 1.0,
      List<String> labels = const ['One', 'Two', 'Three'],
    }) => _host(
      SteadySegmentedControl<String>(
        options: [
          for (final (i, l) in labels.indexed) SteadySegment('abcdef'[i], l),
        ],
        value: value,
        onChanged: onChanged ?? (_) {},
        semanticLabel: 'Pick one',
      ),
      textScale: textScale,
    );

    testWidgets('the selected segment is inverted: ink background, bg text', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(control(value: 'b'));

      final selected = find.ancestor(
        of: find.text('Two'),
        matching: find.byType(Material),
      );
      expect(tester.widget<Material>(selected.first).color, _c.ink);
      expect(_textColor(tester, find.text('Two')), _c.bg);
      for (final other in ['One', 'Three']) {
        final material = find.ancestor(
          of: find.text(other),
          matching: find.byType(Material),
        );
        expect(
          tester.widget<Material>(material.first).color,
          Colors.transparent,
          reason: other,
        );
        expect(_textColor(tester, find.text(other)), _c.inkMuted);
      }
    });

    testWidgets('the track is surface-2 with a full radius', (tester) async {
      await _size(tester);
      await tester.pumpWidget(control());
      final box = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.color == _c.surface2);
      expect(box.borderRadius, BorderRadius.circular(SteadyRadius.full));
    });

    testWidgets('tapping a segment reports its value', (tester) async {
      await _size(tester);
      final taps = <String>[];
      await tester.pumpWidget(control(onChanged: taps.add));

      await tester.tap(find.text('Two'));
      await tester.tap(find.text('Three'));
      await tester.tap(find.text('One'));

      expect(taps, ['b', 'c', 'a']);
    });

    testWidgets('the tap area is 48 tall: the strip above the pill counts', (
      tester,
    ) async {
      await _size(tester);
      final taps = <String>[];
      await tester.pumpWidget(control(onChanged: taps.add));

      final cell = tester.getRect(
        find
            .ancestor(
              of: find.text('Two'),
              matching: find.descendant(
                of: find.byType(SteadySegmentedControl<String>),
                matching: find.byType(GestureDetector),
              ),
            )
            .last,
      );
      expect(cell.height, 48);
      expect(cell.width, greaterThanOrEqualTo(48));
      // Cạnh trên và cạnh dưới của ô (ngoài viên thuốc cao 40) vẫn bấm được.
      await tester.tapAt(Offset(cell.center.dx, cell.top + 1));
      await tester.tapAt(Offset(cell.center.dx, cell.bottom - 1));
      expect(taps, ['b', 'b']);
    });

    testWidgets(
      'each option is a button, selected state, one choice at a time',
      (tester) async {
        await _size(tester);
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(control(value: 'b'));

        for (final (label, selected) in [
          ('One', false),
          ('Two', true),
          ('Three', false),
        ]) {
          expect(
            tester.getSemantics(find.bySemanticsLabel(label)),
            isSemantics(
              label: label,
              isButton: true,
              hasSelectedState: true,
              isSelected: selected,
              isInMutuallyExclusiveGroup: true,
              hasTapAction: true,
            ),
            reason: label,
          );
        }
        expect(find.bySemanticsLabel('Pick one'), findsWidgets);
        handle.dispose();
      },
    );

    testWidgets('long labels scale down at text scale 2.0 without overflow', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(
        control(
          textScale: 2.0,
          labels: const ['Fasting plan', 'Interval', 'Another long one'],
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('SteadyFilterChips', () {
    Widget chips({
      String value = 'a',
      ValueChanged<String>? onChanged,
      List<String> labels = const ['Tabata', 'HIIT', 'Custom'],
    }) => _host(
      SteadyFilterChips<String>(
        options: [
          for (final (i, l) in labels.indexed)
            SteadySegment('abcdefghij'[i], l),
        ],
        value: value,
        onChanged: onChanged ?? (_) {},
        semanticLabel: 'Saved',
      ),
    );

    testWidgets('selected is inverted; the others are surface-2', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(chips(value: 'b'));

      Color? bg(String label) => tester
          .widget<Material>(
            find
                .ancestor(of: find.text(label), matching: find.byType(Material))
                .first,
          )
          .color;
      expect(bg('HIIT'), _c.ink);
      expect(_textColor(tester, find.text('HIIT')), _c.bg);
      expect(bg('Tabata'), _c.surface2);
      expect(bg('Custom'), _c.surface2);
      expect(_textColor(tester, find.text('Tabata')), _c.inkMuted);
    });

    testWidgets('there is no "All" chip, only the options', (tester) async {
      await _size(tester);
      await tester.pumpWidget(chips());
      expect(find.text('All'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(SteadyFilterChips<String>),
          matching: find.byType(Text),
        ),
        findsNWidgets(3),
      );
    });

    testWidgets('a chip is 36 tall in a 48 tall tap area', (tester) async {
      await _size(tester);
      final taps = <String>[];
      await tester.pumpWidget(chips(onChanged: taps.add));

      final pill = tester.getRect(
        find
            .ancestor(of: find.text('HIIT'), matching: find.byType(Material))
            .first,
      );
      expect(pill.height, 36);
      final cell = tester.getRect(
        find
            .ancestor(
              of: find.text('HIIT'),
              matching: find.descendant(
                of: find.byType(SteadyFilterChips<String>),
                matching: find.byType(GestureDetector),
              ),
            )
            .last,
      );
      expect(cell.height, 48);
      await tester.tapAt(Offset(cell.center.dx, cell.top + 1));
      await tester.tapAt(Offset(cell.center.dx, cell.bottom - 1));
      expect(taps, ['b', 'b']);
    });

    testWidgets('many chips scroll sideways instead of overflowing', (
      tester,
    ) async {
      await _size(tester);
      final taps = <String>[];
      await tester.pumpWidget(
        chips(
          onChanged: taps.add,
          labels: const [
            'Alpha one',
            'Bravo two',
            'Charlie three',
            'Delta four',
            'Echo five',
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      final scrollable = find.descendant(
        of: find.byType(SteadyFilterChips<String>),
        matching: find.byType(SingleChildScrollView),
      );
      expect(
        tester.widget<SingleChildScrollView>(scrollable).scrollDirection,
        Axis.horizontal,
      );

      await tester.ensureVisible(find.text('Echo five'));
      await tester.pump();
      await tester.tap(find.text('Echo five'));
      expect(taps, ['e']);
    });

    testWidgets('semantics: a group, buttons, selected, one at a time', (
      tester,
    ) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(chips(value: 'c'));

      expect(
        tester.getSemantics(find.bySemanticsLabel('Custom')),
        isSemantics(
          label: 'Custom',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Tabata')),
        isSemantics(
          label: 'Tabata',
          isButton: true,
          hasSelectedState: true,
          isSelected: false,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });

  group('SteadyIconButton', () {
    Widget button(
      SteadyIconButtonVariant variant, {
      VoidCallback? onPressed,
      bool enabled = true,
    }) => _host(
      Center(
        child: SteadyIconButton(
          icon: SteadyIcons.play,
          semanticLabel: 'Go',
          onPressed: enabled ? (onPressed ?? () {}) : null,
          variant: variant,
        ),
      ),
    );

    testWidgets('sizes: play 72, filled 48, plain 48', (tester) async {
      await _size(tester);
      for (final (variant, size) in [
        (SteadyIconButtonVariant.play, 72.0),
        (SteadyIconButtonVariant.filled, 48.0),
        (SteadyIconButtonVariant.plain, 48.0),
      ]) {
        await tester.pumpWidget(button(variant));
        expect(
          tester.getSize(semLabel('Go')),
          Size.square(size),
          reason: '$variant',
        );
      }
    });

    testWidgets('colors: amber, surface-2 and transparent', (tester) async {
      await _size(tester);
      for (final (variant, color) in [
        (SteadyIconButtonVariant.play, _c.amber),
        (SteadyIconButtonVariant.filled, _c.surface2),
        (SteadyIconButtonVariant.plain, Colors.transparent),
      ]) {
        await tester.pumpWidget(button(variant));
        expect(
          _materialColor(tester, semLabel('Go')),
          color,
          reason: '$variant',
        );
      }
    });

    testWidgets('it is round', (tester) async {
      await _size(tester);
      await tester.pumpWidget(button(SteadyIconButtonVariant.filled));
      final material = tester.widget<Material>(
        find
            .descendant(of: semLabel('Go'), matching: find.byType(Material))
            .first,
      );
      expect(material.shape, isA<CircleBorder>());
    });

    testWidgets('a tap calls onPressed once', (tester) async {
      await _size(tester);
      var taps = 0;
      await tester.pumpWidget(
        button(SteadyIconButtonVariant.filled, onPressed: () => taps++),
      );
      await tester.tap(semLabel('Go'));
      expect(taps, 1);
    });

    testWidgets('disabled: 40% opacity and no taps', (tester) async {
      await _size(tester);
      var taps = 0;
      await tester.pumpWidget(
        button(
          SteadyIconButtonVariant.filled,
          enabled: false,
          onPressed: () => taps++,
        ),
      );
      expect(
        tester
            .widget<Opacity>(
              find.descendant(
                of: semLabel('Go'),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        0.4,
      );
      await tester.tap(semLabel('Go'), warnIfMissed: false);
      expect(taps, 0);
    });

    testWidgets('the label reaches accessibility as a button', (tester) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(button(SteadyIconButtonVariant.play));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Go')),
        isSemantics(
          label: 'Go',
          isButton: true,
          hasTapAction: true,
          isEnabled: true,
          hasEnabledState: true,
        ),
      );
      await tester.pumpWidget(
        button(SteadyIconButtonVariant.play, enabled: false),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Go')),
        isSemantics(
          label: 'Go',
          isButton: true,
          isEnabled: false,
          hasEnabledState: true,
        ),
      );
      handle.dispose();
    });
  });

  group('SteadyStepper', () {
    Widget stepper({
      String value = '8',
      VoidCallback? onDecrement,
      VoidCallback? onIncrement,
      bool divider = true,
      String? detail,
      double textScale = 1.0,
      double width = 360,
    }) => _host(
      SteadyStepper(
        label: 'Rounds',
        value: value,
        icon: SteadyIcons.repeat,
        detail: detail,
        onDecrement: onDecrement,
        onIncrement: onIncrement,
        divider: divider,
      ),
      textScale: textScale,
      width: width,
    );

    testWidgets('the row is at least 72 tall with 48 round buttons', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(stepper(onDecrement: () {}, onIncrement: () {}));

      expect(
        tester.getSize(find.byType(SteadyStepper)).height,
        greaterThanOrEqualTo(72),
      );
      expect(tester.getSize(semLabel('Decrease Rounds')), const Size(48, 48));
      expect(tester.getSize(semLabel('Increase Rounds')), const Size(48, 48));
    });

    testWidgets('the number sits between the buttons, at least 64 wide', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(stepper(onDecrement: () {}, onIncrement: () {}));
      final minus = tester.getRect(semLabel('Decrease Rounds'));
      final plus = tester.getRect(semLabel('Increase Rounds'));
      final number = tester.getRect(find.text('8'));
      expect(number.left, greaterThanOrEqualTo(minus.right));
      expect(number.right, lessThanOrEqualTo(plus.left));
      expect(
        plus.left - minus.right,
        greaterThanOrEqualTo(64 + 2 * SteadySpace.s1),
      );
    });

    testWidgets('the value is a live region', (tester) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(stepper(onDecrement: () {}, onIncrement: () {}));
      final node = tester.getSemantics(find.text('8'));
      expect(node.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });

    testWidgets('the buttons are named "Decrease x" and "Increase x"', (
      tester,
    ) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(stepper(onDecrement: () {}, onIncrement: () {}));
      for (final label in ['Decrease Rounds', 'Increase Rounds']) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(label)),
          isSemantics(
            label: label,
            isButton: true,
            hasTapAction: true,
            isEnabled: true,
            hasEnabledState: true,
          ),
        );
      }
      handle.dispose();
    });

    testWidgets('a null callback disables that button: 40% and no taps', (
      tester,
    ) async {
      await _size(tester);
      var down = 0;
      var up = 0;
      await tester.pumpWidget(
        stepper(onDecrement: null, onIncrement: () => up++),
      );

      Opacity opacityOf(String label) => tester.widget<Opacity>(
        find.descendant(of: semLabel(label), matching: find.byType(Opacity)),
      );
      expect(opacityOf('Decrease Rounds').opacity, 0.4);
      expect(
        find.descendant(
          of: semLabel('Increase Rounds'),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
      await tester.tap(semLabel('Decrease Rounds'), warnIfMissed: false);
      await tester.tap(semLabel('Increase Rounds'));
      expect(down, 0);
      expect(up, 1);
    });

    testWidgets('the divider is a 1px line, left out on the last row', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(stepper(onDecrement: () {}, onIncrement: () {}));
      BoxDecoration decoration() => tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.color == _c.surface);
      expect(decoration().border, isNotNull);
      expect(decoration().border!.bottom.color, _c.line);
      expect(decoration().border!.bottom.width, 1);

      await tester.pumpWidget(
        stepper(onDecrement: () {}, onIncrement: () {}, divider: false),
      );
      expect(decoration().border, isNull);
    });

    testWidgets(
      'at normal text size the buttons share the row with the label',
      (tester) async {
        await _size(tester);
        await tester.pumpWidget(
          stepper(onDecrement: () {}, onIncrement: () {}),
        );
        final label = tester.getRect(find.text('Rounds'));
        final minus = tester.getRect(semLabel('Decrease Rounds'));
        expect(minus.top, lessThan(label.bottom), reason: 'same row');
        expect(minus.left, greaterThan(label.left));
      },
    );

    testWidgets(
      'at large text size it is two lines: label above, buttons below',
      (tester) async {
        await _size(tester);
        await tester.pumpWidget(
          stepper(onDecrement: () {}, onIncrement: () {}, textScale: 2.0),
        );
        final label = tester.getRect(find.text('Rounds'));
        final minus = tester.getRect(semLabel('Decrease Rounds'));
        final plus = tester.getRect(semLabel('Increase Rounds'));
        expect(minus.top, greaterThanOrEqualTo(label.bottom));
        expect(plus.right, lessThanOrEqualTo(360));
        expect(
          plus.right,
          greaterThan(300),
          reason: 'the buttons are right-aligned',
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('exactly 1.3 times is still one line, above it is two', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(
        stepper(onDecrement: () {}, onIncrement: () {}, textScale: 1.3),
      );
      var label = tester.getRect(find.text('Rounds'));
      var minus = tester.getRect(semLabel('Decrease Rounds'));
      expect(minus.top, lessThan(label.bottom));

      await tester.pumpWidget(
        stepper(onDecrement: () {}, onIncrement: () {}, textScale: 1.4),
      );
      label = tester.getRect(find.text('Rounds'));
      minus = tester.getRect(semLabel('Decrease Rounds'));
      expect(minus.top, greaterThanOrEqualTo(label.bottom));
    });

    testWidgets('a detail line shows under the label', (tester) async {
      await _size(tester);
      await tester.pumpWidget(
        stepper(onDecrement: () {}, onIncrement: () {}, detail: 'Work + rest'),
      );
      final label = tester.getRect(find.text('Rounds'));
      final detail = tester.getRect(find.text('Work + rest'));
      expect(detail.top, greaterThanOrEqualTo(label.bottom));
      expect(_textColor(tester, find.text('Work + rest')), _c.inkMuted);
    });

    group('holding a button', () {
      late int count;
      late ValueNotifier<bool> enabled;

      Widget holdable() {
        return _host(
          ValueListenableBuilder<bool>(
            valueListenable: enabled,
            builder: (context, on, _) => SteadyStepper(
              label: 'Rounds',
              value: '8',
              onDecrement: null,
              onIncrement: on ? () => count++ : null,
            ),
          ),
        );
      }

      setUp(() {
        count = 0;
        enabled = ValueNotifier(true);
      });

      testWidgets('after 400 ms it repeats every 100 ms and stops on release', (
        tester,
      ) async {
        await _size(tester);
        await tester.pumpWidget(holdable());
        final g = await tester.startGesture(
          tester.getCenter(semLabel('Increase Rounds')),
        );

        await tester.pump(const Duration(milliseconds: 399));
        expect(count, 0);
        await tester.pump(const Duration(milliseconds: 1));
        expect(count, 1);
        await tester.pump(const Duration(milliseconds: 100));
        expect(count, 2);
        await tester.pump(const Duration(milliseconds: 100));
        expect(count, 3);
        await g.up();
        await tester.pump(const Duration(seconds: 1));
        expect(count, 3, reason: 'releasing neither repeats nor adds a step');
      });

      testWidgets('a short tap is exactly one call', (tester) async {
        await _size(tester);
        await tester.pumpWidget(holdable());
        await tester.tap(semLabel('Increase Rounds'));
        await tester.pump(const Duration(seconds: 1));
        expect(count, 1);
      });

      testWidgets('cancel stops the repeat', (tester) async {
        await _size(tester);
        await tester.pumpWidget(holdable());
        final g = await tester.startGesture(
          tester.getCenter(semLabel('Increase Rounds')),
        );
        await tester.pump(const Duration(milliseconds: 500));
        final atCancel = count;
        expect(atCancel, 2);
        await g.cancel();
        await tester.pump(const Duration(seconds: 1));
        expect(count, atCancel);
      });

      testWidgets('the repeat stops when the callback becomes null', (
        tester,
      ) async {
        await _size(tester);
        await tester.pumpWidget(holdable());
        final g = await tester.startGesture(
          tester.getCenter(semLabel('Increase Rounds')),
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(count, 2);

        enabled.value = false; // đã chạm giới hạn
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(count, 2, reason: 'no more calls once disabled');
        await g.up();
        await tester.pump();
        expect(count, 2);
      });

      testWidgets('pressing a disabled button starts nothing', (tester) async {
        await _size(tester);
        enabled.value = false;
        await tester.pumpWidget(holdable());
        final g = await tester.startGesture(
          tester.getCenter(semLabel('Increase Rounds')),
        );
        await tester.pump(const Duration(seconds: 2));
        await g.up();
        expect(count, 0);
      });

      testWidgets('leaving the screen while holding leaves no timer behind', (
        tester,
      ) async {
        await _size(tester);
        await tester.pumpWidget(holdable());
        await tester.startGesture(
          tester.getCenter(semLabel('Increase Rounds')),
        );
        await tester.pump(const Duration(milliseconds: 500));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));

        expect(tester.takeException(), isNull);
        // flutter_test báo "A Timer is still pending" nếu còn Timer sót lại.
      });

      testWidgets(
        'moving past the touch slop before 400 ms: no repeat, no step',
        (tester) async {
          await _size(tester);
          await tester.pumpWidget(holdable());
          final g = await tester.startGesture(
            tester.getCenter(semLabel('Increase Rounds')),
          );
          await tester.pump(const Duration(milliseconds: 100));
          await g.moveBy(const Offset(0, 30));
          await tester.pump(const Duration(seconds: 1));
          expect(count, 0, reason: 'a drag is a scroll, not a hold');

          await g.up();
          await tester.pump();
          expect(count, 0, reason: 'lifting after a drag is not a tap either');
          await tester.pump(const Duration(seconds: 1));
          expect(count, 0);
        },
      );

      testWidgets(
        'moving past the touch slop while repeating stops the repeat',
        (tester) async {
          await _size(tester);
          await tester.pumpWidget(holdable());
          final g = await tester.startGesture(
            tester.getCenter(semLabel('Increase Rounds')),
          );
          await tester.pump(const Duration(milliseconds: 500));
          expect(count, 2);

          await g.moveBy(const Offset(0, 30));
          await tester.pump(const Duration(seconds: 1));
          expect(count, 2, reason: 'no step after the finger left the button');

          await g.up();
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          expect(count, 2);
        },
      );

      testWidgets('a small wobble inside the touch slop keeps the hold', (
        tester,
      ) async {
        await _size(tester);
        await tester.pumpWidget(holdable());
        final g = await tester.startGesture(
          tester.getCenter(semLabel('Increase Rounds')),
        );
        await g.moveBy(const Offset(0, 10));

        await tester.pump(const Duration(milliseconds: 400));
        expect(count, 1, reason: 'the first repeat still comes at 400 ms');
        await tester.pump(const Duration(milliseconds: 100));
        expect(count, 2);

        await g.up();
        await tester.pump(const Duration(seconds: 1));
        expect(count, 2, reason: 'releasing neither repeats nor adds a step');
      });

      testWidgets('a new press after a drag holds and repeats again', (
        tester,
      ) async {
        await _size(tester);
        await tester.pumpWidget(holdable());
        final center = tester.getCenter(semLabel('Increase Rounds'));

        final drag = await tester.startGesture(center);
        await drag.moveBy(const Offset(0, 30));
        await tester.pump(const Duration(seconds: 1));
        await drag.up();
        await tester.pump();
        expect(count, 0);

        final g = await tester.startGesture(center);
        await tester.pump(const Duration(milliseconds: 399));
        expect(count, 0);
        await tester.pump(const Duration(milliseconds: 1));
        expect(count, 1);
        await tester.pump(const Duration(milliseconds: 100));
        expect(count, 2);
        await g.up();
        await tester.pump(const Duration(seconds: 1));
        expect(count, 2);
      });
    });
  });

  group('TimerRing', () {
    Widget ring({
      double progress = 0.5,
      String time = '10:00:00',
      String? phase = 'FASTING',
      String? caption = 'Ends 1:00 PM',
      TimerRingTone tone = TimerRingTone.amber,
      TimerRingNumerals numerals = TimerRingNumerals.serif,
      double size = 264,
    }) => _host(
      Center(
        child: TimerRing(
          progress: progress,
          time: time,
          phase: phase,
          caption: caption,
          tone: tone,
          numerals: numerals,
          size: size,
        ),
      ),
    );

    Offset center(WidgetTester t) => t.getCenter(find.byType(TimerRing));

    testWidgets('the default size is 264', (tester) async {
      await _size(tester);
      await tester.pumpWidget(
        _host(const Center(child: TimerRing(progress: 0, time: '0:00'))),
      );
      expect(tester.getSize(find.byType(TimerRing)), const Size(264, 264));
    });

    testWidgets('phase, time and caption are stacked in the middle', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(ring());
      final phase = tester.getRect(find.text('FASTING'));
      final time = tester.getRect(find.text('10:00:00'));
      final caption = tester.getRect(find.text('Ends 1:00 PM'));
      expect(phase.bottom, lessThanOrEqualTo(time.top));
      expect(time.bottom, lessThanOrEqualTo(caption.top));
      for (final r in [phase, time, caption]) {
        expect(
          (r.center.dx - center(tester).dx).abs(),
          lessThan(1),
          reason: 'centred',
        );
      }
      expect(_textColor(tester, find.text('10:00:00')), _c.ink);
      expect(_textColor(tester, find.text('Ends 1:00 PM')), _c.inkMuted);
      expect(_textColor(tester, find.text('FASTING')), _c.amber);
    });

    testWidgets('the phase takes the colour of the tone', (tester) async {
      await _size(tester);
      await tester.pumpWidget(ring(tone: TimerRingTone.tide, phase: 'EATING'));
      expect(_textColor(tester, find.text('EATING')), _c.tide);
    });

    testWidgets('phase and caption are optional', (tester) async {
      await _size(tester);
      await tester.pumpWidget(ring(phase: null, caption: null));
      expect(find.text('FASTING'), findsNothing);
      expect(find.text('10:00:00'), findsOne);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the gym numerals use another type style than the serif', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(ring());
      final serif = tester.widget<Text>(find.text('10:00:00')).style!;
      await tester.pumpWidget(ring(numerals: TimerRingNumerals.gym));
      final gym = tester.widget<Text>(find.text('10:00:00')).style!;
      expect(gym.fontSize, isNot(serif.fontSize));
      expect(
        gym.fontFeatures,
        contains(const FontFeature.tabularFigures()),
        reason: 'even-width digits',
      );
    });

    testWidgets('semantics: one label joined from phase, time and caption', (
      tester,
    ) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(ring());
      final node = tester.getSemantics(find.byType(TimerRing));
      expect(node.label, 'FASTING, 10:00:00, Ends 1:00 PM');
      expect(
        node.flagsCollection.isLiveRegion,
        isFalse,
        reason: 'a ticking time must not be read out every second',
      );

      await tester.pumpWidget(ring(phase: null, caption: 'Goal: 16 hours'));
      expect(
        tester.getSemantics(find.byType(TimerRing)).label,
        '10:00:00, Goal: 16 hours',
      );
      handle.dispose();
    });

    // Vẽ: pixel tại 4 hướng cho biết cung tô từ 12 giờ theo chiều kim đồng hồ.
    group('the arc starts at 12 o\'clock and goes clockwise', () {
      Future<List<int>> sides(WidgetTester t) async {
        final c = center(t);
        const r = (264 - 14) / 2; // bán kính đường giữa nét vẽ
        return [
          await pixelAt(t, c + const Offset(r, 0)), // 3 giờ
          await pixelAt(t, c + const Offset(0, r)), // 6 giờ
          await pixelAt(t, c + const Offset(-r, 0)), // 9 giờ
        ];
      }

      final track = _c.surface2.toARGB32();
      final amber = _c.amber.toARGB32();
      final tide = _c.tide.toARGB32();

      testWidgets('progress 0 draws only the track', (tester) async {
        await _size(tester);
        await tester.pumpWidget(ring(progress: 0));
        expect(await sides(tester), [track, track, track]);
      });

      testWidgets('a quarter fills up to 3 o\'clock', (tester) async {
        await _size(tester);
        await tester.pumpWidget(ring(progress: 0.25));
        // 3 giờ là điểm cuối của cung (đầu bo tròn): chỉ kiểm hai bên còn lại.
        final s = await sides(tester);
        expect(s[1], track);
        expect(s[2], track);
      });

      testWidgets('half fills 3 o\'clock and 6 o\'clock side', (tester) async {
        await _size(tester);
        await tester.pumpWidget(ring(progress: 0.5));
        final s = await sides(tester);
        expect(s[0], amber);
        expect(s[2], track);
      });

      testWidgets('three quarters leave only the top-left empty', (
        tester,
      ) async {
        await _size(tester);
        await tester.pumpWidget(ring(progress: 0.75));
        final s = await sides(tester);
        expect(s[0], amber);
        expect(s[1], amber);
      });

      testWidgets('full is a closed circle', (tester) async {
        await _size(tester);
        await tester.pumpWidget(ring(progress: 1));
        expect(await sides(tester), [amber, amber, amber]);
      });

      testWidgets('the tide tone draws the arc in tide', (tester) async {
        await _size(tester);
        await tester.pumpWidget(ring(progress: 1, tone: TimerRingTone.tide));
        expect(await sides(tester), [tide, tide, tide]);
      });

      testWidgets('a value above 1 or below 0 is clamped', (tester) async {
        await _size(tester);
        await tester.pumpWidget(ring(progress: 7));
        expect(await sides(tester), [amber, amber, amber]);
        await tester.pumpWidget(ring(progress: -3));
        expect(await sides(tester), [track, track, track]);
        expect(tester.takeException(), isNull);
      });

      testWidgets('NaN counts as 0 and does not crash', (tester) async {
        await _size(tester);
        await tester.pumpWidget(ring(progress: double.nan));
        expect(await sides(tester), [track, track, track]);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('a long time shrinks to fit inside the ring', (tester) async {
      await _size(tester);
      await tester.pumpWidget(
        ring(time: '168:10:00', caption: 'Goal reached at 12:00 PM', size: 200),
      );
      expect(tester.takeException(), isNull);
      final ringRect = tester.getRect(find.byType(TimerRing));
      final time = tester.getRect(find.text('168:10:00'));
      expect(time.left, greaterThanOrEqualTo(ringRect.left));
      expect(time.right, lessThanOrEqualTo(ringRect.right));
    });

    testWidgets('a very small ring does not crash', (tester) async {
      await _size(tester);
      await tester.pumpWidget(ring(size: 40));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(ring(size: 0));
      expect(tester.takeException(), isNull);
    });
  });

  group('showSteadyConfirmDialog', () {
    Future<void> openDialog(WidgetTester t, {bool? destructive}) async {
      await t.pumpWidget(
        _host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showSteadyConfirmDialog(
                  context,
                  title: 'Sure?',
                  body: 'Body',
                  confirmLabel: 'Yes',
                  cancelLabel: 'No',
                  destructive: destructive ?? true,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
    }

    testWidgets('by default the confirm button is the danger button', (
      tester,
    ) async {
      await _size(tester);
      await openDialog(tester);
      expect(
        tester
            .widget<SteadyButton>(find.widgetWithText(SteadyButton, 'Yes'))
            .variant,
        SteadyButtonVariant.danger,
      );
      expect(
        tester
            .widget<SteadyButton>(find.widgetWithText(SteadyButton, 'No'))
            .variant,
        SteadyButtonVariant.ghost,
      );
    });

    testWidgets('destructive: false makes the confirm button primary', (
      tester,
    ) async {
      await _size(tester);
      await openDialog(tester, destructive: false);
      expect(
        tester
            .widget<SteadyButton>(find.widgetWithText(SteadyButton, 'Yes'))
            .variant,
        SteadyButtonVariant.primary,
      );
      expect(
        tester
            .widget<SteadyButton>(find.widgetWithText(SteadyButton, 'No'))
            .variant,
        SteadyButtonVariant.ghost,
      );
    });

    testWidgets('the answer is true for confirm, false for cancel or outside', (
      tester,
    ) async {
      await _size(tester);
      bool? answer;
      Future<void> ask(bool destructive) async {
        await tester.pumpWidget(
          _host(
            Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  answer = await showSteadyConfirmDialog(
                    context,
                    title: 'Sure?',
                    body: 'Body',
                    confirmLabel: 'Yes',
                    cancelLabel: 'No',
                    destructive: destructive,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        );
        answer = null;
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
      }

      for (final destructive in [true, false]) {
        await ask(destructive);
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();
        expect(answer, isTrue, reason: 'confirm, destructive=$destructive');

        await ask(destructive);
        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();
        expect(answer, isFalse, reason: 'cancel, destructive=$destructive');

        await ask(destructive);
        await tester.tapAt(const Offset(4, 4));
        await tester.pumpAndSettle();
        expect(answer, isFalse, reason: 'outside, destructive=$destructive');
      }
    });
  });
}
