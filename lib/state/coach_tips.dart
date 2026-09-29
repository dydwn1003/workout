import '../data/entities.dart';

/// What today's one-line coaching talks about, most urgent first.
enum DailyTipKind {
  /// Yesterday has no meals although the user logs regularly.
  missedYesterday,

  /// Over the calorie target by [DailyTip.amount] kcal.
  overKcal,

  /// 당류 over its limit by [DailyTip.amount] g.
  overSugar,

  /// 포화지방 over its limit by [DailyTip.amount] g.
  overSatFat,

  /// Afternoon with [DailyTip.amount] g protein still to go; [DailyTip.food]
  /// and [DailyTip.grams] suggest how to get most of it.
  proteinLeft,

  /// Only [DailyTip.amount] kcal left before dinner.
  lowKcalLeft,

  /// Morning, nothing logged yet: today's target [DailyTip.amount] kcal and
  /// [DailyTip.grams] g protein.
  morningPlan,

  /// Everything within target so far.
  onTrack,
}

class DailyTip {
  final DailyTipKind kind;
  final double amount;
  final String? food;
  final double? grams;
  const DailyTip(this.kind, {this.amount = 0, this.food, this.grams});
}

/// Picks the one thing worth saying today. [hour] is the local hour now.
DailyTip? pickDailyTip({
  required int hour,
  required double targetKcal,
  required double targetProteinG,
  required double eatenKcal,
  required double eatenProteinG,
  required int mealsToday,
  required bool missedYesterday,
  required double? sugarG,
  required double? sugarLimitG,
  required double? satFatG,
  required double? satFatLimitG,
  required ({String name, double proteinPer100g})? proteinFood,
}) {
  if (missedYesterday && hour < 14) {
    return const DailyTip(DailyTipKind.missedYesterday);
  }
  if (mealsToday == 0) {
    return hour < 12
        ? DailyTip(
            DailyTipKind.morningPlan,
            amount: targetKcal,
            grams: targetProteinG,
          )
        : null;
  }
  final over = eatenKcal - targetKcal;
  if (over > 100) return DailyTip(DailyTipKind.overKcal, amount: over);
  if (sugarG != null && sugarLimitG != null && sugarG > sugarLimitG) {
    return DailyTip(DailyTipKind.overSugar, amount: sugarG - sugarLimitG);
  }
  if (satFatG != null && satFatLimitG != null && satFatG > satFatLimitG) {
    return DailyTip(DailyTipKind.overSatFat, amount: satFatG - satFatLimitG);
  }
  final proteinLeft = targetProteinG - eatenProteinG;
  final kcalLeft = targetKcal - eatenKcal;
  if (hour >= 14 && proteinLeft >= 25) {
    final f = proteinFood;
    // Enough of the food for most of what's left, in 50 g steps, 100-300 g.
    final grams = f == null
        ? null
        : ((proteinLeft * 0.8 / f.proteinPer100g * 100) / 50).round() * 50.0;
    return DailyTip(
      DailyTipKind.proteinLeft,
      amount: proteinLeft,
      food: f?.name,
      grams: grams?.clamp(100, 300).toDouble(),
    );
  }
  if (hour < 17 && kcalLeft > 0 && kcalLeft < 400) {
    return DailyTip(DailyTipKind.lowKcalLeft, amount: kcalLeft);
  }
  return const DailyTip(DailyTipKind.onTrack);
}

/// Whether [d] has no meals although the user logged on most of the six
/// days before it (someone who rarely logs isn't nagged).
bool missedDay(List<Meal> meals, DateTime d) {
  final dates = {for (final m in meals) m.date};
  if (dates.contains(dateKey(d))) return false;
  var logged = 0;
  for (var i = 1; i <= 6; i++) {
    if (dates.contains(dateKey(DateTime(d.year, d.month, d.day - i)))) {
      logged++;
    }
  }
  return logged >= 4;
}

/// The one habit a check-in asks for next week, most important first.
enum WeeklyFocusKind {
  /// Fewer than 5 days of meals logged.
  logMore,

  /// Fewer than 3 weigh-ins.
  weighMore,

  /// Average intake [WeeklyFocus.amount] kcal over the target.
  keepTarget,

  /// Average protein [WeeklyFocus.amount] g of [WeeklyFocus.target] g.
  moreProtein,

  /// Nothing to fix: keep going.
  keepGoing,
}

class WeeklyFocus {
  final WeeklyFocusKind kind;
  final double amount;
  final double target;
  const WeeklyFocus(this.kind, {this.amount = 0, this.target = 0});
}

WeeklyFocus pickWeeklyFocus({
  required int loggedDays,
  required int weighIns,
  required double? avgIntake,
  required double targetKcal,
  required double? avgProteinG,
  required double targetProteinG,
}) {
  if (loggedDays < 5) {
    return WeeklyFocus(WeeklyFocusKind.logMore, amount: loggedDays.toDouble());
  }
  if (weighIns < 3) {
    return WeeklyFocus(WeeklyFocusKind.weighMore, amount: weighIns.toDouble());
  }
  if (avgIntake != null && avgIntake - targetKcal > 150) {
    return WeeklyFocus(
      WeeklyFocusKind.keepTarget,
      amount: avgIntake - targetKcal,
    );
  }
  if (avgProteinG != null && avgProteinG < targetProteinG * 0.8) {
    return WeeklyFocus(
      WeeklyFocusKind.moreProtein,
      amount: avgProteinG,
      target: targetProteinG,
    );
  }
  return const WeeklyFocus(WeeklyFocusKind.keepGoing);
}
