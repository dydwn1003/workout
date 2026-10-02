import 'dart:math' as math;

import '../data/entities.dart';
import '../data/food.dart';

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

/// A habit visible in the last 4 weeks of meals.
enum MealPatternKind {
  /// Weekends average [MealPattern.amount] kcal more than weekdays.
  weekendHigher,

  /// Snacks are [MealPattern.amount]% of calories; [MealPattern.food] is
  /// the snack eaten most.
  snackHeavy,

  /// Days without breakfast total [MealPattern.amount] kcal more.
  skipBreakfast,
}

class MealPattern {
  final MealPatternKind kind;
  final double amount;
  final String? food;
  const MealPattern(this.kind, this.amount, {this.food});
}

/// Patterns in the 28 days before [today] (today is still in progress),
/// strongest first. Each needs enough logged days to mean something.
List<MealPattern> findMealPatterns(List<Meal> meals, DateTime today) {
  final byDay = <String, List<Meal>>{};
  for (var i = 1; i <= 28; i++) {
    final d = DateTime(today.year, today.month, today.day - i);
    byDay[dateKey(d)] = [];
  }
  for (final m in meals) {
    byDay[m.date]?.add(m);
  }
  final logged = {
    for (final e in byDay.entries)
      if (e.value.isNotEmpty) e.key: e.value,
  };
  double total(List<Meal> ms) => ms.fold(0.0, (a, m) => a + m.kcal);
  double avg(Iterable<double> xs) =>
      xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;
  final out = <(double, MealPattern)>[];

  // Weekend vs weekday.
  final weekend = <double>[], weekday = <double>[];
  for (final e in logged.entries) {
    final wd = parseDateKey(e.key).weekday;
    (wd >= DateTime.saturday ? weekend : weekday).add(total(e.value));
  }
  if (weekend.length >= 3 && weekday.length >= 6) {
    final diff = avg(weekend) - avg(weekday);
    if (diff > 300) {
      out.add((diff, MealPattern(MealPatternKind.weekendHigher, diff)));
    }
  }

  // Snack share.
  final all = [for (final ms in logged.values) ...ms];
  final allKcal = total(all);
  final snacks = [
    for (final m in all)
      if (m.slot == MealSlot.snack) m,
  ];
  if (logged.length >= 7 && allKcal > 0) {
    final share = total(snacks) / allKcal * 100;
    if (share >= 25) {
      final byName = <String, double>{};
      for (final m in snacks) {
        byName[m.name] = (byName[m.name] ?? 0) + m.kcal;
      }
      final top = byName.entries.reduce((a, b) => a.value >= b.value ? a : b);
      // Weighted so a big share outranks a small kcal difference.
      out.add((
        share * 12,
        MealPattern(MealPatternKind.snackHeavy, share, food: top.key),
      ));
    }
  }

  // Skipping breakfast.
  final skipped = <double>[], had = <double>[];
  for (final ms in logged.values) {
    (ms.any((m) => m.slot == MealSlot.breakfast) ? had : skipped).add(
      total(ms),
    );
  }
  if (skipped.length >= 3 && had.length >= 3) {
    final diff = avg(skipped) - avg(had);
    if (diff > 200) {
      out.add((diff, MealPattern(MealPatternKind.skipBreakfast, diff)));
    }
  }

  out.sort((a, b) => b.$1.compareTo(a.$1));
  return [for (final (_, p) in out) p];
}

/// A lighter food of the same kind for something eaten often.
class FoodSwap {
  final Food from;
  final Food to;

  /// Per serving (each food's first unit): kcal saved, 당류 saved (null
  /// when either is unknown).
  final double kcalSaved;
  final double? sugarSaved;
  final int timesEaten;

  /// Per serving, before → after, for showing the whole picture.
  final double fromProteinG;
  final double toProteinG;
  final double? fromSugarG;
  final double? toSugarG;
  const FoodSwap(
    this.from,
    this.to, {
    required this.kcalSaved,
    required this.sugarSaved,
    required this.timesEaten,
    this.fromProteinG = 0,
    this.toProteinG = 0,
    this.fromSugarG,
    this.toSugarG,
  });
}

/// Foods eaten 3+ times in the 28 days before [today] that have a clearly
/// lighter food of the same kind, compared on everything, not just kcal:
/// - same kind (same 대표식품명 for MFDS foods, a shared alias word in the
///   same category for the hand-made ones; a brand's item only within that
///   brand), a published kcal and a similar serving size
/// - 20%+ fewer kcal per serving and fewer per 100 g
/// - a similar make-up: the shares of kcal from protein, carbs and fat
///   close to the original's (a protein shake doesn't become a juice)
/// - protein kept for protein foods (90%+ of it), drinks included
/// - no more 당류 than before and about as much 포화지방 at most (a
///   known value either way)
/// Closest in make-up and nearest to 60% of the kcal first; biggest saving
/// (× times eaten) first across foods.
List<FoodSwap> findFoodSwaps({
  required List<Meal> meals,
  required DateTime today,
  required Food? Function(String id) foodById,
  required List<Food> foods,
  int limit = 3,
}) {
  final since = dateKey(DateTime(today.year, today.month, today.day - 28));
  final counts = <String, int>{};
  for (final m in meals) {
    final id = m.foodId;
    if (id == null || m.date.compareTo(since) < 0) continue;
    counts[id] = (counts[id] ?? 0) + m.servings;
  }
  final frequent = [
    for (final e in counts.entries)
      if (e.value >= 3) ?foodById(e.key),
  ];
  if (frequent.isEmpty) return const [];

  bool curated(Food f) => f.id.startsWith('f');
  Set<String> kinds(Food f) => curated(f)
      ? {
          for (final n in [f.name, ...f.aliases])
            for (final w in n.toLowerCase().split(RegExp(r'\s+')))
              if (w.length >= 2) w,
        }
      : {if (f.aliases.isNotEmpty) f.aliases.first};
  String? brand(Food f) =>
      RegExp(r'\(([^()]+)\)$').firstMatch(f.name)?.group(1);
  double serving(Food f) => f.units.isEmpty ? 100 : f.units.first.grams;
  double per(Food f, double v) => v * serving(f) / 100;

  /// Shares of kcal from protein, carbs and fat (per 100 g).
  (double, double, double) shape(Food f) {
    final p = f.proteinG * 4, c = f.carbsG * 4, fat = f.fatG * 9;
    final sum = p + c + fat;
    return sum <= 0 ? (0, 0, 0) : (p / sum, c / sum, fat / sum);
  }

  double distance(Food a, Food b) {
    final (ap, ac, af) = shape(a);
    final (bp, bc, bf) = shape(b);
    return math.sqrt(
      (ap - bp) * (ap - bp) + (ac - bc) * (ac - bc) + (af - bf) * (af - bf),
    );
  }

  final out = <FoodSwap>[];
  for (final f in frequent) {
    final fk = kinds(f);
    if (fk.isEmpty || f.kcal <= 0) continue;
    final fKcal = per(f, f.kcal), fProtein = per(f, f.proteinG);
    // A protein food: much of its kcal is protein, or a real serving of it.
    final proteinFood = shape(f).$1 >= 0.25 || fProtein >= 10;
    final fSugar = f.sugarG == null ? null : per(f, f.sugarG!);
    final fSat = f.satFatG == null ? null : per(f, f.satFatG!);
    final candidates = [
      for (final g in foods)
        if (g.id != f.id &&
            curated(g) == curated(f) &&
            g.category == f.category &&
            !g.kcalEstimated &&
            !g.unknown.contains('p') &&
            kinds(g).intersection(fk).isNotEmpty &&
            per(g, g.kcal) <= fKcal * 0.8 &&
            // Lighter food, not just a smaller portion of it.
            g.kcal <= f.kcal * 0.9 &&
            per(g, g.kcal) > 0 &&
            serving(g) >= serving(f) * 0.4 &&
            serving(g) <= serving(f) * 1.6 &&
            // Made of the same things.
            distance(f, g) <= 0.35 &&
            (!proteinFood ||
                (per(g, g.proteinG) >= fProtein * 0.9 &&
                    shape(g).$1 >= shape(f).$1 * 0.85)) &&
            // Not sweeter or fattier in the bad way.
            (fSugar == null ||
                (g.sugarG != null && per(g, g.sugarG!) <= fSugar + 0.5)) &&
            (fSat == null ||
                (g.satFatG != null &&
                    per(g, g.satFatG!) <= math.max(fSat * 1.3, fSat + 0.5))))
          g,
    ];
    if (candidates.isEmpty) continue;
    // A brand's menu item is only swapped within that brand's menu.
    final b = brand(f);
    final pool = [
      for (final g in candidates)
        if (b == null || brand(g) == b) g,
    ];
    if (pool.isEmpty) continue;
    // Closest in make-up, then a realistic cut (nearest 60% of the kcal)
    // rather than the emptiest food.
    double score(Food g) =>
        distance(f, g) * 2 + (per(g, g.kcal) / fKcal - 0.6).abs();
    pool.sort((a, c) => score(a).compareTo(score(c)));
    final g = pool.first;
    final gSugar = g.sugarG == null ? null : per(g, g.sugarG!);
    out.add(
      FoodSwap(
        f,
        g,
        kcalSaved: fKcal - per(g, g.kcal),
        sugarSaved: fSugar == null || gSugar == null ? null : fSugar - gSugar,
        timesEaten: counts[f.id]!,
        fromProteinG: fProtein,
        toProteinG: per(g, g.proteinG),
        fromSugarG: fSugar,
        toSugarG: gSugar,
      ),
    );
  }
  out.sort(
    (a, b) =>
        (b.kcalSaved * b.timesEaten).compareTo(a.kcalSaved * a.timesEaten),
  );
  return out.take(limit).toList();
}
