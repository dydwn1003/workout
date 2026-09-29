import 'package:adapt_coach/data/entities.dart';
import 'package:adapt_coach/data/repository.dart';
import 'package:adapt_coach/data/sync.dart';
import 'package:adapt_coach/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory stand-in for public.user_records of one user.
class FakeStore implements RecordStore {
  final rows = <String, RemoteRecord>{};
  var clock = DateTime.utc(2026, 9, 29);
  var upserts = 0;

  @override
  Future<List<RemoteRecord>> fetch({DateTime? since}) async => [
    for (final r in rows.values)
      if (since == null || r.updatedAt!.isAfter(since)) r,
  ];

  @override
  Future<void> upsert(List<RemoteRecord> list) async {
    upserts++;
    for (final r in list) {
      clock = clock.add(const Duration(seconds: 10));
      rows['${r.kind}/${r.id}'] = RemoteRecord(
        r.kind,
        r.id,
        r.data,
        updatedAt: clock,
      );
    }
  }

  @override
  Future<void> deleteAll() async {
    for (final k in rows.keys.toList()) {
      final r = rows[k]!;
      clock = clock.add(const Duration(seconds: 10));
      rows[k] = RemoteRecord(r.kind, r.id, null, updatedAt: clock);
    }
  }

  List<String> live(String kind) => [
    for (final r in rows.values)
      if (r.kind == kind && !r.deleted) r.id,
  ];
}

void main() {
  final now = DateTime(2026, 9, 29, 12);

  Future<(AppState, SyncingRepository)> device(FakeStore store) async {
    final repo = SyncingRepository(
      MemoryCoachRepository(),
      stateStore: MemorySyncStateStore(),
      pushDelay: Duration.zero,
    );
    final s = AppState(repo, clock: () => now);
    await s.load();
    await repo.attach('user-1', store);
    return (s, repo);
  }

  Future<void> meal(AppState s, String name, {int kcal = 300}) => s.addMeal(
    name: name,
    kcal: kcal.toDouble(),
    proteinG: 10,
    carbsG: 30,
    fatG: 10,
    source: MealSource.manual,
  );

  test('records round-trip through AppData', () async {
    final s = AppState(MemoryCoachRepository(), clock: () => now);
    await s.load();
    await s.loadDemoData(korean: true);
    final repo = s.repo as MemoryCoachRepository;
    final back = dataFromRecords(recordsOf(repo.data));
    expect(back.meals.length, repo.data.meals.length);
    expect(back.weights.length, repo.data.weights.length);
    expect(back.plans.length, repo.data.plans.length);
    expect(back.profile!.toJson(), repo.data.profile!.toJson());
  });

  test('two devices share meals, edits and deletions', () async {
    final store = FakeStore();
    final (a, repoA) = await device(store);
    final (b, repoB) = await device(store);

    await meal(a, '김밥');
    await meal(a, '라면');
    await a.syncNow();
    expect(store.live('meal').length, 2);

    await b.syncNow();
    expect(b.meals.map((m) => m.name), containsAll(['김밥', '라면']));

    // B deletes one; A sees it gone after its next sync.
    await b.deleteMeal(b.meals.firstWhere((m) => m.name == '라면').id);
    await b.syncNow();
    await a.syncNow();
    expect(a.meals.map((m) => m.name), ['김밥']);

    // Nothing changed: no upload.
    final before = store.upserts;
    await a.syncNow();
    expect(store.upserts, before);
    expect(repoA.attached && repoB.attached, isTrue);
  });

  test('first sign-in on a new device restores the account and keeps '
      'local-only records', () async {
    final store = FakeStore();
    final (a, _) = await device(store);
    await a.loadDemoData(korean: true);
    await a.syncNow();
    final profile = a.profile!.toJson();

    // A fresh device that logged one meal before signing in.
    final repo = SyncingRepository(
      MemoryCoachRepository(),
      stateStore: MemorySyncStateStore(),
      pushDelay: Duration.zero,
    );
    final b = AppState(repo, clock: () => now);
    await b.load();
    await meal(b, '오프라인 기록');
    await repo.attach('user-1', store);
    await b.syncNow();

    expect(b.onboarded, isTrue);
    expect(b.profile!.toJson(), profile);
    expect(b.meals.map((m) => m.name), contains('오프라인 기록'));
    expect(b.meals.length, a.meals.length + 1);
    expect(store.live('meal'), contains(b.meals.last.id));
  });

  test('delete all clears the server copy for other devices', () async {
    final store = FakeStore();
    final (a, _) = await device(store);
    final (b, _) = await device(store);
    await meal(a, '김밥');
    await a.syncNow();
    await b.syncNow();
    expect(b.meals, isNotEmpty);

    await a.deleteAll();
    expect(store.live('meal'), isEmpty);
    await b.syncNow();
    expect(b.meals, isEmpty);
  });

  test('signing in as another user starts from scratch', () async {
    final store = FakeStore();
    final repo = SyncingRepository(
      MemoryCoachRepository(),
      stateStore: MemorySyncStateStore(),
      pushDelay: Duration.zero,
    );
    await repo.load();
    await repo.attach('user-1', store);
    await repo.saveMeals([
      Meal(
        id: 'm1',
        date: '2026-09-29',
        time: now,
        name: 'x',
        kcal: 1,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
        source: MealSource.manual,
        slot: MealSlot.lunch,
      ),
    ]);
    await repo.sync();
    expect(repo.lastSynced, isNotNull);
    await repo.attach('user-2', FakeStore());
    expect(repo.lastSynced, isNull);
  });
}
