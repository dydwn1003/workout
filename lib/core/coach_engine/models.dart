enum Sex { male, female }

enum GoalType { lose, maintain, gain, recomp }

enum Pace { relaxed, normal, fast }

enum Confidence { high, medium, low }

/// Minimal profile the engine needs.
class CoachProfile {
  final Sex sex;
  final int birthYear;
  final double heightCm;

  const CoachProfile({
    required this.sex,
    required this.birthYear,
    required this.heightCm,
  });

  int ageOn(DateTime date) => date.year - birthYear;
}

class CoachGoal {
  final GoalType type;
  final Pace pace;

  /// Total weekly training sessions (strength + cardio).
  final int sessionsPerWeek;
  final double? targetWeightKg;

  const CoachGoal({
    required this.type,
    required this.pace,
    required this.sessionsPerWeek,
    this.targetWeightKg,
  });
}

/// One calendar day of input data. Days must be contiguous when passed
/// to the engine (use nulls for missing data).
class DayLog {
  final DateTime date;
  final double? weightKg;

  /// Total logged intake for the day, or null when nothing was logged.
  final double? intakeKcal;

  const DayLog({required this.date, this.weightKg, this.intakeKcal});
}

class Macros {
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const Macros({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  @override
  String toString() =>
      'Macros(${kcal.round()} kcal, P${proteinG.round()} C${carbsG.round()} F${fatG.round()})';
}

class TargetResult {
  final double kcal;

  /// True if the safety floor raised the target.
  final bool floorHit;

  const TargetResult(this.kcal, {this.floorHit = false});
}

class ObservedTdee {
  final double avgIntake;
  final double trendChangeKg;
  final double dailyImbalance;
  final double tdee;
  final int validDays;
  final int windowDays;

  const ObservedTdee({
    required this.avgIntake,
    required this.trendChangeKg,
    required this.dailyImbalance,
    required this.tdee,
    required this.validDays,
    required this.windowDays,
  });
}

class EtaRange {
  final double minWeeks;
  final double maxWeeks;

  const EtaRange(this.minWeeks, this.maxWeeks);
}

enum CheckinReason {
  /// Not enough data this week; target kept.
  lowConfidence,

  /// Weight trend is flat while losing — expenditure seems lower.
  plateau,

  /// Estimated expenditure went up.
  tdeeUp,

  /// Estimated expenditure went down.
  tdeeDown,

  /// No meaningful change.
  onTrack,
}

class CheckinResult {
  final double? avgIntake;
  final double? trendChangeKg;
  final double tdeeFormula;
  final ObservedTdee? observed;
  final double previousTdee;
  final double tdeeEstimate;
  final Macros proposal;
  final Confidence confidence;
  final CheckinReason reason;
  final bool floorHit;
  final bool adjusted;
  final double? trendWeightKg;
  final int loggedDaysLastWeek;
  final int weighInsLastWeek;

  const CheckinResult({
    required this.avgIntake,
    required this.trendChangeKg,
    required this.tdeeFormula,
    required this.observed,
    required this.previousTdee,
    required this.tdeeEstimate,
    required this.proposal,
    required this.confidence,
    required this.reason,
    required this.floorHit,
    required this.adjusted,
    required this.trendWeightKg,
    required this.loggedDaysLastWeek,
    required this.weighInsLastWeek,
  });
}
