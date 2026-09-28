import 'package:adapt_coach/core/coach_engine/coach_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/simulate.dart' as sim;

const male = CoachProfile(sex: Sex.male, birthYear: 1996, heightCm: 180);
const female = CoachProfile(sex: Sex.female, birthYear: 1996, heightCm: 165);
final today = DateTime(2026, 9, 28);

List<DayLog> flatDays(int n, {double kg = 80, double kcal = 2500}) => [
  for (var i = 0; i < n; i++)
    DayLog(
      date: today.subtract(Duration(days: n - 1 - i)),
      weightKg: kg,
      intakeKcal: kcal,
    ),
];

void main() {
  group('trendSeries', () {
    test('seeds with first weight, carries forward on missing days', () {
      final t = trendSeries([null, 80, null, 81]);
      expect(t[0], isNull);
      expect(t[1], 80);
      expect(t[2], 80);
      expect(t[3], closeTo(80.1, 1e-9));
    });

    test('dampens single-day spikes', () {
      final t = trendSeries([80, 80, 83, 80]);
      expect(t[2], closeTo(80.3, 1e-9));
    });
  });

  group('formula TDEE', () {
    test('Mifflin-St Jeor male/female', () {
      expect(
        bmrMifflin(sex: Sex.male, weightKg: 80, heightCm: 180, age: 30),
        800 + 1125 - 150 + 5,
      );
      expect(
        bmrMifflin(sex: Sex.female, weightKg: 60, heightCm: 165, age: 30),
        600 + 1031.25 - 150 - 161,
      );
    });

    test('Katch-McArdle uses lean mass', () {
      expect(bmrKatchMcArdle(leanMassKg: 64), closeTo(370 + 21.6 * 64, 1e-9));
    });

    test('activity factor mapping', () {
      expect(CoachConstants.activityFactor(0), 1.2);
      expect(CoachConstants.activityFactor(3), 1.375);
      expect(CoachConstants.activityFactor(5), 1.55);
      expect(CoachConstants.activityFactor(7), 1.725);
    });

    test('formulaTdee picks Katch-McArdle when body fat is known', () {
      final withBf = formulaTdee(
        profile: male,
        weightKg: 80,
        sessionsPerWeek: 0,
        today: today,
        bodyFatPct: 20,
      );
      expect(withBf, closeTo((370 + 21.6 * 64) * 1.2, 1e-9));
    });
  });

  group('observedTdee', () {
    test('null for short histories', () {
      expect(observedTdee(flatDays(9)), isNull);
    });

    test('stable weight -> TDEE equals average intake', () {
      final o = observedTdee(flatDays(20, kcal: 2400))!;
      expect(o.tdee, closeTo(2400, 1e-6));
      expect(o.windowDays, 14);
    });

    test('losing weight -> TDEE above intake', () {
      // Steady loss of 0.1 kg/day, long history so the EMA slope settles.
      final days = [
        for (var i = 0; i < 60; i++)
          DayLog(
            date: today.subtract(Duration(days: 59 - i)),
            weightKg: 90 - 0.1 * i,
            intakeKcal: 2000,
          ),
      ];
      final o = observedTdee(days)!;
      // 0.1 kg/day * 7700 = 770 kcal/day deficit.
      expect(o.tdee, closeTo(2770, 15));
    });

    test('ignores unlogged or incomplete days in intake average', () {
      final days = flatDays(20, kcal: 2400)
          .asMap()
          .entries
          .map(
            (e) => e.key.isEven
                ? e.value
                : DayLog(date: e.value.date, weightKg: 80, intakeKcal: 300),
          )
          .toList();
      final o = observedTdee(days)!;
      expect(o.avgIntake, 2400);
      expect(o.windowDays, 14); // history too short to widen to 21
    });
  });

  group('blend & smooth', () {
    test('beta grows with data and caps at 0.85', () {
      expect(observedWeight(14), 0.5);
      expect(observedWeight(100), 0.85);
      expect(
        blendTdee(formula: 2000, observed: 3000, totalValidDays: 14),
        2500,
      );
    });

    test('weekly change limited to ±150', () {
      expect(smoothTdee(3000, 2500), 2650);
      expect(smoothTdee(2000, 2500), 2350);
      expect(smoothTdee(2550, 2500), 2550);
    });
  });

  group('targetKcal', () {
    const loss = CoachGoal(
      type: GoalType.lose,
      pace: Pace.normal,
      sessionsPerWeek: 3,
    );
    test('loss deficit from rate', () {
      final t = targetKcal(
        tdee: 2800,
        goal: loss,
        trendWeightKg: 80,
        sex: Sex.male,
      );
      // 0.5% * 80 = 0.4 kg/wk -> 440 kcal/day
      expect(t.kcal, closeTo(2360, 1e-6));
      expect(t.floorHit, isFalse);
    });

    test('gain surplus', () {
      const gain = CoachGoal(
        type: GoalType.gain,
        pace: Pace.normal,
        sessionsPerWeek: 3,
      );
      final t = targetKcal(
        tdee: 2800,
        goal: gain,
        trendWeightKg: 80,
        sex: Sex.male,
      );
      expect(t.kcal, closeTo(2800 + 0.2 * 1100, 1e-6));
    });

    test('maintain = TDEE', () {
      const m = CoachGoal(
        type: GoalType.maintain,
        pace: Pace.normal,
        sessionsPerWeek: 3,
      );
      expect(
        targetKcal(tdee: 2500, goal: m, trendWeightKg: 80, sex: Sex.male).kcal,
        2500,
      );
    });

    test('safety floor male 1500 / female 1200', () {
      const fast = CoachGoal(
        type: GoalType.lose,
        pace: Pace.fast,
        sessionsPerWeek: 0,
      );
      final m = targetKcal(
        tdee: 1600,
        goal: fast,
        trendWeightKg: 80,
        sex: Sex.male,
      );
      final f = targetKcal(
        tdee: 1300,
        goal: fast,
        trendWeightKg: 60,
        sex: Sex.female,
      );
      expect(m.kcal, 1500);
      expect(m.floorHit, isTrue);
      expect(f.kcal, 1200);
    });

    test('loss rate never exceeds 1%/week', () {
      for (final p in Pace.values) {
        expect(
          ratePctPerWeek(GoalType.lose, p),
          lessThanOrEqualTo(CoachConstants.maxLossRatePctPerWeek),
        );
      }
    });
  });

  group('macros', () {
    test('protein by body weight when no body fat', () {
      final m = macrosFor(kcal: 2400, weightKg: 80, goalType: GoalType.lose);
      expect(m.proteinG, closeTo(144, 1e-9));
      expect(m.fatG, closeTo(2400 * 0.25 / 9, 1e-9)); // 66.7 > 48
      final total = m.proteinG * 4 + m.carbsG * 4 + m.fatG * 9;
      expect(total, closeTo(2400, 1e-6));
    });

    test('protein by LBM when body fat known', () {
      final m = macrosFor(
        kcal: 2400,
        weightKg: 80,
        goalType: GoalType.gain,
        bodyFatPct: 20,
      );
      expect(m.proteinG, closeTo(64 * 1.8, 1e-9));
    });

    test('fat minimum by body weight at low kcal', () {
      final m = macrosFor(kcal: 1500, weightKg: 100, goalType: GoalType.lose);
      expect(m.fatG, 60);
      expect(m.carbsG, greaterThanOrEqualTo(0));
    });
  });

  group('confidence', () {
    test('levels', () {
      expect(confidenceFor(loggedDays: 7, weighIns: 7), Confidence.high);
      expect(confidenceFor(loggedDays: 5, weighIns: 3), Confidence.medium);
      expect(confidenceFor(loggedDays: 4, weighIns: 7), Confidence.low);
      expect(confidenceFor(loggedDays: 7, weighIns: 2), Confidence.low);
    });
  });

  group('goal helpers', () {
    test('body fat target -> weight (plan example)', () {
      expect(
        targetWeightFromBodyFat(
          weightKg: 80,
          currentBodyFatPct: 20,
          targetBodyFatPct: 15,
        ),
        closeTo(75.29, 0.01),
      );
    });

    test('validateGoal blocks minors and unsafe targets', () {
      const minor = CoachProfile(sex: Sex.male, birthYear: 2012, heightCm: 170);
      const g = CoachGoal(
        type: GoalType.lose,
        pace: Pace.normal,
        sessionsPerWeek: 3,
        targetWeightKg: 45,
      );
      final issues = validateGoal(
        profile: minor,
        weightKg: 60,
        goal: g,
        today: today,
      );
      expect(issues, contains(GoalIssue.underage));
      expect(issues, contains(GoalIssue.targetBmiTooLow));
    });

    test('validateGoal blocks loss at low BMI', () {
      const g = CoachGoal(
        type: GoalType.lose,
        pace: Pace.normal,
        sessionsPerWeek: 3,
      );
      expect(
        validateGoal(profile: female, weightKg: 48, goal: g, today: today),
        contains(GoalIssue.bmiTooLowForLoss),
      );
    });
  });

  group('eta', () {
    test('uses planned rate when history is short', () {
      final e = etaWeeks(
        trend: [80, 80],
        targetKg: 76,
        plannedKgPerWeek: -0.4,
      )!;
      expect(e.minWeeks, closeTo(8, 1e-9));
      expect(e.maxWeeks, closeTo(12, 1e-9));
    });

    test('uses observed slope when available', () {
      final trend = [for (var i = 0; i < 29; i++) 80 - i * 0.1];
      final e = etaWeeks(trend: trend, targetKg: 74.4, plannedKgPerWeek: -0.4)!;
      // 0.7 kg/wk, 77.2 -> 74.4 = 2.8 kg remaining.
      expect((e.minWeeks + e.maxWeeks) / 2, closeTo(2.8 / 0.7, 1e-6));
    });

    test('null when moving away and no planned progress', () {
      expect(etaWeeks(trend: [80], targetKg: 75, plannedKgPerWeek: 0), isNull);
    });
  });

  group('muscle loss', () {
    test('warns on >1% decline over 4 weeks', () {
      expect(
        muscleLossWarning([
          (today.subtract(const Duration(days: 28)), 35.0),
          (today, 34.5),
        ]),
        isTrue,
      );
      expect(
        muscleLossWarning([
          (today.subtract(const Duration(days: 28)), 35.0),
          (today, 34.8),
        ]),
        isFalse,
      );
    });
  });

  group('weeklyCheckin', () {
    const goal = CoachGoal(
      type: GoalType.lose,
      pace: Pace.normal,
      sessionsPerWeek: 3,
    );

    test('low confidence keeps previous TDEE', () {
      final days = [
        for (var i = 0; i < 14; i++)
          DayLog(
            date: today.subtract(Duration(days: 13 - i)),
            weightKg: i % 5 == 0 ? 80 : null,
            intakeKcal: i % 3 == 0 ? 2000 : null,
          ),
      ];
      final r = weeklyCheckin(
        profile: male,
        goal: goal,
        days: days,
        today: today,
        previousTdee: 2600,
      );
      expect(r.confidence, Confidence.low);
      expect(r.reason, CheckinReason.lowConfidence);
      expect(r.tdeeEstimate, 2600);
      expect(r.adjusted, isFalse);
    });

    test('flat weight on low intake is detected as plateau', () {
      final r = weeklyCheckin(
        profile: male,
        goal: goal,
        days: flatDays(42, kcal: 2000),
        today: today,
        previousTdee: 2600,
      );
      expect(r.reason, CheckinReason.plateau);
      expect(r.tdeeEstimate, 2450); // limited to -150
      expect(r.proposal.kcal, lessThan(2600 - 400));
    });
  });

  group('workout feedback', () {
    WorkoutSummary sum({
      int strengthDays = 3,
      int cardio = 60,
      int total = 240,
      int sessions = 4,
      int planned = 4,
      double? prev = 240,
      int streak = 2,
      GoalType goal = GoalType.lose,
    }) => WorkoutSummary(
      strengthDays: strengthDays,
      cardioMinutes: cardio,
      totalMinutes: total,
      sessions: sessions,
      plannedSessions: planned,
      previousAvgMinutes: prev,
      consecutiveDays: streak,
      goalType: goal,
    );
    List<WorkoutTipKind> kinds(WorkoutSummary s) =>
        workoutFeedback(s).map((t) => t.kind).toList();

    test('no feedback without any training data', () {
      expect(
        workoutFeedback(sum(sessions: 0, total: 0, cardio: 0, prev: null)),
        isEmpty,
      );
    });

    test('plan done and cardio progress with remaining minutes', () {
      final tips = workoutFeedback(sum());
      expect(tips.map((t) => t.kind), [
        WorkoutTipKind.planDone,
        WorkoutTipKind.cardioProgress,
      ]);
      expect(tips.last.b, 90);
    });

    test('nudges strength while losing, not while gaining', () {
      expect(kinds(sum(strengthDays: 1)).first, WorkoutTipKind.strengthForLoss);
      expect(
        kinds(sum(strengthDays: 1, goal: GoalType.gain)),
        isNot(contains(WorkoutTipKind.strengthForLoss)),
      );
    });

    test('compares against the 3-week average', () {
      expect(
        kinds(sum(total: 300, prev: 240)),
        contains(WorkoutTipKind.moreThanUsual),
      );
      expect(
        kinds(sum(total: 150, prev: 240)),
        contains(WorkoutTipKind.lessThanUsual),
      );
      expect(
        kinds(sum(total: 250, prev: 240)),
        isNot(
          anyOf(
            contains(WorkoutTipKind.moreThanUsual),
            contains(WorkoutTipKind.lessThanUsual),
          ),
        ),
      );
    });

    test('rest tip first after 7 straight days; cardio guideline reached', () {
      final k = kinds(sum(streak: 7, cardio: 160));
      expect(k.first, WorkoutTipKind.rest);
      expect(k, contains(WorkoutTipKind.cardioDone));
    });

    test('remaining planned sessions', () {
      final tip = workoutFeedback(sum(sessions: 1))
          .firstWhere((t) => t.kind == WorkoutTipKind.planRemaining);
      expect((tip.a, tip.b), (3, 4));
    });
  });

  group('simulator acceptance', () {
    for (final s in sim.scenarios()) {
      test('scenario ${s.id} respects safety floor', () {
        final r = sim.run(s);
        final floor = kcalFloor(s.profile.sex);
        expect(r.rows.every((w) => w.target >= floor), isTrue);
      });
    }

    for (final id in ['A', 'C', 'F']) {
      test('scenario $id converges within ±150 kcal by week 6', () {
        final s = sim.scenarios().firstWhere((s) => s.id == id);
        final w = sim.run(s).convergedWeek();
        expect(w, isNotNull);
        expect(w, lessThanOrEqualTo(6));
      });
    }
  });
}
