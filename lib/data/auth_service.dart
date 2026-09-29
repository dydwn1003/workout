import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthMethod { google, kakao, apple }

/// Sign-in with Supabase Auth.
///
/// - Google: the native Google sign-in sheet on Android/iOS, exchanged for a
///   Supabase session with its ID token; the Supabase OAuth page on the web.
/// - Kakao: the Supabase OAuth page (Kakao's login in the browser/app),
///   returning to the app through [mobileRedirect].
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
    defaultValue: 'com.adapt.adaptcoach://login-callback',
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
    AuthMethod.google,
    AuthMethod.kakao,
  ];

  String get _webRedirect => '${Uri.base.origin}${Uri.base.path}';

  /// Signs in. OAuth flows (Kakao, Google on the web) leave the app and
  /// finish later through [changes]; the native ones finish here.
  Future<void> signIn(AuthMethod m) => switch (m) {
    AuthMethod.google => _google(),
    AuthMethod.kakao => client.auth.signInWithOAuth(
      OAuthProvider.kakao,
      redirectTo: kIsWeb ? _webRedirect : mobileRedirect,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    ),
    AuthMethod.apple => _appleSignIn(),
  };

  Future<void> _google() async {
    if (kIsWeb) {
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _webRedirect,
      );
      return;
    }
    final google = GoogleSignIn.instance;
    await google.initialize(
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? (googleIosClientId.isEmpty ? null : googleIosClientId)
          : null,
      serverClientId: googleWebClientId.isEmpty ? null : googleWebClientId,
    );
    final account = await google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) throw const AuthException('Google: no ID token');
    await client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
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
