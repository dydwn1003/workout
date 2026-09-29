import 'package:adapt_coach/data/entities.dart';
import 'package:adapt_coach/data/reminders.dart';
import 'package:adapt_coach/data/repository.dart';
import 'package:adapt_coach/state/app_state.dart';
import 'package:adapt_coach/state/reminder_plan.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeScheduler implements ReminderScheduler {
  var granted = true;
  List<ReminderNotice>? scheduled;
  var cancelled = 0;

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<void> schedule(List<ReminderNotice> notices) async =>
      scheduled = notices;

  @override
  Future<void> cancelAll() async {
    cancelled++;
    scheduled = null;
  }
}

void main() {
  final now = DateTime(2026, 9, 29, 10);

  group('reminder plan', () {
    test('days 1 and 3, weekly to 28, then every 14 days, at 8 pm', () {
      final p = planReminders(
        now: now,
        lastLog: DateTime(2026, 9, 29),
        nextCheckin: null,
      );
      final days = [for (final r in p) r.days];
      expect(days.take(8), [1, 3, 7, 14, 21, 28, 42, 56]);
      expect(days.last, lessThanOrEqualTo(365));
      expect(p.first.at, DateTime(2026, 9, 30, 20));
      expect(p.every((r) => r.at.hour == 20), isTrue);
    });

    test('only future ones; the check-in wins a shared day', () {
      final p = planReminders(
        now: now,
        lastLog: DateTime(2026, 9, 28), // day 1 is today at 8 pm
        nextCheckin: DateTime(2026, 10, 1), // = day 3
      );
      expect(p.first.kind, ReminderKind.checkin);
      expect(p.first.at, DateTime(2026, 10, 1, 20));
      final days = [
        for (final r in p)
          if (r.kind == ReminderKind.inactive) r.days,
      ];
      expect(days.first, 1); // tonight
      expect(days.contains(3), isFalse); // taken by the check-in
    });

    test('no check-in reminder for someone who stopped logging', () {
      final p = planReminders(
        now: now,
        lastLog: DateTime(2026, 9, 10),
        nextCheckin: DateTime(2026, 9, 29),
      );
      expect(p.where((r) => r.kind == ReminderKind.checkin), isEmpty);
    });
  });

  test('app state schedules on enable and reschedules on new logs', () async {
    final fake = FakeScheduler();
    final s = AppState(
      MemoryCoachRepository(),
      clock: () => now,
      reminderScheduler: fake,
    );
    await s.load();
    await s.addMeal(
      name: 'x',
      kcal: 100,
      proteinG: 0,
      carbsG: 0,
      fatG: 0,
      source: MealSource.manual,
    );
    expect(s.shouldOfferReminders, isTrue);
    expect(fake.scheduled, isNull); // not on yet
    expect(await s.setReminders(true), ReminderResult.on);
    expect(s.remindersOn, isTrue);
    expect(fake.scheduled!.first.at, DateTime(2026, 9, 30, 20));
    expect(fake.scheduled!.first.title, isNotEmpty);

    // Logging tomorrow moves the plan.
    await s.addMeal(
      name: 'y',
      kcal: 100,
      proteinG: 0,
      carbsG: 0,
      fatG: 0,
      source: MealSource.manual,
      date: DateTime(2026, 9, 30),
    );
    expect(fake.scheduled!.first.at, DateTime(2026, 10, 1, 20));

    await s.setReminders(false);
    expect(fake.scheduled, isNull);
    expect(s.remindersOn, isFalse);
  });

  test('denied permission leaves reminders off', () async {
    final fake = FakeScheduler()..granted = false;
    final s = AppState(
      MemoryCoachRepository(),
      clock: () => now,
      reminderScheduler: fake,
    );
    await s.load();
    expect(await s.setReminders(true), ReminderResult.denied);
    expect(s.remindersOn, isFalse);
    expect(fake.scheduled, isNull);
  });
}
