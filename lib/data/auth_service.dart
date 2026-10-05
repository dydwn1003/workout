import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart' show closeInAppWebView;

enum AuthMethod { google, kakao, apple }

/// Sign-in with Supabase Auth.
///
/// - Google: the native Google sign-in sheet on Android/iOS, exchanged for a
///   Supabase session with its ID token; the Supabase OAuth page on the web.
/// - Kakao: the Supabase OAuth page (Kakao's login in an in-app browser on
///   iPhone, the browser app on Android), returning to the app through
///   [mobileRedirect].
/// - Apple: the native Sign in with Apple sheet, iOS/macOS only. The ID token
///   flow needs no client secret, so nothing has to be rotated.
///
/// Build-time configuration (--dart-define):
///   GOOGLE_WEB_CLIENT_ID  Google OAuth "Web application" client id (the one
///                         also entered in Supabase), required on Android/iOS
///   GOOGLE_IOS_CLIENT_ID  Google OAuth "iOS" client id
///   AUTH_REDIRECT         deep link back into the app after Kakao sign-in
class AuthService {
  final SupabaseClient client;
  AuthService(this.client);

  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
  static const mobileRedirect = String.fromEnvironment(
    'AUTH_REDIRECT',
    defaultValue: 'com.alasfit.app://login-callback',
  );

  User? get user => client.auth.currentUser;
  Stream<AuthState> get changes => client.auth.onAuthStateChange;

  static bool get _apple =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// Sign-in options shown on this platform (Apple only on Apple devices).
  List<AuthMethod> get methods => [
    if (_apple) AuthMethod.apple,
    // On iPhone, Google needs its iOS client id (and URL scheme) or the
    // sign-in crashes: without it the button stays hidden.
    if (!_iosApp || googleIosClientId.isNotEmpty) AuthMethod.google,
    AuthMethod.kakao,
  ];

  static bool get _iosApp =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  String get _webRedirect => '${Uri.base.origin}${Uri.base.path}';

  /// Signs in. OAuth flows (Kakao, Google on the web) leave the app and
  /// finish later through [changes]; the native ones finish here.
  Future<void> signIn(AuthMethod m) => switch (m) {
    AuthMethod.google => _google(),
    AuthMethod.kakao => _kakao(),
    AuthMethod.apple => _appleSignIn(),
  };

  /// Closes the in-app browser once the Kakao sign-in comes back.
  StreamSubscription<AuthState>? _closeBrowser;

  /// On iPhone the Kakao page opens inside the app (Safari View
  /// Controller): App Review rejects sending people out to Safari to sign
  /// in (guideline 4). It's closed once the app has the session. Android
  /// keeps the browser app, and the web stays on the page.
  Future<void> _kakao() async {
    final ios = _iosApp;
    if (ios) {
      _closeBrowser ??= changes.listen((s) {
        if (s.event == AuthChangeEvent.signedIn) closeInAppWebView();
      });
    }
    await client.auth.signInWithOAuth(
      OAuthProvider.kakao,
      redirectTo: kIsWeb ? _webRedirect : mobileRedirect,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : ios
          ? LaunchMode.inAppBrowserView
          : LaunchMode.externalApplication,
    );
  }

  /// GoogleSignIn may be initialized only once per app run.
  static Future<void>? _googleReady;

  /// On iPhone, Google puts a nonce in the ID token, and Supabase only
  /// accepts it when it gets the raw nonce too: ours, hashed for Google.
  static String? _googleNonce;

  Future<void> _initGoogle() => _googleReady ??= () {
    final ios = _iosApp;
    final raw = ios ? client.auth.generateRawNonce() : null;
    _googleNonce = raw;
    return GoogleSignIn.instance.initialize(
      clientId: ios && googleIosClientId.isNotEmpty ? googleIosClientId : null,
      serverClientId: googleWebClientId.isEmpty ? null : googleWebClientId,
      nonce: raw == null ? null : sha256.convert(utf8.encode(raw)).toString(),
    );
  }();

  Future<void> _google() async {
    if (kIsWeb) {
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _webRedirect,
      );
      return;
    }
    try {
      await _initGoogle();
    } catch (_) {
      _googleReady = null; // try again next time
      rethrow;
    }
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) throw const AuthException('Google: no ID token');
    await client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      nonce: _googleNonce,
    );
  }

  Future<void> _appleSignIn() async {
    final rawNonce = client.auth.generateRawNonce();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email],
      nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
    );
    final idToken = credential.identityToken;
    if (idToken == null) throw const AuthException('Apple: no ID token');
    await client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await client.auth.signOut();
  }

  /// Deletes the account and all its synced records (App Store requirement
  /// for apps with sign-in), then signs out.
  Future<void> deleteAccount() async {
    await client.rpc('delete_my_account');
    await signOut();
  }

  /// A short label for the signed-in account: its email, else the provider.
  String? get accountLabel {
    final u = user;
    if (u == null) return null;
    final email = u.email;
    if (email != null && email.isNotEmpty) return email;
    final provider = u.appMetadata['provider'] as String?;
    return switch (provider) {
      'kakao' => 'Kakao',
      'apple' => 'Apple',
      'google' => 'Google',
      _ => provider,
    };
  }
}
