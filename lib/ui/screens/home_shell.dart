import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../motion.dart';
import '../theme.dart';
import 'checkin_screen.dart';
import 'settings_screen.dart';
import 'today_screen.dart';
import 'trend_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static void goTo(BuildContext context, int tab) =>
      context.findAncestorStateOfType<_HomeShellState>()?._select(tab);

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _tab = 0;

  static const _tabNames = ['today', 'trend', 'checkin', 'settings'];

  void _select(int i) {
    if (i != _tab) {
      AppScope.read(context).analytics.log('tab', {'tab': _tabNames[i]});
    }
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final due = AppScope.of(context).checkinDue;
    return Scaffold(
      body: FadeIndexedStack(
        index: _tab,
        children: const [
          TodayScreen(),
          TrendScreen(),
          CheckinScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _select,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.wb_sunny_outlined),
            selectedIcon: const Icon(Icons.wb_sunny_rounded),
            label: t.navToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.show_chart_rounded),
            selectedIcon: const Icon(Icons.insights_rounded),
            label: t.navTrend,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: due,
              backgroundColor: AppColors.peach,
              child: const Icon(Icons.event_available_outlined),
            ),
            selectedIcon: const Icon(Icons.event_available_rounded),
            label: t.navCheckin,
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_rounded),
            label: t.navSettings,
          ),
        ],
      ),
    );
  }
}
