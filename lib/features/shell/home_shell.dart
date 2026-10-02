import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services.dart';
import '../../core/theme/tokens.dart';
import '../../core/time/today_notifier.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/components/steady_icon.dart';
import '../../ui/components/steady_tab_bar.dart';
import '../check_in/check_in_screen.dart';
import '../placeholder/placeholder_screen.dart';
import '../streaks/streaks_screen.dart';
import '../timer/timer_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final TodayNotifier _today;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _today = ServicesScope.of(context).today..start();
  }

  @override
  void dispose() {
    _today.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) setState(() => _index = 0);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: c.surface,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _index,
              children: [
                PlaceholderScreen(title: l10n.tabFocus),
                TimerScreen(isActive: _index == 1),
                const StreaksScreen(),
                PlaceholderScreen(title: l10n.tabMoney),
                const CheckInScreen(),
              ],
            ),
          ),
          bottomNavigationBar: SteadyTabBar(
            items: [
              SteadyTabItem(SteadyIcons.audioWaveform, l10n.tabFocus),
              SteadyTabItem(SteadyIcons.timer, l10n.tabTimer),
              SteadyTabItem(SteadyIcons.sprout, l10n.tabStreaks),
              SteadyTabItem(SteadyIcons.wallet, l10n.tabMoney),
              SteadyTabItem(SteadyIcons.notebookPen, l10n.tabCheckIn),
            ],
            current: _index,
            onChanged: (i) => setState(() => _index = i),
          ),
        ),
      ),
    );
  }
}
