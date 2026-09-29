/// Web Push is web-only; the apps will use FCM (not built yet).
bool pushSupported() => false;

/// 'default', 'granted' or 'denied'.
String pushPermission() => 'denied';

/// Result JSON (see web/push.js subscribe()).
Future<String> pushSubscribe(String vapidPublicKey) async =>
    '{"result":"unsupported"}';

/// The endpoint that was unsubscribed, or ''.
Future<String> pushUnsubscribe() async => '';
