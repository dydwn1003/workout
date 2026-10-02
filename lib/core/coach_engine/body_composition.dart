import 'dart:math' as math;

import 'constants.dart';
import 'models.dart';

typedef _C = CoachConstants;

/// A weigh-in with body fat (from a body-composition scale or InBody).
class BodyCompSample {
  final DateTime date;
  final double weightKg;
  final double bodyFatPct;
  const BodyCompSample(this.date, this.weightKg, this.bodyFatPct);

  double get fatKg => weightKg * bodyFatPct / 100;
  double get leanKg => weightKg - fatKg;
}

/// What the measurements say to do about the plan.
enum CompositionAdvice {
  none,

  /// Losing, but too much of it is lean mass: slow down, more protein.
  leanLoss,

  /// Gaining, but mostly fat: smaller surplus.
  fatGain,

  /// Recomposition is working: fat down, lean mass up.
  recompWorking,
}

/// How the weight changed over the last weeks, split into fat and lean mass.
class CompositionChange {
  final int days;
  final int samples;
  final double fatChangeKg;
  final double leanChangeKg;

  /// Energy in one kg of this weight change, used in place of 7,700 kcal
  /// when the change is big enough to tell (null: keep 7,700).
  final double? kcalPerKg;
  final CompositionAdvice advice;

  const CompositionChange({
    required this.days,
    required this.samples,
    required this.fatChangeKg,
    required this.leanChangeKg,
    required this.kcalPerKg,
    required this.advice,
  });

  double get weightChangeKg => fatChangeKg + leanChangeKg;

  /// Share of the weight change that was lean mass (0..1 when both moved
  /// the same way).
  double get leanShare =>
      weightChangeKg == 0 ? 0 : leanChangeKg / weightChangeKg;
}

/// Splits recent weight change into fat and lean mass from body-fat
/// measurements of the last [_C.compWindowDays] days.
///
/// Needs at least two measurements [_C.compMinSpanDays] days apart. With
/// three or more, a straight line through each mass smooths the scale's
/// day-to-day error; with two, their difference is used and trusted less.
/// Returns null when there isn't enough to say.
CompositionChange? compositionChange(
  List<BodyCompSample> samples, {
  required DateTime today,
  required GoalType goal,
}) {
  final from = today.subtract(const Duration(days: _C.compWindowDays));
  final recent = [
    for (final s in samples)
      if (!s.date.isBefore(from) && !s.date.isAfter(today)) s,
  ]..sort((a, b) => a.date.compareTo(b.date));
  if (recent.length < 2) return null;
  final span = recent.last.date.difference(recent.first.date).inDays;
  if (span < _C.compMinSpanDays) return null;

  double fat, lean;
  if (recent.length >= 3) {
    double slope(double Function(BodyCompSample) y) {
      final xs = [
        for (final s in recent)
          s.date.difference(recent.first.date).inHours / 24,
      ];
      final ys = recent.map(y).toList();
      final mx = xs.reduce((a, b) => a + b) / xs.length;
      final my = ys.reduce((a, b) => a + b) / ys.length;
      var num = 0.0, den = 0.0;
      for (var i = 0; i < xs.length; i++) {
        num += (xs[i] - mx) * (ys[i] - my);
        den += (xs[i] - mx) * (xs[i] - mx);
      }
      return den == 0 ? 0 : num / den;
    }

    fat = slope((s) => s.fatKg) * span;
    lean = slope((s) => s.leanKg) * span;
  } else {
    fat = recent.last.fatKg - recent.first.fatKg;
    lean = recent.last.leanKg - recent.first.leanKg;
  }
  final weight = fat + lean;

  // kcal per kg of this change. Only when the weight clearly moved and fat
  // moved the same way (else the ratio is noise), pulled toward 7,700 by how
  // much the measurements can be trusted.
  double? perKg;
  if (weight.abs() >= _C.compMinChangeKg && fat * weight > 0) {
    final raw = (fat * _C.kcalPerKgFat + lean * _C.kcalPerKgLean) / weight;
    final trust = recent.length >= 3 ? 0.75 : 0.5;
    perKg = (_C.kcalPerKg + trust * (raw - _C.kcalPerKg)).clamp(
      _C.compMinKcalPerKg,
      _C.kcalPerKgFat,
    );
  }

  final losing = goal == GoalType.lose || goal == GoalType.recomp;
  var advice = CompositionAdvice.none;
  if (losing &&
      weight <= -_C.compMinChangeKg &&
      lean <= -_C.compMinLeanLossKg &&
      lean / weight > _C.leanLossShareLimit) {
    advice = CompositionAdvice.leanLoss;
  } else if (goal == GoalType.gain &&
      weight >= _C.compMinChangeKg &&
      fat / weight > _C.fatGainShareLimit) {
    advice = CompositionAdvice.fatGain;
  } else if (goal == GoalType.recomp &&
      fat <= -_C.compMinLeanLossKg &&
      lean >= _C.compRecompLeanGainKg) {
    advice = CompositionAdvice.recompWorking;
  }

  return CompositionChange(
    days: span,
    samples: recent.length,
    fatChangeKg: fat,
    leanChangeKg: lean,
    kcalPerKg: perKg,
    advice: advice,
  );
}

/// Where the day's energy goes: resting (BMR), digesting food (about 10% of
/// what's eaten) and moving (the rest, workouts and daily activity).
class BurnBreakdown {
  final double bmr;
  final double digestion;
  final double activity;

  /// The BMR came from lean mass (Katch-McArdle), not height and age.
  final bool fromLeanMass;
  const BurnBreakdown({
    required this.bmr,
    required this.digestion,
    required this.activity,
    required this.fromLeanMass,
  });
}

BurnBreakdown burnBreakdown({
  required double tdee,
  required double bmr,
  required double intake,
  required bool fromLeanMass,
}) {
  final digestion = intake * _C.digestionShare;
  return BurnBreakdown(
    bmr: bmr,
    digestion: digestion,
    activity: math.max(0, tdee - bmr - digestion),
    fromLeanMass: fromLeanMass,
  );
}
