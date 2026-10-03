import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:steady/core/theme/app_theme.dart';
import 'package:steady/core/theme/tokens.dart';
import 'package:steady/l10n/app_localizations_en.dart';
import 'package:steady/ui/components/steady_icon.dart';

void main() {
  group('icons and fonts on disk', () {
    test('every SteadyIcons constant has an svg file', () {
      const declared = [
        SteadyIcons.audioWaveform,
        SteadyIcons.timer,
        SteadyIcons.sprout,
        SteadyIcons.wallet,
        SteadyIcons.notebookPen,
        SteadyIcons.plus,
      ];
      expect(declared, [
        'audio-waveform',
        'timer',
        'sprout',
        'wallet',
        'notebook-pen',
        'plus',
      ]);
      for (final name in declared) {
        expect(
          File('assets/icons/$name.svg').existsSync(),
          isTrue,
          reason: 'missing assets/icons/$name.svg',
        );
      }
    });

    test(
      'every constant in steady_icon.dart has a file (catches new ones)',
      () {
        final source = File('lib/ui/components/steady_icon.dart')
            .readAsStringSync();
        final names = RegExp(r"static const \w+ = '([a-z0-9-]+)';")
            .allMatches(source)
            .map((m) => m.group(1)!)
            .toList();
        expect(names, isNotEmpty);
        for (final name in names) {
          expect(
            File('assets/icons/$name.svg').existsSync(),
            isTrue,
            reason: 'missing assets/icons/$name.svg',
          );
        }
      },
    );

    test('all 67 icons and the ISC license are present', () {
      final svgs = Directory('assets/icons')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.svg'));
      expect(svgs, hasLength(67));
      expect(File('assets/icons/LICENSE').existsSync(), isTrue);
    });

    test('fonts and their licenses are bundled and declared in pubspec', () {
      for (final f in [
        'assets/fonts/Newsreader-Variable.ttf',
        'assets/fonts/Figtree-Variable.ttf',
        'assets/fonts/OFL-Newsreader.txt',
        'assets/fonts/OFL-Figtree.txt',
      ]) {
        final file = File(f);
        expect(file.existsSync(), isTrue, reason: 'missing $f');
        expect(file.lengthSync(), greaterThan(1000), reason: '$f is empty');
      }
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('assets/fonts/Newsreader-Variable.ttf'));
      expect(pubspec, contains('assets/fonts/Figtree-Variable.ttf'));
      expect(pubspec, contains('assets/icons/'));
    });

    test('icon files are real svg documents', () {
      for (final name in ['audio-waveform', 'timer', 'sprout', 'wallet']) {
        expect(
          File('assets/icons/$name.svg').readAsStringSync(),
          contains('<svg'),
        );
      }
    });
  });

  group('English copy matches the plan table (section 7)', () {
    final en = AppLocalizationsEn();

    setUpAll(() async {
      await initializeDateFormatting();
    });

    test('tabs and placeholder', () {
      expect(en.tabFocus, 'Focus');
      expect(en.tabTimer, 'Timer');
      expect(en.tabStreaks, 'Streaks');
      expect(en.tabMoney, 'Money');
      expect(en.tabCheckIn, 'Check-in');
      expect(en.placeholderBody, "This part of Steady isn't ready yet.");
    });

    test('streaks copy', () {
      expect(en.addHabit, 'Add habit');
      expect(en.streaksEmpty, 'Add a habit you want to leave behind.');
      expect(en.streakSince('May 28'), 'Since May 28');
      expect(en.habitNameLabel, 'Habit');
      expect(en.habitNameHint, 'No sugar');
      expect(en.cleanSinceLabel, 'Clean since');
      expect(en.saveHabit, 'Save habit');
      expect(en.resetStreak, 'Reset streak');
      expect(en.resetDone, "That's okay. Your count starts again today.");
      expect(en.deleteHabit, 'Delete habit');
      expect(en.deleteHabitTitle('No sugar'), 'Delete No sugar?');
      expect(
        en.deleteHabitBody,
        "This removes the habit and its count. It can't be undone.",
      );
      expect(en.cancel, 'Cancel');
      expect(en.delete, 'Delete');
    });

    test('day unit is singular only for exactly 1', () {
      expect(en.streakDayUnit(1), 'day');
      expect(en.streakDayUnit(0), 'days');
      expect(en.streakDayUnit(2), 'days');
      expect(en.streakDayUnit(127), 'days');
    });

    test('milestone label pluralizes the target', () {
      expect(en.milestoneNext(180, 53), 'Next: 180 days · 53 to go');
      expect(en.milestoneNext(1, 1), 'Next: 1 day · 1 to go');
      expect(en.milestoneNext(3, 2), 'Next: 3 days · 2 to go');
    });

    test('check-in copy', () {
      expect(en.greetingMorning, 'Good morning');
      expect(en.greetingAfternoon, 'Good afternoon');
      expect(en.greetingEvening, 'Good evening');
      expect(en.howWasToday, 'How was today?');
      expect(
        [en.moodAwful, en.moodLow, en.moodOkay, en.moodGood, en.moodGreat],
        ['Awful', 'Low', 'Okay', 'Good', 'Great'],
      );
      expect(en.noteLabel, 'One line about today');
      expect(en.noteCounter(140, 140), '140 / 140');
      expect(en.noteCounter(0, 140), '0 / 140');
      expect(en.saveCheckIn, 'Save check-in');
      expect(en.checkInSaved, 'Check-in saved.');
      expect(en.saveError, "Couldn't save. Try again.");
      expect(en.streakChip(127, 'No smoking'), 'Day 127 · No smoking');
    });

    test('timer copy: fasting', () {
      expect(
        [en.timerTypeLabel, en.timerModeFasting, en.timerModeInterval],
        ['Timer type', 'Fasting', 'Interval'],
      );
      expect(en.fastingPlanLabel, 'Fasting plan');
      expect(
        [en.fastPlan16, en.fastPlan18, en.fastPlan20, en.fastPlanOmad],
        ['16:8', '18:6', '20:4', 'OMAD'],
      );
      expect(
        [
          en.phaseFasting,
          en.phaseEating,
          en.phaseWork,
          en.phaseRest,
          en.phasePrepare,
          en.phaseDone,
        ],
        ['FASTING', 'EATING', 'WORK', 'REST', 'PREPARE', 'DONE'],
      );
      expect(en.fastStartedToday('9:00 PM'), 'Started today, 9:00 PM');
      expect(en.fastStartedYesterday('9:00 PM'), 'Started yesterday, 9:00 PM');
      expect(en.fastStartedOn('Oct 1', '9:00 PM'), 'Started Oct 1, 9:00 PM');
      expect(en.fastEndsAt('1:00 PM'), 'Ends 1:00 PM');
      expect(en.fastGoalReachedAt('1:00 PM'), 'Goal reached at 1:00 PM');
      expect(en.eatingWindowEndsAt('3:00 PM'), 'Eating window ends 3:00 PM');
      expect(en.fastGoalHours(1), 'Goal: 1 hour');
      expect(en.fastGoalHours(16), 'Goal: 16 hours');
      expect(
        [
          en.statLeftInFast,
          en.statPastGoal,
          en.statLastFast,
          en.statFastingStreak,
        ],
        ['Left in this fast', 'Past your goal', 'Last fast', 'Fasting streak'],
      );
      expect(en.durationHm(6, '01'), '6h 01m');
      expect(en.daysCount(1), '1 day');
      expect(en.daysCount(0), '0 days');
      expect(en.daysCount(12), '12 days');
      expect(en.statEmpty, '—');
      expect([en.startFasting, en.endFast], ['Start fasting', 'End fast']);
      expect(en.endFastEarlyTitle, 'End fast now?');
      expect(en.endFastEarlyBody('6h 00m'), "You're 6h 00m from your goal.");
      expect(en.keepFasting, 'Keep fasting');
      expect(
        en.fastingDisclaimer,
        "Fasting isn't right for everyone. Check with your doctor first.",
      );
    });

    test('timer copy: interval', () {
      expect(en.savedWorkoutsLabel, 'Saved workouts');
      expect(
        [en.presetTabata, en.presetHiit, en.presetCustom],
        ['Tabata', 'HIIT 30/30', 'Custom'],
      );
      expect(en.intervalSummary(16, 8), '16 intervals · 8 rounds');
      expect(en.intervalSummary(1, 1), '1 interval · 1 round');
      expect(
        [
          en.stepPrepare,
          en.stepWork,
          en.stepRest,
          en.stepRounds,
          en.stepRoundsDetail,
          en.stepSets,
          en.stepSetRest,
        ],
        [
          'Prepare',
          'Work',
          'Rest',
          'Rounds',
          'Work + rest',
          'Sets',
          'Rest between sets',
        ],
      );
      expect(en.decreaseLabel('Rounds'), 'Decrease Rounds');
      expect(en.increaseLabel('Rounds'), 'Increase Rounds');
      expect(en.startWorkout, 'Start workout');
      expect(en.intervalRingCaption('20 s', '10 s'), '20 s work · 10 s rest');
      expect(en.secondsShort(20), '20 s');
      expect(en.nextPhase('Work', '0:20'), 'Next: Work 0:20');
      expect(en.roundChip(3, 8), '3 / 8');
      expect(en.roundOf(3, 8), 'Round 3 of 8');
      expect(en.setRoundOf(1, 2, 3, 8), 'Set 1 of 2 · Round 3 of 8');
      expect(en.timeLeft('2:54'), '2:54 left');
      expect(en.workoutProgressLabel, 'Workout progress');
      expect(
        [en.endWorkout, en.restartRound, en.pause, en.skipRound, en.resume],
        ['End workout', 'Restart round', 'Pause', 'Skip round', 'Resume'],
      );
      expect(en.endWorkoutTitle, 'End workout?');
      expect(en.endWorkoutBody, 'This workout stops here.');
      expect(en.keepGoing, 'Keep going');
      expect(en.close, 'Close');
    });
  });

  group('timer icons', () {
    test('the 11 icons added for the Timer tab exist under their names', () {
      const names = {
        SteadyIcons.x: 'x',
        SteadyIcons.play: 'play',
        SteadyIcons.pause: 'pause',
        SteadyIcons.rotateCcw: 'rotate-ccw',
        SteadyIcons.skipForward: 'skip-forward',
        SteadyIcons.hourglass: 'hourglass',
        SteadyIcons.dumbbell: 'dumbbell',
        SteadyIcons.repeat: 'repeat',
        SteadyIcons.layers: 'layers',
        SteadyIcons.armchair: 'armchair',
        SteadyIcons.minus: 'minus',
      };
      for (final entry in names.entries) {
        expect(entry.key, entry.value);
        expect(
          File('assets/icons/${entry.value}.svg').existsSync(),
          isTrue,
          reason: 'missing assets/icons/${entry.value}.svg',
        );
      }
    });
  });

  group('money copy (section 8 of the plan)', () {
    final en = AppLocalizationsEn();

    test('the tab, the header and the big number', () {
      expect(en.tabMoney, 'Money');
      expect(en.moneyOffline, 'Offline · no bank link');
      expect(en.spentThisMonth, 'Spent this month');
      expect(en.spentLastMonth(r'$50.00'), r'Last month: $50.00');
    });

    test('the add and edit screens', () {
      expect(en.addExpense, 'Add expense');
      expect(en.editExpense, 'Edit expense');
      expect(en.saveExpense, 'Save expense');
      expect(en.categoryLabel, 'Category');
      expect(en.chooseCategory, 'Choose a category');
      expect(en.categoryMore, 'More');
      expect(en.noteButton, 'Note');
      expect(en.noteHint, 'What was it for?');
      expect(en.done, 'Done');
      expect(en.keypadLabel, 'Amount keypad');
      expect(en.keypadBackspace, 'Delete last digit');
      expect(en.close, 'Close');
    });

    test('the lists', () {
      expect(en.byCategoryHeader, 'BY CATEGORY');
      expect(en.recentHeader, 'RECENT');
      expect(en.seeAll, 'See all');
      expect(en.moneyEmpty, 'Your expenses will show up here.');
      expect(en.moneyLoadError, "Couldn't load your expenses.");
      expect(en.expensesTitle, 'Expenses');
      expect([en.dayToday, en.dayYesterday], ['TODAY', 'YESTERDAY']);
      expect([en.dateToday, en.dateYesterday], ['Today', 'Yesterday']);
      expect(en.entryDetailLine('Groceries', '9:00 PM'), 'Groceries · 9:00 PM');
    });

    test('the 12 categories', () {
      expect(
        [
          en.catGroceries,
          en.catEatingOut,
          en.catTransport,
          en.catBills,
          en.catShopping,
          en.catHealth,
          en.catGifts,
          en.catHousing,
          en.catTravel,
          en.catPhone,
          en.catEducation,
          en.catOther,
        ],
        [
          'Groceries',
          'Eating out',
          'Transport',
          'Bills',
          'Shopping',
          'Health',
          'Gifts',
          'Housing',
          'Travel',
          'Phone',
          'Education',
          'Other',
        ],
      );
    });

    test('an expense amount starts with a real minus sign (U+2212)', () {
      expect(en.amountExpense(r'$12.40'), '\u2212\$12.40');
      expect(en.amountExpense(r'$12.40').codeUnitAt(0), 0x2212);
      expect(en.amountExpense(r'$12.40'), isNot(startsWith('-')));
    });

    test('deleting an expense', () {
      expect(en.deleteExpense, 'Delete expense');
      expect(en.deleteExpenseTitle, 'Delete this expense?');
      expect(
        en.deleteExpenseBody,
        "This removes it from your history. It can't be undone.",
      );
      expect(en.delete, 'Delete');
      expect(en.cancel, 'Cancel');
      expect(en.saveError, "Couldn't save. Try again.");
    });

    // Money chỉ ghi khoản chi: các phần thu nhập, tích trữ, hạn mức, chuyển tiền
    // đã bị bỏ khỏi thiết kế nên không được lọt vào câu chữ.
    test('there is no income, saving, budget or transfer wording', () {
      final arb = jsonDecode(
        File('lib/l10n/app_en.arb').readAsStringSync(),
      ) as Map<String, dynamic>;
      const moneyKeys = [
        'moneyOffline',
        'spentThisMonth',
        'spentLastMonth',
        'addExpense',
        'editExpense',
        'byCategoryHeader',
        'recentHeader',
        'seeAll',
        'moneyEmpty',
        'moneyLoadError',
        'expensesTitle',
        'dayToday',
        'dayYesterday',
        'categoryLabel',
        'chooseCategory',
        'categoryMore',
        'catGroceries',
        'catEatingOut',
        'catTransport',
        'catBills',
        'catShopping',
        'catHealth',
        'catGifts',
        'catHousing',
        'catTravel',
        'catPhone',
        'catEducation',
        'catOther',
        'dateToday',
        'dateYesterday',
        'noteButton',
        'noteHint',
        'done',
        'keypadLabel',
        'keypadBackspace',
        'saveExpense',
        'entryDetailLine',
        'amountExpense',
        'deleteExpense',
        'deleteExpenseTitle',
        'deleteExpenseBody',
      ];
      for (final key in moneyKeys) {
        expect(arb[key], isA<String>(), reason: 'ARB has no text for "$key"');
      }
      for (final key in moneyKeys) {
        final text = (arb[key] as String).toLowerCase();
        for (final banned in [
          'income',
          'salary',
          'savings',
          'envelope',
          'budget',
          'left to spend',
          'transfer',
          'take-home',
        ]) {
          expect(
            text,
            isNot(contains(banned)),
            reason: '$key mentions $banned',
          );
        }
      }
    });
  });

  group('money icons', () {
    test('the 15 icons added for the Money tab exist under their names', () {
      const names = {
        SteadyIcons.lock: 'lock',
        SteadyIcons.calendar: 'calendar',
        SteadyIcons.delete: 'delete',
        SteadyIcons.receipt: 'receipt',
        SteadyIcons.shoppingCart: 'shopping-cart',
        SteadyIcons.coffee: 'coffee',
        SteadyIcons.car: 'car',
        SteadyIcons.zap: 'zap',
        SteadyIcons.shirt: 'shirt',
        SteadyIcons.heartPulse: 'heart-pulse',
        SteadyIcons.gift: 'gift',
        SteadyIcons.house: 'house',
        SteadyIcons.plane: 'plane',
        SteadyIcons.smartphone: 'smartphone',
        SteadyIcons.graduationCap: 'graduation-cap',
      };
      expect(names, hasLength(15));
      for (final entry in names.entries) {
        expect(entry.key, entry.value);
        final file = File('assets/icons/${entry.value}.svg');
        expect(file.existsSync(), isTrue, reason: 'missing ${file.path}');
        expect(file.readAsStringSync(), contains('<svg'));
      }
    });

    test('the Money tab added no icon file: still exactly 67', () {
      final svgs = Directory('assets/icons')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.svg'));
      expect(svgs, hasLength(67));
    });
  });

  group('theme', () {
    final theme = buildSteadyTheme(SteadyColors.dark, Brightness.dark);
    const c = SteadyColors.dark;

    test('is Material 3, dark, with the Steady colors attached', () {
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, c.bg);
      expect(theme.extension<SteadyColors>(), isNotNull);
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Figtree');
    });

    test('color scheme maps to the tokens (section 5.5)', () {
      final s = theme.colorScheme;
      expect(s.primary, c.amber);
      expect(s.onPrimary, c.onAmber);
      expect(s.secondary, c.tide);
      expect(s.onSecondary, c.onTide);
      expect(s.error, c.rose);
      expect(s.onError, c.onRose);
      expect(s.surface, c.surface);
      expect(s.onSurface, c.ink);
      expect(s.onSurfaceVariant, c.inkMuted);
      expect(s.outline, c.lineStrong);
      expect(s.outlineVariant, c.line);
      expect(s.primaryContainer, c.amberSoft);
      expect(s.secondaryContainer, c.tideSoft);
      expect(s.errorContainer, c.roseSoft);
      expect(s.surfaceContainerHigh, c.surface2);
      expect(s.surfaceContainerHighest, c.surface2);
    });

    test('sheets and dialogs are not tinted amber', () {
      expect(theme.colorScheme.surfaceTint, Colors.transparent);
      expect(theme.bottomSheetTheme.backgroundColor, Colors.transparent);
      expect(theme.bottomSheetTheme.elevation, 0);
      expect(theme.dialogTheme.backgroundColor, c.surface);
    });

    test('snack bars float on surface-2', () {
      expect(theme.snackBarTheme.backgroundColor, c.surface2);
      expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
    });

    test('text selection uses amber', () {
      final t = theme.textSelectionTheme;
      expect(t.cursorColor, c.amber);
      expect(t.selectionHandleColor, c.amber);
      expect(t.selectionColor, c.amber.withValues(alpha: 0.4));
    });
  });

  group('Android launch configuration (no white flash)', () {
    String read(String path) =>
        File('android/app/src/main/$path').readAsStringSync();

    test('launch_bg is the dark background #121110', () {
      expect(
        read('res/values/colors.xml').toLowerCase(),
        contains('<color name="launch_bg">#121110</color>'),
      );
    });

    test('launch drawables use launch_bg and no white', () {
      for (final f in [
        'res/drawable/launch_background.xml',
        'res/drawable-v21/launch_background.xml',
      ]) {
        final xml = read(f);
        expect(xml, contains('@color/launch_bg'), reason: f);
        expect(xml.toLowerCase(), isNot(contains('white')), reason: f);
        expect(xml.toLowerCase(), isNot(contains('#ffffff')), reason: f);
      }
    });

    test('NormalTheme window background is launch_bg in light and night', () {
      for (final f in [
        'res/values/styles.xml',
        'res/values-night/styles.xml',
      ]) {
        final xml = read(f);
        final normal = RegExp(
          r'<style name="NormalTheme".*?</style>',
          dotAll: true,
        ).firstMatch(xml);
        expect(normal, isNotNull, reason: f);
        expect(
          normal!.group(0),
          contains(
            '<item name="android:windowBackground">@color/launch_bg</item>',
          ),
          reason: f,
        );
      }
    });

    test('manifest: name Steady, backup off, no permissions', () {
      final manifest = read('AndroidManifest.xml');
      expect(manifest, contains('android:label="Steady"'));
      expect(manifest, contains('android:allowBackup="false"'));
      expect(manifest, isNot(contains('<uses-permission')));
    });

    test('application id is com.mekoke.steady', () {
      final gradle =
          ['android/app/build.gradle.kts', 'android/app/build.gradle']
              .where((p) => File(p).existsSync())
              .map((p) => File(p).readAsStringSync());
      expect(gradle, isNotEmpty);
      expect(gradle.first, contains('com.mekoke.steady'));
    });
  });

  group('dependency policy (section 4)', () {
    test('no forbidden packages in pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final banned in [
        'riverpod',
        'provider:',
        'get_it',
        'google_fonts',
      ]) {
        expect(pubspec, isNot(contains(banned)), reason: banned);
      }
    });
  });

  group('paywall copy (section 3.6 of the plan)', () {
    final en = AppLocalizationsEn();

    // Khoá ARB (không tham số) và nguyên văn.
    const plain = {
      'seePremium': 'See Premium',
      'paywallOverline': 'STEADY PREMIUM',
      'paywallTitle': 'Every sound, every plan, no ads',
      'paywallBenefitSounds': 'Every sound, offline',
      'paywallBenefitStreaks': 'Unlimited habit streaks',
      'paywallBenefitPlans': 'Custom fasting and interval plans',
      'paywallBenefitHistory': 'Full history and widget themes',
      'choosePlanLabel': 'Choose a plan',
      'planMonthly': 'Monthly',
      'planWeekly': 'Weekly',
      'planPerMonth': 'per month',
      'planPerWeek': 'per week',
      'planTrialNote': '3-day free trial',
      'paywallCta': 'Try 3 days free',
      'paywallUnavailable': "Purchases aren't available yet.",
    };

    test('the entry button, header and the four benefits', () {
      expect(en.seePremium, 'See Premium');
      expect(en.paywallOverline, 'STEADY PREMIUM');
      expect(en.paywallTitle, 'Every sound, every plan, no ads');
      expect(
        [
          en.paywallBenefitSounds,
          en.paywallBenefitStreaks,
          en.paywallBenefitPlans,
          en.paywallBenefitHistory,
        ],
        [
          'Every sound, offline',
          'Unlimited habit streaks',
          'Custom fasting and interval plans',
          'Full history and widget themes',
        ],
      );
    });

    test('the plans, the button and the unavailable line', () {
      expect(en.choosePlanLabel, 'Choose a plan');
      expect([en.planMonthly, en.planWeekly], ['Monthly', 'Weekly']);
      expect([en.planPerMonth, en.planPerWeek], ['per month', 'per week']);
      expect(en.planTrialNote, '3-day free trial');
      expect(en.paywallCta, 'Try 3 days free');
      expect(en.paywallUnavailable, "Purchases aren't available yet.");
      expect(en.close, 'Close', reason: 'the X button reuses the old key');
    });

    test('the terms lines carry the price as given', () {
      expect(
        en.paywallTermsMonthly(r'$9.99'),
        r'Free for 3 days, then $9.99 per month. Cancel anytime in Google Play.',
      );
      expect(
        en.paywallTermsWeekly(r'$4.99'),
        r'Free for 3 days, then $4.99 per week. Cancel anytime in Google Play.',
      );
      expect(en.paywallTermsMonthly('9,99 €'), contains('then 9,99 € per'));
      expect(en.paywallTermsWeekly('US\$4.99'), contains(r'US$4.99'));
    });

    test('the ARB file holds the same 15 plain texts and 2 terms lines', () {
      final arb = jsonDecode(
        File('lib/l10n/app_en.arb').readAsStringSync(),
      ) as Map<String, dynamic>;
      for (final entry in plain.entries) {
        expect(arb[entry.key], entry.value, reason: entry.key);
      }
      expect(
        arb['paywallTermsMonthly'],
        'Free for 3 days, then {price} per month. Cancel anytime in Google Play.',
      );
      expect(
        arb['paywallTermsWeekly'],
        'Free for 3 days, then {price} per week. Cancel anytime in Google Play.',
      );
    });

    test('the terms keys declare one String placeholder named price', () {
      final arb = jsonDecode(
        File('lib/l10n/app_en.arb').readAsStringSync(),
      ) as Map<String, dynamic>;
      for (final key in ['paywallTermsMonthly', 'paywallTermsWeekly']) {
        final meta = arb['@$key'] as Map<String, dynamic>;
        final placeholders = meta['placeholders'] as Map<String, dynamic>;
        expect(placeholders.keys, ['price'], reason: key);
        expect(
          (placeholders['price'] as Map<String, dynamic>)['type'],
          'String',
          reason: key,
        );
      }
    });

    test('SteadyIcons.check is "check" and has its svg file', () {
      expect(SteadyIcons.check, 'check');
      final file = File('assets/icons/check.svg');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('<svg'));
    });
  });
}
