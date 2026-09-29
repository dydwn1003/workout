import '../../core/coach_engine/coach_engine.dart';
import '../../data/entities.dart';
import '../../l10n/app_localizations.dart';

String goalLabel(L t, GoalType g) => switch (g) {
  GoalType.lose => t.goalLose,
  GoalType.maintain => t.goalMaintain,
  GoalType.gain => t.goalGain,
  GoalType.recomp => t.goalRecomp,
};

String goalDesc(L t, GoalType g) => switch (g) {
  GoalType.lose => t.goalLoseDesc,
  GoalType.maintain => t.goalMaintainDesc,
  GoalType.gain => t.goalGainDesc,
  GoalType.recomp => t.goalRecompDesc,
};

String paceLabel(L t, Pace p) => switch (p) {
  Pace.relaxed => t.paceRelaxed,
  Pace.normal => t.paceNormal,
  Pace.fast => t.paceFast,
};

String issueLabel(L t, GoalIssue i) => switch (i) {
  GoalIssue.underage => t.issueUnderage,
  GoalIssue.bmiTooLowForLoss => t.issueBmiLow,
  GoalIssue.targetBmiTooLow => t.issueTargetBmiLow,
  GoalIssue.targetDirection => t.issueTargetDirection,
};

String confidenceLabel(L t, Confidence c) => switch (c) {
  Confidence.high => t.confHigh,
  Confidence.medium => t.confMedium,
  Confidence.low => t.confLow,
};

String statusLabel(L t, PlanStatus s) => switch (s) {
  PlanStatus.initial => t.statusInitial,
  PlanStatus.accepted => t.statusAccepted,
  PlanStatus.kept => t.statusKept,
  PlanStatus.manual => t.statusManual,
  PlanStatus.dietBreak => t.statusDietBreak,
};

String etaText(L t, EtaRange? e) {
  if (e == null) return t.etaUnknown;
  if (e.maxWeeks <= 0.5) return t.etaReached;
  final min = e.minWeeks.floor().clamp(1, 999);
  final max = e.maxWeeks.ceil().clamp(min + 1, 999);
  return t.etaWeeks('$min', '$max');
}

String tipText(L t, WorkoutTip tip) => switch (tip.kind) {
  WorkoutTipKind.rest => t.tipRest('${tip.a}'),
  WorkoutTipKind.strengthForLoss => t.tipStrengthForLoss(
    '${tip.b}',
    '${tip.a}',
  ),
  WorkoutTipKind.moreThanUsual => t.tipMoreThanUsual('${tip.a}'),
  WorkoutTipKind.lessThanUsual => t.tipLessThanUsual('${tip.a}'),
  WorkoutTipKind.planDone => t.tipPlanDone('${tip.a}'),
  WorkoutTipKind.planRemaining => t.tipPlanRemaining('${tip.b}', '${tip.a}'),
  WorkoutTipKind.cardioDone => t.tipCardioDone('${tip.a}'),
  WorkoutTipKind.cardioProgress => t.tipCardioProgress('${tip.a}', '${tip.b}'),
};
