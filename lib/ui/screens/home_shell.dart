import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/update_check.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../motion.dart';
import '../platform/reload.dart';
import '../theme.dart';
import 'checkin_screen.dart';
import 'review_sheet.dart';
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

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  var _tab = 0;
  var _updateShown = false;
  final _today = GlobalKey<TodayScreenState>();
  DateTime? _lastBack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkForUpdate();
    _maybeAskReview();
    _warmUpSearch();
  }

  /// Builds the food search index once the first screen is up, so the
  /// first keystroke in 식사 기록 doesn't pause for it.
  Future<void> _warmUpSearch() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (mounted) AppScope.read(context).warmUpSearch();
  }

  var _reviewShown = false;

  /// "알아서핏 어떠세요?" at a good moment (AppState.shouldAskReview), once
  /// per launch, a little after the screen settles.
  Future<void> _maybeAskReview() async {
    if (_reviewShown) return;
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted || !AppScope.read(context).shouldAskReview) return;
    if (ModalRoute.of(context)?.isCurrent == false) return; // a sheet is open
    _reviewShown = true;
    await showReviewSheet(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForUpdate();
      _maybeAskReview();
    }
  }

  /// Offers the newer version: a reload on the web, the store in the apps.
  Future<void> _checkForUpdate() async {
    if (_updateShown) return;
    final update = await checkForUpdate();
    if (update == null || !mounted) return;
    // Already reloaded for this build and still old (cached files): the
    // next visit gets it, don't keep asking.
    if (update.action == UpdateAction.reload &&
        reloadedFor() == update.latest) {
      return;
    }
    _updateShown = true;
    final t = L.of(context);
    final store = update.action == UpdateAction.store;
    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: Text(store ? t.updateInStore : t.updateAvailable),
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: store ? t.updateStoreAction : t.reload,
              textColor: AppColors.peachSoft,
              onPressed: () => store
                  ? launchUrl(
                      Uri.parse(
                        defaultTargetPlatform == TargetPlatform.iOS
                            ? iosStoreUrl
                            : androidStoreUrl,
                      ),
                      mode: LaunchMode.externalApplication,
                    )
                  : reloadPage(forBuild: update.latest),
            ),
          ),
        )
        .closed
        // Offered again the next time the app comes back to the front.
        .then((_) => _updateShown = false);
  }

  static const _tabNames = ['today', 'trend', 'checkin', 'settings'];

  void _select(int i) {
    if (i != _tab) {
      AppScope.read(context).analytics.log('tab', {'tab': _tabNames[i]});
    }
    setState(() => _tab = i);
  }

  /// Back button (Android, or the browser's on the web; open sheets close
  /// first on their own): other tab -> 오늘, another day -> today, then a
  /// second press within 2 s leaves the app.
  void _onBack() {
    if (_tab != 0) {
      _select(0);
      return;
    }
    if (_today.currentState?.handleBack() ?? false) return;
    final now = DateTime.now();
    if (_lastBack != null &&
        now.difference(_lastBack!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _lastBack = now;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(L.of(context).pressBackAgainToExit),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final due = AppScope.of(context).checkinDue;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: _scaffold(t, due),
    );
  }

  Widget _scaffold(L t, bool due) {
    return Scaffold(
      body: FadeIndexedStack(
        index: _tab,
        children: [
          TodayScreen(key: _today),
          const TrendScreen(),
          const CheckinScreen(),
          const SettingsScreen(),
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
