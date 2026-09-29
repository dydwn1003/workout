import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// A reminder ready to schedule: when, and what it says.
typedef ReminderNotice = ({int id, DateTime at, String title, String body});

/// Reminder notifications scheduled on this device (the Android/iOS apps;
/// the web has none). Nothing goes through a server: the app reschedules
/// the whole plan whenever the last log or the next check-in changes.
abstract class ReminderScheduler {
  /// Asks for notification permission; true when reminders can be shown.
  Future<bool> requestPermission();

  /// Replaces everything scheduled with [notices].
  Future<void> schedule(List<ReminderNotice> notices);

  Future<void> cancelAll();

  /// Shows a notification right away (Settings -> 테스트 알림).
  Future<void> showNow(String title, String body);
}

class LocalReminders implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  /// Local notifications exist on Android and iOS only.
  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _init() => _ready ??= () async {
    // Times are scheduled as instants, so UTC is enough (no zone lookup).
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        // White peach silhouette (Android draws notification icons as
        // single-colour shapes; generated from assets/icon/icon.png).
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      '기록·체크인 알림',
      channelDescription: '기록을 쉬거나 체크인 날일 때 알려 드려요',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      color: Color(0xFFFF8E7F),
    ),
    iOS: DarwinNotificationDetails(),
  );

  @override
  Future<bool> requestPermission() async {
    await _init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  @override
  Future<void> schedule(List<ReminderNotice> notices) async {
    await _init();
    await _plugin.cancelAll();
    for (final n in notices) {
      await _plugin.zonedSchedule(
        id: n.id,
        title: n.title,
        body: n.body,
        scheduledDate: tz.TZDateTime.from(n.at, tz.UTC),
        notificationDetails: _details,
        // No exact-alarm permission needed; a few minutes late is fine.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    await _init();
    await _plugin.cancelAll();
  }

  @override
  Future<void> showNow(String title, String body) async {
    await _init();
    await _plugin.show(
      id: 999,
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }
}
