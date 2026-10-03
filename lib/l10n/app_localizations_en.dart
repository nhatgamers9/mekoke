// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabFocus => 'Focus';

  @override
  String get tabTimer => 'Timer';

  @override
  String get tabStreaks => 'Streaks';

  @override
  String get tabMoney => 'Money';

  @override
  String get tabCheckIn => 'Check-in';

  @override
  String get placeholderBody => 'This part of Steady isn\'t ready yet.';

  @override
  String get addHabit => 'Add habit';

  @override
  String get streaksEmpty => 'Add a habit you want to leave behind.';

  @override
  String streakDayUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String streakSince(String date) {
    return 'Since $date';
  }

  @override
  String milestoneNext(int target, int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      target,
      locale: localeName,
      other: '$target days',
      one: '1 day',
    );
    return 'Next: $_temp0 · $remaining to go';
  }

  @override
  String get habitNameLabel => 'Habit';

  @override
  String get habitNameHint => 'No sugar';

  @override
  String get cleanSinceLabel => 'Clean since';

  @override
  String get saveHabit => 'Save habit';

  @override
  String get resetStreak => 'Reset streak';

  @override
  String get resetDone => 'That\'s okay. Your count starts again today.';

  @override
  String get deleteHabit => 'Delete habit';

  @override
  String deleteHabitTitle(String habit) {
    return 'Delete $habit?';
  }

  @override
  String get deleteHabitBody =>
      'This removes the habit and its count. It can\'t be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get howWasToday => 'How was today?';

  @override
  String get moodAwful => 'Awful';

  @override
  String get moodLow => 'Low';

  @override
  String get moodOkay => 'Okay';

  @override
  String get moodGood => 'Good';

  @override
  String get moodGreat => 'Great';

  @override
  String get noteLabel => 'One line about today';

  @override
  String noteCounter(int count, int max) {
    return '$count / $max';
  }

  @override
  String get saveCheckIn => 'Save check-in';

  @override
  String get checkInSaved => 'Check-in saved.';

  @override
  String get saveError => 'Couldn\'t save. Try again.';

  @override
  String streakChip(int count, String habit) {
    return 'Day $count · $habit';
  }

  @override
  String get timerTypeLabel => 'Timer type';

  @override
  String get timerModeFasting => 'Fasting';

  @override
  String get timerModeInterval => 'Interval';

  @override
  String get fastingPlanLabel => 'Fasting plan';

  @override
  String get fastPlan16 => '16:8';

  @override
  String get fastPlan18 => '18:6';

  @override
  String get fastPlan20 => '20:4';

  @override
  String get fastPlanOmad => 'OMAD';

  @override
  String get phaseFasting => 'FASTING';

  @override
  String get phaseEating => 'EATING';

  @override
  String get phaseWork => 'WORK';

  @override
  String get phaseRest => 'REST';

  @override
  String get phasePrepare => 'PREPARE';

  @override
  String get phaseDone => 'DONE';

  @override
  String fastStartedToday(String time) {
    return 'Started today, $time';
  }

  @override
  String fastStartedYesterday(String time) {
    return 'Started yesterday, $time';
  }

  @override
  String fastStartedOn(String date, String time) {
    return 'Started $date, $time';
  }

  @override
  String fastEndsAt(String time) {
    return 'Ends $time';
  }

  @override
  String fastGoalReachedAt(String time) {
    return 'Goal reached at $time';
  }

  @override
  String eatingWindowEndsAt(String time) {
    return 'Eating window ends $time';
  }

  @override
  String fastGoalHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return 'Goal: $_temp0';
  }

  @override
  String get statLeftInFast => 'Left in this fast';

  @override
  String get statPastGoal => 'Past your goal';

  @override
  String get statLastFast => 'Last fast';

  @override
  String get statFastingStreak => 'Fasting streak';

  @override
  String durationHm(int hours, String minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get statEmpty => '—';

  @override
  String get startFasting => 'Start fasting';

  @override
  String get endFast => 'End fast';

  @override
  String get endFastEarlyTitle => 'End fast now?';

  @override
  String endFastEarlyBody(String left) {
    return 'You\'re $left from your goal.';
  }

  @override
  String get keepFasting => 'Keep fasting';

  @override
  String get fastingDisclaimer =>
      'Fasting isn\'t right for everyone. Check with your doctor first.';

  @override
  String get savedWorkoutsLabel => 'Saved workouts';

  @override
  String get presetTabata => 'Tabata';

  @override
  String get presetHiit => 'HIIT 30/30';

  @override
  String get presetCustom => 'Custom';

  @override
  String intervalSummary(int intervals, int rounds) {
    String _temp0 = intl.Intl.pluralLogic(
      intervals,
      locale: localeName,
      other: '$intervals intervals',
      one: '1 interval',
    );
    String _temp1 = intl.Intl.pluralLogic(
      rounds,
      locale: localeName,
      other: '$rounds rounds',
      one: '1 round',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get stepPrepare => 'Prepare';

  @override
  String get stepWork => 'Work';

  @override
  String get stepRest => 'Rest';

  @override
  String get stepRounds => 'Rounds';

  @override
  String get stepRoundsDetail => 'Work + rest';

  @override
  String get stepSets => 'Sets';

  @override
  String get stepSetRest => 'Rest between sets';

  @override
  String decreaseLabel(String label) {
    return 'Decrease $label';
  }

  @override
  String increaseLabel(String label) {
    return 'Increase $label';
  }

  @override
  String get startWorkout => 'Start workout';

  @override
  String intervalRingCaption(String work, String rest) {
    return '$work work · $rest rest';
  }

  @override
  String secondsShort(int seconds) {
    return '$seconds s';
  }

  @override
  String nextPhase(String phase, String time) {
    return 'Next: $phase $time';
  }

  @override
  String roundChip(int round, int rounds) {
    return '$round / $rounds';
  }

  @override
  String roundOf(int round, int rounds) {
    return 'Round $round of $rounds';
  }

  @override
  String setRoundOf(int set, int sets, int round, int rounds) {
    return 'Set $set of $sets · Round $round of $rounds';
  }

  @override
  String timeLeft(String time) {
    return '$time left';
  }

  @override
  String get workoutProgressLabel => 'Workout progress';

  @override
  String get endWorkout => 'End workout';

  @override
  String get restartRound => 'Restart round';

  @override
  String get pause => 'Pause';

  @override
  String get skipRound => 'Skip round';

  @override
  String get resume => 'Resume';

  @override
  String get endWorkoutTitle => 'End workout?';

  @override
  String get endWorkoutBody => 'This workout stops here.';

  @override
  String get keepGoing => 'Keep going';

  @override
  String get close => 'Close';

  @override
  String get moneyOffline => 'Offline · no bank link';

  @override
  String get spentThisMonth => 'Spent this month';

  @override
  String spentLastMonth(String amount) {
    return 'Last month: $amount';
  }

  @override
  String get addExpense => 'Add expense';

  @override
  String get editExpense => 'Edit expense';

  @override
  String get byCategoryHeader => 'BY CATEGORY';

  @override
  String get recentHeader => 'RECENT';

  @override
  String get seeAll => 'See all';

  @override
  String get moneyEmpty => 'Your expenses will show up here.';

  @override
  String get moneyLoadError => 'Couldn\'t load your expenses.';

  @override
  String get expensesTitle => 'Expenses';

  @override
  String get dayToday => 'TODAY';

  @override
  String get dayYesterday => 'YESTERDAY';

  @override
  String get categoryLabel => 'Category';

  @override
  String get chooseCategory => 'Choose a category';

  @override
  String get categoryMore => 'More';

  @override
  String get catGroceries => 'Groceries';

  @override
  String get catEatingOut => 'Eating out';

  @override
  String get catTransport => 'Transport';

  @override
  String get catBills => 'Bills';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catHealth => 'Health';

  @override
  String get catGifts => 'Gifts';

  @override
  String get catHousing => 'Housing';

  @override
  String get catTravel => 'Travel';

  @override
  String get catPhone => 'Phone';

  @override
  String get catEducation => 'Education';

  @override
  String get catOther => 'Other';

  @override
  String get dateToday => 'Today';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String get noteButton => 'Note';

  @override
  String get noteHint => 'What was it for?';

  @override
  String get done => 'Done';

  @override
  String get keypadLabel => 'Amount keypad';

  @override
  String get keypadBackspace => 'Delete last digit';

  @override
  String get saveExpense => 'Save expense';

  @override
  String entryDetailLine(String category, String time) {
    return '$category · $time';
  }

  @override
  String amountExpense(String amount) {
    return '−$amount';
  }

  @override
  String get deleteExpense => 'Delete expense';

  @override
  String get deleteExpenseTitle => 'Delete this expense?';

  @override
  String get deleteExpenseBody =>
      'This removes it from your history. It can\'t be undone.';

  @override
  String get seePremium => 'See Premium';

  @override
  String get paywallOverline => 'STEADY PREMIUM';

  @override
  String get paywallTitle => 'Every sound, every plan, no ads';

  @override
  String get paywallBenefitSounds => 'Every sound, offline';

  @override
  String get paywallBenefitStreaks => 'Unlimited habit streaks';

  @override
  String get paywallBenefitPlans => 'Custom fasting and interval plans';

  @override
  String get paywallBenefitHistory => 'Full history and widget themes';

  @override
  String get choosePlanLabel => 'Choose a plan';

  @override
  String get planMonthly => 'Monthly';

  @override
  String get planWeekly => 'Weekly';

  @override
  String get planPerMonth => 'per month';

  @override
  String get planPerWeek => 'per week';

  @override
  String get planTrialNote => '3-day free trial';

  @override
  String get paywallCta => 'Try 3 days free';

  @override
  String get paywallUnavailable => 'Purchases aren\'t available yet.';

  @override
  String paywallTermsMonthly(String price) {
    return 'Free for 3 days, then $price per month. Cancel anytime in Google Play.';
  }

  @override
  String paywallTermsWeekly(String price) {
    return 'Free for 3 days, then $price per week. Cancel anytime in Google Play.';
  }
}
