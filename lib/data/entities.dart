import '../core/coach_engine/coach_engine.dart';

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDateKey(String k) {
  final p = k.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.firstWhere((v) => v.name == name, orElse: () => fallback);

double? _d(Object? v) => v == null ? null : (v as num).toDouble();

class UserProfile {
  final Sex sex;
  final int birthYear;
  final double heightCm;
  final GoalType goalType;
  final Pace pace;
  final int strengthPerWeek;
  final int cardioPerWeek;
  final double? targetWeightKg;
  final double? targetBodyFatPct;
  final DateTime createdAt;

  const UserProfile({
    required this.sex,
    required this.birthYear,
    required this.heightCm,
    required this.goalType,
    required this.pace,
    required this.strengthPerWeek,
    required this.cardioPerWeek,
    this.targetWeightKg,
    this.targetBodyFatPct,
    required this.createdAt,
  });

  CoachProfile get coachProfile =>
      CoachProfile(sex: sex, birthYear: birthYear, heightCm: heightCm);

  CoachGoal get coachGoal => CoachGoal(
    type: goalType,
    pace: pace,
    sessionsPerWeek: strengthPerWeek + cardioPerWeek,
    targetWeightKg: targetWeightKg,
  );

  Map<String, Object?> toJson() => {
    'sex': sex.name,
    'birthYear': birthYear,
    'heightCm': heightCm,
    'goalType': goalType.name,
    'pace': pace.name,
    'strengthPerWeek': strengthPerWeek,
    'cardioPerWeek': cardioPerWeek,
    'targetWeightKg': targetWeightKg,
    'targetBodyFatPct': targetBodyFatPct,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, Object?> j) => UserProfile(
    sex: _enumByName(Sex.values, j['sex'], Sex.male),
    birthYear: j['birthYear'] as int,
    heightCm: _d(j['heightCm'])!,
    goalType: _enumByName(GoalType.values, j['goalType'], GoalType.lose),
    pace: _enumByName(Pace.values, j['pace'], Pace.normal),
    strengthPerWeek: j['strengthPerWeek'] as int? ?? 0,
    cardioPerWeek: j['cardioPerWeek'] as int? ?? 0,
    targetWeightKg: _d(j['targetWeightKg']),
    targetBodyFatPct: _d(j['targetBodyFatPct']),
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

enum WeightSource { manual, health }

class WeightEntry {
  final String date; // yyyy-mm-dd
  final double kg;
  final double? bodyFatPct;
  final double? skeletalMuscleKg;
  final WeightSource source;

  const WeightEntry({
    required this.date,
    required this.kg,
    this.bodyFatPct,
    this.skeletalMuscleKg,
    this.source = WeightSource.manual,
  });

  Map<String, Object?> toJson() => {
    'date': date,
    'kg': kg,
    'bodyFatPct': bodyFatPct,
    'skeletalMuscleKg': skeletalMuscleKg,
    'source': source.name,
  };

  factory WeightEntry.fromJson(Map<String, Object?> j) => WeightEntry(
    date: j['date'] as String,
    kg: _d(j['kg'])!,
    bodyFatPct: _d(j['bodyFatPct']),
    skeletalMuscleKg: _d(j['skeletalMuscleKg']),
    source: _enumByName(WeightSource.values, j['source'], WeightSource.manual),
  );
}

enum MealSource { photo, text, saved, manual }

class Meal {
  final String id;
  final String date;
  final DateTime time;
  final String name;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final MealSource source;
  final bool edited;

  const Meal({
    required this.id,
    required this.date,
    required this.time,
    required this.name,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.source,
    this.edited = false,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'date': date,
    'time': time.toIso8601String(),
    'name': name,
    'kcal': kcal,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatG': fatG,
    'source': source.name,
    'edited': edited,
  };

  factory Meal.fromJson(Map<String, Object?> j) => Meal(
    id: j['id'] as String,
    date: j['date'] as String,
    time: DateTime.parse(j['time'] as String),
    name: j['name'] as String,
    kcal: _d(j['kcal'])!,
    proteinG: _d(j['proteinG']) ?? 0,
    carbsG: _d(j['carbsG']) ?? 0,
    fatG: _d(j['fatG']) ?? 0,
    source: _enumByName(MealSource.values, j['source'], MealSource.manual),
    edited: j['edited'] as bool? ?? false,
  );
}

class SavedMeal {
  final String id;
  final String name;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const SavedMeal({
    required this.id,
    required this.name,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'kcal': kcal,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatG': fatG,
  };

  factory SavedMeal.fromJson(Map<String, Object?> j) => SavedMeal(
    id: j['id'] as String,
    name: j['name'] as String,
    kcal: _d(j['kcal'])!,
    proteinG: _d(j['proteinG']) ?? 0,
    carbsG: _d(j['carbsG']) ?? 0,
    fatG: _d(j['fatG']) ?? 0,
  );
}

enum PlanStatus { initial, accepted, kept, manual }

class Plan {
  final String weekStart; // date the plan took effect
  final double targetKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double tdeeEst;
  final Confidence? confidence;
  final CheckinReason? reason;
  final PlanStatus status;

  const Plan({
    required this.weekStart,
    required this.targetKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.tdeeEst,
    this.confidence,
    this.reason,
    required this.status,
  });

  Map<String, Object?> toJson() => {
    'weekStart': weekStart,
    'targetKcal': targetKcal,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatG': fatG,
    'tdeeEst': tdeeEst,
    'confidence': confidence?.name,
    'reason': reason?.name,
    'status': status.name,
  };

  factory Plan.fromJson(Map<String, Object?> j) => Plan(
    weekStart: j['weekStart'] as String,
    targetKcal: _d(j['targetKcal'])!,
    proteinG: _d(j['proteinG']) ?? 0,
    carbsG: _d(j['carbsG']) ?? 0,
    fatG: _d(j['fatG']) ?? 0,
    tdeeEst: _d(j['tdeeEst'])!,
    confidence: j['confidence'] == null
        ? null
        : _enumByName(Confidence.values, j['confidence'], Confidence.low),
    reason: j['reason'] == null
        ? null
        : _enumByName(CheckinReason.values, j['reason'], CheckinReason.onTrack),
    status: _enumByName(PlanStatus.values, j['status'], PlanStatus.initial),
  );
}

class AppSettings {
  /// null = follow system language.
  final String? language;

  /// 1 = Monday ... 7 = Sunday.
  final int checkinWeekday;
  final bool notifications;
  final DateTime? consentedAt;

  const AppSettings({
    this.language,
    this.checkinWeekday = DateTime.monday,
    this.notifications = true,
    this.consentedAt,
  });

  AppSettings copyWith({
    String? Function()? language,
    int? checkinWeekday,
    bool? notifications,
    DateTime? consentedAt,
  }) => AppSettings(
    language: language != null ? language() : this.language,
    checkinWeekday: checkinWeekday ?? this.checkinWeekday,
    notifications: notifications ?? this.notifications,
    consentedAt: consentedAt ?? this.consentedAt,
  );

  Map<String, Object?> toJson() => {
    'language': language,
    'checkinWeekday': checkinWeekday,
    'notifications': notifications,
    'consentedAt': consentedAt?.toIso8601String(),
  };

  factory AppSettings.fromJson(Map<String, Object?> j) => AppSettings(
    language: j['language'] as String?,
    checkinWeekday: j['checkinWeekday'] as int? ?? DateTime.monday,
    notifications: j['notifications'] as bool? ?? true,
    consentedAt: j['consentedAt'] == null
        ? null
        : DateTime.parse(j['consentedAt'] as String),
  );
}
