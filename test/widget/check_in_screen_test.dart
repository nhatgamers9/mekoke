import 'package:flutter/material.dart';
import 'package:steady/core/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/app.dart';
import 'package:steady/core/time/local_date.dart';
import 'package:steady/data/database.dart';
import 'package:steady/features/check_in/check_in_rules.dart';
import 'package:steady/ui/components/mood_picker.dart';
import 'package:steady/ui/components/steady_chip.dart';

import '../helpers/test_app.dart';
import '../helpers/widget_helpers.dart';

const _family = '👨‍👩‍👧';

Finder get _noteField => find.byType(TextField);

String _noteText(WidgetTester t) =>
    t.widget<TextField>(_noteField).controller!.text;

Mood? _selectedMood(WidgetTester t) =>
    t.widget<MoodPicker>(find.byType(MoodPicker)).value;

Future<CheckIn?> _stored(WidgetTester t, AppServices s, LocalDate d) async {
  return t.runAsync<CheckIn?>(() => s.checkIns.getForDate(d));
}

Future<int> _rowCount(WidgetTester t, AppServices s) async {
  final rows = await t.runAsync(() => s.db.select(s.db.checkIns).get());
  return rows!.length;
}

/// Cho tác vụ đọc DB của `_fill` chạy xong rồi dựng lại khung hình.
Future<void> _letFillFinish(WidgetTester t) async {
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await t.pump();
  await t.pump();
}

/// Dòng trạng thái nằm trên nút Save: cạnh dưới của chữ không thấp hơn cạnh
/// trên của nút, và chữ nằm trọn trong màn hình.
void _expectStatusAboveSave(WidgetTester t, String text) {
  final status = t.getRect(find.text(text));
  final save = t.getRect(find.widgetWithText(FilledButton, 'Save check-in'));
  expect(
    status.bottom,
    lessThanOrEqualTo(save.top),
    reason: '"$text" must sit above the Save button, not over it',
  );
  final screen = Offset.zero & t.view.physicalSize;
  expect(status.left, greaterThanOrEqualTo(screen.left));
  expect(status.right, lessThanOrEqualTo(screen.right));
  expect(status.top, greaterThanOrEqualTo(screen.top));
}

void main() {
  group('Check-in screen basics', () {
    testWidgets('shows the date, greeting, prompts and a disabled Save', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');

      expect(find.text('Friday, October 2'), findsOne);
      expect(find.text('Good evening'), findsOne);
      expect(find.text('How was today?'), findsOne);
      for (final mood in ['Awful', 'Low', 'Okay', 'Good', 'Great']) {
        expect(find.text(mood), findsOne);
      }
      expect(find.text('One line about today'), findsOne);
      expect(find.text('0 / 140'), findsOne);
      expect(find.text('Save check-in'), findsOne);
      expect(isButtonEnabled(tester, 'Save check-in'), isFalse);
      expect(_selectedMood(tester), isNull);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    for (final c in [
      (DateTime(2026, 10, 2, 4, 59), 'Good evening'),
      (DateTime(2026, 10, 2, 5, 0), 'Good morning'),
      (DateTime(2026, 10, 2, 11, 59), 'Good morning'),
      (DateTime(2026, 10, 2, 12, 0), 'Good afternoon'),
      (DateTime(2026, 10, 2, 17, 59), 'Good afternoon'),
      (DateTime(2026, 10, 2, 18, 0), 'Good evening'),
    ]) {
      testWidgets('greeting at ${c.$1.hour}:${c.$1.minute} is "${c.$2}"', (
        tester,
      ) async {
        final now = FakeNow(c.$1);
        final services = await pumpSteadyApp(tester, clock: now.clock);
        await tapTab(tester, 'Check-in');
        expect(find.text(c.$2), findsOne);
        await disposeSteadyApp(tester, services);
      });
    }

    testWidgets('choosing a mood enables Save', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');

      await tester.tap(find.text('Good'));
      await tester.pump();

      expect(_selectedMood(tester), Mood.good);
      expect(isButtonEnabled(tester, 'Save check-in'), isTrue);

      await tester.tap(find.text('Awful'));
      await tester.pump();
      expect(_selectedMood(tester), Mood.awful, reason: 'one choice at a time');

      await disposeSteadyApp(tester, services);
    });
  });

  group('Note field', () {
    testWidgets('typing 150 characters keeps 140 and the counter says so', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');

      await tester.enterText(_noteField, 'x' * 150);
      await tester.pump();

      expect(_noteText(tester), 'x' * 140);
      expect(find.text('140 / 140'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the counter follows what is typed', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');

      await tester.enterText(_noteField, 'hello');
      await tester.pump();
      expect(find.text('5 / 140'), findsOne);
      await tester.enterText(_noteField, '');
      await tester.pump();
      expect(find.text('0 / 140'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('grapheme clusters count once in the limit and the counter', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');

      await tester.enterText(_noteField, _family * 3);
      await tester.pump();
      expect(find.text('3 / 140'), findsOne);

      await tester.enterText(_noteField, _family * 150);
      await tester.pump();
      expect(_noteText(tester).characters.length, 140);
      expect(find.text('140 / 140'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Vietnamese text with combining marks counts per letter', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');

      const viet = 'ế';
      await tester.enterText(_noteField, viet * 10);
      await tester.pump();
      expect(find.text('10 / 140'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('pasted line breaks become single spaces', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');

      await tester.enterText(_noteField, 'a\nb');
      await tester.pump();
      expect(_noteText(tester), 'a b');
      await tester.enterText(_noteField, 'a\r\n\r\nb');
      await tester.pump();
      expect(_noteText(tester), 'a b');
      expect(_noteText(tester).contains(RegExp(r'[\r\n]')), isFalse);
      expect(find.text('3 / 140'), findsOne);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Saving', () {
    testWidgets('Save stores the mood, normalizes the note and confirms', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await tester.tap(find.text('Good'));
      await tester.pump();
      await tester.enterText(_noteField, '  Long walk  ');
      await tester.pump();

      await tester.tap(find.text('Save check-in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(checkInSavedText), findsOne);
      final row = await _stored(tester, services, today);
      expect(row, isNotNull);
      expect(row!.mood, 4);
      expect(row.note, 'Long walk');
      expect(row.updatedAt, now.value);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('an empty note is stored as no note', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await tester.tap(find.text('Great'));
      await tester.pump();
      await tester.tap(find.text('Save check-in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final row = await _stored(tester, services, today);
      expect(row!.mood, 5);
      expect(row.note, isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a note with line breaks is saved on one line', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await tester.tap(find.text('Okay'));
      await tester.pump();
      await tester.enterText(_noteField, 'one\ntwo');
      await tester.pump();
      await tester.tap(find.text('Save check-in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect((await _stored(tester, services, today))!.note, 'one two');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a 140-character note saves', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await tester.tap(find.text('Okay'));
      await tester.pump();
      await tester.enterText(_noteField, 'y' * 140);
      await tester.pump();
      await tester.tap(find.text('Save check-in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(checkInSavedText), findsOne);
      expect((await _stored(tester, services, today))!.note, 'y' * 140);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('saving twice in one day keeps a single row with new values', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await tester.tap(find.text('Low'));
      await tester.pump();
      await tester.enterText(_noteField, 'first');
      await tester.pump();
      await tester.tap(find.text('Save check-in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await waitSnackBarGone(tester);

      await tester.tap(find.text('Great'));
      await tester.pump();
      await tester.enterText(_noteField, 'second');
      await tester.pump();
      await tester.tap(find.text('Save check-in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(await _rowCount(tester, services), 1);
      final row = (await _stored(tester, services, today))!;
      expect(row.mood, 5);
      expect(row.note, 'second');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('tapping Save twice without waiting still makes one row', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await tester.tap(find.text('Good'));
      await tester.pump();

      await tester.tap(find.text('Save check-in'));
      await tester.tap(find.text('Save check-in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(await _rowCount(tester, services), 1);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('after saving the keyboard focus is released', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await tester.tap(find.text('Good'));
      await tester.pump();
      await tester.tap(_noteField);
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );

      await tester.tap(find.text('Save check-in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('tapping the background dismisses the keyboard', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await tester.tap(_noteField);
      await tester.pump();

      await tester.tapAt(const Offset(300, 60)); // vùng trống cạnh ngày
      await tester.pump();

      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );

      await disposeSteadyApp(tester, services);
    });

    // Case phải thất bại: ghi DB lỗi.
    testWidgets('a failed save shows the error and keeps the draft', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await breakWrites(tester, services, 'check_ins');
      await tester.tap(find.text('Great'));
      await tester.pump();
      await tester.enterText(_noteField, 'worth keeping');
      await tester.pump();

      await tester.tap(find.text('Save check-in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text(saveErrorText), findsOne);
      expect(find.text(checkInSavedText), findsNothing);
      expect(_selectedMood(tester), Mood.great);
      expect(_noteText(tester), 'worth keeping');
      expect(
        isButtonEnabled(tester, 'Save check-in'),
        isTrue,
        reason: 'saving flag is cleared so the user can retry',
      );
      expect(await _rowCount(tester, services), 0);
      // Lỗi nằm ngay trên nút Save (không đè lên nút) và không có SnackBar.
      expect(find.byType(SnackBar), findsNothing);
      _expectStatusAboveSave(tester, saveErrorText);
      expect(tester.takeException(), isNull);

      await repairWrites(tester, services, 'check_ins');
      await tester.tap(find.text('Save check-in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(saveErrorText), findsNothing, reason: 'old error gone');
      expect(find.text(checkInSavedText), findsOne);
      expect(find.byType(SnackBar), findsNothing);
      expect((await _stored(tester, services, today))!.note, 'worth keeping');

      await disposeSteadyApp(tester, services);
    });

    testWidgets(
      'the Save button can be tapped again right after the error status',
      (tester) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(tester, clock: now.clock);
        await tapTab(tester, 'Check-in');
        await breakWrites(tester, services, 'check_ins');
        await tester.tap(find.text('Great'));
        await tester.pump();
        await tester.tap(find.text('Save check-in'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text(saveErrorText), findsOne);

        // Điểm giữa của nút Save phải còn chạm được (không bị gì đè lên).
        final centre = tester.getCenter(
          find.widgetWithText(FilledButton, 'Save check-in'),
        );
        final hits = tester
            .hitTestOnBinding(centre)
            .path
            .map((e) => e.target)
            .toList();
        final buttonBox = tester.renderObject(
          find.widgetWithText(FilledButton, 'Save check-in'),
        );
        expect(
          hits,
          contains(buttonBox),
          reason: 'nothing may cover the Save button after an error',
        );

        await disposeSteadyApp(tester, services);
      },
    );

    testWidgets('a failed overwrite leaves the earlier entry untouched', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await tester.tap(find.text('Low'));
      await tester.pump();
      await tester.tap(find.text('Save check-in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await waitSnackBarGone(tester);
      await breakWrites(tester, services, 'check_ins');
      await tester.tap(find.text('Great'));
      await tester.pump();
      await tester.tap(find.text('Save check-in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(saveErrorText), findsOne);
      expect((await _stored(tester, services, today))!.mood, 2);
      expect(_selectedMood(tester), Mood.great, reason: 'draft is kept');

      await disposeSteadyApp(tester, services);
    });
  });

  group('Status line above Save (section 11, items 1 and 2)', () {
    Future<void> saveGood(WidgetTester t) async {
      await t.tap(find.text('Good'));
      await t.pump();
      await t.tap(find.text('Save check-in'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
    }

    testWidgets('before saving there is no status at all', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await tester.tap(find.text('Good'));
      await tester.pump();

      expect(find.text(checkInSavedText), findsNothing);
      expect(find.text(saveErrorText), findsNothing);
      expect(find.byType(SnackBar), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a saved check-in says so above Save, with no snackbar', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await saveGood(tester);

      expect(find.text(checkInSavedText), findsOne);
      expect(find.byType(SnackBar), findsNothing);
      _expectStatusAboveSave(tester, checkInSavedText);
      // Nút Save vẫn chạm được ngay lập tức, không phải chờ 4 giây.
      final button = find.widgetWithText(FilledButton, 'Save check-in');
      final hits = tester
          .hitTestOnBinding(tester.getCenter(button))
          .path
          .map((e) => e.target);
      expect(hits, contains(tester.renderObject(button)));
      expect(isButtonEnabled(tester, 'Save check-in'), isTrue);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('saving again replaces the line instead of stacking', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await saveGood(tester);
      await tester.tap(find.text('Save check-in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(checkInSavedText), findsOne);
      expect(await _rowCount(tester, services), 1);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('changing the mood clears "Check-in saved."', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await saveGood(tester);
      expect(find.text(checkInSavedText), findsOne);

      await tester.tap(find.text('Great'));
      await tester.pump();

      expect(find.text(checkInSavedText), findsNothing);
      expect(_selectedMood(tester), Mood.great);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('typing in the note clears "Check-in saved."', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await saveGood(tester);
      expect(find.text(checkInSavedText), findsOne);

      await tester.enterText(_noteField, 'one more thing');
      await tester.pump();

      expect(find.text(checkInSavedText), findsNothing);
      expect(_noteText(tester), 'one more thing');
      expect(find.text('14 / 140'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('typing with no status keeps working and shows no status', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await tester.tap(find.text('Good'));
      await tester.pump();

      for (final text in ['a', 'ab', 'abc']) {
        await tester.enterText(_noteField, text);
        await tester.pump();
        expect(find.text('${text.length} / 140'), findsOne);
      }
      expect(find.text(checkInSavedText), findsNothing);
      expect(find.text(saveErrorText), findsNothing);
      expect(isButtonEnabled(tester, 'Save check-in'), isTrue);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the next day never shows "Check-in saved."', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await saveGood(tester);
      expect(find.text(checkInSavedText), findsOne);

      now.value = DateTime(2026, 10, 3, 8);
      services.today.refresh();
      await tester.pump();
      await _letFillFinish(tester);

      expect(find.text('Saturday, October 3'), findsOne);
      expect(find.text(checkInSavedText), findsNothing);
      expect(_selectedMood(tester), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('an error is cleared by the next edit', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await breakWrites(tester, services, 'check_ins');
      await tester.tap(find.text('Good'));
      await tester.pump();
      await tester.tap(find.text('Save check-in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(saveErrorText), findsOne);

      await tester.tap(find.text('Great'));
      await tester.pump();
      expect(find.text(saveErrorText), findsNothing);

      await tester.tap(find.text('Save check-in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(saveErrorText), findsOne);
      await tester.enterText(_noteField, 'x');
      await tester.pump();
      expect(find.text(saveErrorText), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a restored saved entry opens without a status line', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await dbAction(
        tester,
        () => services.checkIns.saveForDate(
          date: today,
          mood: Mood.low,
          note: 'earlier today',
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(SteadyApp(services: services));
      await tester.pump();
      await _letFillFinish(tester);
      await tapTab(tester, 'Check-in');

      expect(_selectedMood(tester), Mood.low);
      expect(find.text(checkInSavedText), findsNothing);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Restoring a saved entry', () {
    testWidgets('after restarting the screen mood and note are filled in', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await tester.tap(find.text('Good'));
      await tester.pump();
      await tester.enterText(_noteField, 'Slept well');
      await tester.pump();
      await tester.tap(find.text('Save check-in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dựng lại cả app trên cùng DB, như lúc mở app lần sau.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(SteadyApp(services: services));
      await tester.pump();
      await _letFillFinish(tester);
      await tapTab(tester, 'Check-in');

      expect(_selectedMood(tester), Mood.good);
      expect(_noteText(tester), 'Slept well');
      expect(find.text('10 / 140'), findsOne);
      expect(find.text('Good'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('an entry that exists before the app opens is shown', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await dbAction(
        tester,
        () => services.checkIns.saveForDate(
          date: today,
          mood: Mood.low,
          note: 'earlier today',
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(SteadyApp(services: services));
      await tester.pump();
      await _letFillFinish(tester);
      await tapTab(tester, 'Check-in');

      expect(_selectedMood(tester), Mood.low);
      expect(_noteText(tester), 'earlier today');

      await disposeSteadyApp(tester, services);
    });
  });

  group('Streak chip', () {
    testWidgets('no habit means no chip', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      expect(find.byType(SteadyChip), findsNothing);
      await disposeSteadyApp(tester, services);
    });

    testWidgets('shows "Day 127 · No smoking" for the main habit', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedHabit(tester, services);
      await tapTab(tester, 'Check-in');

      expect(find.text('Day 127 · No smoking'), findsOne);
      expect(find.byType(SteadyChip), findsOne);
      expect(
        tester.widget<SteadyChip>(find.byType(SteadyChip)).tone,
        SteadyChipTone.tide,
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('uses the habit with the most days when there are several', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedHabit(
        tester,
        services,
        name: 'Short',
        since: LocalDate(2026, 9, 1),
      );
      await seedHabit(
        tester,
        services,
        name: 'Long',
        since: LocalDate(2026, 1, 1),
      );
      await tapTab(tester, 'Check-in');

      expect(find.text('Day 274 · Long'), findsOne);
      expect(find.byType(SteadyChip), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('follows reset and delete done on the Streaks tab', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedHabit(tester, services);
      await tapTab(tester, 'Streaks');
      await tester.tap(find.text('No smoking'));
      await settle(tester);
      await tester.tap(find.text('Reset streak'));
      await settle(tester);
      await tapTab(tester, 'Check-in');
      expect(find.text('Day 0 · No smoking'), findsOne);

      await tapTab(tester, 'Streaks');
      await tester.tap(find.text('No smoking'));
      await settle(tester);
      await tester.tap(find.text('Delete habit'));
      await settle(tester);
      await tester.tap(find.text('Delete'));
      await settle(tester);
      await tapTab(tester, 'Check-in');
      expect(find.byType(SteadyChip), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a habit added later appears on the Check-in tab', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      expect(find.byType(SteadyChip), findsNothing);
      await seedHabit(
        tester,
        services,
        name: 'No sugar',
        since: LocalDate(2026, 10, 1),
      );
      expect(find.text('Day 1 · No sugar'), findsOne);
      await disposeSteadyApp(tester, services);
    });

    testWidgets('the chip count goes up after midnight', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedHabit(tester, services);
      await tapTab(tester, 'Check-in');
      expect(find.text('Day 127 · No smoking'), findsOne);

      now.value = DateTime(2026, 10, 3, 0, 5);
      services.today.refresh();
      await tester.pump();
      expect(find.text('Day 128 · No smoking'), findsOne);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Drafts and the day changing', () {
    testWidgets('a draft survives switching to another tab and back', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await tester.tap(find.text('Great'));
      await tester.pump();
      await tester.enterText(_noteField, 'draft text');
      await tester.pump();

      await tapTab(tester, 'Streaks');
      await tapTab(tester, 'Timer');
      await tapTab(tester, 'Check-in');

      expect(_selectedMood(tester), Mood.great);
      expect(_noteText(tester), 'draft text');
      expect(find.text('10 / 140'), findsOne);
      expect(await _rowCount(tester, services), 0, reason: 'nothing saved');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the day rolling over does not overwrite a draft', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await tester.tap(find.text('Great'));
      await tester.pump();
      await tester.enterText(_noteField, 'late draft');
      await tester.pump();

      now.value = DateTime(2026, 10, 3, 0, 30);
      services.today.refresh();
      await tester.pump();
      await _letFillFinish(tester);

      expect(find.text('Saturday, October 3'), findsOne);
      expect(_selectedMood(tester), Mood.great);
      expect(_noteText(tester), 'late draft');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a draft saved after midnight is filed under the new day', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await tester.tap(find.text('Great'));
      await tester.pump();
      await tester.enterText(_noteField, 'late draft');
      await tester.pump();

      now.value = DateTime(2026, 10, 3, 0, 30);
      // Không gọi refresh(): bấm Save phải tự lấy "hôm nay" mới.
      await tester.tap(find.text('Save check-in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(await _stored(tester, services, LocalDate(2026, 10, 2)), isNull);
      final row = await _stored(tester, services, LocalDate(2026, 10, 3));
      expect(row!.note, 'late draft');
      expect(find.text('Saturday, October 3'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('without a draft the new day starts blank', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await tester.tap(find.text('Good'));
      await tester.pump();
      await tester.enterText(_noteField, 'yesterday');
      await tester.pump();
      await tester.tap(find.text('Save check-in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      now.value = DateTime(2026, 10, 3, 8);
      services.today.refresh();
      await tester.pump();
      await _letFillFinish(tester);

      expect(find.text('Saturday, October 3'), findsOne);
      expect(_selectedMood(tester), isNull);
      expect(_noteText(tester), '');
      expect(isButtonEnabled(tester, 'Save check-in'), isFalse);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('without a draft a saved entry of the new day is shown', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await dbAction(
        tester,
        () => services.checkIns.saveForDate(
          date: LocalDate(2026, 10, 3),
          mood: Mood.okay,
          note: 'planned ahead',
        ),
      );

      now.value = DateTime(2026, 10, 3, 8);
      services.today.refresh();
      await tester.pump();
      await _letFillFinish(tester);

      expect(_selectedMood(tester), Mood.okay);
      expect(_noteText(tester), 'planned ahead');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('after saving, the next day no longer counts as a draft', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await tester.tap(find.text('Low'));
      await tester.pump();
      await tester.tap(find.text('Save check-in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_selectedMood(tester), Mood.low);

      now.value = DateTime(2026, 10, 3, 8);
      services.today.refresh();
      await tester.pump();
      await _letFillFinish(tester);

      expect(_selectedMood(tester), isNull);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Greeting over time', () {
    testWidgets('returning from the background refreshes the greeting', (
      tester,
    ) async {
      final now = FakeNow(DateTime(2026, 10, 2, 8));
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      expect(find.text('Good morning'), findsOne);

      sendToBackground(tester);
      now.value = DateTime(2026, 10, 2, 13);
      bringToForeground(tester);
      await tester.pump();
      expect(find.text('Good afternoon'), findsOne);
      expect(find.text('Good morning'), findsNothing);

      sendToBackground(tester);
      now.value = DateTime(2026, 10, 2, 19);
      bringToForeground(tester);
      await tester.pump();
      expect(find.text('Good evening'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('open across midnight: date and greeting update', (
      tester,
    ) async {
      final now = FakeNow(DateTime(2026, 10, 2, 23, 59, 30));
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      expect(find.text('Friday, October 2'), findsOne);

      now.value = DateTime(2026, 10, 3, 0, 0, 20);
      await tester.pump(const Duration(seconds: 40));

      expect(find.text('Saturday, October 3'), findsOne);
      expect(find.text('Good evening'), findsOne);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Keyboard', () {
    testWidgets('the Save button stays above a 300px keyboard', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await tapTab(tester, 'Check-in');
      await tester.tap(find.text('Good'));
      await tester.pump();

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.tap(_noteField);
      await tester.pumpAndSettle();

      final save = tester.getRect(
        find.widgetWithText(FilledButton, 'Save check-in'),
      );
      expect(save.bottom, lessThanOrEqualTo(800 - 300));
      expect(save.top, greaterThanOrEqualTo(0));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Save check-in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(checkInSavedText), findsOne);

      await disposeSteadyApp(tester, services);
    });
  });
}
