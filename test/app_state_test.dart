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
  });
}
