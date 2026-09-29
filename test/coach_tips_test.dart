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
}
