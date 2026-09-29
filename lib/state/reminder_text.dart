import '../l10n/app_localizations.dart';
import 'reminder_plan.dart';

/// Notification title of a planned reminder.
String reminderTitle(L t, PlannedReminder p) => switch (p.kind) {
  ReminderKind.checkin => t.notifCheckinTitle,
  ReminderKind.inactive => switch (p.days) {
    1 => t.notifDay1Title,
    3 => t.notifDay3Title,
    7 => t.notifDay7Title,
    14 => t.notifDay14Title,
    21 => t.notifDay21Title,
    28 => t.notifDay28Title,
    _ => [
      t.notifLong1Title,
      t.notifLong2Title,
      t.notifLong3Title,
    ][(p.days ~/ 14) % 3],
  },
};

/// Notification text of a planned reminder.
String reminderBody(L t, PlannedReminder p) => switch (p.kind) {
  ReminderKind.checkin => t.notifCheckinBody,
  ReminderKind.inactive => switch (p.days) {
    1 => t.notifDay1Body,
    3 => t.notifDay3Body,
    7 => t.notifDay7Body,
    14 => t.notifDay14Body,
    21 => t.notifDay21Body,
    28 => t.notifDay28Body,
    _ => [
      t.notifLong1Body,
      t.notifLong2Body,
      t.notifLong3Body,
    ][(p.days ~/ 14) % 3],
  },
};
