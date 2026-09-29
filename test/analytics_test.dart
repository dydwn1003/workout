import 'package:adapt_coach/data/analytics.dart';
import 'package:adapt_coach/data/entities.dart';
import 'package:adapt_coach/data/repository.dart';
import 'package:adapt_coach/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSink implements EventSink {
  final sent = <Map<String, Object?>>[];
  var fail = false;
  @override
  Future<void> send(List<Map<String, Object?>> rows) async {
    if (fail) throw Exception('offline');
    sent.addAll(rows);
  }
}

void main() {
  Analytics analytics(FakeSink sink) => Analytics(
    sink: sink,
    deviceId: () async => 'dev-1',
    flushDelay: const Duration(hours: 1),
  );

  test('events are batched with device and session ids', () async {
    final sink = FakeSink();
    final a = analytics(sink)
      ..log('app_open')
      ..log('tab', {'tab': 'trend'});
    expect(sink.sent, isEmpty);
    await a.flush();
    expect(sink.sent.map((e) => e['name']), ['app_open', 'tab']);
    expect(sink.sent.first['device_id'], 'dev-1');
    expect(sink.sent.first['session_id'], a.sessionId);
    expect(sink.sent.last['props'], {'tab': 'trend'});
    expect(a.pending, isEmpty);
  });

  test('failed sends are kept and retried', () async {
    final sink = FakeSink()..fail = true;
    final a = analytics(sink)..log('app_open');
    await a.flush();
    expect(a.pending.length, 1);
    sink.fail = false;
    await a.flush();
    expect(sink.sent.single['name'], 'app_open');
  });

  test('opting out drops queued events and stops logging', () async {
    final sink = FakeSink();
    final a = analytics(sink)..log('app_open');
    a.setEnabled(false);
    a.log('tab');
    await a.flush();
    expect(sink.sent, isEmpty);
  });

  test('app actions log behaviour, not health data', () async {
    final sink = FakeSink();
    final s = AppState(
      MemoryCoachRepository(),
      clock: () => DateTime(2026, 9, 29, 12),
      analytics: analytics(sink),
    );
    await s.load();
    await s.addMeal(
      name: '김치찌개',
      kcal: 450,
      proteinG: 20,
      carbsG: 30,
      fatG: 25,
      source: MealSource.search,
      slot: MealSlot.dinner,
    );
    await s.analytics.flush();
    final e = sink.sent.single;
    expect(e['name'], 'meal_log');
    expect(e['props'], {'source': 'search', 'slot': 'dinner', 'past': false});
    expect(e.toString(), isNot(contains('김치찌개')));
    expect(e.toString(), isNot(contains('450')));

    // The setting turns it off (and records the opt-out itself).
    await s.updateSettings(s.settings.copyWith(usageAnalytics: false));
    await s.addWorkout(WorkoutType.cardio, 30);
    await s.analytics.flush();
    expect(sink.sent.map((e) => e['name']), [
      'meal_log',
      'usage_analytics_off',
    ]);
  });
}
