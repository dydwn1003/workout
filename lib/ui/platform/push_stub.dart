/// Web Push is web-only; the apps will use FCM (not built yet).
bool pushSupported() => false;

/// 'default', 'granted' or 'denied'.
String pushPermission() => 'denied';

/// Subscription JSON, or '' when refused or unsupported.
Future<String> pushSubscribe(String vapidPublicKey) async => '';

/// The endpoint that was unsubscribed, or ''.
Future<String> pushUnsubscribe() async => '';
