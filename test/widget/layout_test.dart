import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/time/local_date.dart';
import 'package:steady/ui/components/mood_picker.dart';
import 'package:steady/ui/components/steady_tab_bar.dart';
import 'package:steady/ui/components/streak_card.dart';

import '../helpers/test_app.dart';
import '../helpers/widget_helpers.dart';

const _family = '👨‍👩‍👧';
const _longName = 'WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW'; // 40 ký tự
final _longNote = ('lorem ipsum ' * 20).substring(0, 140);

void main() {
  for (final scale in [1.0, 2.0]) {
    group('no overflow at 360x800, text scale $scale', () {
      testWidgets('placeholder tabs and the tab bar', (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(
          tester,
          clock: now.clock,
          textScale: scale,
        );

        for (final label in ['Focus', 'Timer', 'Money']) {
          await tapTab(tester, label);
          expect(tester.takeException(), isNull, reason: label);
        }
        // Thanh tab giới hạn cỡ chữ ở 1.3 nên vẫn đủ chỗ cho "Check-in".
        expect(tester.getSize(find.byType(SteadyTabBar)).height, 72);
        await tapTab(tester, 'Check-in');
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      });

      testWidgets('Streaks with long names, a huge count and many habits', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(
          tester,
          clock: now.clock,
          textScale: scale,
        );
        await tapTab(tester, 'Streaks');
        expect(tester.takeException(), isNull, reason: 'empty state');

        await seedHabit(
          tester,
          services,
          name: _longName,
          since: LocalDate(1990, 1, 1),
        );
        await seedHabit(
          tester,
          services,
          name: _family * 40,
          since: LocalDate(2026, 1, 1),
        );
        await seedHabit(
          tester,
          services,
          name: 'No sugar',
          since: LocalDate(2026, 9, 1),
        );
        await seedHabit(
          tester,
          services,
          name: 'Walk',
          since: LocalDate(2026, 10, 2),
        );
        expect(tester.takeException(), isNull, reason: 'four habits');

        // Cuộn tới cuối để dựng mọi thẻ và nút "Add habit".
        await tester.scrollUntilVisible(
          find.text('Add habit'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        expect(find.text('Add habit'), findsOne);
        expect(tester.takeException(), isNull, reason: 'scrolled to the end');

        await disposeSteadyApp(tester, services);
      });

      testWidgets('Streaks card with 365+ days and an extreme count', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(
          tester,
          clock: now.clock,
          textScale: scale,
        );
        await tapTab(tester, 'Streaks');
        await seedHabit(
          tester,
          services,
          name: _longName,
          since: LocalDate(1900, 1, 1),
        );

        expect(find.text('Since Jan 1, 1900'), findsOne);
        expect(
          tester.widget<StreakCard>(find.byType(StreakCard)).days,
          greaterThan(40000),
        );
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      });

      testWidgets('Add habit sheet with a long name and the date picker', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(
          tester,
          clock: now.clock,
          textScale: scale,
        );
        await tapTab(tester, 'Streaks');
        await tester.tap(find.text('Add habit'));
        await settle(tester);
        expect(tester.takeException(), isNull, reason: 'sheet open');

        await tester.enterText(find.byType(TextField), _longName);
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'long name');

        // Ở cỡ chữ lớn, nút Save có thể phải cuộn mới thấy: sheet cuộn được.
        await tester.ensureVisible(find.text('Save habit'));
        await tester.pump();
        expect(isButtonEnabled(tester, 'Save habit'), isTrue);

        await tester.ensureVisible(find.text('Oct 2'));
        await tester.tap(find.text('Oct 2'));
        await settle(tester);
        expect(tester.takeException(), isNull, reason: 'date picker');

        await disposeSteadyApp(tester, services);
      });

      testWidgets('Actions sheet and delete dialog with a long name', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(
          tester,
          clock: now.clock,
          textScale: scale,
        );
        await tapTab(tester, 'Streaks');
        await seedHabit(tester, services, name: _longName);

        await tester.tap(find.text(_longName));
        await settle(tester);
        expect(tester.takeException(), isNull, reason: 'actions sheet');

        await tester.ensureVisible(find.text('Delete habit'));
        await tester.tap(find.text('Delete habit'));
        await settle(tester);
        expect(find.textContaining('Delete WWW'), findsOne);
        expect(tester.takeException(), isNull, reason: 'confirm dialog');

        await disposeSteadyApp(tester, services);
      });

      testWidgets('Check-in with a long chip, full note and a mood', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(
          tester,
          clock: now.clock,
          textScale: scale,
        );
        await seedHabit(tester, services, name: _longName);
        await tapTab(tester, 'Check-in');
        expect(tester.takeException(), isNull, reason: 'initial');

        await tester.tap(find.text('Awful'));
        await tester.pump();
        await tester.enterText(find.byType(TextField), _longNote);
        await tester.pump();
        expect(find.text('140 / 140'), findsOne);
        expect(tester.takeException(), isNull, reason: 'filled in');

        await tester.tap(find.text('Save check-in'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text(checkInSavedText), findsOne);
        expect(tester.takeException(), isNull, reason: 'with snackbar');

        await disposeSteadyApp(tester, services);
      });

      testWidgets('Check-in with a 300px keyboard', (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(
          tester,
          clock: now.clock,
          textScale: scale,
        );
        await seedHabit(tester, services, name: _longName);
        await tapTab(tester, 'Check-in');
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final save = tester.getRect(
          find.widgetWithText(FilledButton, 'Save check-in'),
        );
        expect(
          save.bottom,
          lessThanOrEqualTo(800 - 300),
          reason: 'keyboard must not hide the Save button',
        );

        await disposeSteadyApp(tester, services);
      });

      testWidgets('Add habit sheet with a 300px keyboard', (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(
          tester,
          clock: now.clock,
          textScale: scale,
        );
        await tapTab(tester, 'Streaks');
        await tester.tap(find.text('Add habit'));
        await settle(tester);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
        await tester.enterText(find.byType(TextField), 'No sugar');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Nút Save phải với tới được: nếu cần thì cuộn trong sheet.
        await tester.ensureVisible(find.text('Save habit'));
        await tester.pumpAndSettle();
        final save = tester.getRect(
          find.widgetWithText(FilledButton, 'Save habit'),
        );
        expect(save.bottom, lessThanOrEqualTo(800 - 300));
        expect(save.top, greaterThanOrEqualTo(0));

        await tester.tap(find.text('Save habit'));
        await settle(tester);
        expect(find.text('No sugar'), findsOne);
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      });
    });
  }

  group('Save is visible without scrolling at scale 1.0', () {
    testWidgets('Add habit sheet with a 300px keyboard', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Streaks');
      await tester.tap(find.text('Add habit'));
      await settle(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.enterText(find.byType(TextField), 'No sugar');
      await tester.pumpAndSettle();

      final save = tester.getRect(
        find.widgetWithText(FilledButton, 'Save habit'),
      );
      expect(save.bottom, lessThanOrEqualTo(500));
      expect(save.top, greaterThanOrEqualTo(0));

      await disposeSteadyApp(tester, services);
    });
  });

  group('touch targets are at least 48dp', () {
    void expectTarget(WidgetTester t, Finder f, String what) {
      final size = t.getSize(f);
      expect(size.width, greaterThanOrEqualTo(48), reason: '$what width');
      expect(size.height, greaterThanOrEqualTo(48), reason: '$what height');
    }

    for (final scale in [1.0, 2.0]) {
      testWidgets('tabs and primary buttons at scale $scale', (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(
          tester,
          clock: now.clock,
          textScale: scale,
        );

        for (final label in [
          'Focus',
          'Timer',
          'Streaks',
          'Money',
          'Check-in',
        ]) {
          expectTarget(
            tester,
            find.ancestor(of: tabLabel(label), matching: find.byType(InkWell)),
            'tab $label',
          );
        }

        await tapTab(tester, 'Streaks');
        expectTarget(
          tester,
          find.widgetWithText(FilledButton, 'Add habit'),
          'Add habit',
        );
        await tester.tap(find.text('Add habit'));
        await settle(tester);
        await tester.ensureVisible(find.text('Save habit'));
        expectTarget(
          tester,
          find.widgetWithText(FilledButton, 'Save habit'),
          'Save habit',
        );
        expectTarget(
          tester,
          find.ancestor(of: find.text('Oct 2'), matching: find.byType(InkWell)),
          'date field',
        );
        expectTarget(tester, find.byType(TextField), 'name field');

        await disposeSteadyApp(tester, services);
      });

      testWidgets('actions sheet and dialog buttons at scale $scale', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(
          tester,
          clock: now.clock,
          textScale: scale,
        );
        await tapTab(tester, 'Streaks');
        await seedHabit(tester, services);
        expectTarget(tester, find.byType(StreakCard), 'streak card');
        await tester.tap(find.text('No smoking'));
        await settle(tester);

        expectTarget(
          tester,
          find.widgetWithText(FilledButton, 'Reset streak'),
          'Reset streak',
        );
        await tester.ensureVisible(find.text('Delete habit'));
        expectTarget(
          tester,
          find.widgetWithText(FilledButton, 'Delete habit'),
          'Delete habit',
        );

        await tester.tap(find.text('Delete habit'));
        await settle(tester);
        expectTarget(
          tester,
          find.widgetWithText(FilledButton, 'Cancel'),
          'Cancel',
        );
        expectTarget(
          tester,
          find.widgetWithText(FilledButton, 'Delete'),
          'Delete',
        );

        await disposeSteadyApp(tester, services);
      });

      testWidgets('Check-in mood cells and Save at scale $scale', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(
          tester,
          clock: now.clock,
          textScale: scale,
        );
        await tapTab(tester, 'Check-in');

        final cells = find.descendant(
          of: find.byType(MoodPicker),
          matching: find.byType(InkWell),
        );
        expect(cells, findsNWidgets(5));
        for (var i = 0; i < 5; i++) {
          expectTarget(tester, cells.at(i), 'mood cell $i');
        }
        // Năm ô bằng nhau và nằm ngang hàng.
        final widths = [
          for (var i = 0; i < 5; i++) tester.getSize(cells.at(i)).width,
        ];
        for (final w in widths) {
          expect(w, closeTo(widths.first, 0.5));
        }
        expectTarget(
          tester,
          find.widgetWithText(FilledButton, 'Save check-in'),
          'Save check-in',
        );
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      });
    }
  });
}
