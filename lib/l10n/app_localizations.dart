import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @tabFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get tabFocus;

  /// No description provided for @tabTimer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get tabTimer;

  /// No description provided for @tabStreaks.
  ///
  /// In en, this message translates to:
  /// **'Streaks'**
  String get tabStreaks;

  /// No description provided for @tabMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get tabMoney;

  /// No description provided for @tabCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get tabCheckIn;

  /// No description provided for @placeholderBody.
  ///
  /// In en, this message translates to:
  /// **'This part of Steady isn\'t ready yet.'**
  String get placeholderBody;

  /// No description provided for @addHabit.
  ///
  /// In en, this message translates to:
  /// **'Add habit'**
  String get addHabit;

  /// No description provided for @streaksEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add a habit you want to leave behind.'**
  String get streaksEmpty;

  /// No description provided for @streakDayUnit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day} other{days}}'**
  String streakDayUnit(int count);

  /// No description provided for @streakSince.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String streakSince(String date);

  /// No description provided for @milestoneNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {target, plural, =1{1 day} other{{target} days}} · {remaining} to go'**
  String milestoneNext(int target, int remaining);

  /// No description provided for @habitNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Habit'**
  String get habitNameLabel;

  /// No description provided for @habitNameHint.
  ///
  /// In en, this message translates to:
  /// **'No sugar'**
  String get habitNameHint;

  /// No description provided for @cleanSinceLabel.
  ///
  /// In en, this message translates to:
  /// **'Clean since'**
  String get cleanSinceLabel;

  /// No description provided for @saveHabit.
  ///
  /// In en, this message translates to:
  /// **'Save habit'**
  String get saveHabit;

  /// No description provided for @resetStreak.
  ///
  /// In en, this message translates to:
  /// **'Reset streak'**
  String get resetStreak;

  /// No description provided for @resetDone.
  ///
  /// In en, this message translates to:
  /// **'That\'s okay. Your count starts again today.'**
  String get resetDone;

  /// No description provided for @deleteHabit.
  ///
  /// In en, this message translates to:
  /// **'Delete habit'**
  String get deleteHabit;

  /// No description provided for @deleteHabitTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {habit}?'**
  String deleteHabitTitle(String habit);

  /// No description provided for @deleteHabitBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the habit and its count. It can\'t be undone.'**
  String get deleteHabitBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @howWasToday.
  ///
  /// In en, this message translates to:
  /// **'How was today?'**
  String get howWasToday;

  /// No description provided for @moodAwful.
  ///
  /// In en, this message translates to:
  /// **'Awful'**
  String get moodAwful;

  /// No description provided for @moodLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get moodLow;

  /// No description provided for @moodOkay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get moodOkay;

  /// No description provided for @moodGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get moodGood;

  /// No description provided for @moodGreat.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get moodGreat;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'One line about today'**
  String get noteLabel;

  /// No description provided for @noteCounter.
  ///
  /// In en, this message translates to:
  /// **'{count} / {max}'**
  String noteCounter(int count, int max);

  /// No description provided for @saveCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Save check-in'**
  String get saveCheckIn;

  /// No description provided for @checkInSaved.
  ///
  /// In en, this message translates to:
  /// **'Check-in saved.'**
  String get checkInSaved;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Try again.'**
  String get saveError;

  /// No description provided for @streakChip.
  ///
  /// In en, this message translates to:
  /// **'Day {count} · {habit}'**
  String streakChip(int count, String habit);

  /// No description provided for @timerTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Timer type'**
  String get timerTypeLabel;

  /// No description provided for @timerModeFasting.
  ///
  /// In en, this message translates to:
  /// **'Fasting'**
  String get timerModeFasting;

  /// No description provided for @timerModeInterval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get timerModeInterval;

  /// No description provided for @fastingPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Fasting plan'**
  String get fastingPlanLabel;

  /// No description provided for @fastPlan16.
  ///
  /// In en, this message translates to:
  /// **'16:8'**
  String get fastPlan16;

  /// No description provided for @fastPlan18.
  ///
  /// In en, this message translates to:
  /// **'18:6'**
  String get fastPlan18;

  /// No description provided for @fastPlan20.
  ///
  /// In en, this message translates to:
  /// **'20:4'**
  String get fastPlan20;

  /// No description provided for @fastPlanOmad.
  ///
  /// In en, this message translates to:
  /// **'OMAD'**
  String get fastPlanOmad;

  /// No description provided for @phaseFasting.
  ///
  /// In en, this message translates to:
  /// **'FASTING'**
  String get phaseFasting;

  /// No description provided for @phaseEating.
  ///
  /// In en, this message translates to:
  /// **'EATING'**
  String get phaseEating;

  /// No description provided for @phaseWork.
  ///
  /// In en, this message translates to:
  /// **'WORK'**
  String get phaseWork;

  /// No description provided for @phaseRest.
  ///
  /// In en, this message translates to:
  /// **'REST'**
  String get phaseRest;

  /// No description provided for @phasePrepare.
  ///
  /// In en, this message translates to:
  /// **'PREPARE'**
  String get phasePrepare;

  /// No description provided for @phaseDone.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get phaseDone;

  /// No description provided for @fastStartedToday.
  ///
  /// In en, this message translates to:
  /// **'Started today, {time}'**
  String fastStartedToday(String time);

  /// No description provided for @fastStartedYesterday.
  ///
  /// In en, this message translates to:
  /// **'Started yesterday, {time}'**
  String fastStartedYesterday(String time);

  /// No description provided for @fastStartedOn.
  ///
  /// In en, this message translates to:
  /// **'Started {date}, {time}'**
  String fastStartedOn(String date, String time);

  /// No description provided for @fastEndsAt.
  ///
  /// In en, this message translates to:
  /// **'Ends {time}'**
  String fastEndsAt(String time);

  /// No description provided for @fastGoalReachedAt.
  ///
  /// In en, this message translates to:
  /// **'Goal reached at {time}'**
  String fastGoalReachedAt(String time);

  /// No description provided for @eatingWindowEndsAt.
  ///
  /// In en, this message translates to:
  /// **'Eating window ends {time}'**
  String eatingWindowEndsAt(String time);

  /// No description provided for @fastGoalHours.
  ///
  /// In en, this message translates to:
  /// **'Goal: {hours, plural, =1{1 hour} other{{hours} hours}}'**
  String fastGoalHours(int hours);

  /// No description provided for @statLeftInFast.
  ///
  /// In en, this message translates to:
  /// **'Left in this fast'**
  String get statLeftInFast;

  /// No description provided for @statPastGoal.
  ///
  /// In en, this message translates to:
  /// **'Past your goal'**
  String get statPastGoal;

  /// No description provided for @statLastFast.
  ///
  /// In en, this message translates to:
  /// **'Last fast'**
  String get statLastFast;

  /// No description provided for @statFastingStreak.
  ///
  /// In en, this message translates to:
  /// **'Fasting streak'**
  String get statFastingStreak;

  /// No description provided for @durationHm.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String durationHm(int hours, String minutes);

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String daysCount(int count);

  /// No description provided for @statEmpty.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get statEmpty;

  /// No description provided for @startFasting.
  ///
  /// In en, this message translates to:
  /// **'Start fasting'**
  String get startFasting;

  /// No description provided for @endFast.
  ///
  /// In en, this message translates to:
  /// **'End fast'**
  String get endFast;

  /// No description provided for @endFastEarlyTitle.
  ///
  /// In en, this message translates to:
  /// **'End fast now?'**
  String get endFastEarlyTitle;

  /// No description provided for @endFastEarlyBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re {left} from your goal.'**
  String endFastEarlyBody(String left);

  /// No description provided for @keepFasting.
  ///
  /// In en, this message translates to:
  /// **'Keep fasting'**
  String get keepFasting;

  /// No description provided for @fastingDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Fasting isn\'t right for everyone. Check with your doctor first.'**
  String get fastingDisclaimer;

  /// No description provided for @savedWorkoutsLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved workouts'**
  String get savedWorkoutsLabel;

  /// No description provided for @presetTabata.
  ///
  /// In en, this message translates to:
  /// **'Tabata'**
  String get presetTabata;

  /// No description provided for @presetHiit.
  ///
  /// In en, this message translates to:
  /// **'HIIT 30/30'**
  String get presetHiit;

  /// No description provided for @presetCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get presetCustom;

  /// No description provided for @intervalSummary.
  ///
  /// In en, this message translates to:
  /// **'{intervals, plural, =1{1 interval} other{{intervals} intervals}} · {rounds, plural, =1{1 round} other{{rounds} rounds}}'**
  String intervalSummary(int intervals, int rounds);

  /// No description provided for @stepPrepare.
  ///
  /// In en, this message translates to:
  /// **'Prepare'**
  String get stepPrepare;

  /// No description provided for @stepWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get stepWork;

  /// No description provided for @stepRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get stepRest;

  /// No description provided for @stepRounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get stepRounds;

  /// No description provided for @stepRoundsDetail.
  ///
  /// In en, this message translates to:
  /// **'Work + rest'**
  String get stepRoundsDetail;

  /// No description provided for @stepSets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get stepSets;

  /// No description provided for @stepSetRest.
  ///
  /// In en, this message translates to:
  /// **'Rest between sets'**
  String get stepSetRest;

  /// No description provided for @decreaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Decrease {label}'**
  String decreaseLabel(String label);

  /// No description provided for @increaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Increase {label}'**
  String increaseLabel(String label);

  /// No description provided for @startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get startWorkout;

  /// No description provided for @intervalRingCaption.
  ///
  /// In en, this message translates to:
  /// **'{work} work · {rest} rest'**
  String intervalRingCaption(String work, String rest);

  /// No description provided for @secondsShort.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String secondsShort(int seconds);

  /// No description provided for @nextPhase.
  ///
  /// In en, this message translates to:
  /// **'Next: {phase} {time}'**
  String nextPhase(String phase, String time);

  /// No description provided for @roundChip.
  ///
  /// In en, this message translates to:
  /// **'{round} / {rounds}'**
  String roundChip(int round, int rounds);

  /// No description provided for @roundOf.
  ///
  /// In en, this message translates to:
  /// **'Round {round} of {rounds}'**
  String roundOf(int round, int rounds);

  /// No description provided for @setRoundOf.
  ///
  /// In en, this message translates to:
  /// **'Set {set} of {sets} · Round {round} of {rounds}'**
  String setRoundOf(int set, int sets, int round, int rounds);

  /// No description provided for @timeLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String timeLeft(String time);

  /// No description provided for @workoutProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Workout progress'**
  String get workoutProgressLabel;

  /// No description provided for @endWorkout.
  ///
  /// In en, this message translates to:
  /// **'End workout'**
  String get endWorkout;

  /// No description provided for @restartRound.
  ///
  /// In en, this message translates to:
  /// **'Restart round'**
  String get restartRound;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @skipRound.
  ///
  /// In en, this message translates to:
  /// **'Skip round'**
  String get skipRound;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @endWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'End workout?'**
  String get endWorkoutTitle;

  /// No description provided for @endWorkoutBody.
  ///
  /// In en, this message translates to:
  /// **'This workout stops here.'**
  String get endWorkoutBody;

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get keepGoing;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @moneyOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline · no bank link'**
  String get moneyOffline;

  /// No description provided for @spentThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Spent this month'**
  String get spentThisMonth;

  /// No description provided for @spentLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month: {amount}'**
  String spentLastMonth(String amount);

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// No description provided for @editExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get editExpense;

  /// No description provided for @byCategoryHeader.
  ///
  /// In en, this message translates to:
  /// **'BY CATEGORY'**
  String get byCategoryHeader;

  /// No description provided for @recentHeader.
  ///
  /// In en, this message translates to:
  /// **'RECENT'**
  String get recentHeader;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @moneyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your expenses will show up here.'**
  String get moneyEmpty;

  /// No description provided for @moneyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your expenses.'**
  String get moneyLoadError;

  /// No description provided for @expensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesTitle;

  /// No description provided for @dayToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get dayToday;

  /// No description provided for @dayYesterday.
  ///
  /// In en, this message translates to:
  /// **'YESTERDAY'**
  String get dayYesterday;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get chooseCategory;

  /// No description provided for @categoryMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get categoryMore;

  /// No description provided for @catGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get catGroceries;

  /// No description provided for @catEatingOut.
  ///
  /// In en, this message translates to:
  /// **'Eating out'**
  String get catEatingOut;

  /// No description provided for @catTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get catTransport;

  /// No description provided for @catBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get catBills;

  /// No description provided for @catShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get catShopping;

  /// No description provided for @catHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get catHealth;

  /// No description provided for @catGifts.
  ///
  /// In en, this message translates to:
  /// **'Gifts'**
  String get catGifts;

  /// No description provided for @catHousing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get catHousing;

  /// No description provided for @catTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get catTravel;

  /// No description provided for @catPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get catPhone;

  /// No description provided for @catEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get catEducation;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// No description provided for @dateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// No description provided for @noteButton.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteButton;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'What was it for?'**
  String get noteHint;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @keypadLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount keypad'**
  String get keypadLabel;

  /// No description provided for @keypadBackspace.
  ///
  /// In en, this message translates to:
  /// **'Delete last digit'**
  String get keypadBackspace;

  /// No description provided for @saveExpense.
  ///
  /// In en, this message translates to:
  /// **'Save expense'**
  String get saveExpense;

  /// No description provided for @entryDetailLine.
  ///
  /// In en, this message translates to:
  /// **'{category} · {time}'**
  String entryDetailLine(String category, String time);

  /// No description provided for @amountExpense.
  ///
  /// In en, this message translates to:
  /// **'−{amount}'**
  String amountExpense(String amount);

  /// No description provided for @deleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Delete expense'**
  String get deleteExpense;

  /// No description provided for @deleteExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this expense?'**
  String get deleteExpenseTitle;

  /// No description provided for @deleteExpenseBody.
  ///
  /// In en, this message translates to:
  /// **'This removes it from your history. It can\'t be undone.'**
  String get deleteExpenseBody;

  /// No description provided for @seePremium.
  ///
  /// In en, this message translates to:
  /// **'See Premium'**
  String get seePremium;

  /// No description provided for @paywallOverline.
  ///
  /// In en, this message translates to:
  /// **'STEADY PREMIUM'**
  String get paywallOverline;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Every sound, every plan, no ads'**
  String get paywallTitle;

  /// No description provided for @paywallBenefitSounds.
  ///
  /// In en, this message translates to:
  /// **'Every sound, offline'**
  String get paywallBenefitSounds;

  /// No description provided for @paywallBenefitStreaks.
  ///
  /// In en, this message translates to:
  /// **'Unlimited habit streaks'**
  String get paywallBenefitStreaks;

  /// No description provided for @paywallBenefitPlans.
  ///
  /// In en, this message translates to:
  /// **'Custom fasting and interval plans'**
  String get paywallBenefitPlans;

  /// No description provided for @paywallBenefitHistory.
  ///
  /// In en, this message translates to:
  /// **'Full history and widget themes'**
  String get paywallBenefitHistory;

  /// No description provided for @choosePlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan'**
  String get choosePlanLabel;

  /// No description provided for @planMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get planMonthly;

  /// No description provided for @planWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get planWeekly;

  /// No description provided for @planPerMonth.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get planPerMonth;

  /// No description provided for @planPerWeek.
  ///
  /// In en, this message translates to:
  /// **'per week'**
  String get planPerWeek;

  /// No description provided for @planTrialNote.
  ///
  /// In en, this message translates to:
  /// **'3-day free trial'**
  String get planTrialNote;

  /// No description provided for @paywallCta.
  ///
  /// In en, this message translates to:
  /// **'Try 3 days free'**
  String get paywallCta;

  /// No description provided for @paywallUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Purchases aren\'t available yet.'**
  String get paywallUnavailable;

  /// No description provided for @paywallTermsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Free for 3 days, then {price} per month. Cancel anytime in Google Play.'**
  String paywallTermsMonthly(String price);

  /// No description provided for @paywallTermsWeekly.
  ///
  /// In en, this message translates to:
  /// **'Free for 3 days, then {price} per week. Cancel anytime in Google Play.'**
  String paywallTermsWeekly(String price);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
