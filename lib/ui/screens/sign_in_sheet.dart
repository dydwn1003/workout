import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../brand_logos.dart';
import '../motion.dart';
import '../theme.dart';
import '../widgets.dart';
import 'settings_screen.dart' show privacyPolicyUrl;

Future<void> showSignInSheet(BuildContext context) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  sheetAnimationStyle: Motion.sheet,
  builder: (_) => const SignInSheet(),
);

/// Apple / Google / Kakao buttons, styled per each provider's guidelines
/// (Apple black, Google white with a border, Kakao #FEE500 with black text).
class SignInSheet extends StatefulWidget {
  const SignInSheet({super.key});

  @override
  State<SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends State<SignInSheet> {
  AuthMethod? _busy;
  var _closing = false;

  Future<void> _go(AuthMethod m) async {
    final t = L.of(context);
    final s = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = m);
    try {
      await s.signIn(m); // closes via build() once signed in
    } catch (e) {
      debugPrint('sign-in failed: $e');
      // The reason in small print, so a failure on a phone can be told apart.
      final why = e.toString().replaceAll('\n', ' ');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${t.signInFailed}\n${why.length > 140 ? '${why.substring(0, 140)}…' : why}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final s = AppScope.of(context);
    final methods = s.auth?.methods ?? const <AuthMethod>[];
    // OAuth sign-in (Kakao) completes after returning to the app.
    if (s.signedIn && !_closing) {
      _closing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.maybePop(context);
      });
    }
    Widget button(AuthMethod m) {
      final (label, bg, fg, border, icon) = switch (m) {
        AuthMethod.apple => (
          t.signInApple,
          Colors.black,
          Colors.white,
          Colors.black,
          const Icon(Icons.apple, color: Colors.white, size: 24),
        ),
        AuthMethod.google => (
          t.signInGoogle,
          Colors.white,
          const Color(0xFF1F1F1F),
          const Color(0xFF747775),
          const GoogleLogo(size: 20),
        ),
        AuthMethod.kakao => (
          t.signInKakao,
          const Color(0xFFFEE500),
          const Color(0xD9000000),
          const Color(0xFFFEE500),
          const KakaoLogo(size: 19),
        ),
      };
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: _busy == null ? () => _go(m) : null,
            style: OutlinedButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              disabledBackgroundColor: bg.withValues(alpha: 0.6),
              side: BorderSide(color: border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 28, child: Center(child: icon)),
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: fg,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: _busy == m
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: fg,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: Mascot(size: 64)),
          const SizedBox(height: 12),
          Text(
            t.signInTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            t.signInBody,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.inkSoft, height: 1.5),
          ),
          const SizedBox(height: 20),
          if (methods.isEmpty)
            Text(
              t.signInUnavailable,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft),
            ),
          for (final m in methods) button(m),
          if (methods.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              t.signInNotice,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.inkSoft,
                height: 1.5,
              ),
            ),
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse(privacyPolicyUrl),
                mode: LaunchMode.externalApplication,
              ),
              child: Text(t.privacyPolicy),
            ),
          ],
        ],
      ),
    );
  }
}
