import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/theme/app_theme.dart';
import 'package:steady/core/theme/tokens.dart';
import 'package:steady/core/theme/typography.dart';
import 'package:steady/features/check_in/check_in_rules.dart';
import 'package:steady/l10n/app_localizations.dart';
import 'package:steady/ui/components/mood_picker.dart';
import 'package:steady/ui/components/steady_button.dart';
import 'package:steady/ui/components/steady_chip.dart';
import 'package:steady/ui/components/steady_dialogs.dart';
import 'package:steady/ui/components/steady_icon.dart';
import 'package:steady/ui/components/steady_progress_bar.dart';
import 'package:steady/ui/components/steady_tab_bar.dart';
import 'package:steady/ui/components/steady_text_field.dart';
import 'package:steady/ui/components/streak_card.dart';

const _c = SteadyColors.dark;

Widget _host(
  Widget child, {
  double width = 360,
  EdgeInsets padding = EdgeInsets.zero,
  double textScale = 1.0,
  bool scaffold = true,
}) {
  return MaterialApp(
    theme: buildSteadyTheme(_c, Brightness.dark),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale), padding: padding),
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

Color _buttonBackground(WidgetTester t) {
  final button = t.widget<FilledButton>(find.byType(FilledButton));
  return button.style!.backgroundColor!.resolve({})!;
}

void main() {
  group('SteadyProgressBar', () {
    Future<void> pumpBar(WidgetTester t, double value) async {
      await _size(t);
      await t.pumpWidget(
        _host(
          SteadyProgressBar(
            value: value,
            semanticLabel: 'Next: 7 days',
            tone: SteadyBarTone.tide,
          ),
        ),
      );
    }

    double factor(WidgetTester t) => t
        .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .widthFactor!;

    testWidgets('is 8 tall and fills in proportion to value', (tester) async {
      await pumpBar(tester, 0.25);
      expect(tester.getSize(find.byType(SteadyProgressBar)).height, 8);
      expect(factor(tester), 0.25);
    });

    testWidgets('clamps values below 0 and above 1', (tester) async {
      await pumpBar(tester, -3);
      expect(factor(tester), 0.0);
      await pumpBar(tester, 7);
      expect(factor(tester), 1.0);
    });

    testWidgets('NaN does not crash', (tester) async {
      await pumpBar(tester, double.nan);
      expect(factor(tester), 0.0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('exposes a label and a percentage to accessibility', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpBar(tester, 37 / 90);
      final node = tester.getSemantics(find.byType(SteadyProgressBar));
      expect(node.label, 'Next: 7 days');
      expect(node.value, '41%');
      await pumpBar(tester, 5);
      expect(tester.getSemantics(find.byType(SteadyProgressBar)).value, '100%');
      handle.dispose();
    });
  });

  group('SteadyButton', () {
    testWidgets('variants use the planned colors', (tester) async {
      await _size(tester);
      final expected = {
        SteadyButtonVariant.primary: _c.amber,
        SteadyButtonVariant.secondary: _c.surface2,
        SteadyButtonVariant.ghost: Colors.transparent,
        SteadyButtonVariant.danger: _c.roseSoft,
      };
      for (final entry in expected.entries) {
        await tester.pumpWidget(
          _host(
            SteadyButton(label: 'Go', onPressed: () {}, variant: entry.key),
          ),
        );
        expect(_buttonBackground(tester), entry.value, reason: '${entry.key}');
      }
    });

    testWidgets('lg is 52 tall, md is 44 tall inside a 48 tap area', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(
        _host(SteadyButton(label: 'Go', onPressed: () {})),
      );
      expect(tester.getSize(find.byType(FilledButton)).height, 52);

      await tester.pumpWidget(
        _host(
          SteadyButton(
            label: 'Go',
            onPressed: () {},
            size: SteadyButtonSize.md,
          ),
        ),
      );
      // Phần nhìn thấy cao 44, vùng chạm cao 48.
      expect(tester.getSize(find.byType(FilledButton)).height, 48);
      final visible = tester.getSize(
        find
            .descendant(
              of: find.byType(FilledButton),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(visible.height, 44);
    });

    testWidgets('block stretches to the full width', (tester) async {
      await _size(tester);
      await tester.pumpWidget(
        _host(SteadyButton(label: 'Go', onPressed: () {}, block: true)),
      );
      expect(tester.getSize(find.byType(FilledButton)).width, 360);
    });

    testWidgets('disabled: 40% opacity, same colors, no taps', (tester) async {
      await _size(tester);
      var taps = 0;
      await tester.pumpWidget(
        _host(
          SteadyButton(
            label: 'Go',
            onPressed: null,
            variant: SteadyButtonVariant.primary,
          ),
        ),
      );
      expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 0.4);
      expect(_buttonBackground(tester), _c.amber);
      await tester.tap(find.text('Go'), warnIfMissed: false);
      expect(taps, 0);

      await tester.pumpWidget(
        _host(SteadyButton(label: 'Go', onPressed: () => taps++)),
      );
      await tester.tap(find.text('Go'));
      expect(taps, 1);
    });

    testWidgets('a long label is clipped with an ellipsis, no overflow', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(
        _host(
          SteadyButton(
            label: 'A very long button label that cannot possibly fit',
            onPressed: () {},
            icon: SteadyIcons.plus,
          ),
          width: 160,
          textScale: 2.0,
        ),
      );
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.textContaining('A very long'));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('an icon is drawn before the label', (tester) async {
      await _size(tester);
      await tester.pumpWidget(
        _host(
          SteadyButton(
            label: 'Add habit',
            onPressed: () {},
            icon: SteadyIcons.plus,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SteadyIcon), findsOne);
      expect(
        tester.getCenter(find.byType(SteadyIcon)).dx,
        lessThan(tester.getCenter(find.text('Add habit')).dx),
      );
    });
  });

  group('SteadyChip', () {
    testWidgets('has a minimum height of 28 and grows with the text', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(_host(const SteadyChip(label: 'Day 1')));
      expect(tester.getSize(find.byType(SteadyChip)).height, 28);

      await tester.pumpWidget(
        _host(const SteadyChip(label: 'Day 1'), textScale: 2.0),
      );
      expect(
        tester.getSize(find.byType(SteadyChip)).height,
        greaterThan(28),
        reason: 'not a fixed height',
      );
    });

    testWidgets('tones pick the planned colors', (tester) async {
      await _size(tester);
      final expected = {
        SteadyChipTone.neutral: (_c.surface2, _c.inkMuted),
        SteadyChipTone.amber: (_c.amberSoft, _c.amber),
        SteadyChipTone.tide: (_c.tideSoft, _c.tide),
        SteadyChipTone.rose: (_c.roseSoft, _c.rose),
      };
      for (final entry in expected.entries) {
        await tester.pumpWidget(
          _host(SteadyChip(label: 'Label', tone: entry.key)),
        );
        final box = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(SteadyChip),
                matching: find.byType(Container),
              )
              .first,
        );
        expect((box.decoration as BoxDecoration).color, entry.value.$1);
        expect(
          tester.widget<Text>(find.text('Label')).style!.color,
          entry.value.$2,
        );
      }
    });

    testWidgets('a long label is ellipsized without overflow', (tester) async {
      await _size(tester);
      await tester.pumpWidget(
        _host(
          const SteadyChip(
            label: 'A very long chip label that cannot possibly fit here',
            icon: SteadyIcons.sprout,
          ),
          width: 140,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(SteadyChip)).width,
        lessThanOrEqualTo(140),
      );
    });
  });

  group('StreakCard', () {
    Widget card({
      StreakCardSize size = StreakCardSize.lg,
      int days = 127,
      StreakMilestoneView? milestone,
      VoidCallback? onTap,
      String habit = 'No smoking',
    }) => StreakCard(
      habit: habit,
      days: days,
      since: 'Since May 28',
      size: size,
      milestone: milestone,
      onTap: onTap,
    );

    testWidgets('lg uses count-xl, sm uses stat', (tester) async {
      await _size(tester);
      await tester.pumpWidget(_host(card()));
      expect(
        tester.widget<Text>(find.text('127')).style!.fontSize,
        SteadyText.countXl.fontSize,
      );
      await tester.pumpWidget(_host(card(size: StreakCardSize.sm)));
      expect(
        tester.widget<Text>(find.text('127')).style!.fontSize,
        SteadyText.stat.fontSize,
      );
    });

    testWidgets('unit is "day" for 1 and "days" otherwise', (tester) async {
      await _size(tester);
      for (final (days, unit) in [(0, 'days'), (1, 'day'), (2, 'days')]) {
        await tester.pumpWidget(_host(card(days: days)));
        expect(find.text(unit), findsOne, reason: '$days');
      }
    });

    testWidgets('shows the milestone bar and caption only when given', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(_host(card()));
      expect(find.byType(SteadyProgressBar), findsNothing);

      await tester.pumpWidget(
        _host(
          card(
            milestone: const StreakMilestoneView(
              label: 'Next: 180 days · 53 to go',
              progress: 0.4,
            ),
          ),
        ),
      );
      expect(find.byType(SteadyProgressBar), findsOne);
      expect(find.text('Next: 180 days · 53 to go'), findsOne);
    });

    testWidgets('onTap fires, and the card is a button for accessibility', (
      tester,
    ) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(_host(card(onTap: () => taps++)));
      await tester.tap(find.byType(StreakCard));
      expect(taps, 1);
      final node = tester.getSemantics(find.byType(StreakCard));
      expect(node.label, contains('No smoking'));
      expect(node.label, contains('127'));
      expect(node.label, contains('Since May 28'));
      expect(node, isSemantics(isButton: true, hasTapAction: true));
      handle.dispose();
    });

    testWidgets('without onTap it is not announced as a button', (
      tester,
    ) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(card()));
      expect(
        tester.getSemantics(find.byType(StreakCard)),
        isSemantics(isButton: false),
      );
      handle.dispose();
    });

    testWidgets('a huge number scales down instead of overflowing', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(
        _host(card(days: 99999, habit: 'W' * 40), textScale: 2.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('99999'), findsOne);
    });
  });

  group('MoodPicker', () {
    testWidgets('five equal columns with 8px gaps', (tester) async {
      await _size(tester);
      await tester.pumpWidget(
        _host(MoodPicker(value: null, onChanged: (_) {}), width: 320),
      );
      final cells = find.descendant(
        of: find.byType(MoodPicker),
        matching: find.byType(InkWell),
      );
      expect(cells, findsNWidgets(5));
      final rects = [for (var i = 0; i < 5; i++) tester.getRect(cells.at(i))];
      for (final r in rects) {
        expect(r.width, closeTo((320 - 4 * 8) / 5, 0.01));
      }
      for (var i = 1; i < 5; i++) {
        expect(rects[i].left - rects[i - 1].right, closeTo(8, 0.01));
      }
    });

    testWidgets('tapping a cell reports that mood', (tester) async {
      await _size(tester);
      final picked = <Mood>[];
      await tester.pumpWidget(
        _host(MoodPicker(value: null, onChanged: picked.add)),
      );
      for (final label in ['Awful', 'Low', 'Okay', 'Good', 'Great']) {
        await tester.tap(find.text(label));
      }
      expect(picked, Mood.values);
    });

    testWidgets('the selected cell is marked by an amber border', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(
        _host(MoodPicker(value: Mood.okay, onChanged: (_) {})),
      );
      Color? borderOf(String label) {
        final material = tester.widget<Material>(
          find
              .ancestor(of: find.text(label), matching: find.byType(Material))
              .first,
        );
        return (material.shape as RoundedRectangleBorder).side.color;
      }

      expect(borderOf('Okay'), _c.amber);
      expect(borderOf('Good'), Colors.transparent);
      expect(borderOf('Awful'), Colors.transparent);
    });

    testWidgets('accessibility: buttons in an exclusive group, one selected', (
      tester,
    ) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(MoodPicker(value: Mood.good, onChanged: (_) {})),
      );
      for (final label in ['Awful', 'Low', 'Okay', 'Good', 'Great']) {
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        expect(
          node,
          isSemantics(
            label: label,
            isButton: true,
            hasSelectedState: true,
            isSelected: label == 'Good',
            isInMutuallyExclusiveGroup: true,
            hasTapAction: true,
          ),
          reason: label,
        );
      }
      handle.dispose();
    });

    testWidgets('labels never overflow at text scale 2.0', (tester) async {
      await _size(tester);
      await tester.pumpWidget(
        _host(MoodPicker(value: null, onChanged: (_) {}), textScale: 2.0),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('SteadyTabBar', () {
    const items = [
      SteadyTabItem(SteadyIcons.audioWaveform, 'Focus'),
      SteadyTabItem(SteadyIcons.timer, 'Timer'),
      SteadyTabItem(SteadyIcons.sprout, 'Streaks'),
      SteadyTabItem(SteadyIcons.wallet, 'Money'),
      SteadyTabItem(SteadyIcons.notebookPen, 'Check-in'),
    ];

    Widget bar({
      int current = 0,
      ValueChanged<int>? onChanged,
      EdgeInsets? pad,
      double scale = 1.0,
    }) => _host(
      Align(
        alignment: Alignment.bottomCenter,
        child: SteadyTabBar(
          items: items,
          current: current,
          onChanged: onChanged ?? (_) {},
        ),
      ),
      padding: pad ?? EdgeInsets.zero,
      textScale: scale,
    );

    testWidgets('tapping a tab reports its index', (tester) async {
      await _size(tester);
      final taps = <int>[];
      await tester.pumpWidget(bar(onChanged: taps.add));
      for (final item in items) {
        await tester.tap(find.text(item.label));
      }
      expect(taps, [0, 1, 2, 3, 4]);
    });

    testWidgets('adds the bottom safe area to the 72 height', (tester) async {
      await _size(tester);
      await tester.pumpWidget(bar(pad: const EdgeInsets.only(bottom: 24)));
      expect(tester.getSize(find.byType(SteadyTabBar)).height, 72 + 24);
    });

    testWidgets('the active tab has an amber-soft pill, others do not', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(bar(current: 2));
      Color? pillOf(String label) {
        final tab = find.ancestor(
          of: find.text(label),
          matching: find.byType(InkWell),
        );
        final pill = find.descendant(of: tab, matching: find.byType(Container));
        for (final e in pill.evaluate()) {
          final w = e.widget as Container;
          final d = w.decoration;
          if (d is BoxDecoration && (w.constraints?.maxWidth == 56)) {
            return d.color;
          }
        }
        return null;
      }

      expect(pillOf('Streaks'), _c.amberSoft);
      expect(pillOf('Focus'), Colors.transparent);
    });

    testWidgets('text scale is capped at 1.3 inside the bar', (tester) async {
      await _size(tester);
      await tester.pumpWidget(bar(scale: 2.0));
      final h = tester.getSize(find.text('Check-in')).height;
      expect(h, closeTo(16 * 1.3, 0.5), reason: 'caption line 16 * 1.3');
      expect(tester.takeException(), isNull);
    });
  });

  group('SteadyTextField', () {
    testWidgets('enforces maxLength by grapheme and hides the counter', (
      tester,
    ) async {
      await _size(tester);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(SteadyTextField(controller: controller, maxLength: 5)),
      );
      await tester.enterText(find.byType(TextField), '👨‍👩‍👧' * 8);
      expect(controller.text.characters.length, 5);
      expect(find.textContaining('/'), findsNothing, reason: 'no counter');
    });

    testWidgets('border turns amber on focus', (tester) async {
      await _size(tester);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(SteadyTextField(controller: controller, hint: 'No sugar')),
      );
      InputBorder? border() => tester
          .widget<TextField>(find.byType(TextField))
          .decoration!
          .enabledBorder;
      expect((border() as OutlineInputBorder).borderSide.color, _c.lineStrong);
      expect(
        (tester
                    .widget<TextField>(find.byType(TextField))
                    .decoration!
                    .focusedBorder
                as OutlineInputBorder)
            .borderSide
            .color,
        _c.amber,
      );
      expect(find.text('No sugar'), findsOne);
    });

    testWidgets('tapping outside removes focus', (tester) async {
      await _size(tester);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              SteadyTextField(controller: controller),
              const SizedBox(height: 300),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      await tester.tapAt(const Offset(200, 500));
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );
    });

    testWidgets('a multi-line field has the requested lines', (tester) async {
      await _size(tester);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          SteadyTextField(controller: controller, minLines: 3, maxLines: 3),
        ),
      );
      // 3 dòng x 24 + đệm dọc 2 x 12.
      expect(
        tester.getSize(find.byType(TextField)).height,
        greaterThanOrEqualTo(3 * 24 + 24),
      );
    });
  });

  group('SteadyIcon', () {
    testWidgets('is decorative without a semantic label', (tester) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const SteadyIcon(SteadyIcons.plus)));
      await tester.pump();
      expect(find.bySemanticsLabel('Add'), findsNothing);
      handle.dispose();
    });

    testWidgets('announces its label when one is given', (tester) async {
      await _size(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const SteadyIcon(SteadyIcons.plus, semanticLabel: 'Add')),
      );
      await tester.pump();
      expect(find.bySemanticsLabel('Add'), findsOne);
      handle.dispose();
    });

    testWidgets('renders every icon the app uses without errors', (
      tester,
    ) async {
      await _size(tester);
      await tester.pumpWidget(
        _host(
          const Wrap(
            children: [
              SteadyIcon(SteadyIcons.audioWaveform),
              SteadyIcon(SteadyIcons.timer),
              SteadyIcon(SteadyIcons.sprout),
              SteadyIcon(SteadyIcons.wallet),
              SteadyIcon(SteadyIcons.notebookPen),
              SteadyIcon(SteadyIcons.plus),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });
  });

  group('steady_dialogs', () {
    Future<void> openHost(
      WidgetTester t,
      void Function(BuildContext) onPressed,
    ) async {
      await _size(t);
      await t.pumpWidget(
        _host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => onPressed(context),
              child: const Text('open'),
            ),
          ),
        ),
      );
    }

    testWidgets('confirm dialog: true only on the confirm button', (
      tester,
    ) async {
      bool? result;
      await openHost(tester, (context) async {
        result = await showSteadyConfirmDialog(
          context,
          title: 'Delete X?',
          body: 'Gone for good.',
          confirmLabel: 'Delete',
          cancelLabel: 'Cancel',
        );
      });

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Delete X?'), findsOne);
      expect(find.text('Gone for good.'), findsOne);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(result, isTrue);

      result = null;
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isFalse);

      result = null;
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(result, isFalse, reason: 'tap outside is a cancel');

      result = null;
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(result, isFalse, reason: 'Back is a cancel');
    });

    testWidgets('the sheet pads the bottom by the keyboard height', (
      tester,
    ) async {
      await openHost(tester, (context) {
        showSteadySheet<void>(
          context,
          builder: (_) => const SizedBox(height: 40, child: Text('content')),
        );
      });
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final withoutKeyboard = tester.getRect(find.byType(BottomSheet));

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final content = tester.getRect(find.text('content'));
      expect(content.bottom, lessThanOrEqualTo(800 - 300 - 20 + 1));
      expect(
        tester.getRect(find.byType(BottomSheet)).top,
        lessThan(withoutKeyboard.top),
        reason: 'sheet grows upward with the keyboard',
      );
    });

    testWidgets('the sheet has a rounded top, no bottom radius', (
      tester,
    ) async {
      await openHost(tester, (context) {
        showSteadySheet<void>(context, builder: (_) => const Text('content'));
      });
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final decorated = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(Container),
            )
            .first,
      );
      final deco = decorated.decoration! as BoxDecoration;
      expect(deco.color, _c.surface);
      expect(
        deco.borderRadius,
        const BorderRadius.vertical(top: Radius.circular(SteadyRadius.xl)),
      );
      expect(deco.boxShadow!.single.color, _c.sheetShadow);
      expect(deco.boxShadow!.single.offset, const Offset(0, -12));
      expect(deco.boxShadow!.single.blurRadius, 40);
    });

    testWidgets('a new snackbar replaces the one that is showing', (
      tester,
    ) async {
      await _size(tester);
      late ScaffoldMessengerState messenger;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              messenger = ScaffoldMessenger.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      showSteadySnackBar(messenger, 'first');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('first'), findsOne);

      showSteadySnackBar(messenger, 'second');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('second'), findsOne);
      expect(find.text('first'), findsNothing);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('showing a snackbar on a messenger that is gone is a no-op', (
      tester,
    ) async {
      await _size(tester);
      late ScaffoldMessengerState messenger;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              messenger = ScaffoldMessenger.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());

      expect(() => showSteadySnackBar(messenger, 'late'), returnsNormally);
      expect(tester.takeException(), isNull);
    });
  });
}
