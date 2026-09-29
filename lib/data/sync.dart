import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'entities.dart';
import 'food.dart';
import 'repository.dart';

/// One synced record: everything the app stores is split into rows keyed by
/// (kind, id), the shape of public.user_records (supabase/user_sync.sql).
typedef RecordKey = ({String kind, String id});

class RemoteRecord {
  final String kind;
  final String id;

  /// Null for a deletion.
  final Map<String, Object?>? data;
  final DateTime? updatedAt;
  const RemoteRecord(this.kind, this.id, this.data, {this.updatedAt});
  bool get deleted => data == null;
}

/// The signed-in user's rows on the server.
abstract class RecordStore {
  /// Rows changed after [since] (all rows when null), deletions included.
  Future<List<RemoteRecord>> fetch({DateTime? since});
  Future<void> upsert(List<RemoteRecord> rows);
  Future<void> deleteAll();
}

Map<RecordKey, Map<String, Object?>> recordsOf(AppData d) => {
  if (d.profile != null) (kind: 'profile', id: 'me'): d.profile!.toJson(),
  (kind: 'settings', id: 'me'): d.settings.toJson(),
  for (final w in d.weights) (kind: 'weight', id: w.date): w.toJson(),
  for (final m in d.meals) (kind: 'meal', id: m.id): m.toJson(),
  for (final m in d.savedMeals) (kind: 'savedMeal', id: m.id): m.toJson(),
  for (final w in d.workouts) (kind: 'workout', id: w.id): w.toJson(),
  for (final f in d.customFoods) (kind: 'customFood', id: f.id): f.toJson(),
  for (final f in d.remoteFoods) (kind: 'remoteFood', id: f.id): f.toJson(),
  for (final p in d.plans) (kind: 'plan', id: p.weekStart): p.toJson(),
};

AppData dataFromRecords(Map<RecordKey, Map<String, Object?>> r) {
  List<T> all<T>(String kind, T Function(Map<String, Object?>) f) => [
    for (final e in r.entries)
      if (e.key.kind == kind) f(e.value),
  ];
  final profile = r[(kind: 'profile', id: 'me')];
  final settings = r[(kind: 'settings', id: 'me')];
  return AppData(
    profile: profile == null ? null : UserProfile.fromJson(profile),
    settings: settings == null
        ? const AppSettings()
        : AppSettings.fromJson(settings),
    weights: all('weight', WeightEntry.fromJson),
    meals: all('meal', Meal.fromJson),
    savedMeals: all('savedMeal', SavedMeal.fromJson),
    workouts: all('workout', Workout.fromJson),
    customFoods: all('customFood', CustomFood.fromJson),
    remoteFoods: all('remoteFood', Food.fromJson),
    plans: all('plan', Plan.fromJson),
  );
}

String _hash(Map<String, Object?> data) =>
    sha1.convert(utf8.encode(jsonEncode(data))).toString().substring(0, 16);

String _k(RecordKey k) => '${k.kind}/${k.id}';

/// What was last agreed with the server, so pushes send only changes.
class SyncState {
  String? userId;
  DateTime? lastPull;
  Map<String, String> shadow; // "kind/id" -> hash of the synced data

  SyncState({this.userId, this.lastPull, Map<String, String>? shadow})
    : shadow = shadow ?? {};

  Map<String, Object?> toJson() => {
    'userId': userId,
    'lastPull': lastPull?.toIso8601String(),
    'shadow': shadow,
  };

  factory SyncState.fromJson(Map<String, Object?> j) => SyncState(
    userId: j['userId'] as String?,
    lastPull: j['lastPull'] == null
        ? null
        : DateTime.parse(j['lastPull'] as String),
    shadow: (j['shadow'] as Map?)?.cast<String, String>(),
  );
}

abstract class SyncStateStore {
  Future<SyncState> read();
  Future<void> write(SyncState s);
}

class PrefsSyncStateStore implements SyncStateStore {
  static const _key = 'adapt.v1.sync';
  final SharedPreferencesAsync _prefs;
  PrefsSyncStateStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  @override
  Future<SyncState> read() async {
    try {
      final raw = await _prefs.getString(_key);
      if (raw != null) {
        return SyncState.fromJson(
          (jsonDecode(raw) as Map).cast<String, Object?>(),
        );
      }
    } catch (_) {}
    return SyncState();
  }

  @override
  Future<void> write(SyncState s) async {
    try {
      await _prefs.setString(_key, jsonEncode(s.toJson()));
    } catch (_) {}
  }
}

class MemorySyncStateStore implements SyncStateStore {
  SyncState state = SyncState();
  @override
  Future<SyncState> read() async => state;
  @override
  Future<void> write(SyncState s) async => state = s;
}

/// Local repository that also keeps the signed-in user's server copy in step.
///
/// Every save goes to the device first (the app works offline and signed
/// out), then the changed records are pushed shortly after. [sync] pushes
/// pending changes and pulls what other devices changed. The first sync of
/// an account pulls first and lets the server win, so signing in on a new
/// device restores the account instead of overwriting it; records that only
/// exist on this device are then uploaded.
class SyncingRepository implements CoachRepository {
  final CoachRepository local;
  final SyncStateStore stateStore;
  final Duration pushDelay;

  RecordStore? _store;
  AppData _mirror = AppData();
  SyncState _state = SyncState();
  Timer? _pushTimer;
  Future<bool>? _running;

  SyncingRepository(
    this.local, {
    SyncStateStore? stateStore,
    this.pushDelay = const Duration(milliseconds: 1500),
  }) : stateStore = stateStore ?? PrefsSyncStateStore();

  bool get attached => _store != null;

  /// Server time of the newest pulled change (null before the first sync).
  DateTime? get lastSynced => _state.lastPull;

  /// Device time of the last successful sync, for display.
  DateTime? syncedAt;

  /// Starts syncing for [userId]. A different user than last time starts
  /// from scratch (nothing is assumed to be on their server copy yet).
  Future<void> attach(String userId, RecordStore store) async {
    _state = await stateStore.read();
    if (_state.userId != userId) {
      _state = SyncState(userId: userId);
      await stateStore.write(_state);
    }
    _store = store;
  }

  /// Stops syncing and forgets the account (the server copy is kept).
  Future<void> detach() async {
    _pushTimer?.cancel();
    _store = null;
    syncedAt = null;
    _state = SyncState();
    await stateStore.write(_state);
  }

  @override
  Future<AppData> load() async => _mirror = await local.load();

  /// Pushes local changes and pulls remote ones. True when the pull changed
  /// local data (the caller should reload it).
  Future<bool> sync() {
    final running = _running;
    if (running != null) return running;
    final f = _sync()
        .then((changed) {
          syncedAt = DateTime.now();
          return changed;
        })
        .whenComplete(() => _running = null);
    _running = f;
    return f;
  }

  Future<bool> _sync() async {
    final store = _store;
    if (store == null) return false;
    _pushTimer?.cancel();
    if (_state.lastPull == null) {
      final changed = await _pull(store);
      await _push(store);
      return changed;
    }
    await _push(store);
    return _pull(store);
  }

  Future<void> _push(RecordStore store) async {
    final current = recordsOf(_mirror);
    final rows = <RemoteRecord>[];
    final hashes = <String, String>{};
    for (final e in current.entries) {
      final h = _hash(e.value);
      hashes[_k(e.key)] = h;
      if (_state.shadow[_k(e.key)] != h) {
        rows.add(RemoteRecord(e.key.kind, e.key.id, e.value));
      }
    }
    for (final k in _state.shadow.keys) {
      if (!hashes.containsKey(k)) {
        final i = k.indexOf('/');
        rows.add(RemoteRecord(k.substring(0, i), k.substring(i + 1), null));
      }
    }
    if (rows.isEmpty) return;
    await store.upsert(rows);
    _state.shadow = hashes;
    await stateStore.write(_state);
  }

  Future<bool> _pull(RecordStore store) async {
    // A little overlap guards against clock skew; re-applying is harmless.
    final since = _state.lastPull?.subtract(const Duration(seconds: 5));
    final rows = await store.fetch(since: since);
    final records = recordsOf(_mirror);
    var changed = false;
    DateTime? newest = _state.lastPull;
    for (final r in rows) {
      final key = (kind: r.kind, id: r.id);
      if (r.deleted) {
        if (records.remove(key) != null) changed = true;
        _state.shadow.remove(_k(key));
      } else {
        final h = _hash(r.data!);
        final mine = records[key];
        if (mine == null || _hash(mine) != h) changed = true;
        records[key] = r.data!;
        _state.shadow[_k(key)] = h;
      }
      final at = r.updatedAt;
      if (at != null && (newest == null || at.isAfter(newest))) newest = at;
    }
    // Only server timestamps: a device clock ahead of the server would skip
    // other devices' changes. The epoch marks "synced once, nothing yet".
    _state.lastPull = newest ?? DateTime.utc(1970);
    if (changed) {
      _mirror = dataFromRecords(records);
      await _writeLocal(_mirror);
    }
    await stateStore.write(_state);
    return changed;
  }

  Future<void> _writeLocal(AppData d) async {
    await local.saveProfile(d.profile);
    await local.saveSettings(d.settings);
    await local.saveWeights(d.weights);
    await local.saveMeals(d.meals);
    await local.saveSavedMeals(d.savedMeals);
    await local.saveWorkouts(d.workouts);
    await local.saveCustomFoods(d.customFoods);
    await local.saveRemoteFoods(d.remoteFoods);
    await local.savePlans(d.plans);
  }

  void _changed() {
    if (_store == null) return;
    _pushTimer?.cancel();
    _pushTimer = Timer(pushDelay, () async {
      final store = _store;
      if (store == null) return;
      try {
        await _push(store);
      } catch (_) {
        // Offline: the next sync() retries; nothing is lost locally.
      }
    });
  }

  @override
  Future<void> saveProfile(UserProfile? profile) async {
    _mirror.profile = profile;
    await local.saveProfile(profile);
    _changed();
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _mirror.settings = settings;
    await local.saveSettings(settings);
    _changed();
  }

  @override
  Future<void> saveWeights(List<WeightEntry> weights) async {
    _mirror.weights = [...weights];
    await local.saveWeights(weights);
    _changed();
  }

  @override
  Future<void> saveMeals(List<Meal> meals) async {
    _mirror.meals = [...meals];
    await local.saveMeals(meals);
    _changed();
  }

  @override
  Future<void> saveSavedMeals(List<SavedMeal> savedMeals) async {
    _mirror.savedMeals = [...savedMeals];
    await local.saveSavedMeals(savedMeals);
    _changed();
  }

  @override
  Future<void> saveWorkouts(List<Workout> workouts) async {
    _mirror.workouts = [...workouts];
    await local.saveWorkouts(workouts);
    _changed();
  }

  @override
  Future<void> saveCustomFoods(List<CustomFood> foods) async {
    _mirror.customFoods = [...foods];
    await local.saveCustomFoods(foods);
    _changed();
  }

  /// Device-only: not part of the synced records.
  @override
  Future<void> saveRecentSearches(List<String> queries) async {
    _mirror.recentSearches = [...queries];
    await local.saveRecentSearches(queries);
  }

  @override
  Future<void> saveRemoteFoods(List<Food> foods) async {
    _mirror.remoteFoods = [...foods];
    await local.saveRemoteFoods(foods);
    _changed();
  }

  @override
  Future<void> savePlans(List<Plan> plans) async {
    _mirror.plans = [...plans];
    await local.savePlans(plans);
    _changed();
  }

  /// Deletes this device's data, and the account's server copy when signed
  /// in ("delete all my data").
  @override
  Future<void> deleteAll() async {
    _pushTimer?.cancel();
    await local.deleteAll();
    _mirror = AppData();
    final store = _store;
    if (store != null) {
      await store.deleteAll();
      _state.shadow = {};
      await stateStore.write(_state);
    }
  }

  /// Clears only this device (used on sign-out, so the next account on this
  /// device doesn't inherit the data). The server copy is untouched.
  Future<void> clearDevice() async {
    _pushTimer?.cancel();
    await local.deleteAll();
    _mirror = AppData();
  }
}
