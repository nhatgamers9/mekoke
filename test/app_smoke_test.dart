import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/ui/components/steady_tab_bar.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('app starts and shows the five tabs', (tester) async {
    var now = DateTime(2026, 10, 2, 21);
    final clock = Clock(() => now);
    final services = await pumpSteadyApp(tester, clock: clock);

    for (final label in ['Focus', 'Timer', 'Streaks', 'Money', 'Check-in']) {
      expect(
        find.descendant(
          of: find.byType(SteadyTabBar),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);

    await disposeSteadyApp(tester, services);
  });
}
