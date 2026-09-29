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

enum ReminderResult { on, denied, unsupported, signedOut, failed }

/// Reminder pushes (supabase/push.sql): this device's Web Push
/// subscription, stored for the signed-in user so the server's daily job
/// can reach it.
class Reminders {
  final SupabaseClient client;
  Reminders(this.client);

  bool get supported => pushSupported();

  /// Browser permission: 'default' (not asked), 'granted' or 'denied'.
  String get permission => pushPermission();

  Future<ReminderResult> enable() async {
    final user = client.auth.currentUser;
    if (user == null) return ReminderResult.signedOut;
    if (!supported) return ReminderResult.unsupported;
    try {
      final raw = await pushSubscribe(vapidPublicKey);
      if (raw.isEmpty) return ReminderResult.denied;
      final sub = jsonDecode(raw) as Map<String, Object?>;
      final keys = (sub['keys'] as Map).cast<String, Object?>();
      await client.from('push_subscriptions').upsert({
        'endpoint': sub['endpoint'],
        'user_id': user.id,
        'platform': 'web',
        'p256dh': keys['p256dh'],
        'auth': keys['auth'],
      });
      return ReminderResult.on;
    } catch (_) {
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
