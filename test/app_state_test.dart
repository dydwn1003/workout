import 'package:adapt_coach/core/coach_engine/coach_engine.dart';
import 'package:adapt_coach/data/entities.dart';
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

  group('food estimator', () {
    test('scales by grams and counts', () {
      final e = estimateFromText('닭가슴살 200g, 계란 2개, 현미밥 1공기');
      expect(e.items.length, 3);
      expect(e.items.every((i) => i.matched), isTrue);
      expect(e.kcal, closeTo(330 + 144 + 300, 1e-6));
    });

    test('english and unknown items', () {
      final e = estimateFromText('2 eggs and mystery stew');
      expect(e.items.first.kcal, closeTo(144, 1e-6));
      expect(e.hasUnmatched, isTrue);
    });

    test('prefers the longest matching food name', () {
      final e = estimateFromText('볶음밥, 초밥 10개, 크림치즈');
      expect(e.items[0].kcal, 600); // not plain rice
      expect(e.items[1].kcal, closeTo(500, 1e-6));
      expect(e.items[2].kcal, 70); // not cheese
    });
  });
}
