import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../ui/platform/push.dart';

/// VAPID public key for Web Push (the private key is a Supabase secret of
/// supabase/functions/daily-push). Public by design; override per build
/// with --dart-define=VAPID_PUBLIC_KEY.
const vapidPublicKey = String.fromEnvironment(
  'VAPID_PUBLIC_KEY',
  defaultValue: 'BD1438Acaz9xDqYVd6OzqU5t4_HNwTxVi241E8Ct0em6KyaynvL07bNgrTzaHHWZQtohe9VBViSNjyp7o8ApaBY',
);

enum ReminderResult {
  on,

  /// Notifications are blocked for this site.
  denied,

  /// The permission prompt was closed or quietly not shown.
  dismissed,

  /// No Web Push here (in-app browsers, iPhone outside the home screen).
  unsupported,
  signedOut,
  failed,
}

/// Reminder pushes (supabase/push.sql): this device's Web Push
/// subscription, stored for the signed-in user so the server's daily job
/// can reach it.
class Reminders {
  final SupabaseClient client;
  Reminders(this.client);

  /// Why the last enable() failed, for the usage log (no personal data).
  String? lastError;

  bool get supported => pushSupported();

  /// Browser permission: 'default' (not asked), 'granted' or 'denied'.
  String get permission => pushPermission();

  Future<ReminderResult> enable() async {
    final user = client.auth.currentUser;
    if (user == null) return ReminderResult.signedOut;
    if (!supported) return ReminderResult.unsupported;
    try {
      final res = jsonDecode(await pushSubscribe(vapidPublicKey)) as Map;
      switch (res['result']) {
        case 'denied':
          return ReminderResult.denied;
        case 'dismissed':
          return ReminderResult.dismissed;
        case 'unsupported':
          return ReminderResult.unsupported;
        case 'error':
          lastError = res['error'] as String?;
          return ReminderResult.failed;
      }
      final sub = (res['subscription'] as Map).cast<String, Object?>();
      final keys = (sub['keys'] as Map).cast<String, Object?>();
      await client.from('push_subscriptions').upsert({
        'endpoint': sub['endpoint'],
        'user_id': user.id,
        'platform': 'web',
        'p256dh': keys['p256dh'],
        'auth': keys['auth'],
      });
      return ReminderResult.on;
    } catch (e) {
      lastError = '$e';
      return ReminderResult.failed;
    }
  }

  Future<void> disable() async {
    try {
      final endpoint = await pushUnsubscribe();
      if (endpoint.isNotEmpty) {
        await client
            .from('push_subscriptions')
            .delete()
            .eq('endpoint', endpoint);
      }
    } catch (_) {} // the server drops dead subscriptions on its own
  }
}
