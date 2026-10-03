import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/format/money_format.dart';
import 'package:steady/core/services.dart';
import 'package:steady/core/theme/app_theme.dart';
import 'package:steady/core/theme/tokens.dart';
import 'package:steady/features/premium/paywall_screen.dart';
import 'package:steady/features/premium/premium_plans.dart';
import 'package:steady/l10n/app_localizations.dart';
import 'package:steady/ui/components/plan_option.dart';
import 'package:steady/ui/components/steady_button.dart';
import 'package:steady/ui/components/steady_icon.dart';
import 'package:steady/ui/components/steady_inline_status.dart';
import 'package:steady/ui/components/steady_tab_bar.dart';

import '../helpers/money_helpers.dart';
import '../helpers/test_app.dart';
import '../helpers/timer_helpers.dart';
import '../helpers/widget_helpers.dart';

const _placeholder = "This part of Steady isn't ready yet.";
const _unavailable = "Purchases aren't available yet.";
const _cta = 'Try 3 days free';
const _trial = '3-day free trial';
const _termsMonthly =
    r'Free for 3 days, then $9.99 per month. Cancel anytime in Google Play.';
const _termsWeekly =
    r'Free for 3 days, then $4.99 per week. Cancel anytime in Google Play.';

Finder get _paywall => find.byType(PaywallScreen);
Finder get _terms => find.textContaining('Free for 3 days');
Finder get _unavailableLine => find.text(_unavailable);
Finder get _ctaButton => find.widgetWithText(SteadyButton, _cta);

Finder _card(String title) => find.widgetWithText(PlanOption, title);

Finder _inCard(String title, String text) =>
    find.descendant(of: _card(title), matching: find.text(text));

List<PlanOption> _options(WidgetTester t) =>
    t.widgetList<PlanOption>(find.byType(PlanOption)).toList();

/// Tên các gói đang được chọn: luôn phải có đúng một.
List<String> _selectedTitles(WidgetTester t) => [
  for (final o in _options(t))
    if (o.selected) o.title,
];

int _primaryButtons(WidgetTester t) => t
    .widgetList<SteadyButton>(
      find.descendant(of: _paywall, matching: find.byType(SteadyButton)),
    )
    .where((b) => b.variant == SteadyButtonVariant.primary)
    .length;

Future<void> _back(WidgetTester t) async {
  await t.binding.handlePopRoute();
  await t.pumpAndSettle();
}

/// Bấm "See Premium" trên tab Focus rồi chờ route mở xong.
Future<void> _openPaywall(WidgetTester t) async {
  await t.tap(find.text('See Premium'));
  await settle(t);
}

/// Paywall đứng một mình, không có tab Focus bên dưới: để đo riêng bố cục của
/// paywall ở màn thấp và cỡ chữ lớn (với phông Ahem, tab Focus ở 360x560 và
/// cỡ chữ 2.0 tự nó đã tràn; phần đó có test phông thật ở
/// `paywall_fit_test.dart`).
Widget _barePaywall({double textScale = 1.0}) => MaterialApp(
  theme: buildSteadyTheme(SteadyColors.dark, Brightness.dark),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: app!,
  ),
  home: const PaywallScreen(),
);

/// Bấm X (cuộn lên tới nó trước: nút X nằm đầu thân cuộn) rồi chờ route đóng.
Future<void> _close(WidgetTester t) async {
  await tapScrolled(t, semLabel('Close'));
  await settle(t);
}

Future<AppServices> _appWithPaywall(
  WidgetTester t,
  FakeNow now, {
  Size size = const Size(360, 800),
  double textScale = 1.0,
}) async {
  final services = await pumpSteadyApp(
    t,
    clock: now.clock,
    size: size,
    textScale: textScale,
  );
  await _openPaywall(t);
  return services;
}

Future<void> _pressCta(WidgetTester t) => tapScrolled(t, _ctaButton);

/// Chạm tên gói (đầu thẻ) để chọn: thẻ có thể cao hơn màn hình ở cỡ chữ 2.0
/// nên không chạm giữa thẻ.
Future<void> _choose(WidgetTester t, String title) =>
    tapScrolled(t, _inCard(title, title));

Future<List<String>> _dbDump(WidgetTester t, AppServices s) async {
  Future<List<String>> rows(Future<List<Object>> Function() read) async {
    final result = await t.runAsync(read);
    return [for (final r in result!) r.toString()];
  }

  return [
    ...await rows(() => s.db.select(s.db.habits).get()),
    ...await rows(() => s.db.select(s.db.checkIns).get()),
    ...await rows(() => s.db.select(s.db.fasts).get()),
    ...await rows(() => s.db.select(s.db.prefs).get()),
    ...await rows(() => s.db.select(s.db.moneyEntries).get()),
  ];
}

void _expectOnScreen(WidgetTester t, Finder f, double viewHeight, String what) {
  final r = t.getRect(f);
  expect(r.top, greaterThanOrEqualTo(0), reason: '$what: top');
  expect(r.bottom, lessThanOrEqualTo(viewHeight), reason: '$what: bottom');
}

void main() {
  group('Entry: the See Premium button on the Focus tab', () {
    testWidgets('Focus keeps its placeholder and gets a secondary button', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);

      expect(currentTab(tester), 0);
      expect(find.text(_placeholder), findsOne);
      expect(find.text('Focus'), findsNWidgets(2)); // tab + tiêu đề
      expect(find.text('See Premium'), findsOne);
      expect(
        buttonLabeled(tester, 'See Premium').variant,
        SteadyButtonVariant.secondary,
      );
      expect(buttonLabeled(tester, 'See Premium').block, isFalse);
      expect(_paywall, findsNothing);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the button sits right under the text, above y=500', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);

      final body = tester.getRect(find.text(_placeholder));
      final button = tester.getRect(find.byType(SteadyButton));
      expect(button.top, greaterThanOrEqualTo(body.bottom));
      expect(button.bottom, lessThan(500));
      expect(button.left, closeTo(body.left, 0.5), reason: 'left-aligned');
      expect(button.width, lessThan(360 - 40), reason: 'not a block button');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the empty middle of Focus is still the dark background', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);

      expect(
        await pixelAt(tester, const Offset(180, 500)),
        SteadyColors.dark.bg.toARGB32(),
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('tapping it opens the paywall over the whole screen', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);

      await _openPaywall(tester);

      expect(_paywall, findsOne);
      expect(find.byType(SteadyTabBar), findsNothing, reason: 'covered');
      expect(
        tester
            .widget<SteadyTabBar>(
              find.byType(SteadyTabBar, skipOffstage: false),
            )
            .current,
        0,
        reason: 'the shell underneath is still on Focus',
      );
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('on Focus without the paywall, Back still leaves the app', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      final pops = captureSystemPop(tester);

      await _back(tester);

      expect(pops, hasLength(1));
      expect(_paywall, findsNothing);

      await disposeSteadyApp(tester, services);
    });
  });

  group('The paywall opens only when the user taps the button', () {
    testWidgets('not at launch and not on any other tab', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      expect(_paywall, findsNothing);

      for (final label in ['Timer', 'Streaks', 'Money', 'Check-in', 'Focus']) {
        await tapTab(tester, label);
        await letDbFinish(tester);
        expect(
          find.byType(PaywallScreen, skipOffstage: false),
          findsNothing,
          reason: label,
        );
      }

      await disposeSteadyApp(tester, services);
    });

    testWidgets('not while a fast is running', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await seedFast(
        tester,
        services,
        startedAt: evening().subtract(const Duration(hours: 4)),
      );

      await openTimer(tester);
      await advanceTo(tester, now, evening().add(const Duration(minutes: 5)));

      expect(find.byType(PaywallScreen, skipOffstage: false), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('not while an interval workout is running', (tester) async {
      final now = FakeNow(evening());
      final services = await pumpSteadyApp(tester, clock: now.clock);
      await openInterval(tester);
      await tester.tap(find.text('Start workout'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SteadyTabBar), findsNothing, reason: 'run screen');

      await advanceTo(tester, now, evening().add(const Duration(seconds: 30)));

      expect(find.byType(PaywallScreen, skipOffstage: false), findsNothing);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Paywall content', () {
    testWidgets('title, overline and the four benefits, word for word', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);

      expect(find.text('STEADY PREMIUM'), findsOne);
      expect(find.text('Every sound, every plan, no ads'), findsOne);
      final benefits = [
        'Every sound, offline',
        'Unlimited habit streaks',
        'Custom fasting and interval plans',
        'Full history and widget themes',
      ];
      var previousTop = -1.0;
      for (final text in benefits) {
        expect(find.text(text), findsOne, reason: text);
        final top = tester.getTopLeft(find.text(text)).dy;
        expect(top, greaterThan(previousTop), reason: 'order of $text');
        previousTop = top;
      }
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('each benefit has a tide-colored tick', (tester) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);

      final ticks = tester
          .widgetList<SteadyIcon>(
            find.descendant(
              of: find.ancestor(
                of: find.text('Every sound, offline'),
                matching: find.byType(Row),
              ),
              matching: find.byType(SteadyIcon),
            ),
          )
          .toList();
      expect(ticks, isNotEmpty);
      expect(ticks.first.name, SteadyIcons.check);
      expect(ticks.first.color, SteadyColors.dark.tide);
      expect(ticks.first.size, 20);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('two plans: Monthly above Weekly, with price and period', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);

      expect(_options(tester).map((o) => o.title), ['Monthly', 'Weekly']);
      expect(_options(tester).map((o) => o.price), [r'$9.99', r'$4.99']);
      expect(_options(tester).map((o) => o.period), ['per month', 'per week']);
      expect(_options(tester).map((o) => o.note), [_trial, _trial]);
      expect(find.text(r'$9.99'), findsOne);
      expect(find.text(r'$4.99'), findsOne);
      expect(find.text('per month'), findsOne);
      expect(find.text('per week'), findsOne);
      expect(find.text(_trial), findsNWidgets(2));
      expect(
        tester.getTopLeft(_card('Monthly')).dy,
        lessThan(tester.getTopLeft(_card('Weekly')).dy),
      );
      expect(find.text('Weekly'), findsOne);
      expect(find.text('Monthly'), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('no plan carries a badge or any extra label', (tester) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);

      for (final text in ['Best value', 'Save', 'Popular', 'BEST VALUE']) {
        expect(find.textContaining(text), findsNothing, reason: text);
      }
      expect(_options(tester), hasLength(kPremiumPlans.length));

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Monthly is preselected, with the tick and the amber border', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);

      expect(_selectedTitles(tester), ['Monthly']);
      expect(
        find.descendant(
          of: _card('Monthly'),
          matching: find.byType(SteadyIcon),
        ),
        findsOne,
        reason: 'ticked',
      );
      expect(
        find.descendant(of: _card('Weekly'), matching: find.byType(SteadyIcon)),
        findsNothing,
        reason: 'not ticked',
      );
      Color border(String title) =>
          (tester
                      .widget<Material>(
                        find
                            .descendant(
                              of: _card(title),
                              matching: find.byType(Material),
                            )
                            .first,
                      )
                      .shape!
                  as RoundedRectangleBorder)
              .side
              .color;
      expect(border('Monthly'), SteadyColors.dark.amber);
      expect(border('Weekly'), SteadyColors.dark.lineStrong);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the terms line is the Monthly one, price included', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);

      expect(_terms, findsOne);
      expect(find.text(_termsMonthly), findsOne);
      expect(find.text(_termsWeekly), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the main button says "Try 3 days free" and no unavailable '
        'line is shown yet', (tester) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);

      expect(find.text(_cta), findsOne);
      expect(_unavailableLine, findsNothing);
      expect(find.byType(SteadyInlineStatus), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('exactly one primary button on the whole paywall', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);

      expect(_primaryButtons(tester), 1);
      expect(
        tester.widget<SteadyButton>(_ctaButton).variant,
        SteadyButtonVariant.primary,
      );
      expect(tester.widget<SteadyButton>(_ctaButton).block, isTrue);

      // Hiện dòng báo xong vẫn chỉ có một nút `primary` (dòng báo không phải
      // nút).
      await _pressCta(tester);
      expect(_primaryButtons(tester), 1);
      expect(_unavailableLine, findsOne);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Choosing a plan', () {
    testWidgets('tapping Weekly selects it and the terms follow', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);

      await _choose(tester, 'Weekly');

      expect(_selectedTitles(tester), ['Weekly']);
      expect(_terms, findsOne);
      expect(find.text(_termsWeekly), findsOne);
      expect(find.text(_termsMonthly), findsNothing);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('going back to Monthly restores the Monthly terms', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);

      await _choose(tester, 'Weekly');
      await _choose(tester, 'Monthly');

      expect(_selectedTitles(tester), ['Monthly']);
      expect(find.text(_termsMonthly), findsOne);
      expect(_terms, findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('tapping the selected plan again keeps it selected', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);

      await _choose(tester, 'Monthly');
      await _choose(tester, 'Monthly');
      expect(_selectedTitles(tester), ['Monthly']);
      expect(find.text(_termsMonthly), findsOne);

      await _choose(tester, 'Weekly');
      await _choose(tester, 'Weekly');
      await _choose(tester, 'Weekly');
      expect(_selectedTitles(tester), ['Weekly']);
      expect(find.text(_termsWeekly), findsOne);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('one plan is selected after every single tap', (tester) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);

      for (final title in [
        'Weekly',
        'Weekly',
        'Monthly',
        'Weekly',
        'Monthly',
        'Monthly',
      ]) {
        await _choose(tester, title);
        expect(_selectedTitles(tester), [title], reason: 'after $title');
        expect(_terms, findsOne, reason: 'one terms line after $title');
      }

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a tap on the note or the price also selects the plan', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);

      await tapScrolled(tester, _inCard('Weekly', _trial));
      expect(_selectedTitles(tester), ['Weekly']);

      await tapScrolled(tester, _inCard('Monthly', r'$9.99'));
      expect(_selectedTitles(tester), ['Monthly']);

      await tapScrolled(tester, _inCard('Weekly', 'per week'));
      expect(_selectedTitles(tester), ['Weekly']);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the selected card is drawn with the amber border', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);

      await _choose(tester, 'Weekly');

      RoundedRectangleBorder shapeOf(String title) =>
          tester
                  .widget<Material>(
                    find
                        .descendant(
                          of: _card(title),
                          matching: find.byType(Material),
                        )
                        .first,
                  )
                  .shape!
              as RoundedRectangleBorder;
      expect(shapeOf('Weekly').side.color, SteadyColors.dark.amber);
      expect(shapeOf('Monthly').side.color, SteadyColors.dark.lineStrong);

      await disposeSteadyApp(tester, services);
    });
  });

  group('The main button only shows the unavailable line', () {
    testWidgets('one press: one line above the button, screen stays open', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);
      final before = await _dbDump(tester, services);
      final pops = captureSystemPop(tester);

      await _pressCta(tester);

      expect(_unavailableLine, findsOne);
      expect(find.byType(SteadyInlineStatus), findsOne);
      expect(_paywall, findsOne, reason: 'the screen did not close');
      expect(_selectedTitles(tester), ['Monthly'], reason: 'plan unchanged');
      expect(find.text(_termsMonthly), findsOne);
      expect(pops, isEmpty);
      expect(
        tester.getRect(_unavailableLine).bottom,
        lessThanOrEqualTo(tester.getRect(_ctaButton).top),
        reason: 'the line sits above the button',
      );
      expect(
        await _dbDump(tester, services),
        before,
        reason: 'nothing is written to the database or the prefs',
      );
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('pressing five times still shows exactly one line', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);

      for (var i = 0; i < 5; i++) {
        await _pressCta(tester);
        expect(_unavailableLine, findsOne, reason: 'after press ${i + 1}');
        expect(find.byType(SteadyInlineStatus), findsOne);
      }
      expect(_paywall, findsOne);
      expect(
        tester.widget<SteadyButton>(_ctaButton).onPressed,
        isNotNull,
        reason: 'the button stays pressable',
      );

      await disposeSteadyApp(tester, services);
    });

    testWidgets('changing the plan afterwards keeps the line', (tester) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);

      await _pressCta(tester);
      await _choose(tester, 'Weekly');

      expect(_unavailableLine, findsOne);
      expect(find.text(_termsWeekly), findsOne);
      expect(_selectedTitles(tester), ['Weekly']);

      await _choose(tester, 'Monthly');
      expect(_unavailableLine, findsOne);
      expect(find.text(_termsMonthly), findsOne);

      await _pressCta(tester);
      expect(_unavailableLine, findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('pressing on Weekly writes nothing either', (tester) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);
      await _choose(tester, 'Weekly');
      final before = await _dbDump(tester, services);

      await _pressCta(tester);
      await _pressCta(tester);

      expect(await _dbDump(tester, services), before);
      expect(_paywall, findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the unavailable line is announced as a live region', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);
      final handle = tester.ensureSemantics();

      await _pressCta(tester);

      expect(
        tester.getSemantics(_unavailableLine),
        isSemantics(label: _unavailable, isLiveRegion: true),
      );
      handle.dispose();
      await disposeSteadyApp(tester, services);
    });
  });

  group('Leaving the paywall', () {
    testWidgets('the X button closes it and Focus is back', (tester) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);
      final pops = captureSystemPop(tester);

      await _close(tester);

      expect(_paywall, findsNothing);
      expect(find.text('See Premium'), findsOne);
      expect(find.text(_placeholder), findsOne);
      expect(currentTab(tester), 0);
      expect(pops, isEmpty, reason: 'the app must not exit');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('the X button is at least 48 x 48', (tester) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);

      final size = tester.getSize(semLabel('Close'));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Back closes the paywall first, then the next Back exits', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);
      final pops = captureSystemPop(tester);

      await _back(tester);
      expect(_paywall, findsNothing);
      expect(currentTab(tester), 0);
      expect(find.text('See Premium'), findsOne);
      expect(pops, isEmpty, reason: 'first Back only closes the paywall');

      await _back(tester);
      expect(pops, hasLength(1), reason: 'second Back leaves the app');

      await disposeSteadyApp(tester, services);
    });

    testWidgets('Back after pressing the main button still only closes it', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);
      final pops = captureSystemPop(tester);
      await _choose(tester, 'Weekly');
      await _pressCta(tester);

      await _back(tester);

      expect(_paywall, findsNothing);
      expect(pops, isEmpty);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('X after pressing the main button closes it too', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);
      await _pressCta(tester);

      await _close(tester);

      expect(_paywall, findsNothing);
      expect(currentTab(tester), 0);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('opening it again starts fresh: Monthly, no unavailable line', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now);
      await _choose(tester, 'Weekly');
      await _pressCta(tester);
      await _close(tester);

      await _openPaywall(tester);

      expect(_paywall, findsOne);
      expect(_selectedTitles(tester), ['Monthly']);
      expect(_unavailableLine, findsNothing);
      expect(find.text(_termsMonthly), findsOne);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Layout', () {
    for (final scale in [1.0, 2.0]) {
      testWidgets('360x800 at text scale $scale: Focus and paywall fit', (
        tester,
      ) async {
        final now = FakeNow(evening());
        final services = await pumpSteadyApp(
          tester,
          clock: now.clock,
          textScale: scale,
        );
        expect(tester.takeException(), isNull, reason: 'Focus with the button');

        await _openPaywall(tester);
        expect(_paywall, findsOne);
        expect(tester.takeException(), isNull, reason: 'paywall opened');

        // Giá hiện đủ trong thẻ.
        for (final (title, price, period) in [
          ('Monthly', r'$9.99', 'per month'),
          ('Weekly', r'$4.99', 'per week'),
        ]) {
          final card = tester.getRect(_card(title));
          final priceBox = tester.getRect(_inCard(title, price));
          final periodBox = tester.getRect(_inCard(title, period));
          expect(card.contains(priceBox.topLeft), isTrue, reason: price);
          expect(card.contains(priceBox.bottomRight), isTrue, reason: price);
          expect(card.contains(periodBox.bottomRight), isTrue, reason: period);
          expect(card.height, greaterThanOrEqualTo(SteadySize.tap));
          expect(card.width, 360 - 40, reason: 'full width inside s5 padding');
        }

        // Cuộn tới nút chính và dòng điều khoản.
        await tester.ensureVisible(_ctaButton);
        await tester.pump();
        _expectOnScreen(tester, _ctaButton, 800, 'main button');
        await tester.ensureVisible(_terms);
        await tester.pump();
        _expectOnScreen(tester, _terms, 800, 'terms');
        expect(tester.takeException(), isNull, reason: 'scrolled to the end');

        // Bấm được nút chính sau khi cuộn tới.
        await _pressCta(tester);
        expect(_unavailableLine, findsOne);
        expect(_paywall, findsOne);
        await tester.ensureVisible(_unavailableLine);
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'with the line shown');

        await disposeSteadyApp(tester, services);
      });
    }

    testWidgets('360x800 at scale 2.0: the paywall scrolls', (tester) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now, textScale: 2.0);

      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: _paywall, matching: find.byType(Scrollable)).first,
      );
      expect(scrollable.position.maxScrollExtent, greaterThan(0));
      await tester.ensureVisible(_terms);
      await tester.pump();
      expect(scrollable.position.pixels, greaterThan(0));
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('360x560 at text scale $scale: scrolls, no overflow', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 560);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(_barePaywall(textScale: scale));
        expect(_paywall, findsOne);
        expect(tester.takeException(), isNull, reason: 'opened');

        final scrollable = tester.state<ScrollableState>(
          find
              .descendant(of: _paywall, matching: find.byType(Scrollable))
              .first,
        );
        expect(scrollable.position.maxScrollExtent, greaterThan(0));

        await tester.ensureVisible(_ctaButton);
        await tester.pump();
        _expectOnScreen(tester, _ctaButton, 560, 'main button');
        await tester.ensureVisible(_terms);
        await tester.pump();
        _expectOnScreen(tester, _terms, 560, 'terms');
        expect(tester.takeException(), isNull, reason: 'scrolled');

        await _choose(tester, 'Weekly');
        await _pressCta(tester);
        expect(_unavailableLine, findsOne);
        expect(find.text(_termsWeekly), findsOne);
        expect(tester.takeException(), isNull, reason: 'interacted');
      });
    }

    testWidgets('360x560 at scale 1.0: opens from the See Premium button', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(
        tester,
        now,
        size: const Size(360, 560),
      );

      expect(_paywall, findsOne);
      await _back(tester);
      expect(_paywall, findsNothing);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    testWidgets('a tall screen puts the plans, not a gap, under the benefits '
        'and keeps the main button at the bottom', (tester) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(
        tester,
        now,
        size: const Size(360, 2400),
      );

      expect(tester.takeException(), isNull);
      final cta = tester.getRect(_ctaButton);
      final terms = tester.getRect(_terms);
      expect(terms.bottom, lessThanOrEqualTo(2400));
      expect(cta.bottom, lessThanOrEqualTo(terms.top));
      expect(
        tester.getRect(_card('Weekly')).bottom,
        lessThanOrEqualTo(cta.top),
      );
      // Màn cao thì khoảng trống nằm trên các thẻ (Spacer), thẻ dồn xuống dưới.
      expect(
        tester.getRect(find.text('Full history and widget themes')).bottom,
        lessThan(tester.getTopLeft(_card('Monthly')).dy),
      );

      await disposeSteadyApp(tester, services);
    });
  });

  group('Prices go through MoneyFormat for every phone locale', () {
    Future<AppServices> openWith(
      WidgetTester t,
      Locale locale, {
      double textScale = 1.0,
    }) async {
      setDeviceLocale(t, locale);
      final now = FakeNow(evening());
      return _appWithPaywall(t, now, textScale: textScale);
    }

    testWidgets(r'an en_US phone shows $9.99 and $4.99', (tester) async {
      final services = await openWith(tester, const Locale('en', 'US'));

      expect(_options(tester).map((o) => o.price), [r'$9.99', r'$4.99']);
      expect(find.text(_termsMonthly), findsOne);
      await _choose(tester, 'Weekly');
      expect(find.text(_termsWeekly), findsOne);

      await disposeSteadyApp(tester, services);
    });

    testWidgets(r'a de_DE phone still shows $9.99 and $4.99', (tester) async {
      final services = await openWith(tester, const Locale('de', 'DE'));

      expect(_options(tester).map((o) => o.price), [r'$9.99', r'$4.99']);
      expect(find.text(r'$9.99'), findsOne);
      expect(find.text(r'$4.99'), findsOne);
      expect(find.text(_termsMonthly), findsOne);
      await _choose(tester, 'Weekly');
      expect(find.text(_termsWeekly), findsOne);
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });

    for (final region in ['GB', 'AU', 'CA', 'IN', 'ZA']) {
      testWidgets('an en_$region phone gets what MoneyFormat gives for it', (
        tester,
      ) async {
        final services = await openWith(tester, Locale('en', region));

        final money = MoneyFormat('en_$region', kPlanCurrency);
        final monthly = money.format(kPremiumPlans[0].priceMinor);
        final weekly = money.format(kPremiumPlans[1].priceMinor);
        expect(_options(tester).map((o) => o.price), [monthly, weekly]);
        // Một số vùng (ví dụ en_ZA) dùng dấu phẩy thập phân: MoneyFormat quyết
        // định, màn chỉ hiện đúng kết quả của nó.
        expect(monthly, matches(RegExp(r'9[.,]99')));
        expect(weekly, matches(RegExp(r'4[.,]99')));
        expect(
          find.text(
            'Free for 3 days, then $monthly per month. '
            'Cancel anytime in Google Play.',
          ),
          findsOne,
        );
        await _choose(tester, 'Weekly');
        expect(
          find.text(
            'Free for 3 days, then $weekly per week. '
            'Cancel anytime in Google Play.',
          ),
          findsOne,
        );
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      });
    }

    final others = <Locale>[
      const Locale('ja', 'JP'),
      const Locale('vi', 'VN'),
      const Locale('ar', 'EG'),
      const Locale('fr', 'FR'),
      const Locale('es', 'MX'),
      const Locale('pt', 'BR'),
      const Locale('hi', 'IN'),
      const Locale('ru', 'RU'),
      const Locale('tr', 'TR'),
      const Locale('he', 'IL'),
      const Locale('th', 'TH'),
      Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'TW',
      ),
      const Locale('en'),
      const Locale('xx', 'YY'),
    ];
    for (final locale in others) {
      testWidgets('a $locale phone does not crash and shows both prices', (
        tester,
      ) async {
        final services = await openWith(tester, locale);

        expect(tester.takeException(), isNull);
        expect(_paywall, findsOne);
        expect(_options(tester), hasLength(2));
        for (final o in _options(tester)) {
          expect(o.price, anyOf(r'$9.99', r'$4.99'));
        }
        expect(_terms, findsOne);
        await _choose(tester, 'Weekly');
        expect(_terms, findsOne);
        expect(tester.takeException(), isNull);

        await disposeSteadyApp(tester, services);
      });
    }

    testWidgets('a de_DE phone at text scale 2.0 does not overflow', (
      tester,
    ) async {
      final services = await openWith(
        tester,
        const Locale('de', 'DE'),
        textScale: 2.0,
      );

      expect(tester.takeException(), isNull);
      await tester.ensureVisible(_terms);
      await tester.pump();
      expect(tester.takeException(), isNull);

      await disposeSteadyApp(tester, services);
    });
  });

  group('Screen reader', () {
    // Màn cao để mọi nút nằm trong khung nhìn (nút ngoài khung bị đánh dấu ẩn).
    const tall = Size(360, 2400);

    testWidgets('each plan card is a button in a one-of-many group', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now, size: tall);
      final handle = tester.ensureSemantics();

      expect(
        tester.getSemantics(_card('Monthly')),
        isSemantics(
          label: 'Monthly, \$9.99, per month, 3-day free trial',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(_card('Weekly')),
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
      await disposeSteadyApp(tester, services);
    });

    testWidgets('the selected state in the semantics follows the choice', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now, size: tall);
      final handle = tester.ensureSemantics();

      await _choose(tester, 'Weekly');

      expect(
        tester.getSemantics(_card('Weekly')),
        isSemantics(
          label: 'Weekly, \$4.99, per week, 3-day free trial',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(_card('Monthly')),
        isSemantics(
          label: 'Monthly, \$9.99, per month, 3-day free trial',
          isButton: true,
          hasSelectedState: true,
          isSelected: false,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );

      handle.dispose();
      await disposeSteadyApp(tester, services);
    });

    testWidgets('a screen reader can select a plan with the tap action', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now, size: tall);
      final handle = tester.ensureSemantics();

      tester.semantics.tap(find.semantics.byLabel(RegExp('^Weekly')));
      await tester.pump();

      expect(_selectedTitles(tester), ['Weekly']);
      expect(find.text(_termsWeekly), findsOne);

      handle.dispose();
      await disposeSteadyApp(tester, services);
    });

    testWidgets('the cards sit in a group labelled "Choose a plan"', (
      tester,
    ) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now, size: tall);
      final handle = tester.ensureSemantics();

      final group = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Choose a plan',
      );
      expect(group, findsOne);
      expect(tester.getSemantics(group), isSemantics(label: 'Choose a plan'));
      expect(
        find.descendant(of: group, matching: find.byType(PlanOption)),
        findsNWidgets(2),
      );

      handle.dispose();
      await disposeSteadyApp(tester, services);
    });

    testWidgets('the X button is labelled "Close"', (tester) async {
      final now = FakeNow(evening());
      final services = await _appWithPaywall(tester, now, size: tall);
      final handle = tester.ensureSemantics();

      expect(
        tester.getSemantics(semLabel('Close')),
        isSemantics(
          label: 'Close',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );

      handle.dispose();
      await disposeSteadyApp(tester, services);
    });
  });
}
