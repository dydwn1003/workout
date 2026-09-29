import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/coach_engine/coach_engine.dart';
import '../data/entities.dart';
import '../data/food.dart';
import '../data/food_db.g.dart';
import '../data/remote_food_search.dart';
import '../data/repository.dart';

class WorkoutWeek {
  final DateTime start;
  final int strength;
  final int cardio;
  final int minutes;
  const WorkoutWeek({
    required this.start,
    required this.strength,
    required this.cardio,
    required this.minutes,
  });
  int get sessions => strength + cardio;
}

class AppState extends ChangeNotifier {
  final CoachRepository repo;
  final DateTime Function() clock;
  AppData _data = AppData();
  bool loaded = false;

  /// Full server food search; null when not configured (tests, offline builds).
  final RemoteFoodSearch? remoteSearch;

  AppState(this.repo, {DateTime Function()? clock, this.remoteSearch})
    : clock = clock ?? DateTime.now;

  Future<void> load() async {
    _data = await repo.load();
    _sort();
    loaded = true;
    notifyListeners();
  }

  void _sort() {
    _data.weights.sort((a, b) => a.date.compareTo(b.date));
    _data.meals.sort((a, b) => a.time.compareTo(b.time));
    _data.workouts.sort((a, b) => a.date.compareTo(b.date));
    _data.plans.sort((a, b) => a.weekStart.compareTo(b.weekStart));
  }

  // ---------------------------------------------------------------------------
  // Read model
  // ---------------------------------------------------------------------------

  DateTime get today => dayOnly(clock());
  UserProfile? get profile => _data.profile;
  AppSettings get settings => _data.settings;
  List<WeightEntry> get weights => List.unmodifiable(_data.weights);
  List<Meal> get meals => List.unmodifiable(_data.meals);
  List<SavedMeal> get savedMeals => List.unmodifiable(_data.savedMeals);
  List<Workout> get workouts => List.unmodifiable(_data.workouts);
  List<CustomFood> get customFoods => List.unmodifiable(_data.customFoods);

  /// Custom foods first so they win ties in search.
  List<Food> get allFoods => [
    for (final c in _data.customFoods) c.toFood(),
    ...builtInFoods,
  ];

  static final _builtInById = {for (final f in builtInFoods) f.id: f};

  Food? foodById(String id) {
    for (final c in _data.customFoods) {
      if (c.id == id) return c.toFood();
    }
    final built = _builtInById[id];
    if (built != null) return built;
    for (final f in _data.remoteFoods) {
      if (f.id == id) return f;
    }
    return null;
  }

  static const _remoteFoodsKept = 300;

  /// Keeps a server food the user is logging so recent foods can show it
  /// without the network. Built-in and custom foods need nothing.
  Future<void> rememberFood(Food f) async {
    if (f.custom || _builtInById.containsKey(f.id)) return;
    _data.remoteFoods
      ..removeWhere((x) => x.id == f.id)
      ..add(f);
    if (_data.remoteFoods.length > _remoteFoodsKept) {
      _data.remoteFoods.removeRange(
        0,
        _data.remoteFoods.length - _remoteFoodsKept,
      );
    }
    await repo.saveRemoteFoods(_data.remoteFoods);
  }

  /// Server results for [q] that local search didn't already find.
  Future<List<Food>> searchRemoteFoods(String q, List<Food> local) async {
    final remote = remoteSearch;
    if (remote == null) return const [];
    final seenIds = {for (final f in local) f.id};
    final seenNames = {for (final f in local) f.name.toLowerCase()};
    return [
      for (final f in await remote.search(q))
        if (!seenIds.contains(f.id) &&
            !seenNames.contains(f.name.toLowerCase()))
          f,
    ];
  }

  /// Distinct foods logged from search recently (newest first).
  List<Food> recentFoods({int limit = 8}) {
    final seen = <String>{};
    final out = <Food>[];
    for (final m in _data.meals.reversed) {
      final id = m.foodId;
      if (id == null || !seen.add(id)) continue;
      final f = foodById(id);
      if (f != null) out.add(f);
      if (out.length >= limit) break;
    }
    return out;
  }

  List<Food> searchAllFoods(String q) => searchFoods(allFoods, q);

  Future<Food> addCustomFood({
    required String name,
    required String unitLabel,
    double? grams,
    required double kcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) async {
    final c = CustomFood(
      id: 'c${clock().microsecondsSinceEpoch}',
      name: name,
      unitLabel: unitLabel,
      grams: grams,
      kcal: kcal,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
    );
    _data.customFoods.add(c);
    await repo.saveCustomFoods(_data.customFoods);
    notifyListeners();
    return c.toFood();
  }

  Future<void> deleteCustomFood(String id) async {
    _data.customFoods.removeWhere((c) => c.id == id);
    await repo.saveCustomFoods(_data.customFoods);
    notifyListeners();
  }

  List<Plan> get plans => List.unmodifiable(_data.plans);
  bool get onboarded => _data.profile != null && _data.plans.isNotEmpty;

  Plan? get currentPlan => _data.plans.isEmpty ? null : _data.plans.last;

  /// The plan that was in effect on [d] (falls back to the first plan).
  Plan? planOn(DateTime d) {
    if (_data.plans.isEmpty) return null;
    final k = dateKey(d);
    Plan? found;
    for (final p in _data.plans) {
      if (p.weekStart.compareTo(k) <= 0) found = p;
    }
    return found ?? _data.plans.first;
  }

  WeightEntry? weightOn(DateTime d) {
    final k = dateKey(d);
    for (final w in _data.weights) {
      if (w.date == k) return w;
    }
    return null;
  }

  WeightEntry? get latestWeight =>
      _data.weights.isEmpty ? null : _data.weights.last;

  double? get latestBodyFat {
    for (final w in _data.weights.reversed) {
      if (w.bodyFatPct != null) return w.bodyFatPct;
    }
    return null;
  }

  List<Meal> mealsOn(DateTime d) {
    final k = dateKey(d);
    return _data.meals.where((m) => m.date == k).toList();
  }

  Macros totalsOn(DateTime d) {
    final ms = mealsOn(d);
    return Macros(
      kcal: ms.fold(0, (a, m) => a + m.kcal),
      proteinG: ms.fold(0, (a, m) => a + m.proteinG),
      carbsG: ms.fold(0, (a, m) => a + m.carbsG),
      fatG: ms.fold(0, (a, m) => a + m.fatG),
    );
  }

  DateTime? get _firstDataDay {
    DateTime? first;
    if (_data.weights.isNotEmpty) {
      first = parseDateKey(_data.weights.first.date);
    }
    if (_data.meals.isNotEmpty) {
      final m = parseDateKey(_data.meals.first.date);
      if (first == null || m.isBefore(first)) first = m;
    }
    return first;
  }

  /// Contiguous day logs from the first data day to today.
  List<DayLog> dayLogs() {
    final first = _firstDataDay;
    if (first == null) return [];
    final weightsByDay = {for (final w in _data.weights) w.date: w.kg};
    final intakeByDay = <String, double>{};
    for (final m in _data.meals) {
      intakeByDay[m.date] = (intakeByDay[m.date] ?? 0) + m.kcal;
    }
    final out = <DayLog>[];
    for (var d = first; !d.isAfter(today); d = _addDays(d, 1)) {
      final k = dateKey(d);
      out.add(
        DayLog(date: d, weightKg: weightsByDay[k], intakeKcal: intakeByDay[k]),
      );
    }
    return out;
  }

  static DateTime _addDays(DateTime d, int n) =>
      DateTime(d.year, d.month, d.day + n);

  /// (date, raw weight, trend) for each day.
  List<(DateTime, double?, double?)> trendPoints() {
    final logs = dayLogs();
    final trend = trendSeries(logs.map((d) => d.weightKg).toList());
    return [
      for (var i = 0; i < logs.length; i++)
        (logs[i].date, logs[i].weightKg, trend[i]),
    ];
  }

  double? get trendWeight {
    final pts = trendPoints();
    return pts.isEmpty ? null : pts.last.$3;
  }

  /// Trend change over the last 7 days (kg).
  double? get weeklyTrendChange {
    final pts = trendPoints();
    if (pts.length < 8 ||
        pts.last.$3 == null ||
        pts[pts.length - 8].$3 == null) {
      return null;
    }
    return pts.last.$3! - pts[pts.length - 8].$3!;
  }

  EtaRange? get eta {
    final p = profile;
    final target = p?.targetWeightKg;
    if (p == null || target == null) return null;
    final pts = trendPoints();
    return etaWeeks(
      trend: pts.map((e) => e.$3).toList(),
      targetKg: target,
      plannedKgPerWeek: plannedKgPerWeek(
        p.goalType,
        p.pace,
        trendWeight ?? latestWeight?.kg ?? 70,
      ),
    );
  }

  /// Distinct recently eaten meals (newest first), excluding saved ones.
  List<Meal> recentMeals({int limit = 6, int days = 14}) {
    final since = dateKey(_addDays(today, -days));
    final saved = {for (final s in _data.savedMeals) s.name};
    final seen = <String>{};
    final out = <Meal>[];
    for (final m in _data.meals.reversed) {
      if (m.date.compareTo(since) < 0) break;
      if (saved.contains(m.name) || !seen.add(m.name)) continue;
      out.add(m);
      if (out.length >= limit) break;
    }
    return out;
  }

  List<Workout> workoutsOn(DateTime d) {
    final k = dateKey(d);
    return _data.workouts.where((w) => w.date == k).toList();
  }

  /// Workouts in the last 7 days (including today).
  int get weekWorkouts {
    final since = dateKey(_addDays(today, -6));
    return _data.workouts.where((w) => w.date.compareTo(since) >= 0).length;
  }

  /// When the last 2 weeks of logged training differ enough from the
  /// profile's weekly sessions to change the activity factor, returns the
  /// observed (strength, cardio) sessions per week. Only for users who have
  /// been logging workouts for at least 2 weeks.
  (int, int)? get workoutSuggestion {
    final p = profile;
    if (p == null || _data.workouts.isEmpty) return null;
    final since = _addDays(today, -13);
    if (parseDateKey(_data.workouts.first.date).isAfter(since)) return null;
    final recent = _data.workouts
        .where((w) => w.date.compareTo(dateKey(since)) >= 0)
        .toList();
    final strength =
        (recent.where((w) => w.type == WorkoutType.strength).length / 2)
            .round();
    final cardio =
        (recent.where((w) => w.type == WorkoutType.cardio).length / 2).round();
    final planned = p.strengthPerWeek + p.cardioPerWeek;
    if (CoachConstants.activityFactor(strength + cardio) ==
        CoachConstants.activityFactor(planned)) {
      return null;
    }
    return (strength, cardio);
  }

  Future<void> applyWorkoutSuggestion() async {
    final sug = workoutSuggestion;
    final p = profile;
    if (sug == null || p == null) return;
    await updateProfile(
      UserProfile(
        sex: p.sex,
        birthYear: p.birthYear,
        heightCm: p.heightCm,
        goalType: p.goalType,
        pace: p.pace,
        strengthPerWeek: sug.$1,
        cardioPerWeek: sug.$2,
        targetWeightKg: p.targetWeightKg,
        targetBodyFatPct: p.targetBodyFatPct,
        createdAt: p.createdAt,
      ),
    );
  }

  /// Rolling 7-day buckets ending today, oldest first.
  List<WorkoutWeek> workoutWeeks({int weeks = 8}) {
    return [
      for (var i = weeks - 1; i >= 0; i--)
        (() {
          final end = _addDays(today, -7 * i);
          final start = _addDays(end, -6);
          final from = dateKey(start), to = dateKey(end);
          final ws = _data.workouts
              .where(
                (w) => w.date.compareTo(from) >= 0 && w.date.compareTo(to) <= 0,
              )
              .toList();
          return WorkoutWeek(
            start: start,
            strength: ws.where((w) => w.type == WorkoutType.strength).length,
            cardio: ws.where((w) => w.type == WorkoutType.cardio).length,
            minutes: ws.fold(0, (a, w) => a + w.minutes),
          );
        })(),
    ];
  }

  /// Time-based training feedback for the last 7 days.
  List<WorkoutTip> workoutTips() {
    final p = profile;
    if (p == null) return const [];
    final weeks = workoutWeeks(weeks: 4);
    final since = dateKey(_addDays(today, -6));
    final recent = _data.workouts.where((w) => w.date.compareTo(since) >= 0);
    final prior = weeks.sublist(0, 3);
    final hasPrior =
        _data.workouts.isNotEmpty &&
        !parseDateKey(_data.workouts.first.date).isAfter(_addDays(today, -27));
    final days = {for (final w in _data.workouts) w.date};
    var d = today;
    if (!days.contains(dateKey(d))) d = _addDays(d, -1);
    var streak = 0;
    while (days.contains(dateKey(d))) {
      streak++;
      d = _addDays(d, -1);
    }
    return workoutFeedback(
      WorkoutSummary(
        strengthDays: {
          for (final w in recent)
            if (w.type == WorkoutType.strength) w.date,
        }.length,
        cardioMinutes: recent
            .where((w) => w.type == WorkoutType.cardio)
            .fold(0, (a, w) => a + w.minutes),
        totalMinutes: recent.fold(0, (a, w) => a + w.minutes),
        sessions: recent.length,
        plannedSessions: p.strengthPerWeek + p.cardioPerWeek,
        previousAvgMinutes: hasPrior
            ? prior.fold(0, (a, w) => a + w.minutes) / 3
            : null,
        consecutiveDays: streak,
        goalType: p.goalType,
      ),
    );
  }

  /// Last 7 days ending today: (date, meals logged, weighed in, worked out).
  List<(DateTime, bool, bool, bool)> weekLog() {
    final mealDays = {for (final m in _data.meals) m.date};
    final weighDays = {for (final w in _data.weights) w.date};
    final workoutDays = {for (final w in _data.workouts) w.date};
    return [
      for (var i = 6; i >= 0; i--)
        (() {
          final d = _addDays(today, -i);
          final k = dateKey(d);
          return (
            d,
            mealDays.contains(k),
            weighDays.contains(k),
            workoutDays.contains(k),
          );
        })(),
    ];
  }

  /// Days with any log (meal, weight or workout), as [dateKey]s.
  Set<String> get loggedDays => {
    for (final m in _data.meals) m.date,
    for (final w in _data.weights) w.date,
    for (final w in _data.workouts) w.date,
  };

  /// First day of the log calendar: the start of the plan, or an earlier
  /// log (e.g. sample data), never after today.
  DateTime get logStart {
    var start = profile?.createdAt ?? today;
    for (final k in loggedDays) {
      final d = DateTime.parse(k);
      if (d.isBefore(start)) start = d;
    }
    start = dayOnly(start);
    return start.isAfter(today) ? today : start;
  }

  /// Consecutive days with any log (meal, weight or workout), counting back from
  /// today (or yesterday, if today has nothing yet).
  int get loggingStreak {
    final days = loggedDays;
    var d = today;
    if (!days.contains(dateKey(d))) d = _addDays(d, -1);
    var n = 0;
    while (days.contains(dateKey(d))) {
      n++;
      d = _addDays(d, -1);
    }
    return n;
  }

  /// Longest run of consecutive logged days since [logStart].
  int get longestLoggingStreak {
    final days = loggedDays;
    var best = 0, run = 0;
    for (var d = logStart; !d.isAfter(today); d = _addDays(d, 1)) {
      run = days.contains(dateKey(d)) ? run + 1 : 0;
      if (run > best) best = run;
    }
    return best;
  }

  bool get muscleWarning {
    if (profile?.goalType == GoalType.maintain ||
        profile?.goalType == GoalType.gain) {
      return false;
    }
    return muscleLossWarning([
      for (final w in _data.weights)
        if (w.skeletalMuscleKg != null)
          (parseDateKey(w.date), w.skeletalMuscleKg!),
    ]);
  }

  /// Next scheduled check-in: the first configured weekday at least 4 days
  /// after the current plan started.
  DateTime? get nextCheckinDate {
    final plan = currentPlan;
    if (plan == null) return null;
    var d = _addDays(parseDateKey(plan.weekStart), 4);
    while (d.weekday != settings.checkinWeekday) {
      d = _addDays(d, 1);
    }
    return d;
  }

  bool get checkinDue {
    final next = nextCheckinDate;
    return next != null && !today.isBefore(next);
  }

  CheckinResult? runCheckin() {
    final p = profile;
    final plan = currentPlan;
    if (p == null || plan == null) return null;
    // Today's meal log is usually incomplete, so only its weight is used.
    final logs = [
      for (final d in dayLogs())
        d.date == today ? DayLog(date: d.date, weightKg: d.weightKg) : d,
    ];
    if (logs.isEmpty) return null;
    return weeklyCheckin(
      profile: p.coachProfile,
      goal: p.coachGoal,
      days: logs,
      today: today,
      previousTdee: plan.tdeeEst,
      bodyFatPct: latestBodyFat,
    );
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  Future<void> completeOnboarding({
    required UserProfile profile,
    required double weightKg,
    double? bodyFatPct,
    double? skeletalMuscleKg,
  }) async {
    _data.profile = profile;
    await repo.saveProfile(profile);
    await upsertWeight(
      WeightEntry(
        date: dateKey(today),
        kg: weightKg,
        bodyFatPct: bodyFatPct,
        skeletalMuscleKg: skeletalMuscleKg,
      ),
      notify: false,
    );
    final init = initialPlan(
      profile: profile.coachProfile,
      goal: profile.coachGoal,
      weightKg: weightKg,
      today: today,
      bodyFatPct: bodyFatPct,
    );
    await _addPlan(
      Plan(
        weekStart: dateKey(today),
        targetKcal: init.macros.kcal,
        proteinG: init.macros.proteinG,
        carbsG: init.macros.carbsG,
        fatG: init.macros.fatG,
        tdeeEst: init.tdee,
        status: PlanStatus.initial,
      ),
    );
    _data.settings = settings.copyWith(consentedAt: clock());
    await repo.saveSettings(_data.settings);
    notifyListeners();
  }

  Future<void> _addPlan(Plan plan) async {
    _data.plans.removeWhere((p) => p.weekStart == plan.weekStart);
    _data.plans.add(plan);
    _sort();
    await repo.savePlans(_data.plans);
  }

  Future<void> upsertWeight(WeightEntry e, {bool notify = true}) async {
    _data.weights.removeWhere((w) => w.date == e.date);
    _data.weights.add(e);
    _sort();
    await repo.saveWeights(_data.weights);
    if (notify) notifyListeners();
  }

  Future<void> deleteWeight(String date) async {
    _data.weights.removeWhere((w) => w.date == date);
    await repo.saveWeights(_data.weights);
    notifyListeners();
  }

  Future<void> addMeal({
    required String name,
    required double kcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    required MealSource source,
    bool edited = false,
    DateTime? date,
    MealSlot? slot,
    String? portion,
    String? foodId,
  }) async {
    final now = clock();
    final d = date ?? today;
    _data.meals.add(
      Meal(
        id: '${now.microsecondsSinceEpoch}-${math.Random().nextInt(1 << 20)}',
        date: dateKey(d),
        time: DateTime(
          d.year,
          d.month,
          d.day,
          now.hour,
          now.minute,
          now.second,
        ),
        name: name,
        kcal: kcal,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        source: source,
        edited: edited,
        slot: slot ?? MealSlot.forTime(now),
        portion: portion,
        foodId: foodId,
      ),
    );
    _sort();
    await repo.saveMeals(_data.meals);
    notifyListeners();
  }

  Future<void> updateMeal(Meal meal) async {
    final i = _data.meals.indexWhere((m) => m.id == meal.id);
    if (i < 0) return;
    _data.meals[i] = meal;
    await repo.saveMeals(_data.meals);
    notifyListeners();
  }

  Future<void> deleteMeal(String id) async {
    _data.meals.removeWhere((m) => m.id == id);
    await repo.saveMeals(_data.meals);
    notifyListeners();
  }

  Future<void> saveMealTemplate({
    required String name,
    required double kcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) async {
    _data.savedMeals.removeWhere((s) => s.name == name);
    _data.savedMeals.add(
      SavedMeal(
        id: '${clock().microsecondsSinceEpoch}',
        name: name,
        kcal: kcal,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
      ),
    );
    await repo.saveSavedMeals(_data.savedMeals);
    notifyListeners();
  }

  Future<void> addWorkout(
    WorkoutType type,
    int minutes, {
    DateTime? date,
  }) async {
    _data.workouts.add(
      Workout(
        id: '${clock().microsecondsSinceEpoch}',
        date: dateKey(date ?? today),
        type: type,
        minutes: minutes,
      ),
    );
    _sort();
    await repo.saveWorkouts(_data.workouts);
    notifyListeners();
  }

  Future<void> deleteWorkout(String id) async {
    _data.workouts.removeWhere((w) => w.id == id);
    await repo.saveWorkouts(_data.workouts);
    notifyListeners();
  }

  Future<void> deleteSavedMeal(String id) async {
    _data.savedMeals.removeWhere((s) => s.id == id);
    await repo.saveSavedMeals(_data.savedMeals);
    notifyListeners();
  }

  Future<void> applyCheckin(
    CheckinResult r,
    PlanStatus status, {
    double? manualKcal,
  }) async {
    final plan = currentPlan!;
    final p = profile!;
    late Macros m;
    switch (status) {
      case PlanStatus.accepted:
        m = r.proposal;
      case PlanStatus.manual:
        m = macrosFor(
          kcal: math.max(manualKcal!, kcalFloor(p.sex)),
          weightKg: r.trendWeightKg ?? latestWeight!.kg,
          goalType: p.goalType,
          bodyFatPct: latestBodyFat,
        );
      default:
        m = Macros(
          kcal: plan.targetKcal,
          proteinG: plan.proteinG,
          carbsG: plan.carbsG,
          fatG: plan.fatG,
        );
    }
    await _addPlan(
      Plan(
        weekStart: dateKey(today),
        targetKcal: m.kcal,
        proteinG: m.proteinG,
        carbsG: m.carbsG,
        fatG: m.fatG,
        tdeeEst: r.tdeeEstimate,
        confidence: r.confidence,
        reason: r.reason,
        status: status,
      ),
    );
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile p) async {
    _data.profile = p;
    await repo.saveProfile(p);
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings s) async {
    _data.settings = s;
    await repo.saveSettings(s);
    notifyListeners();
  }

  Future<void> deleteAll() async {
    await repo.deleteAll();
    _data = AppData();
    notifyListeners();
  }

  /// Fills ~5 weeks of realistic sample history so the trend chart and
  /// weekly check-in can be tried immediately. The last check-in is left due.
  Future<void> loadDemoData({required bool korean}) async {
    final rng = math.Random(7);
    double gauss(double sd) {
      final u1 = 1 - rng.nextDouble();
      final u2 = rng.nextDouble();
      return sd * math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
    }

    const weeks = 5;
    final start = _addDays(today, -weeks * 7);
    final profile =
        _data.profile ??
        UserProfile(
          sex: Sex.male,
          birthYear: today.year - 32,
          heightCm: 176,
          goalType: GoalType.lose,
          pace: Pace.normal,
          strengthPerWeek: 3,
          cardioPerWeek: 1,
          targetWeightKg: 74,
          createdAt: start,
        );
    const startKg = 80.0;
    const bf = 22.0;
    final init = initialPlan(
      profile: profile.coachProfile,
      goal: profile.coachGoal,
      weightKg: startKg,
      today: start,
      bodyFatPct: bf,
    );
    final trueTdee = init.tdee + 180;
    final weights = <WeightEntry>[];
    final meals = <Meal>[];
    final plans = <Plan>[
      Plan(
        weekStart: dateKey(start),
        targetKcal: init.macros.kcal,
        proteinG: init.macros.proteinG,
        carbsG: init.macros.carbsG,
        fatG: init.macros.fatG,
        tdeeEst: init.tdee,
        status: PlanStatus.initial,
      ),
    ];
    final names = korean
        ? [
            ['그릭요거트 + 바나나', '오트밀 + 우유', '계란 2개 + 식빵'],
            ['닭가슴살 샐러드', '현미밥 + 제육볶음', '비빔밥', '김밥 1줄'],
            ['연어 스테이크 + 고구마', '두부 된장찌개 + 밥', '소고기 + 현미밥', '닭가슴살 + 고구마'],
          ]
        : [
            ['Greek yogurt + banana', 'Oatmeal + milk', '2 eggs + toast'],
            [
              'Chicken salad',
              'Brown rice + spicy pork',
              'Bibimbap',
              'Gimbap roll',
            ],
            [
              'Salmon + sweet potato',
              'Tofu stew + rice',
              'Beef + brown rice',
              'Chicken + sweet potato',
            ],
          ];
    var mass = startKg;
    var target = init.macros.kcal;
    var prevTdee = init.tdee;
    for (var i = 0; i < weeks * 7; i++) {
      final d = _addDays(start, i);
      final eaten = target + gauss(140);
      mass +=
          (eaten - (trueTdee + 22 * (mass - startKg))) /
          CoachConstants.kcalPerKg;
      if (rng.nextDouble() < 0.88) {
        final bodyComp = i % 7 == 0;
        weights.add(
          WeightEntry(
            date: dateKey(d),
            kg: double.parse((mass + gauss(0.45)).toStringAsFixed(1)),
            bodyFatPct: bodyComp
                ? double.parse((bf - i * 0.06).toStringAsFixed(1))
                : null,
            skeletalMuscleKg: bodyComp
                ? double.parse((35.2 - i * 0.004).toStringAsFixed(1))
                : null,
          ),
        );
      }
      if (rng.nextDouble() < 0.93) {
        final split = [0.25, 0.4, 0.35];
        for (var j = 0; j < 3; j++) {
          final k = (eaten * split[j]).roundToDouble();
          final list = names[j];
          meals.add(
            Meal(
              id: 'demo-$i-$j',
              date: dateKey(d),
              time: DateTime(
                d.year,
                d.month,
                d.day,
                [8, 13, 19][j],
                rng.nextInt(50),
              ),
              name: list[rng.nextInt(list.length)],
              slot: MealSlot.values[j],
              kcal: k,
              proteinG: (k * 0.3 / 4).roundToDouble(),
              carbsG: (k * 0.42 / 4).roundToDouble(),
              fatG: (k * 0.28 / 9).roundToDouble(),
              source: MealSource.manual,
            ),
          );
        }
      }
      // Weekly check-ins accepted for weeks 1..4; week 5 is left due today.
      if ((i + 1) % 7 == 0 && i + 1 < weeks * 7) {
        final logs = <DayLog>[];
        final wByDay = {for (final w in weights) w.date: w.kg};
        final iByDay = <String, double>{};
        for (final m in meals) {
          iByDay[m.date] = (iByDay[m.date] ?? 0) + m.kcal;
        }
        for (var j = 0; j <= i; j++) {
          final dd = _addDays(start, j);
          logs.add(
            DayLog(
              date: dd,
              weightKg: wByDay[dateKey(dd)],
              intakeKcal: iByDay[dateKey(dd)],
            ),
          );
        }
        final r = weeklyCheckin(
          profile: profile.coachProfile,
          goal: profile.coachGoal,
          days: logs,
          today: d,
          previousTdee: prevTdee,
          bodyFatPct: bf,
        );
        final next = _addDays(d, 1);
        plans.add(
          Plan(
            weekStart: dateKey(next),
            targetKcal: r.proposal.kcal,
            proteinG: r.proposal.proteinG,
            carbsG: r.proposal.carbsG,
            fatG: r.proposal.fatG,
            tdeeEst: r.tdeeEstimate,
            confidence: r.confidence,
            reason: r.reason,
            status: r.adjusted ? PlanStatus.accepted : PlanStatus.kept,
          ),
        );
        if (r.adjusted) {
          prevTdee = r.tdeeEstimate;
          target = r.proposal.kcal;
        }
      }
    }
    // Today: a weigh-in and the first two meals, plus a few saved meals.
    weights.add(
      WeightEntry(
        date: dateKey(today),
        kg: double.parse((mass + gauss(0.45)).toStringAsFixed(1)),
      ),
    );
    final saved = korean
        ? [
            ('그릭요거트 + 바나나', 290.0, 17.0, 40.0, 6.0),
            ('닭가슴살 샐러드', 380.0, 38.0, 22.0, 14.0),
            ('현미밥 + 제육볶음', 750.0, 32.0, 78.0, 34.0),
          ]
        : [
            ('Greek yogurt + banana', 290.0, 17.0, 40.0, 6.0),
            ('Chicken salad', 380.0, 38.0, 22.0, 14.0),
            ('Brown rice + spicy pork', 750.0, 32.0, 78.0, 34.0),
          ];
    for (var j = 0; j < 2; j++) {
      final m = saved[j];
      meals.add(
        Meal(
          id: 'demo-today-$j',
          date: dateKey(today),
          time: DateTime(today.year, today.month, today.day, [8, 12][j], 20),
          name: m.$1,
          kcal: m.$2,
          proteinG: m.$3,
          carbsG: m.$4,
          fatG: m.$5,
          source: MealSource.saved,
          slot: MealSlot.values[j],
        ),
      );
    }
    _data.savedMeals = [
      for (var j = 0; j < saved.length; j++)
        SavedMeal(
          id: 'demo-saved-$j',
          name: saved[j].$1,
          kcal: saved[j].$2,
          proteinG: saved[j].$3,
          carbsG: saved[j].$4,
          fatG: saved[j].$5,
        ),
    ];
    await repo.saveSavedMeals(_data.savedMeals);
    // Sample training: 4x strength + 2x cardio per week, more than the
    // profile's 3 + 1, so the activity suggestion shows up.
    final workouts = <Workout>[];
    for (var i = 0; i <= weeks * 7; i++) {
      final d = _addDays(start, i);
      final wd = d.weekday;
      final type = switch (wd) {
        DateTime.monday ||
        DateTime.tuesday ||
        DateTime.thursday ||
        DateTime.friday => WorkoutType.strength,
        DateTime.wednesday || DateTime.saturday => WorkoutType.cardio,
        _ => null,
      };
      if (type == null) continue;
      workouts.add(
        Workout(
          id: 'demo-w-$i',
          date: dateKey(d),
          type: type,
          minutes: type == WorkoutType.strength ? 60 : 30 + 15 * rng.nextInt(3),
        ),
      );
    }
    _data.workouts = workouts;
    await repo.saveWorkouts(workouts);
    _data
      ..profile = profile
      ..weights = weights
      ..meals = meals
      ..plans = plans
      ..settings = settings.copyWith(
        checkinWeekday: today.weekday,
        consentedAt: settings.consentedAt ?? clock(),
      );
    _sort();
    await repo.saveProfile(profile);
    await repo.saveWeights(weights);
    await repo.saveMeals(meals);
    await repo.savePlans(plans);
    await repo.saveSettings(_data.settings);
    notifyListeners();
  }
}

/// Makes [AppState] available to the widget tree.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
