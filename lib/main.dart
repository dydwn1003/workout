import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/repository.dart';
import 'l10n/app_localizations.dart';
import 'state/app_state.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState(LocalCoachRepository());
  await state.load();
  runApp(CoachApp(state: state));
}

class CoachApp extends StatelessWidget {
  final AppState state;
  const CoachApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
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
