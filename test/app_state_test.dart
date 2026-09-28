import 'package:adapt_coach/core/coach_engine/coach_engine.dart';
import 'package:adapt_coach/data/entities.dart';
import 'package:adapt_coach/data/food.dart';
import 'package:adapt_coach/data/food_db.g.dart';
import 'package:adapt_coach/data/food_estimator.dart';
import 'package:adapt_coach/data/repository.dart';
import 'package:adapt_coach/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 28, 20);

  group('AppState', () {
    test('onboarding creates profile, weight and initial plan', () async {
      final s = AppState(MemoryCoachRepository(), clock: () => now);
      await s.load();
      expect(s.onboarded, isFalse);
      await s.completeOnboarding(
        profile: UserProfile(
          sex: Sex.female,
          birthYear: 1995,
          heightCm: 165,
          goalType: GoalType.lose,
          pace: Pace.normal,
          strengthPerWeek: 3,
          cardioPerWeek: 1,
          targetWeightKg: 60,
          createdAt: now,
        ),
        weightKg: 66,
      );
      expect(s.onboarded, isTrue);
      expect(s.currentPlan!.status, PlanStatus.initial);
      expect(s.currentPlan!.targetKcal, greaterThanOrEqualTo(1200));
      expect(s.checkinDue, isFalse);
    });

    test('demo data leaves a check-in due and accept adds a plan', () async {
      final repo = MemoryCoachRepository();
      final s = AppState(repo, clock: () => now);
      await s.load();
      await s.loadDemoData(korean: true);
      expect(s.checkinDue, isTrue);
      expect(s.mealsOn(s.today), isNotEmpty);
      final r = s.runCheckin()!;
      expect(r.confidence, isNot(Confidence.low));
      final before = s.plans.length;
      await s.applyCheckin(r, PlanStatus.accepted);
      expect(s.plans.length, before + 1);
      expect(s.currentPlan!.targetKcal, r.proposal.kcal);
      expect(s.checkinDue, isFalse);
      expect(s.planOn(s.today)!.targetKcal, r.proposal.kcal);
      expect(s.planOn(DateTime(2026, 8, 1))!.status, PlanStatus.initial);

      // Persisted and reloadable.
      final reloaded = AppState(repo, clock: () => now);
      await reloaded.load();
      expect(reloaded.plans.length, s.plans.length);
    });

    test('manual target is floored for safety', () async {
      final s = AppState(MemoryCoachRepository(), clock: () => now);
      await s.load();
      await s.loadDemoData(korean: false);
      await s.applyCheckin(s.runCheckin()!, PlanStatus.manual, manualKcal: 900);
      expect(s.currentPlan!.targetKcal, CoachConstants.minKcalMale);
    });
  });

  group('logging helpers', () {
    test('streak, week log, recent meals and meal edit', () async {
      final s = AppState(MemoryCoachRepository(), clock: () => now);
      await s.load();
      await s.loadDemoData(korean: true);
      final log = s.weekLog();
      expect(log.length, 7);
      expect(log.last.$1, s.today);
      expect(log.last.$2, isTrue); // demo logs meals today
      expect(s.loggingStreak, greaterThan(0));
      final recent = s.recentMeals();
      final savedNames = s.savedMeals.map((m) => m.name).toSet();
      expect(recent.any((m) => savedNames.contains(m.name)), isFalse);
      expect(recent.map((m) => m.name).toSet().length, recent.length);

      final m = s.mealsOn(s.today).first;
      await s.updateMeal(
        Meal(
          id: m.id,
          date: m.date,
          time: m.time,
          name: 'edited',
          kcal: 123,
          proteinG: 1,
          carbsG: 2,
          fatG: 3,
          source: m.source,
          edited: true,
          slot: m.slot,
        ),
      );
      expect(s.mealsOn(s.today).firstWhere((x) => x.id == m.id).kcal, 123);
    });

    test('meals can be logged on a past day', () async {
      final s = AppState(MemoryCoachRepository(), clock: () => now);
      await s.load();
      final yesterday = DateTime(2026, 9, 27);
      await s.addMeal(
        name: 'late log',
        kcal: 500,
        proteinG: 20,
        carbsG: 60,
        fatG: 15,
        source: MealSource.manual,
        date: yesterday,
      );
      expect(s.mealsOn(yesterday).single.name, 'late log');
      expect(s.mealsOn(s.today), isEmpty);
      expect(s.loggingStreak, 1); // yesterday counts when today is empty
    });

    test('log calendar: start, logged days and longest streak', () async {
      final s = AppState(MemoryCoachRepository(), clock: () => now);
      await s.load();
      Future<void> log(DateTime d) => s.addMeal(
        name: 'x',
        kcal: 100,
        proteinG: 1,
        carbsG: 1,
        fatG: 1,
        source: MealSource.manual,
        date: d,
      );
      // 3 days in a row, a gap, then 2 days ending yesterday.
      for (final d in [20, 21, 22, 25, 26, 27]) {
        await log(DateTime(2026, 9, d));
      }
      expect(s.logStart, DateTime(2026, 9, 20));
      expect(s.loggedDays, contains('2026-09-22'));
      expect(s.loggedDays, isNot(contains('2026-09-23')));
      expect(s.longestLoggingStreak, 3);
      expect(s.loggingStreak, 3); // 25-27, today not logged yet
    });
  });

  group('workouts', () {
    test('logging, weekly count and delete', () async {
      final s = AppState(MemoryCoachRepository(), clock: () => now);
      await s.load();
      await s.addWorkout(WorkoutType.strength, 60);
      await s.addWorkout(WorkoutType.cardio, 30, date: DateTime(2026, 9, 20));
      expect(s.workoutsOn(s.today).single.minutes, 60);
      expect(s.weekWorkouts, 1); // Sep 20 is outside the last 7 days
      await s.deleteWorkout(s.workoutsOn(s.today).single.id);
      expect(s.workoutsOn(s.today), isEmpty);
    });

    test('weekly buckets end today and count by type', () async {
      final s = AppState(MemoryCoachRepository(), clock: () => now);
      await s.load();
      await s.addWorkout(WorkoutType.strength, 60);
      await s.addWorkout(WorkoutType.cardio, 30, date: DateTime(2026, 9, 22));
      await s.addWorkout(WorkoutType.cardio, 40, date: DateTime(2026, 9, 21));
      final w = s.workoutWeeks();
      expect(w.length, 8);
      expect(w.last.start, DateTime(2026, 9, 22));
      expect((w.last.strength, w.last.cardio, w.last.minutes), (1, 1, 90));
      expect(w[6].cardio, 1); // Sep 21 falls in the previous bucket
    });

    test('suggests matching logged frequency after 2 weeks', () async {
      final s = AppState(MemoryCoachRepository(), clock: () => now);
      await s.load();
      await s.loadDemoData(korean: true); // profile says 3 + 1 per week
      final sug = s.workoutSuggestion;
      expect(sug, isNotNull);
      expect(sug!.$1 + sug.$2, greaterThanOrEqualTo(5));
      await s.applyWorkoutSuggestion();
      expect(s.profile!.strengthPerWeek, sug.$1);
      expect(s.profile!.cardioPerWeek, sug.$2);
      expect(s.workoutSuggestion, isNull);
    });

    test('workout tips from demo data', () async {
      final s = AppState(MemoryCoachRepository(), clock: () => now);
      await s.load();
      await s.loadDemoData(korean: true);
      final kinds = s.workoutTips().map((t) => t.kind).toList();
      expect(kinds, contains(WorkoutTipKind.planDone)); // 6 sessions vs 4
      expect(
        kinds.last,
        anyOf(WorkoutTipKind.cardioDone, WorkoutTipKind.cardioProgress),
      );
    });

    test('no suggestion without 2 weeks of workout logs', () async {
      final s = AppState(MemoryCoachRepository(), clock: () => now);
      await s.load();
      await s.loadDemoData(korean: true);
      for (final w in s.workouts.toList()) {
        await s.deleteWorkout(w.id);
      }
      expect(s.workoutSuggestion, isNull);
      for (var i = 0; i < 6; i++) {
        await s.addWorkout(WorkoutType.strength, 45);
      }
      expect(s.workoutSuggestion, isNull); // only logging since today
    });
  });

  group('food logging', () {
    test('slot defaults by time and is stored with portion', () async {
      final s = AppState(MemoryCoachRepository(), clock: () => now); // 20:00
      await s.load();
      final rice = builtInFoods.firstWhere((f) => f.name == '현미밥');
      await s.addMeal(
        name: rice.name,
        kcal: 300,
        proteinG: 6,
        carbsG: 63,
        fatG: 2,
        source: MealSource.search,
        portion: '1공기 × 1 (210g)',
        foodId: rice.id,
      );
      final m = s.mealsOn(s.today).single;
      expect(m.slot, MealSlot.dinner);
      expect(m.portion, '1공기 × 1 (210g)');
      expect(s.recentFoods().single.id, rice.id);
      expect(MealSlot.forTime(DateTime(2026, 1, 1, 7)), MealSlot.breakfast);
      expect(MealSlot.forTime(DateTime(2026, 1, 1, 15, 30)), MealSlot.snack);
    });

    test('custom foods are searchable, persisted and deletable', () async {
      final repo = MemoryCoachRepository();
      final s = AppState(repo, clock: () => now);
      await s.load();
      final f = await s.addCustomFood(
        name: '엄마표 김밥',
        unitLabel: '1줄',
        kcal: 420,
        proteinG: 12,
        carbsG: 60,
        fatG: 14,
      );
      expect(s.searchAllFoods('엄마').first.id, f.id);
      expect(
        s.searchAllFoods('김밥').first.custom,
        isFalse,
      ); // exact built-in wins
      final reloaded = AppState(repo, clock: () => now);
      await reloaded.load();
      expect(reloaded.customFoods.single.name, '엄마표 김밥');
      await s.deleteCustomFood(s.customFoods.single.id);
      expect(s.searchAllFoods('엄마').where((f) => f.custom), isEmpty);
    });

    test('old meals without slot load with a time-based slot', () {
      final m = Meal.fromJson({
        'id': 'x',
        'date': '2026-09-28',
        'time': '2026-09-28T08:30:00.000',
        'name': 'old',
        'kcal': 100,
        'source': 'manual',
      });
      expect(m.slot, MealSlot.breakfast);
    });
  });

  group('food estimator', () {
    test('scales by grams and units', () {
      final e = estimateFromText('닭가슴살 200g, 계란 2개, 현미밥 1공기');
      expect(e.items.length, 3);
      expect(e.items.every((i) => i.matched), isTrue);
      expect(e.items[0].kcal, closeTo(330, 0.01)); // 165/100g
      expect(e.items[1].kcal, closeTo(144, 0.01)); // 2 x 50 g
      expect(e.items[2].grams, 210);
    });

    test('english, korean number words and unknown items', () {
      final e = estimateFromText('2 eggs and 사과 반 개, mystery stew');
      expect(e.items[0].kcal, closeTo(144, 0.01));
      expect(e.items[1].grams, 100);
      expect(e.hasUnmatched, isTrue);
    });

    test('prefers the longest matching food name', () {
      final e = estimateFromText('볶음밥, 초밥 10개, 크림치즈');
      expect(e.items[0].food!.name, '볶음밥'); // not plain rice
      expect(e.items[1].grams, 300);
      expect(e.items[2].food!.name, '크림치즈'); // not cheese
    });
  });

  group('food search', () {
    test('prefix beats contains; aliases and english work', () {
      final r = searchFoods(builtInFoods, '닭');
      expect(r.first.name.startsWith('닭'), isTrue);
      expect(searchFoods(builtInFoods, 'salmon').first.name, '연어');
      expect(
        searchFoods(builtInFoods, '치킨').map((f) => f.name),
        contains('후라이드치킨'),
      );
    });

    test('franchise menus missing from MFDS are searchable estimates', () {
      final f = searchFoods(builtInFoods, 'bhc 뿌링클').first;
      expect(f.name, '뿌링클 (bhc)');
      expect(f.kcalEstimated, isTrue);
      expect(f.kcal, greaterThan(0));
      expect(
        searchFoods(builtInFoods, '네네 스노윙').first.name,
        startsWith('스노윙치킨'),
      );
    });

    test('no initial consonant search', () {
      expect(searchFoods(builtInFoods, 'ㄷㄱㅅㅅ'), isEmpty);
    });

    test('unpublished franchise macros are estimated from kcal', () {
      final menus = builtInFoods.where((f) => f.unknown.isNotEmpty).toList();
      expect(menus, isNotEmpty);
      for (final f in menus) {
        final e = {'p': f.proteinG * 4, 'c': f.carbsG * 4, 'f': f.fatG * 9};
        final published = [
          for (final k in e.keys)
            if (!f.unknown.contains(k)) e[k]!,
        ].fold(0.0, (a, b) => a + b);
        final total = e.values.reduce((a, b) => a + b);
        // Estimates fill the energy the published macros leave (none when
        // the source's own numbers already exceed kcal).
        final target = published > f.kcal ? published : f.kcal;
        expect(total, closeTo(target, target * 0.02 + 1), reason: f.name);
      }
    });

    test('portion math and custom foods', () {
      final rice = builtInFoods.firstWhere((f) => f.name == '흰쌀밥');
      final n = rice.forPortion(rice.units.first, 1.5);
      expect(n.kcal, closeTo(148 * 2.1 * 1.5, 0.01));
      expect(rice.allUnits.last.isGram, isTrue);
      final c = Food.customPerServing(
        id: 'c1',
        name: '엄마 김밥',
        unitLabel: '1줄',
        kcal: 420,
        proteinG: 12,
        carbsG: 60,
        fatG: 14,
      );
      expect(c.forPortion(c.units.first, 2).kcal, closeTo(840, 0.01));
      expect(c.allUnits.length, 1); // no gram unit without a real weight
    });
  });
}
