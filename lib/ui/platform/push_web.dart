import 'dart:js_interop';

// web/push.js
@JS('alasPush.supported')
external JSBoolean _supported();

@JS('alasPush.permission')
external JSString _permission();

@JS('alasPush.subscribe')
external JSPromise<JSString> _subscribe(JSString vapidPublicKey);

@JS('alasPush.unsubscribe')
external JSPromise<JSString> _unsubscribe();

bool pushSupported() {
  try {
    return _supported().toDart;
  } catch (_) {
    return false; // push.js missing (e.g. a local build without it)
  }
}

/// 'default', 'granted' or 'denied'.
String pushPermission() {
  try {
    return _permission().toDart;
  } catch (_) {
    return 'denied';
  }
}

/// Subscription JSON, or '' when refused or unsupported.
Future<String> pushSubscribe(String vapidPublicKey) async =>
    (await _subscribe(vapidPublicKey.toJS).toDart).toDart;

/// The endpoint that was unsubscribed, or ''.
Future<String> pushUnsubscribe() async => (await _unsubscribe().toDart).toDart;
