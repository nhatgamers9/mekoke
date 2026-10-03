import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../helpers/test_app.dart';
import '../helpers/widget_helpers.dart';

void main() {
  testWidgets('an en_GB phone gets day-first dates in the UI', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('en', 'GB');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    final now = FakeNow(evening());
    final services = await pumpSteadyApp(tester, clock: now.clock);
    await seedHabit(tester, services);

    await tapTab(tester, 'Streaks');
    expect(find.text('Since 28 May'), findsOne);

    await tapTab(tester, 'Check-in');
    final longDate = DateFormat.MMMMEEEEd('en_GB')
        .format(DateTime(2026, 10, 2));
    expect(find.text(longDate), findsOne);
    expect(longDate, isNot('Friday, October 2'));
    expect(longDate, contains('2 October'));

    await disposeSteadyApp(tester, services);
  });

  testWidgets('a de_DE phone still gets the English format', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('de', 'DE');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    final now = FakeNow(evening());
    final services = await pumpSteadyApp(tester, clock: now.clock);
    await seedHabit(tester, services);

    await tapTab(tester, 'Streaks');
    expect(find.text('Since May 28'), findsOne);
    await tapTab(tester, 'Check-in');
    expect(find.text('Friday, October 2'), findsOne);
    expect(find.text('Good evening'), findsOne);

    await disposeSteadyApp(tester, services);
  });
}
