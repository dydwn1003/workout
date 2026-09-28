import 'constants.dart';
import 'models.dart';

/// Summary of the last 7 days of training plus context.
class WorkoutSummary {
  final int strengthDays; // distinct days with strength training
  final int cardioMinutes;
  final int totalMinutes;
  final int sessions;
  final int plannedSessions; // per week, from the profile
  final double? previousAvgMinutes; // avg weekly minutes of the 3 prior weeks
  final int consecutiveDays; // training days in a row ending today/yesterday
  final GoalType goalType;

  const WorkoutSummary({
    required this.strengthDays,
    required this.cardioMinutes,
    required this.totalMinutes,
    required this.sessions,
    required this.plannedSessions,
    required this.previousAvgMinutes,
    required this.consecutiveDays,
    required this.goalType,
  });
}

enum WorkoutTipKind {
  rest,
  strengthForLoss,
  moreThanUsual,
  lessThanUsual,
  planDone,
  planRemaining,
  cardioDone,
  cardioProgress,
}

enum TipTone { positive, neutral, nudge }

class WorkoutTip {
  final WorkoutTipKind kind;
  final TipTone tone;

  /// Numbers the message needs (meaning depends on [kind]).
  final int a;
  final int b;

  const WorkoutTip(this.kind, this.tone, [this.a = 0, this.b = 0]);

  @override
  String toString() => 'WorkoutTip($kind, $a, $b)';
}

/// Time-based training feedback, most important first. Empty when the user
/// has no recent training data at all.
List<WorkoutTip> workoutFeedback(WorkoutSummary s) {
  final tips = <WorkoutTip>[];
  if (s.sessions == 0 && (s.previousAvgMinutes ?? 0) == 0) return tips;

  if (s.consecutiveDays >= CoachConstants.restAfterConsecutiveDays) {
    tips.add(WorkoutTip(WorkoutTipKind.rest, TipTone.nudge, s.consecutiveDays));
  }

  final losing = s.goalType == GoalType.lose || s.goalType == GoalType.recomp;
  if (losing && s.strengthDays < CoachConstants.strengthDaysGuideline) {
    tips.add(
      WorkoutTip(
        WorkoutTipKind.strengthForLoss,
        TipTone.nudge,
        s.strengthDays,
        CoachConstants.strengthDaysGuideline,
      ),
    );
  }

  final prev = s.previousAvgMinutes;
  if (prev != null && prev > 0) {
    final diff = (s.totalMinutes - prev).round();
    if (diff >= CoachConstants.moreThanUsualMin) {
      tips.add(
        WorkoutTip(WorkoutTipKind.moreThanUsual, TipTone.positive, diff),
      );
    } else if (-diff >= CoachConstants.lessThanUsualMin) {
      tips.add(
        WorkoutTip(WorkoutTipKind.lessThanUsual, TipTone.neutral, -diff),
      );
    }
  }

  if (s.plannedSessions > 0) {
    if (s.sessions >= s.plannedSessions) {
      tips.add(
        WorkoutTip(
          WorkoutTipKind.planDone,
          TipTone.positive,
          s.plannedSessions,
        ),
      );
    } else {
      tips.add(
        WorkoutTip(
          WorkoutTipKind.planRemaining,
          TipTone.neutral,
          s.plannedSessions - s.sessions,
          s.plannedSessions,
        ),
      );
    }
  }

  if (s.cardioMinutes >= CoachConstants.cardioGuidelineMinPerWeek) {
    tips.add(
      WorkoutTip(WorkoutTipKind.cardioDone, TipTone.positive, s.cardioMinutes),
    );
  } else {
    tips.add(
      WorkoutTip(
        WorkoutTipKind.cardioProgress,
        TipTone.neutral,
        s.cardioMinutes,
        CoachConstants.cardioGuidelineMinPerWeek - s.cardioMinutes,
      ),
    );
  }
  return tips;
}
