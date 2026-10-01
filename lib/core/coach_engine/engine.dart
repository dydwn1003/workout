import 'dart:math' as math;

import 'constants.dart';
import 'models.dart';

typedef C = CoachConstants;

// ---------------------------------------------------------------------------
// Trend weight
// ---------------------------------------------------------------------------

/// Exponential moving average of daily weights.
///
/// Missing days carry the previous trend forward. Entries before the first
/// weigh-in are null. The first weigh-in seeds the trend.
List<double?> trendSeries(
  List<double?> weights, {
  double alpha = C.trendAlpha,
}) {
  final out = <double?>[];
  double? trend;
  for (final w in weights) {
    if (w != null) {
      trend = trend == null ? w : trend + alpha * (w - trend);
    }
    out.add(trend);
  }
  return out;
}

double? lastNonNull(List<double?> xs) {
  for (var i = xs.length - 1; i >= 0; i--) {
    if (xs[i] != null) return xs[i];
  }
  return null;
}

// ---------------------------------------------------------------------------
// Formula TDEE (cold start)
// ---------------------------------------------------------------------------

double bmrMifflin({
  required Sex sex,
  required double weightKg,
  required double heightCm,
  required int age,
}) {
  final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  return sex == Sex.male ? base + 5 : base - 161;
}

double bmrKatchMcArdle({required double leanMassKg}) => 370 + 21.6 * leanMassKg;

double leanMass(double weightKg, double bodyFatPct) =>
    weightKg * (1 - bodyFatPct / 100);

/// Uses Katch-McArdle when body fat is known, Mifflin-St Jeor otherwise.
double formulaTdee({
  required CoachProfile profile,
  required double weightKg,
  required int sessionsPerWeek,
  required DateTime today,
  double? bodyFatPct,
}) {
  final bmr = bodyFatPct != null
      ? bmrKatchMcArdle(leanMassKg: leanMass(weightKg, bodyFatPct))
      : bmrMifflin(
          sex: profile.sex,
          weightKg: weightKg,
          heightCm: profile.heightCm,
          age: profile.ageOn(today),
        );
  return bmr * C.activityFactor(sessionsPerWeek);
}

// ---------------------------------------------------------------------------
// Observed TDEE
// ---------------------------------------------------------------------------

bool isLoggedDay(DayLog d) =>
    d.intakeKcal != null && d.intakeKcal! >= C.minLoggedDayKcal;

/// Back-calculates expenditure from logged intake and trend weight change.
///
/// Uses a 14-day window, shrinking to as few as 10 days for short histories
/// and widening to 21 days when logging in the 14-day window is sparse.
/// Returns null when there is not enough data.
ObservedTdee? observedTdee(List<DayLog> days, {List<double?>? trend}) {
  trend ??= trendSeries(days.map((d) => d.weightKg).toList());
  final n = days.length;
  final span = n - 1; // intervals available
  if (span < C.minWindowDays) return null;

  var window = math.min(C.windowDays, span);
  int validIn(int w) => days.sublist(n - w).where(isLoggedDay).length;
  if (validIn(window) < (window * 0.7).ceil() && span >= C.maxWindowDays) {
    window = C.maxWindowDays;
  }

  final recent = days.sublist(n - window);
  final valid = recent.where(isLoggedDay).toList();
  if (valid.length < C.minLoggedDaysPerWeek) return null;

  final start = trend[n - 1 - window];
  final end = trend[n - 1];
  if (start == null || end == null) return null;

  final avgIntake =
      valid.map((d) => d.intakeKcal!).reduce((a, b) => a + b) / valid.length;
  final delta = end - start;
  final imbalance = delta * C.kcalPerKg / window;
  return ObservedTdee(
    avgIntake: avgIntake,
    trendChangeKg: delta,
    dailyImbalance: imbalance,
    tdee: avgIntake - imbalance,
    validDays: valid.length,
    windowDays: window,
  );
}

// ---------------------------------------------------------------------------
// Blending & smoothing
// ---------------------------------------------------------------------------

double observedWeight(int totalValidDays) =>
    math.min(C.maxObservedWeight, totalValidDays / C.fullObservedWeightDays);

double blendTdee({
  required double formula,
  required double observed,
  required int totalValidDays,
}) {
  final beta = observedWeight(totalValidDays);
  return (1 - beta) * formula + beta * observed;
}

double smoothTdee(double blended, double previous) => blended.clamp(
  previous - C.maxWeeklyTdeeChange,
  previous + C.maxWeeklyTdeeChange,
);

// ---------------------------------------------------------------------------
// Target calories
// ---------------------------------------------------------------------------

/// Weekly rate as % of body weight (always positive), capped for safety.
double ratePctPerWeek(GoalType type, Pace pace) {
  final key = pace.name;
  switch (type) {
    case GoalType.lose:
      return math.min(C.lossRates[key]!, C.maxLossRatePctPerWeek);
    case GoalType.recomp:
      return math.min(C.recompRates[key]!, C.maxLossRatePctPerWeek);
    case GoalType.gain:
      return math.min(C.gainRates[key]!, C.maxGainRatePctPerWeek);
    case GoalType.maintain:
      return 0;
  }
}

/// Signed expected weekly weight change (kg/week).
double plannedKgPerWeek(GoalType type, Pace pace, double weightKg) {
  final kg = ratePctPerWeek(type, pace) / 100 * weightKg;
  return type == GoalType.gain ? kg : -kg;
}

double kcalFloor(Sex sex) => sex == Sex.male ? C.minKcalMale : C.minKcalFemale;

TargetResult targetKcal({
  required double tdee,
  required CoachGoal goal,
  required double trendWeightKg,
  required Sex sex,
}) {
  final dailyImbalance =
      plannedKgPerWeek(goal.type, goal.pace, trendWeightKg) * C.kcalPerKg / 7;
  final raw = tdee + dailyImbalance;
  final floor = kcalFloor(sex);
  if (raw < floor) return TargetResult(floor, floorHit: true);
  return TargetResult(raw);
}

// ---------------------------------------------------------------------------
// Macros
// ---------------------------------------------------------------------------

Macros macrosFor({
  required double kcal,
  required double weightKg,
  required GoalType goalType,
  double? bodyFatPct,
}) {
  final losing = goalType == GoalType.lose || goalType == GoalType.recomp;
  final protein = bodyFatPct != null
      ? leanMass(weightKg, bodyFatPct) *
            (losing ? C.proteinLossPerKgLbm : C.proteinMaintainPerKgLbm)
      : weightKg * (losing ? C.proteinLossPerKgBw : C.proteinMaintainPerKgBw);
  final fat = math.max(
    C.fatMinPerKgBw * weightKg,
    kcal * C.fatMinPctOfKcal / C.kcalPerGFat,
  );
  final carbs = math.max(
    0.0,
    (kcal - protein * C.kcalPerGProtein - fat * C.kcalPerGFat) / C.kcalPerGCarb,
  );
  return Macros(kcal: kcal, proteinG: protein, carbsG: carbs, fatG: fat);
}

// ---------------------------------------------------------------------------
// Confidence
// ---------------------------------------------------------------------------

Confidence confidenceFor({required int loggedDays, required int weighIns}) {
  if (loggedDays < C.minLoggedDaysPerWeek || weighIns < C.minWeighInsPerWeek) {
    return Confidence.low;
  }
  if (loggedDays >= C.highLoggedDaysPerWeek &&
      weighIns >= C.highWeighInsPerWeek) {
    return Confidence.high;
  }
  return Confidence.medium;
}

// ---------------------------------------------------------------------------
// Goal helpers
// ---------------------------------------------------------------------------

/// Target weight for a body-fat goal assuming lean mass is kept.
double targetWeightFromBodyFat({
  required double weightKg,
  required double currentBodyFatPct,
  required double targetBodyFatPct,
}) => leanMass(weightKg, currentBodyFatPct) / (1 - targetBodyFatPct / 100);

double bmi(double weightKg, double heightCm) =>
    weightKg / math.pow(heightCm / 100, 2);

enum GoalIssue { underage, bmiTooLowForLoss, targetBmiTooLow, targetDirection }

List<GoalIssue> validateGoal({
  required CoachProfile profile,
  required double weightKg,
  required CoachGoal goal,
  required DateTime today,
}) {
  final issues = <GoalIssue>[];
  if (profile.ageOn(today) < C.minAge) issues.add(GoalIssue.underage);
  final losing = goal.type == GoalType.lose || goal.type == GoalType.recomp;
  if (losing && bmi(weightKg, profile.heightCm) < C.minBmiForLoss) {
    issues.add(GoalIssue.bmiTooLowForLoss);
  }
  final t = goal.targetWeightKg;
  if (t != null) {
    if (losing && bmi(t, profile.heightCm) < C.minTargetBmi) {
      issues.add(GoalIssue.targetBmiTooLow);
    }
    if ((goal.type == GoalType.lose && t >= weightKg) ||
        (goal.type == GoalType.gain && t <= weightKg)) {
      issues.add(GoalIssue.targetDirection);
    }
  }
  return issues;
}

// ---------------------------------------------------------------------------
// ETA
// ---------------------------------------------------------------------------

/// Weeks until [targetKg] is reached. Uses the observed trend slope over the
/// last 3-4 weeks when it points toward the target, otherwise the plan rate.
/// Returns null when no progress toward the target is expected.
EtaRange? etaWeeks({
  required List<double?> trend,
  required double targetKg,
  required double plannedKgPerWeek,
}) {
  final last = lastNonNull(trend);
  if (last == null) return null;
  final remaining = targetKg - last;
  if (remaining.abs() < 0.2) return const EtaRange(0, 0);

  double? rate;
  final n = trend.length;
  if (n - 1 >= C.etaMinSlopeDays) {
    final k = math.min(C.etaSlopeDays, n - 1);
    final start = trend[n - 1 - k];
    if (start != null) {
      final observed = (last - start) / k * 7;
      if (observed.abs() > 0.05 && observed.sign == remaining.sign) {
        rate = observed;
      }
    }
  }
  if (rate == null &&
      plannedKgPerWeek != 0 &&
      plannedKgPerWeek.sign == remaining.sign) {
    rate = plannedKgPerWeek;
  }
  if (rate == null) return null;
  final weeks = remaining / rate;
  return EtaRange(weeks * (1 - C.etaSpread), weeks * (1 + C.etaSpread));
}

// ---------------------------------------------------------------------------
// Body composition
// ---------------------------------------------------------------------------

/// True when skeletal muscle fell by more than the measurement-error band
/// over roughly the last 4 weeks. [entries] are (date, kg), any order.
bool muscleLossWarning(List<(DateTime, double)> entries) {
  if (entries.length < 2) return false;
  final sorted = [...entries]..sort((a, b) => a.$1.compareTo(b.$1));
  final latest = sorted.last;
  final cutoff = latest.$1.subtract(
    const Duration(days: C.muscleLossWindowDays - 7),
  );
  final older = sorted.where((e) => !e.$1.isAfter(cutoff)).toList();
  if (older.isEmpty) return false;
  // Closest measurement to ~4 weeks before the latest one.
  final target = latest.$1.subtract(
    const Duration(days: C.muscleLossWindowDays),
  );
  older.sort(
    (a, b) => (a.$1.difference(target).inDays.abs()).compareTo(
      b.$1.difference(target).inDays.abs(),
    ),
  );
  final base = older.first.$2;
  return (base - latest.$2) / base > C.muscleLossWarnFraction;
}

// ---------------------------------------------------------------------------
// Plans
// ---------------------------------------------------------------------------

class InitialPlan {
  final double tdee;
  final Macros macros;
  final bool floorHit;

  const InitialPlan(this.tdee, this.macros, this.floorHit);
}

InitialPlan initialPlan({
  required CoachProfile profile,
  required CoachGoal goal,
  required double weightKg,
  required DateTime today,
  double? bodyFatPct,
  // What check-ins already learned from the logs (a goal changed later),
  // in place of the formula.
  double? tdee,
}) {
  tdee ??= formulaTdee(
    profile: profile,
    weightKg: weightKg,
    sessionsPerWeek: goal.sessionsPerWeek,
    today: today,
    bodyFatPct: bodyFatPct,
  );
  final t = targetKcal(
    tdee: tdee,
    goal: goal,
    trendWeightKg: weightKg,
    sex: profile.sex,
  );
  return InitialPlan(
    tdee,
    macrosFor(
      kcal: t.kcal,
      weightKg: weightKg,
      goalType: goal.type,
      bodyFatPct: bodyFatPct,
    ),
    t.floorHit,
  );
}

/// Full weekly check-in pipeline.
///
/// [days] must be contiguous daily logs ending today (oldest first).
/// [previousTdee] is last week's estimate (null on the first check-in).
CheckinResult weeklyCheckin({
  required CoachProfile profile,
  required CoachGoal goal,
  required List<DayLog> days,
  required DateTime today,
  double? previousTdee,
  double? bodyFatPct,
}) {
  final trend = trendSeries(days.map((d) => d.weightKg).toList());
  final trendNow = lastNonNull(trend);
  final weight = trendNow ?? 70.0;

  final formula = formulaTdee(
    profile: profile,
    weightKg: weight,
    sessionsPerWeek: goal.sessionsPerWeek,
    today: today,
    bodyFatPct: bodyFatPct,
  );
  final prev = previousTdee ?? formula;

  final lastWeek = days.length > 7 ? days.sublist(days.length - 7) : days;
  final logged = lastWeek.where(isLoggedDay).length;
  final weighIns = lastWeek.where((d) => d.weightKg != null).length;
  final confidence = confidenceFor(loggedDays: logged, weighIns: weighIns);

  final observed = observedTdee(days, trend: trend);
  final totalValid = days.where(isLoggedDay).length;

  var tdee = prev;
  var reason = CheckinReason.lowConfidence;
  var adjusted = false;

  if (confidence != Confidence.low && trendNow != null) {
    final blended = observed == null
        ? formula
        : blendTdee(
            formula: formula,
            observed: observed.tdee,
            totalValidDays: totalValid,
          );
    tdee = smoothTdee(blended, prev);
    adjusted = true;

    final losing = goal.type == GoalType.lose || goal.type == GoalType.recomp;
    final n = trend.length;
    final flat =
        n - 1 >= C.plateauDays &&
        trend[n - 1 - C.plateauDays] != null &&
        (trendNow - trend[n - 1 - C.plateauDays]!).abs() <
            C.plateauMaxTrendChangeKg;
    if (losing && flat && confidence == Confidence.high && tdee < prev - 25) {
      reason = CheckinReason.plateau;
    } else if (tdee > prev + 25) {
      reason = CheckinReason.tdeeUp;
    } else if (tdee < prev - 25) {
      reason = CheckinReason.tdeeDown;
    } else {
      reason = CheckinReason.onTrack;
    }
  }

  final target = targetKcal(
    tdee: tdee,
    goal: goal,
    trendWeightKg: weight,
    sex: profile.sex,
  );
  final macros = macrosFor(
    kcal: target.kcal,
    weightKg: weight,
    goalType: goal.type,
    bodyFatPct: bodyFatPct,
  );

  return CheckinResult(
    avgIntake: observed?.avgIntake,
    trendChangeKg: observed?.trendChangeKg,
    tdeeFormula: formula,
    observed: observed,
    previousTdee: prev,
    tdeeEstimate: tdee,
    proposal: macros,
    confidence: confidence,
    reason: reason,
    floorHit: target.floorHit,
    adjusted: adjusted,
    trendWeightKg: trendNow,
    loggedDaysLastWeek: logged,
    weighInsLastWeek: weighIns,
  );
}
