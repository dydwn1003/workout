/// Which reminder, for the message text.
enum ReminderKind { inactive, checkin }

/// One reminder notification to schedule on this device.
class PlannedReminder {
  /// Stable per slot so rescheduling replaces rather than duplicates.
  final int id;
  final DateTime at;
  final ReminderKind kind;

  /// Days since the last log (inactivity reminders).
  final int days;
  const PlannedReminder(this.id, this.at, this.kind, {this.days = 0});
}

/// Hour of the day reminders go out.
const reminderHour = 20;

/// Reminders from [now] on: after [lastLog] (last day with a meal or
/// weigh-in) on days 1 and 3, weekly to day 28, then every 14 days for a
/// year; and on [nextCheckin] while the user still logs (within a week
/// before it). At most one per day (the check-in wins).
List<PlannedReminder> planReminders({
  required DateTime now,
  required DateTime? lastLog,
  required DateTime? nextCheckin,
}) {
  DateTime at(DateTime d) => DateTime(d.year, d.month, d.day, reminderHour);
  DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
  final out = <PlannedReminder>[];

  DateTime? checkinAt;
  if (nextCheckin != null && lastLog != null) {
    // Due already: remind tonight (tomorrow if tonight has passed).
    var d = day(nextCheckin);
    if (at(d).isBefore(now)) d = day(now);
    if (at(d).isBefore(now)) d = DateTime(d.year, d.month, d.day + 1);
    if (d.difference(day(lastLog)).inDays < 7) {
      checkinAt = at(d);
      out.add(PlannedReminder(1, checkinAt, ReminderKind.checkin));
    }
  }

  if (lastLog != null) {
    final days = [1, 3, 7, 14, 21, 28, for (var d = 42; d <= 365; d += 14) d];
    for (final d in days) {
      final t = at(DateTime(lastLog.year, lastLog.month, lastLog.day + d));
      if (!t.isAfter(now) || t == checkinAt) continue;
      out.add(PlannedReminder(1000 + d, t, ReminderKind.inactive, days: d));
    }
  }
  return out;
}

/// Outcome of turning reminders on.
enum ReminderResult { on, denied, unsupported }
