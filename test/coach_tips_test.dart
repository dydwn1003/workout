import 'package:adapt_coach/data/entities.dart';
import 'package:adapt_coach/data/food_db.g.dart';
import 'package:adapt_coach/state/coach_tips.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DailyTip? tip({
    int hour = 15,
    double eatenKcal = 1200,
    double eatenProteinG = 60,
    int meals = 2,
    bool missed = false,
    double? sugar,
    double? satFat,
  }) => pickDailyTip(
    hour: hour,
    targetKcal: 2000,
    targetProteinG: 120,
    eatenKcal: eatenKcal,
    eatenProteinG: eatenProteinG,
    mealsToday: meals,
    missedYesterday: missed,
    sugarG: sugar,
    sugarLimitG: 50,
    satFatG: satFat,
    satFatLimitG: 15,
    proteinFood: (name: '닭가슴살', proteinPer100g: 23),
  );

  group('daily tip', () {
    test('a missed yesterday comes first in the morning', () {
      expect(tip(hour: 9, missed: true)!.kind, DailyTipKind.missedYesterday);
      expect(
        tip(hour: 20, missed: true)!.kind,
        isNot(DailyTipKind.missedYesterday),
      );
    });
    test('morning with nothing logged shows the plan; later nothing', () {
      expect(tip(hour: 8, meals: 0)!.kind, DailyTipKind.morningPlan);
      expect(tip(hour: 13, meals: 0), isNull);
    });
    test('over target, then sugar, then saturated fat', () {
      expect(tip(eatenKcal: 2300, sugar: 80)!.kind, DailyTipKind.overKcal);
      expect(tip(sugar: 60, satFat: 20)!.kind, DailyTipKind.overSugar);
      expect(tip(satFat: 20)!.kind, DailyTipKind.overSatFat);
    });
    test('protein left suggests a portion in 50 g steps', () {
      final t = tip(eatenProteinG: 60)!;
      expect(t.kind, DailyTipKind.proteinLeft);
      expect(t.amount, 60);
      expect(t.grams, 200); // 60 * 0.8 / 23 * 100 = 209 -> 200
    });
    test('little left before dinner, otherwise on track', () {
      expect(
        tip(hour: 13, eatenKcal: 1700, eatenProteinG: 110)!.kind,
        DailyTipKind.lowKcalLeft,
      );
      expect(
        tip(hour: 19, eatenKcal: 1700, eatenProteinG: 110)!.kind,
        DailyTipKind.onTrack,
      );
    });
  });

  group('weekly focus', () {
    WeeklyFocus focus({
      int logged = 7,
      int weighs = 5,
      double? avg = 1900,
      double? protein = 110,
    }) => pickWeeklyFocus(
      loggedDays: logged,
      weighIns: weighs,
      avgIntake: avg,
      targetKcal: 1800,
      avgProteinG: protein,
      targetProteinG: 120,
    );
    test('logging, then weighing, then target, then protein', () {
      expect(focus(logged: 3).kind, WeeklyFocusKind.logMore);
      expect(focus(weighs: 1).kind, WeeklyFocusKind.weighMore);
      expect(focus(avg: 2100).kind, WeeklyFocusKind.keepTarget);
      expect(focus(protein: 80).kind, WeeklyFocusKind.moreProtein);
      expect(focus().kind, WeeklyFocusKind.keepGoing);
    });
  });

  group('meal patterns', () {
    final today = DateTime(2026, 9, 29); // Tuesday
    Meal meal(DateTime d, MealSlot slot, double kcal, [String name = 'x']) =>
        Meal(
          id: '${d.toIso8601String()}-${slot.name}-$name',
          date: dateKey(d),
          time: d,
          name: name,
          kcal: kcal,
          proteinG: 0,
          carbsG: 0,
          fatG: 0,
          source: MealSource.manual,
          slot: slot,
        );
    List<Meal> month({
      double weekend = 2000,
      double snack = 0,
      bool breakfast = true,
    }) => [
      for (var i = 1; i <= 28; i++)
        ...() {
          final d = DateTime(today.year, today.month, today.day - i);
          final we = d.weekday >= DateTime.saturday;
          return [
            if (breakfast || i.isEven) meal(d, MealSlot.breakfast, 400),
            meal(d, MealSlot.lunch, we ? weekend - 400 - snack : 1600 - snack),
            if (snack > 0) meal(d, MealSlot.snack, snack, '과자'),
          ];
        }(),
    ];

    test('weekends much higher than weekdays', () {
      final p = findMealPatterns(month(weekend: 2600), today);
      expect(p.first.kind, MealPatternKind.weekendHigher);
      expect(p.first.amount, closeTo(600, 1));
    });
    test('snack-heavy names the top snack', () {
      final p = findMealPatterns(month(snack: 600, weekend: 2000), today);
      expect(p.first.kind, MealPatternKind.snackHeavy);
      expect(p.first.food, '과자');
    });
    test('nothing notable, nothing said', () {
      expect(findMealPatterns(month(), today), isEmpty);
    });
  });

  group('food swaps', () {
    final today = DateTime(2026, 9, 29);
    final byId = {for (final f in builtInFoods) f.id: f};
    List<FoodSwap> swapsFor(String name, {int times = 3}) {
      final f = builtInFoods.firstWhere((f) => f.name == name);
      return findFoodSwaps(
        meals: [
          for (var i = 1; i <= times; i++)
            Meal(
              id: '$i',
              date: dateKey(DateTime(2026, 9, 29 - i)),
              time: today,
              name: f.name,
              kcal: 100,
              proteinG: 0,
              carbsG: 0,
              fatG: 0,
              source: MealSource.search,
              slot: MealSlot.lunch,
              foodId: f.id,
            ),
        ],
        today: today,
        foodById: (id) => byId[id],
        foods: builtInFoods,
      );
    }

    test('a lighter food of the same kind', () {
      expect(swapsFor('삼겹살').single.to.name, '목살');
      expect(swapsFor('바닐라라떼').single.to.name, '카페라떼');
    });
    test('brand items stay within the brand', () {
      final s = swapsFor('커피 카페 라떼 핫(HOT) (Tall) (스타벅스)').single;
      expect(s.to.name, endsWith('(스타벅스)'));
      expect(s.kcalSaved, greaterThan(0));
    });
    test('not for foods eaten fewer than 3 times', () {
      expect(swapsFor('삼겹살', times: 2), isEmpty);
    });
  });
}
