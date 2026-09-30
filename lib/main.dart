import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/analytics.dart';
import 'data/auth_service.dart';
import 'data/community.dart';
import 'data/reminders.dart';
import 'data/remote_food_search.dart';
import 'data/repository.dart';
import 'data/sync.dart';
import 'l10n/app_localizations.dart';
import 'state/app_state.dart';
import 'state/community_state.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Sign-in and sync need the Supabase project (--dart-define SUPABASE_URL /
  // SUPABASE_ANON_KEY); without it the app runs signed out, on-device only.
  const url = String.fromEnvironment('SUPABASE_URL');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  AuthService? auth;
  if (url.isNotEmpty && anonKey.isNotEmpty) {
    try {
      await Supabase.initialize(url: url, publishableKey: anonKey);
      auth = AuthService(Supabase.instance.client);
    } catch (_) {}
  }
  // 헬스장 커뮤니티 (--dart-define=COMMUNITY=true); COMMUNITY_DEMO=true runs
  // it on sample data in memory, without a server.
  const communityOn = bool.fromEnvironment('COMMUNITY');
  const communityDemo = bool.fromEnvironment('COMMUNITY_DEMO');
  final CommunityRepository? communityRepo = communityDemo
      ? MemoryCommunity.demo(me: 'me', meJoined: true)
      : communityOn && auth != null
      ? SupabaseCommunity(auth.client)
      : null;
  final community = communityRepo == null
      ? null
      : CommunityState(communityRepo);
  final state = AppState(
    SyncingRepository(LocalCoachRepository()),
    beforeAccountDelete: communityRepo?.deleteMyPhotos,
    remoteSearch: RemoteFoodSearch.fromEnvironment(),
    auth: auth,
    reminderScheduler: LocalReminders.supported ? LocalReminders() : null,
    analytics: Analytics(
      sink: auth == null ? null : SupabaseEventSink(auth.client),
    ),
  );
  await state.load();
  state.startSync();
  state.analytics.log('app_open', {
    'onboarded': state.onboarded,
    'signed_in': state.signedIn,
  });
  // Signing in or out elsewhere (settings) reloads who I am there.
  if (community != null) state.addListener(community.refresh);
  runApp(CoachApp(state: state, community: community));
}

class CoachApp extends StatefulWidget {
  final AppState state;
  final CommunityState? community;
  const CoachApp({super.key, required this.state, this.community});

  @override
  State<CoachApp> createState() => _CoachAppState();
}

class _CoachAppState extends State<CoachApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Pick up what other devices changed when the app comes back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      widget.state.analytics.log('app_resume');
      widget.state.syncNow();
    } else if (s == AppLifecycleState.paused || s == AppLifecycleState.hidden) {
      widget.state.analytics.flush();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final community = widget.community;
    final app = AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final lang = state.settings.language;
          return MaterialApp(
            onGenerateTitle: (context) => L.of(context).appName,
            debugShowCheckedModeBanner: false,
            theme: buildTheme(),
            locale: lang == null ? null : Locale(lang),
            supportedLocales: L.supportedLocales,
            localizationsDelegates: const [
              L.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: state.onboarded
                ? const HomeShell()
                : const OnboardingScreen(),
          );
        },
      ),
    );
    return community == null
        ? app
        : CommunityScope(state: community, child: app);
  }
}
