import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'entities.dart';
import 'food.dart';

/// Snapshot of everything stored for the (single, local) user.
class AppData {
  UserProfile? profile;
  AppSettings settings;
  List<WeightEntry> weights;
  List<Meal> meals;
  List<SavedMeal> savedMeals;
  List<Workout> workouts;
  List<CustomFood> customFoods;

  /// Server foods (see RemoteFoodSearch) the user logged, so they keep
  /// showing up in recent foods offline.
  List<Food> remoteFoods;
  List<Plan> plans;

  /// Food search queries, newest first (this device only, not synced).
  List<String> recentSearches;

  AppData({
    this.profile,
    this.settings = const AppSettings(),
    List<WeightEntry>? weights,
    List<Meal>? meals,
    List<SavedMeal>? savedMeals,
    List<Workout>? workouts,
    List<CustomFood>? customFoods,
    List<Food>? remoteFoods,
    List<Plan>? plans,
    List<String>? recentSearches,
  }) : recentSearches = recentSearches ?? [],
       weights = weights ?? [],
       meals = meals ?? [],
       savedMeals = savedMeals ?? [],
       workouts = workouts ?? [],
       customFoods = customFoods ?? [],
       remoteFoods = remoteFoods ?? [],
       plans = plans ?? [];
}

/// Storage abstraction. The MVP ships a local implementation; a Firebase
/// implementation can be added later without touching the UI.
abstract class CoachRepository {
  Future<AppData> load();
  Future<void> saveProfile(UserProfile? profile);
  Future<void> saveSettings(AppSettings settings);
  Future<void> saveWeights(List<WeightEntry> weights);
  Future<void> saveMeals(List<Meal> meals);
  Future<void> saveSavedMeals(List<SavedMeal> savedMeals);
  Future<void> saveWorkouts(List<Workout> workouts);
  Future<void> saveCustomFoods(List<CustomFood> foods);
  Future<void> saveRemoteFoods(List<Food> foods);
  Future<void> savePlans(List<Plan> plans);
  Future<void> saveRecentSearches(List<String> queries);
  Future<void> deleteAll();
}

/// Local, offline repository backed by shared_preferences (JSON per
/// collection). Works on Android, iOS and web.
class LocalCoachRepository implements CoachRepository {
  static const _prefix = 'adapt.v1.';
  final SharedPreferencesAsync _prefs;

  LocalCoachRepository([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  // Storage can be unavailable (e.g. blocked site data in a browser). The app
  // then keeps working in memory for the session instead of crashing.
  Future<Object?> _read(String key) async {
    try {
      final raw = await _prefs.getString('$_prefix$key');
      return raw == null ? null : jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(String key, Object? value) async {
    try {
      await _prefs.setString('$_prefix$key', jsonEncode(value));
    } catch (_) {}
  }

  List<T> _list<T>(Object? raw, T Function(Map<String, Object?>) f) =>
      raw == null
      ? <T>[]
      : (raw as List)
            .map((e) => f((e as Map).cast<String, Object?>()))
            .toList();

  @override
  Future<AppData> load() async {
    final profile = await _read('profile');
    final settings = await _read('settings');
    return AppData(
      profile: profile == null
          ? null
          : UserProfile.fromJson((profile as Map).cast<String, Object?>()),
      settings: settings == null
          ? const AppSettings()
          : AppSettings.fromJson((settings as Map).cast<String, Object?>()),
      weights: _list(await _read('weights'), WeightEntry.fromJson),
      meals: _list(await _read('meals'), Meal.fromJson),
      savedMeals: _list(await _read('savedMeals'), SavedMeal.fromJson),
      workouts: _list(await _read('workouts'), Workout.fromJson),
      customFoods: _list(await _read('customFoods'), CustomFood.fromJson),
      remoteFoods: _list(await _read('remoteFoods'), Food.fromJson),
      plans: _list(await _read('plans'), Plan.fromJson),
      recentSearches: [
        for (final q in (await _read('recentSearches') as List? ?? const []))
          q as String,
      ],
    );
  }

  @override
  Future<void> saveProfile(UserProfile? profile) =>
      _write('profile', profile?.toJson());

  @override
  Future<void> saveSettings(AppSettings settings) =>
      _write('settings', settings.toJson());

  @override
  Future<void> saveWeights(List<WeightEntry> weights) =>
      _write('weights', weights.map((e) => e.toJson()).toList());

  @override
  Future<void> saveMeals(List<Meal> meals) =>
      _write('meals', meals.map((e) => e.toJson()).toList());

  @override
  Future<void> saveSavedMeals(List<SavedMeal> savedMeals) =>
      _write('savedMeals', savedMeals.map((e) => e.toJson()).toList());

  @override
  Future<void> saveWorkouts(List<Workout> workouts) =>
      _write('workouts', workouts.map((e) => e.toJson()).toList());

  @override
  Future<void> saveCustomFoods(List<CustomFood> foods) =>
      _write('customFoods', foods.map((e) => e.toJson()).toList());

  @override
  Future<void> saveRemoteFoods(List<Food> foods) =>
      _write('remoteFoods', foods.map((e) => e.toJson()).toList());

  @override
  Future<void> saveRecentSearches(List<String> queries) =>
      _write('recentSearches', queries);

  @override
  Future<void> savePlans(List<Plan> plans) =>
      _write('plans', plans.map((e) => e.toJson()).toList());

  @override
  Future<void> deleteAll() async {
    try {
      final keys = await _prefs.getKeys();
      for (final k in keys.where((k) => k.startsWith(_prefix))) {
        await _prefs.remove(k);
      }
    } catch (_) {}
  }
}

/// In-memory repository for tests.
class MemoryCoachRepository implements CoachRepository {
  AppData data = AppData();

  @override
  Future<AppData> load() async => data;
  @override
  Future<void> saveProfile(UserProfile? profile) async =>
      data.profile = profile;
  @override
  Future<void> saveSettings(AppSettings settings) async =>
      data.settings = settings;
  @override
  Future<void> saveWeights(List<WeightEntry> weights) async =>
      data.weights = [...weights];
  @override
  Future<void> saveMeals(List<Meal> meals) async => data.meals = [...meals];
  @override
  Future<void> saveSavedMeals(List<SavedMeal> savedMeals) async =>
      data.savedMeals = [...savedMeals];
  @override
  Future<void> saveWorkouts(List<Workout> workouts) async =>
      data.workouts = [...workouts];
  @override
  Future<void> saveCustomFoods(List<CustomFood> foods) async =>
      data.customFoods = [...foods];
  @override
  Future<void> saveRemoteFoods(List<Food> foods) async =>
      data.remoteFoods = [...foods];
  @override
  Future<void> savePlans(List<Plan> plans) async => data.plans = [...plans];
  @override
  Future<void> saveRecentSearches(List<String> queries) async =>
      data.recentSearches = [...queries];
  @override
  Future<void> deleteAll() async => data = AppData();
}
