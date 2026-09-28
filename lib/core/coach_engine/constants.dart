/// All tunable algorithm constants live here.
///
/// Every value is a starting default from the product plan and should be
/// validated with the simulator (`dart run tool/simulate.dart`).
class CoachConstants {
  CoachConstants._();

  // --- Energy ---
  /// Approximate energy content of 1 kg of body mass change.
  static const double kcalPerKg = 7700;

  // --- Trend weight (EMA) ---
  static const double trendAlpha = 0.1;

  // --- Observed TDEE window ---
  static const int windowDays = 14;
  static const int minWindowDays = 10;
  static const int maxWindowDays = 21;

  /// A day counts as "logged" only if intake is at least this many kcal.
  /// Filters out obviously incomplete logging days.
  static const double minLoggedDayKcal = 800;

  // --- Blending & smoothing ---
  static const double maxObservedWeight = 0.85;
  static const int fullObservedWeightDays = 28;
  static const double maxWeeklyTdeeChange = 150;

  // --- Safety ---
  static const double minKcalMale = 1500;
  static const double minKcalFemale = 1200;
  static const double maxLossRatePctPerWeek = 1.0;
  static const double maxGainRatePctPerWeek = 0.5;
  static const int minAge = 18;

  /// Weight loss goals are blocked below this BMI.
  static const double minBmiForLoss = 18.5;

  /// Target weight may not be set below this BMI.
  static const double minTargetBmi = 18.5;

  // --- Rates (% of body weight per week) ---
  static const Map<String, double> lossRates = {
    'relaxed': 0.25,
    'normal': 0.5,
    'fast': 0.75,
  };
  static const Map<String, double> gainRates = {
    'relaxed': 0.1,
    'normal': 0.25,
    'fast': 0.4,
  };

  /// Recomposition = slow loss while keeping muscle (assumption, see README).
  static const Map<String, double> recompRates = {
    'relaxed': 0.1,
    'normal': 0.2,
    'fast': 0.3,
  };

  // --- Activity factor by total weekly sessions (strength + cardio) ---
  static double activityFactor(int sessionsPerWeek) {
    if (sessionsPerWeek <= 1) return 1.2;
    if (sessionsPerWeek <= 3) return 1.375;
    if (sessionsPerWeek <= 5) return 1.55;
    return 1.725;
  }

  // --- Macros ---
  static const double proteinLossPerKgLbm = 2.2;
  static const double proteinMaintainPerKgLbm = 1.8;
  static const double proteinLossPerKgBw = 1.8;
  static const double proteinMaintainPerKgBw = 1.6;
  static const double fatMinPerKgBw = 0.6;
  static const double fatMinPctOfKcal = 0.25;
  static const double kcalPerGProtein = 4;
  static const double kcalPerGCarb = 4;
  static const double kcalPerGFat = 9;

  // --- Confidence (per 7-day week) ---
  static const int minLoggedDaysPerWeek = 5;
  static const int minWeighInsPerWeek = 3;
  static const int highLoggedDaysPerWeek = 6;
  static const int highWeighInsPerWeek = 5;

  // --- Plateau ---
  static const int plateauDays = 14;

  /// |trend change| over [plateauDays] below this (kg) counts as flat.
  static const double plateauMaxTrendChangeKg = 0.15;

  // --- Body composition ---
  /// Skeletal muscle decline over 4 weeks beyond this fraction triggers a notice.
  static const double muscleLossWarnFraction = 0.01;
  static const int muscleLossWindowDays = 28;

  // --- ETA ---
  static const int etaSlopeDays = 28;
  static const int etaMinSlopeDays = 21;

  /// ETA range spread (+/-) around the point estimate.
  static const double etaSpread = 0.2;

  // --- Workout feedback (general activity guidelines, not medical advice) ---
  /// WHO: 150-300 min/week of moderate aerobic activity.
  static const int cardioGuidelineMinPerWeek = 150;

  /// WHO: muscle-strengthening on 2+ days/week; also helps keep muscle
  /// while losing weight.
  static const int strengthDaysGuideline = 2;

  /// Consecutive training days after which a rest day is suggested.
  static const int restAfterConsecutiveDays = 7;

  /// Weekly minutes vs the previous 3-week average that count as a notable
  /// change.
  static const int moreThanUsualMin = 30;
  static const int lessThanUsualMin = 60;
}
