import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/analytics.dart';
import 'data/auth_service.dart';
import 'data/remote_food_search.dart';
import 'data/repository.dart';
import 'data/sync.dart';
import 'l10n/app_localizations.dart';
import 'state/app_state.dart';
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
  final state = AppState(
    SyncingRepository(LocalCoachRepository()),
    remoteSearch: RemoteFoodSearch.fromEnvironment(),
    auth: auth,
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
  runApp(CoachApp(state: state));
}

class CoachApp extends StatefulWidget {
  final AppState state;
  const CoachApp({super.key, required this.state});

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
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final lang = state.settings.language;
          return MaterialApp(
            title: 'Adapt',
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
  }
}
