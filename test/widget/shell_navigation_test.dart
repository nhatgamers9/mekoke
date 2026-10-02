import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/theme/tokens.dart';
import 'package:steady/ui/components/mood_picker.dart';
import 'package:steady/ui/components/steady_tab_bar.dart';

import '../helpers/test_app.dart';
import '../helpers/widget_helpers.dart';

Future<void> _back(WidgetTester t) async {
  await t.binding.handlePopRoute();
  await t.pumpAndSettle();
}

void main() {
  group('Shell and tabs', () {
    testWidgets('opens on Focus with the five tabs in the planned order', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);

      expect(currentTab(tester), 0);
      expect(find.text('This part of Steady isn\'t ready yet.'), findsOne);
      final labels = ['Focus', 'Timer', 'Streaks', 'Money', 'Check-in'];
      final xs = [for (final l in labels) tester.getCenter(tabLabel(l)).dx];
      expect(xs, orderedEquals([...xs]..sort()), reason: 'left to right');
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the tab bar is 72 tall and has five equal columns', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);

      expect(tester.getSize(find.byType(SteadyTabBar)).height, 72);
      final centres = [
        for (final l in ['Focus', 'Timer', 'Streaks', 'Money', 'Check-in'])
          tester.getCenter(tabLabel(l)).dx,
      ];
      for (var i = 1; i < centres.length; i++) {
        expect(centres[i] - centres[i - 1], closeTo(72, 0.5));
      }

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Focus and Money show the placeholder', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);

      for (final (label, index) in [('Money', 3), ('Focus', 0)]) {
        await tapTab(tester, label);
        expect(currentTab(tester), index);
        expect(find.text(label), findsNWidgets(2)); // tab + tiêu đề
        expect(find.text('This part of Steady isn\'t ready yet.'), findsOne);
      }

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Timer is a real screen: title, Fasting and Interval', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);

      await tapTab(tester, 'Timer');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pump();
      await tester.pump();

      expect(currentTab(tester), 1);
      expect(find.text('Timer'), findsNWidgets(2)); // tab + tiêu đề
      expect(find.text('Fasting'), findsOne);
      expect(find.text('Interval'), findsOne);
      expect(
        find.text('This part of Steady isn\'t ready yet.'),
        findsNothing,
        reason: 'the Timer tab is no longer a placeholder',
      );
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Streaks and Check-in tabs show their own screens', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);

      await tapTab(tester, 'Streaks');
      expect(currentTab(tester), 2);
      expect(find.text('Add a habit you want to leave behind.'), findsOne);
      expect(find.byType(MoodPicker), findsNothing);

      await tapTab(tester, 'Check-in');
      expect(currentTab(tester), 4);
      expect(find.byType(MoodPicker), findsOne);
      expect(find.text('Add a habit you want to leave behind.'), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('each tab is a button with a label and a selected state', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Streaks');
      final handle = tester.ensureSemantics();

      for (final label in ['Focus', 'Timer', 'Streaks', 'Money', 'Check-in']) {
        final node = tester.getSemantics(
          find.descendant(
            of: find.byType(SteadyTabBar),
            matching: find.bySemanticsLabel(label),
          ),
        );
        expect(
          node,
          isSemantics(
            label: label,
            isButton: true,
            hasSelectedState: true,
            isSelected: label == 'Streaks',
            hasTapAction: true,
          ),
          reason: label,
        );
      }

      handle.dispose();
      await disposeSteadyApp(tester, services);
    });

    testWidgets('system bars: transparent status bar, surface nav bar', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);

      final style = tester
          .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
          )
          .value;
      expect(style.statusBarColor, Colors.transparent);
      expect(style.statusBarIconBrightness, Brightness.light);
      expect(style.systemNavigationBarColor, SteadyColors.dark.surface);
      expect(style.systemNavigationBarIconBrightness, Brightness.light);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the app paints the dark background, not white', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);

      // Vùng trống giữa màn hình Focus.
      expect(
        await pixelAt(tester, const Offset(180, 500)),
        SteadyColors.dark.bg.toARGB32(),
      );
      // Thanh tab nền surface.
      expect(
        await pixelAt(tester, const Offset(2, 790)),
        SteadyColors.dark.surface.toARGB32(),
      );

      await disposeSteadyApp(tester, services);
    });
  });

  group('Android Back button', () {
    testWidgets('on Streaks, Back goes to Focus', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      final pops = captureSystemPop(tester);
      await tapTab(tester, 'Streaks');

      await _back(tester);

      expect(currentTab(tester), 0);
      expect(pops, isEmpty, reason: 'the app must not exit yet');

      await disposeSteadyApp(tester, services);
    });

    for (final (label, index) in [
      ('Timer', 1),
      ('Money', 3),
      ('Check-in', 4),
    ]) {
      testWidgets('on $label, Back goes to Focus', (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(tester, clock: now.clock);
        final pops = captureSystemPop(tester);
        await tapTab(tester, label);
        expect(currentTab(tester), index);

        await _back(tester);

        expect(currentTab(tester), 0);
        expect(pops, isEmpty);

        await disposeSteadyApp(tester, services);
      });
    }

    testWidgets('on Focus, Back leaves the app', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      final pops = captureSystemPop(tester);

      await _back(tester);

      expect(pops, hasLength(1));
      expect(currentTab(tester), 0);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Streaks, Back, Back: first to Focus, then out of the app', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      final pops = captureSystemPop(tester);
      await tapTab(tester, 'Streaks');

      await _back(tester);
      expect(pops, isEmpty);
      await _back(tester);
      expect(pops, hasLength(1));

      await disposeSteadyApp(tester, services);
    });

    testWidgets('an open sheet is closed first, the tab stays', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      final pops = captureSystemPop(tester);
      await tapTab(tester, 'Streaks');
      await tester.tap(find.text('Add habit'));
      await settle(tester);
      expect(find.text('Save habit'), findsOne);

      await _back(tester);

      expect(find.text('Save habit'), findsNothing, reason: 'sheet closed');
      expect(currentTab(tester), 2, reason: 'still on Streaks');
      expect(pops, isEmpty);

      await _back(tester);
      expect(currentTab(tester), 0);
      await _back(tester);
      expect(pops, hasLength(1));

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a confirm dialog closes first, then the sheet, then the tab', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      final pops = captureSystemPop(tester);
      await tapTab(tester, 'Streaks');
      await seedHabit(tester, services);
      await tester.tap(find.text('No smoking'));
      await settle(tester);
      await tester.tap(find.text('Delete habit'));
      await settle(tester);
      expect(find.text('Delete No smoking?'), findsOne);

      await _back(tester);
      expect(find.text('Delete No smoking?'), findsNothing);
      expect(find.text('Delete habit'), findsOne, reason: 'sheet still open');
      expect(currentTab(tester), 2);
      final stored = await tester.runAsync(
        () => services.habits.watchHabits().first,
      );
      expect(stored, hasLength(1), reason: 'Back is not a confirmation');

      await _back(tester);
      expect(find.text('Delete habit'), findsNothing);
      expect(currentTab(tester), 2);

      await _back(tester);
      expect(currentTab(tester), 0);
      expect(pops, isEmpty);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a date picker closes first without changing the date', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Streaks');
      await tester.tap(find.text('Add habit'));
      await settle(tester);
      await tester.tap(find.text('Oct 2'));
      await settle(tester);
      expect(find.text('OK'), findsOne);

      await _back(tester);

      expect(find.text('OK'), findsNothing);
      expect(find.text('Save habit'), findsOne, reason: 'sheet still open');
      expect(find.text('Oct 2'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the Check-in draft is kept when Back returns to Focus', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await tester.tap(find.text('Great'));
      await tester.pump();

      await _back(tester);
      expect(currentTab(tester), 0);
      await tapTab(tester, 'Check-in');

      expect(
        tester.widget<MoodPicker>(find.byType(MoodPicker)).value?.value,
        5,
      );

      await disposeSteadyApp(tester, services);
    });
  });
}
