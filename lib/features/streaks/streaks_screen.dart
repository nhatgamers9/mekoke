import 'package:flutter/material.dart';

import '../../core/format/formatting.dart';
import '../../core/services.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/time/local_date.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/components/steady_button.dart';
import '../../ui/components/steady_icon.dart';
import '../../ui/components/streak_card.dart';
import 'add_habit_sheet.dart';
import 'habit_actions_sheet.dart';
import 'streak_math.dart';

class StreaksScreen extends StatefulWidget {
  const StreaksScreen({super.key});

  @override
  State<StreaksScreen> createState() => _StreaksScreenState();
}

class _StreaksScreenState extends State<StreaksScreen> {
  late final AppServices _services;
  late final Stream<List<Habit>> _habits;

  @override
  void initState() {
    super.initState();
    _services = ServicesScope.of(context);
    _habits = _services.habits.watchHabits();
  }

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final l10n = AppLocalizations.of(context);
    final tag = formatLocaleOf(context);
    return StreamBuilder<List<Habit>>(
      stream: _habits,
      builder: (context, snapshot) {
        return ValueListenableBuilder<LocalDate>(
          valueListenable: _services.today,
          builder: (context, today, _) {
            final habits = snapshot.data;
            final children = <Widget>[
              Text(
                l10n.tabStreaks,
                style: SteadyText.display.copyWith(color: c.ink),
              ),
            ];
            if (habits != null) {
              if (habits.isEmpty) {
                children.add(
                  Text(
                    l10n.streaksEmpty,
                    style: SteadyText.body.copyWith(color: c.inkMuted),
                  ),
                );
              }
              for (var i = 0; i < habits.length; i++) {
                final habit = habits[i];
                final days = daysClean(habit.cleanSince, today);
                final next = i == 0 ? nextMilestone(days) : null;
                children.add(
                  StreakCard(
                    habit: habit.name,
                    days: days,
                    since: l10n.streakSince(
                      formatShortDate(habit.cleanSince, today, tag),
                    ),
                    size: i == 0 ? StreakCardSize.lg : StreakCardSize.sm,
                    milestone: next == null
                        ? null
                        : StreakMilestoneView(
                            label: l10n.milestoneNext(
                              next.next,
                              next.remaining,
                            ),
                            progress: next.progress,
                          ),
                    onTap: () => showHabitActionsSheet(context, habit),
                  ),
                );
              }
              children.add(
                SteadyButton(
                  label: l10n.addHabit,
                  onPressed: () => showAddHabitSheet(context),
                  block: true,
                  icon: SteadyIcons.plus,
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                SteadySpace.s5,
                SteadySpace.s8,
                SteadySpace.s5,
                SteadySpace.s5,
              ),
              itemCount: children.length,
              itemBuilder: (context, index) => children[index],
              separatorBuilder: (context, index) =>
                  const SizedBox(height: SteadySpace.s4),
            );
          },
        );
      },
    );
  }
}
