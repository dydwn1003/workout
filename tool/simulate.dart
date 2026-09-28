// ignore_for_file: avoid_print
// Coach engine simulator.
//
// Generates synthetic users with a known "true" expenditure and noisy
// weigh-ins, feeds the data into the engine week by week and prints how the
// trend, estimated TDEE and targets evolve.
//
// Run: dart run tool/simulate.dart            (all scenarios)
//      dart run tool/simulate.dart A E        (selected scenarios)
import 'dart:math' as math;

import 'package:adapt_coach/core/coach_engine/coach_engine.dart';

class Scenario {
  final String id;
  final String name;
  final CoachProfile profile;
  final CoachGoal goal;
  final double startWeight;
  final double? bodyFatPct;

  /// True TDEE minus formula TDEE at the start (formula error).
  final double formulaError;
  final double waterNoiseSd;
  final double logProbability;
  final double weighProbability;

  /// Extra expenditure change (kcal/day) as a function of the day index.
  final double Function(int day) adaptation;

  /// When true the user ignores proposals and keeps eating the initial target.
  final bool fixedIntake;
  final int weeks;

  Scenario({
    required this.id,
    required this.name,
    required this.profile,
    required this.goal,
    required this.startWeight,
    this.bodyFatPct,
    this.formulaError = 200,
    this.waterNoiseSd = 0.4,
    this.logProbability = 0.95,
    this.weighProbability = 0.9,
    double Function(int day)? adaptation,
    this.fixedIntake = false,
    this.weeks = 12,
  }) : adaptation = adaptation ?? ((_) => 0);
}

final today0 = DateTime(2026, 1, 5);

List<Scenario> scenarios() => [
  Scenario(
    id: 'A',
    name: 'Loss: 80kg, 20% -> 15% BF, normal pace',
    profile: const CoachProfile(sex: Sex.male, birthYear: 1994, heightCm: 178),
    goal: CoachGoal(
      type: GoalType.lose,
      pace: Pace.normal,
      sessionsPerWeek: 4,
      targetWeightKg: targetWeightFromBodyFat(
        weightKg: 80,
        currentBodyFatPct: 20,
        targetBodyFatPct: 15,
      ),
    ),
    startWeight: 80,
    bodyFatPct: 20,
  ),
  Scenario(
    id: 'B',
    name: 'Plateau: fixed intake, expenditure drops 300 kcal from week 3',
    profile: const CoachProfile(
      sex: Sex.female,
      birthYear: 1990,
      heightCm: 165,
    ),
    goal: const CoachGoal(
      type: GoalType.lose,
      pace: Pace.normal,
      sessionsPerWeek: 3,
      targetWeightKg: 63,
    ),
    startWeight: 70,
    formulaError: 0,
    adaptation: (d) => d < 21 ? 0.0 : -math.min(300.0, (d - 21) * 20.0),
    fixedIntake: true,
  ),
  Scenario(
    id: 'C',
    name: 'Gain: 65kg lean bulk, normal pace',
    profile: const CoachProfile(sex: Sex.male, birthYear: 2000, heightCm: 175),
    goal: const CoachGoal(
      type: GoalType.gain,
      pace: Pace.normal,
      sessionsPerWeek: 5,
      targetWeightKg: 70,
    ),
    startWeight: 65,
    formulaError: -150,
  ),
  Scenario(
    id: 'D',
    name: 'Sparse logging: 50% meal logs, 35% weigh-ins',
    profile: const CoachProfile(sex: Sex.male, birthYear: 1988, heightCm: 172),
    goal: const CoachGoal(
      type: GoalType.lose,
      pace: Pace.normal,
      sessionsPerWeek: 2,
      targetWeightKg: 75,
    ),
    startWeight: 82,
    logProbability: 0.5,
    weighProbability: 0.35,
  ),
  Scenario(
    id: 'E',
    name: 'High water fluctuation (sd 1.0 kg)',
    profile: const CoachProfile(sex: Sex.male, birthYear: 1994, heightCm: 178),
    goal: const CoachGoal(
      type: GoalType.lose,
      pace: Pace.normal,
      sessionsPerWeek: 4,
      targetWeightKg: 75,
    ),
    startWeight: 80,
    waterNoiseSd: 1.0,
  ),
  Scenario(
    id: 'F',
    name: 'Recomp: 60kg, 28% -> 23% BF',
    profile: const CoachProfile(
      sex: Sex.female,
      birthYear: 1998,
      heightCm: 163,
    ),
    goal: CoachGoal(
      type: GoalType.recomp,
      pace: Pace.normal,
      sessionsPerWeek: 4,
      targetWeightKg: targetWeightFromBodyFat(
        weightKg: 60,
        currentBodyFatPct: 28,
        targetBodyFatPct: 23,
      ),
    ),
    startWeight: 60,
    bodyFatPct: 28,
    formulaError: 150,
  ),
];

class _Rng {
  final math.Random r;
  _Rng(int seed) : r = math.Random(seed);
  double gauss(double sd) {
    final u1 = 1 - r.nextDouble();
    final u2 = r.nextDouble();
    return sd * math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
  }

  bool chance(double p) => r.nextDouble() < p;
}

class WeekRow {
  final int week;
  final double trueWeight;
  final double? trend;
  final double trueTdee;
  final double estTdee;
  final double target;
  final Confidence confidence;
  final CheckinReason reason;
  final bool floorHit;
  WeekRow(
    this.week,
    this.trueWeight,
    this.trend,
    this.trueTdee,
    this.estTdee,
    this.target,
    this.confidence,
    this.reason,
    this.floorHit,
  );
}

class SimResult {
  final Scenario s;
  final List<WeekRow> rows;
  SimResult(this.s, this.rows);

  /// First week from which |err| stays within 150 kcal.
  int? convergedWeek() {
    for (var i = 0; i < rows.length; i++) {
      if (rows.skip(i).every((r) => (r.estTdee - r.trueTdee).abs() <= 150)) {
        return rows[i].week;
      }
    }
    return null;
  }
}

SimResult run(Scenario s, {int seed = 42}) {
  final rng = _Rng(seed + s.id.codeUnitAt(0));
  final plan0 = initialPlan(
    profile: s.profile,
    goal: s.goal,
    weightKg: s.startWeight,
    today: today0,
    bodyFatPct: s.bodyFatPct,
  );
  final baseTrueTdee = plan0.tdee + s.formulaError;
  var mass = s.startWeight;
  var target = plan0.macros.kcal;
  final fixedTarget = target;
  double? prevTdee = plan0.tdee;
  final days = <DayLog>[];
  final rows = <WeekRow>[];
  var trueTdee = baseTrueTdee;

  for (var d = 0; d < s.weeks * 7; d++) {
    // Expenditure scales ~22 kcal per kg of mass change plus adaptation.
    trueTdee = baseTrueTdee + 22 * (mass - s.startWeight) + s.adaptation(d);
    final eaten = (s.fixedIntake ? fixedTarget : target) + rng.gauss(150);
    mass += (eaten - trueTdee) / CoachConstants.kcalPerKg;
    final observed = mass + rng.gauss(s.waterNoiseSd);
    days.add(
      DayLog(
        date: today0.add(Duration(days: d)),
        weightKg: rng.chance(s.weighProbability)
            ? double.parse(observed.toStringAsFixed(1))
            : null,
        intakeKcal: rng.chance(s.logProbability) ? eaten.roundToDouble() : null,
      ),
    );

    if ((d + 1) % 7 == 0) {
      final res = weeklyCheckin(
        profile: s.profile,
        goal: s.goal,
        days: days,
        today: today0.add(Duration(days: d)),
        previousTdee: prevTdee,
        bodyFatPct: s.bodyFatPct,
      );
      if (res.adjusted) {
        prevTdee = res.tdeeEstimate;
        target = res.proposal.kcal;
      }
      rows.add(
        WeekRow(
          (d + 1) ~/ 7,
          mass,
          res.trendWeightKg,
          trueTdee,
          res.tdeeEstimate,
          res.proposal.kcal,
          res.confidence,
          res.reason,
          res.floorHit,
        ),
      );
    }
  }
  return SimResult(s, rows);
}

String pad(Object o, int w) => o.toString().padLeft(w);

void printResult(SimResult r) {
  final s = r.s;
  print('\n=== Scenario ${s.id}: ${s.name} ===');
  print(
    ' wk | true kg | trend kg | true TDEE | est TDEE |  err | target | conf   | reason',
  );
  print(
    '----+---------+----------+-----------+----------+------+--------+--------+-------------',
  );
  for (final row in r.rows) {
    final err = (row.estTdee - row.trueTdee).round();
    print(
      '${pad(row.week, 3)} | ${pad(row.trueWeight.toStringAsFixed(1), 7)} | '
      '${pad(row.trend?.toStringAsFixed(1) ?? '-', 8)} | ${pad(row.trueTdee.round(), 9)} | '
      '${pad(row.estTdee.round(), 8)} | ${pad(err, 4)} | ${pad(row.target.round(), 6)} | '
      '${row.confidence.name.padRight(6)} | ${row.reason.name}${row.floorHit ? ' (floor)' : ''}',
    );
  }
  final conv = r.convergedWeek();
  final floor = kcalFloor(s.profile.sex);
  final floorOk = r.rows.every((w) => w.target >= floor - 0.001);
  final weeklyRates = <double>[];
  for (var i = 1; i < r.rows.length; i++) {
    weeklyRates.add(
      (r.rows[i - 1].trueWeight - r.rows[i].trueWeight) /
          r.rows[i - 1].trueWeight *
          100,
    );
  }
  final maxLoss = weeklyRates.isEmpty ? 0.0 : weeklyRates.reduce(math.max);
  print('-> converged within ±150 kcal from week: ${conv ?? 'not converged'}');
  print(
    '-> safety floor respected: $floorOk | max weekly loss: '
    '${maxLoss.toStringAsFixed(2)}% (cap ${CoachConstants.maxLossRatePctPerWeek}%)',
  );
}

void main(List<String> args) {
  final selected = args.map((a) => a.toUpperCase()).toSet();
  for (final s in scenarios()) {
    if (selected.isNotEmpty && !selected.contains(s.id)) continue;
    printResult(run(s));
  }
}
