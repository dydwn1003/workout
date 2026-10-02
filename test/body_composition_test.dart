import 'package:adapt_coach/core/coach_engine/coach_engine.dart';
import 'package:flutter_test/flutter_test.dart';

final today = DateTime(2026, 10, 2);
DateTime ago(int days) => today.subtract(Duration(days: days));

/// Weight losing steadily over [n] days at [kcal] a day.
List<DayLog> losingDays(int n, {double from = 80, double to = 78.5}) => [
  for (var i = 0; i < n; i++)
    DayLog(
      date: ago(n - 1 - i),
      weightKg: from + (to - from) * i / (n - 1),
      intakeKcal: 2000,
    ),
];

const male = CoachProfile(sex: Sex.male, birthYear: 1994, heightCm: 178);
const lose = CoachGoal(
  type: GoalType.lose,
  pace: Pace.normal,
  sessionsPerWeek: 4,
);

void main() {
  group('compositionChange', () {
    test('needs two measurements two weeks apart', () {
      expect(
        compositionChange(
          [BodyCompSample(ago(10), 80, 25), BodyCompSample(ago(0), 79, 24.5)],
          today: today,
          goal: GoalType.lose,
        ),
        isNull,
      );
      expect(
        compositionChange(
          [BodyCompSample(ago(0), 79, 24.5)],
          today: today,
          goal: GoalType.lose,
        ),
        isNull,
      );
    });

    test('mostly fat lost: more kcal per kg, no slowdown', () {
      // 80 kg at 25% (fat 20, lean 60) -> 77 kg at 22.4% (fat 17.25, lean 59.75)
      final c = compositionChange(
        [BodyCompSample(ago(28), 80, 25), BodyCompSample(ago(0), 77, 22.4)],
        today: today,
        goal: GoalType.lose,
      )!;
      expect(c.fatChangeKg, closeTo(-2.75, 0.01));
      expect(c.leanChangeKg, closeTo(-0.25, 0.01));
      // raw (2.75*9440 + 0.25*1816)/3 = 8805, half-trusted with two samples
      final f = 77 * 0.224 - 20, l = (77 - 77 * 0.224) - 60;
      final raw = (f * 9440 + l * 1816) / (f + l);
      expect(c.kcalPerKg, closeTo(7700 + 0.5 * (raw - 7700), 0.01));
      expect(c.advice, CompositionAdvice.none);
    });

    test('too much lean mass lost: lean-loss advice', () {
      // 80/25% -> 77/25%: fat -0.75, lean -2.25 (75% of the loss)
      final c = compositionChange(
        [BodyCompSample(ago(28), 80, 25), BodyCompSample(ago(0), 77, 25)],
        today: today,
        goal: GoalType.lose,
      )!;
      expect(c.leanShare, closeTo(0.75, 0.01));
      expect(c.advice, CompositionAdvice.leanLoss);
      expect(c.kcalPerKg, greaterThanOrEqualTo(C.compMinKcalPerKg));
    });

    test('three or more measurements use a line through them', () {
      final c = compositionChange(
        [
          BodyCompSample(ago(28), 80, 25),
          BodyCompSample(ago(14), 79.5, 26), // a noisy reading
          BodyCompSample(ago(0), 77, 22.4),
        ],
        today: today,
        goal: GoalType.lose,
      )!;
      expect(c.samples, 3);
      expect(c.fatChangeKg, lessThan(-2));
      expect(c.advice, CompositionAdvice.none);
    });

    test('small change keeps 7,700 kcal per kg', () {
      final c = compositionChange(
        [BodyCompSample(ago(21), 80, 25), BodyCompSample(ago(0), 79.6, 24.8)],
        today: today,
        goal: GoalType.lose,
      )!;
      expect(c.kcalPerKg, isNull);
    });

    test('gaining mostly fat: fat-gain advice', () {
      // 70/15% (fat 10.5) -> 72/17.6% (fat 12.67): 2.17 of 2 kg is fat
      final c = compositionChange(
        [BodyCompSample(ago(28), 70, 15), BodyCompSample(ago(0), 72, 17.6)],
        today: today,
        goal: GoalType.gain,
      )!;
      expect(c.advice, CompositionAdvice.fatGain);
    });

    test('recomp working: fat down, lean up', () {
      // 75/22% (fat 16.5, lean 58.5) -> 75/20.8% (fat 15.6, lean 59.4)
      final c = compositionChange(
        [BodyCompSample(ago(28), 75, 22), BodyCompSample(ago(0), 75, 20.8)],
        today: today,
        goal: GoalType.recomp,
      )!;
      expect(c.advice, CompositionAdvice.recompWorking);
      expect(c.kcalPerKg, isNull); // weight didn't move
    });

    test('old measurements are ignored', () {
      expect(
        compositionChange(
          [BodyCompSample(ago(90), 85, 28), BodyCompSample(ago(70), 80, 25)],
          today: today,
          goal: GoalType.lose,
        ),
        isNull,
      );
    });
  });

  group('weekly check-in with body composition', () {
    final days = losingDays(28);

    test('fat-heavy loss raises the energy per kg and the observed burn', () {
      final plain = weeklyCheckin(
        profile: male,
        goal: lose,
        days: days,
        today: today,
        bodyFatPct: 22.4,
      );
      final comp = compositionChange(
        [BodyCompSample(ago(28), 80, 25), BodyCompSample(ago(0), 77, 22.4)],
        today: today,
        goal: GoalType.lose,
      );
      final r = weeklyCheckin(
        profile: male,
        goal: lose,
        days: days,
        today: today,
        bodyFatPct: 22.4,
        composition: comp,
      );
      expect(
        r.observed!.dailyImbalance,
        lessThan(plain.observed!.dailyImbalance),
      );
      expect(r.observed!.tdee, greaterThan(plain.observed!.tdee));
      expect(r.compositionAdvice, CompositionAdvice.none);
    });

    test('lean loss slows the pace and raises protein', () {
      final comp = compositionChange(
        [BodyCompSample(ago(28), 80, 25), BodyCompSample(ago(0), 77, 25)],
        today: today,
        goal: GoalType.lose,
      );
      final plain = weeklyCheckin(
        profile: male,
        goal: lose,
        days: days,
        today: today,
        previousTdee: 2500,
        bodyFatPct: 25,
      );
      final r = weeklyCheckin(
        profile: male,
        goal: lose,
        days: days,
        today: today,
        previousTdee: 2500,
        bodyFatPct: 25,
        composition: comp,
      );
      expect(r.compositionAdvice, CompositionAdvice.leanLoss);
      final deficit = r.tdeeEstimate - r.proposal.kcal;
      final plainDeficit = plain.tdeeEstimate - plain.proposal.kcal;
      expect(deficit, closeTo(plainDeficit * C.compSlowPace, 1));
      expect(r.proposal.proteinG, greaterThan(plain.proposal.proteinG));
    });

    test('burn breakdown adds up and uses lean mass when known', () {
      final r = weeklyCheckin(
        profile: male,
        goal: lose,
        days: days,
        today: today,
        bodyFatPct: 20,
      );
      final b = r.burn!;
      expect(b.fromLeanMass, isTrue);
      expect(b.bmr, closeTo(370 + 21.6 * 78.5 * 0.8, 15));
      expect(b.bmr + b.activity + b.digestion, closeTo(r.tdeeEstimate, 1));
      final noFat = weeklyCheckin(
        profile: male,
        goal: lose,
        days: days,
        today: today,
      );
      expect(noFat.burn!.fromLeanMass, isFalse);
    });

    test('a kept target is not changed by the composition', () {
      final comp = compositionChange(
        [BodyCompSample(ago(28), 80, 25), BodyCompSample(ago(0), 77, 25)],
        today: today,
        goal: GoalType.lose,
      );
      // Two days of logs: too little to adjust anything.
      final r = weeklyCheckin(
        profile: male,
        goal: lose,
        days: losingDays(2),
        today: today,
        composition: comp,
      );
      expect(r.adjusted, isFalse);
      expect(r.compositionAdvice, CompositionAdvice.none);
    });
  });
}
