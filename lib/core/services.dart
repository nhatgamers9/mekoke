import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';

import '../data/check_in_repository.dart';
import '../data/database.dart';
import '../data/fasting_repository.dart';
import '../data/habit_repository.dart';
import '../data/money_repository.dart';
import '../data/prefs_repository.dart';
import 'screen_awake.dart';
import 'time/today_notifier.dart';

class AppServices {
  AppServices({required this.db, required this.clock, ScreenAwake? screenAwake})
    : habits = HabitRepository(db, clock),
      checkIns = CheckInRepository(db, clock),
      fasts = FastingRepository(db, clock),
      money = MoneyRepository(db, clock),
      prefs = PrefsRepository(db),
      today = TodayNotifier(clock),
      screenAwake = screenAwake ?? const WakelockScreenAwake();

  final AppDatabase db;
  final Clock clock;
  final HabitRepository habits;
  final CheckInRepository checkIns;
  final FastingRepository fasts;
  final MoneyRepository money;
  final PrefsRepository prefs;
  final TodayNotifier today;
  final ScreenAwake screenAwake;

  Future<void> dispose() async {
    today.dispose();
    await db.close();
  }
}

class ServicesScope extends InheritedWidget {
  const ServicesScope({
    super.key,
    required this.services,
    required super.child,
  });

  final AppServices services;

  /// Không đăng ký phụ thuộc: [AppServices] không đổi suốt vòng đời của app,
  /// và nhờ vậy có thể gọi cả trong `initState`.
  static AppServices of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ServicesScope>();
    assert(scope != null, 'No ServicesScope found in context');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(ServicesScope oldWidget) =>
      services != oldWidget.services;
}
