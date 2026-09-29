import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/coach_engine/coach_engine.dart';
import '../../data/entities.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../motion.dart';
import '../theme.dart';
import '../widgets.dart';
import 'labels.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  var _forcePreview = false;
  var _goalLater = false;
  var _logsOpen = false;

  String _reasonText(L t, CheckinResult r) => switch (r.reason) {
    CheckinReason.lowConfidence => t.reasonLowConfidence(
      '${r.loggedDaysLastWeek}',
      '${r.weighInsLastWeek}',
    ),
    CheckinReason.plateau => t.reasonPlateau(fmt0(r.tdeeEstimate)),
    CheckinReason.tdeeUp => t.reasonTdeeUp(fmt0(r.tdeeEstimate)),
    CheckinReason.tdeeDown => t.reasonTdeeDown(fmt0(r.tdeeEstimate)),
    CheckinReason.onTrack => t.reasonOnTrack,
  };

  MascotMood _mood(CheckinReason r) => switch (r) {
    CheckinReason.lowConfidence => MascotMood.sleepy,
    CheckinReason.plateau => MascotMood.thinking,
    CheckinReason.tdeeUp || CheckinReason.onTrack => MascotMood.cheer,
    CheckinReason.tdeeDown => MascotMood.happy,
  };

  Future<void> _apply(
    CheckinResult r,
    PlanStatus status, {
    double? kcal,
  }) async {
    final s = AppScope.read(context);
    final t = L.of(context);
    await s.applyCheckin(r, status, manualKcal: kcal);
    if (!mounted) return;
    setState(() => _forcePreview = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (status) {
          PlanStatus.accepted => t.appliedAccept,
          PlanStatus.manual => t.appliedManual,
          _ => t.appliedKeep,
        }),
      ),
    );
  }

  Future<void> _manual(CheckinResult r) async {
    final t = L.of(context);
    final floor = kcalFloor(AppScope.read(context).profile!.sex);
    final c = TextEditingController(text: r.proposal.kcal.round().toString());
    final v = await showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final val = double.tryParse(c.text);
          final ok = val != null && val >= floor && val < 8000;
          return AlertDialog(
            title: Text(t.manualKcalTitle),
            content: TextField(
              controller: c,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setD(() {}),
              decoration: InputDecoration(
                suffixText: 'kcal',
                helperText: t.manualKcalFloor(fmt0(floor)),
                errorText: val != null && val < floor
                    ? t.manualKcalFloor(fmt0(floor))
                    : null,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(t.cancel),
              ),
              TextButton(
                onPressed: ok ? () => Navigator.pop(ctx, val) : null,
                child: Text(t.confirm),
              ),
            ],
          );
        },
      ),
    );
    if (v != null) await _apply(r, PlanStatus.manual, kcal: v);
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final s = AppScope.of(context);
    final locale = Localizations.localeOf(context).toString();
    final plan = s.currentPlan!;
    final due = s.checkinDue;
    final doneToday =
        plan.status != PlanStatus.initial && plan.weekStart == dateKey(s.today);
    final showResult = due || _forcePreview || !doneToday;
    final r = s.runCheckin();
    final next = s.nextCheckinDate;

    return Scaffold(
      appBar: AppBar(title: Text(t.checkinTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              if (!due && next != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 4),
                  child: Row(
                    children: [
                      Pill(
                        text: t.nextCheckin(
                          DateFormat.MMMEd(locale).format(next),
                        ),
                        color: AppColors.peach,
                        soft: AppColors.peachSoft,
                        icon: Icons.event_rounded,
                      ),
                    ],
                  ),
                ),
              if (s.goalReached && !_goalLater) ...[
                FadeSlideIn(child: _goalReachedCard(t)),
                const SizedBox(height: 14),
              ],
              if (s.dietBreakUntil case final until?) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 4),
                  child: Row(
                    children: [
                      Flexible(
                        child: Pill(
                          text: t.breakActive(
                            DateFormat.MMMEd(locale).format(until),
                          ),
                          color: AppColors.mint,
                          soft: AppColors.mintSoft,
                          icon: Icons.spa_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (s.workoutSuggestion case final sug?) ...[
                FadeSlideIn(child: _WorkoutSuggestion(sug: sug)),
                const SizedBox(height: 14),
              ],
              if (doneToday && !_forcePreview) ...[
                SoftCard(
                  child: Column(
                    children: [
                      const Mascot(size: 80, mood: MascotMood.cheer),
                      const SizedBox(height: 10),
                      Text(
                        t.checkinDone,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t.checkinDoneDesc,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.inkSoft,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _targetSummary(t, plan),
                      TextButton(
                        onPressed: () => setState(() => _forcePreview = true),
                        child: Text(t.checkinAnyway),
                      ),
                    ],
                  ),
                ),
              ] else if (r != null && showResult) ...[
                if (!due)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, left: 4),
                    child: Text(
                      t.checkinPreview,
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 13,
                      ),
                    ),
                  ),
                MascotSays(text: _reasonText(t, r), mood: _mood(r.reason)),
                const SizedBox(height: 16),
                if (s.stalled && !s.goalReached) ...[
                  _stallCard(t, plan, r),
                  const SizedBox(height: 16),
                ],
                _statsGrid(t, r),
                const SizedBox(height: 14),
                _proposalCard(t, plan, r),
                if (r.floorHit) ...[
                  const SizedBox(height: 10),
                  Text(
                    t.floorHitCheckin(fmt0(r.proposal.kcal)),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.peach,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                if (r.adjusted) ...[
                  FilledButton.icon(
                    onPressed: () => _apply(r, PlanStatus.accepted),
                    icon: const Icon(Icons.check_rounded),
                    label: Text(t.accept),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: r.adjusted
                          ? OutlinedButton(
                              onPressed: () => _apply(r, PlanStatus.kept),
                              child: Text(t.keep),
                            )
                          : FilledButton(
                              onPressed: () => _apply(r, PlanStatus.kept),
                              child: Text(t.keep),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _manual(r),
                        child: Text(t.adjust),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _report(t, plan, r),
              ],
              const SizedBox(height: 8),
              SectionTitle(t.planHistory),
              SoftCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    for (final p in s.plans.reversed.take(12))
                      ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        title: Text(
                          DateFormat.MMMd(locale)
                              .format(parseDateKey(p.weekStart)),
                        ),
                        subtitle: Text(
                          '${t.estTdee} ${fmt0(p.tdeeEst)} kcal',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Pill(
                              text: statusLabel(t, p.status),
                              color: AppColors.inkSoft,
                              soft: AppColors.line,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${fmt0(p.targetKcal)} kcal',
                              style: const TextStyle(
                                fontFamily: headingFont,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _targetSummary(L t, Plan p) => Row(
    children: [
      _mini(t.dailyTarget, fmt0(p.targetKcal), AppColors.peach),
      _mini(t.protein, '${fmt0(p.proteinG)}g', AppColors.mint),
      _mini(t.carbs, '${fmt0(p.carbsG)}g', const Color(0xFFD49B1F)),
      _mini(t.fat, '${fmt0(p.fatG)}g', AppColors.lilac),
    ],
  );

  Widget _mini(String label, String v, Color c) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: c,
            fontFamily: headingFont,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          v,
          style: const TextStyle(
            fontFamily: headingFont,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ],
    ),
  );

  Widget _statsGrid(L t, CheckinResult r) {
    final conf = r.confidence;
    final (cc, cs) = switch (conf) {
      Confidence.high => (AppColors.mint, AppColors.mintSoft),
      Confidence.medium => (const Color(0xFFD49B1F), AppColors.butterSoft),
      Confidence.low => (AppColors.inkSoft, AppColors.line),
    };
    Widget tile(String label, String value, {String? sub, Widget? trailing}) =>
        Expanded(
          child: SoftCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 4),
                trailing ??
                    Text(
                      value,
                      style: const TextStyle(
                        fontFamily: headingFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                if (sub != null)
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.inkSoft,
                    ),
                  ),
              ],
            ),
          ),
        );
    return Column(
      children: [
        Row(
          children: [
            tile(
              t.avgIntake,
              r.avgIntake == null ? '—' : '${fmt0(r.avgIntake!)} kcal',
              sub: r.observed == null
                  ? null
                  : t.lastNDays('${r.observed!.windowDays}'),
            ),
            const SizedBox(width: 10),
            tile(
              t.trendChange,
              r.trendChangeKg == null ? '—' : '${signed1(r.trendChangeKg!)} kg',
              sub: r.observed == null
                  ? null
                  : t.lastNDays('${r.observed!.windowDays}'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            tile(t.estTdee, '${fmt0(r.tdeeEstimate)} kcal'),
            const SizedBox(width: 10),
            tile(
              t.confidence,
              '',
              trailing: Pill(
                text: confidenceLabel(t, conf),
                color: cc,
                soft: cs,
                icon: Icons.verified_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _proposalCard(L t, Plan current, CheckinResult r) {
    final m = r.proposal;
    final diff = m.kcal - current.targetKcal;
    return SoftCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      t.currentTarget,
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      fmt0(current.targetKcal),
                      style: const TextStyle(
                        fontFamily: headingFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: AppColors.peach),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      t.newTarget,
                      style: const TextStyle(
                        color: AppColors.peach,
                        fontSize: 13,
                      ),
                    ),
                    CountUp(
                      value: m.kcal,
                      format: fmt0,
                      style: const TextStyle(
                        fontFamily: headingFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 34,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Pill(
            text: '${diff >= 0 ? '+' : ''}${fmt0(diff)} kcal',
            color: diff.abs() < 1 ? AppColors.inkSoft : AppColors.peach,
            soft: diff.abs() < 1 ? AppColors.line : AppColors.peachSoft,
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _targetSummary(
            t,
            Plan(
              weekStart: '',
              targetKcal: m.kcal,
              proteinG: m.proteinG,
              carbsG: m.carbsG,
              fatG: m.fatG,
              tdeeEst: r.tdeeEstimate,
              status: PlanStatus.accepted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalReachedCard(L t) => SoftCard(
    color: AppColors.mintSoft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Mascot(size: 72, mood: MascotMood.cheer),
        const SizedBox(height: 8),
        Text(
          t.goalReachedTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          t.goalReachedBody,
          textAlign: TextAlign.center,
          style: const TextStyle(height: 1.5),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: () async {
            final s = AppScope.read(context);
            await s.startMaintenance();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  t.maintainStarted(fmt0(s.currentPlan!.targetKcal)),
                ),
              ),
            );
          },
          child: Text(t.goalReachedMaintain),
        ),
        TextButton(
          onPressed: () => setState(() => _goalLater = true),
          child: Text(t.goalReachedLater),
        ),
      ],
    ),
  );

  /// A 3-week stall: check the logs, lower the target, or take a break.
  Widget _stallCard(L t, Plan current, CheckinResult r) {
    final s = AppScope.read(context);
    final locale = Localizations.localeOf(context).toString();
    final floor = kcalFloor(s.profile!.sex);
    final lower = math.max(
      floor,
      math.min(r.proposal.kcal, current.targetKcal) - 120,
    );
    final days = s.suspiciousDays();
    Widget option(String title, {Widget? body, VoidCallback? onTap}) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: headingFont,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                ?body,
              ],
            ),
          ),
        ),
      ),
    );
    return SoftCard(
      color: AppColors.butterSoft,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.stallTitle,
            style: const TextStyle(
              fontFamily: headingFont,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(t.stallBody, style: const TextStyle(fontSize: 13.5)),
          option(
            t.stallCheckLogs,
            onTap: () => setState(() => _logsOpen = !_logsOpen),
            body: AnimatedSize(
              duration: Motion.medium,
              curve: Motion.ease,
              alignment: Alignment.topCenter,
              child: !_logsOpen
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        days.isEmpty
                            ? t.stallNoSuspicious
                            : '${t.stallCheckLogsBody}\n${[for (final (d, k) in days) '· ${DateFormat.MMMEd(locale).format(d)} ${fmt0(k)} kcal'].join('\n')}',
                        style: const TextStyle(fontSize: 13, height: 1.6),
                      ),
                    ),
            ),
          ),
          option(
            t.stallLower(fmt0(lower)),
            onTap: () => _apply(r, PlanStatus.manual, kcal: lower),
          ),
          option(
            t.stallBreak(fmt0(r.tdeeEstimate)),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                Text(
                  t.stallBreakBody,
                  style: const TextStyle(fontSize: 12.5, height: 1.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final w in [1, 2]) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _startBreak(r, w),
                          child: Text(t.breakWeeks('$w')),
                        ),
                      ),
                      if (w == 1) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startBreak(CheckinResult r, int weeks) async {
    final s = AppScope.read(context);
    final t = L.of(context);
    final locale = Localizations.localeOf(context).toString();
    await s.startDietBreak(r, weeks: weeks);
    if (!mounted) return;
    setState(() => _forcePreview = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t.breakStarted(DateFormat.MMMEd(locale).format(s.dietBreakUntil!)),
        ),
      ),
    );
  }

  /// Step by step: what was eaten, what the weight trend says that means,
  /// the burn it implies, and the new target; then one habit for next week.
  Widget _report(L t, Plan current, CheckinResult r) {
    final s = AppScope.read(context);
    final o = r.observed;
    final gap = r.tdeeEstimate - r.proposal.kcal;
    final kgPerWeek = -gap * 7 / C.kcalPerKg;
    final focus = pickWeeklyFocus(
      loggedDays: r.loggedDaysLastWeek,
      weighIns: r.weighInsLastWeek,
      avgIntake: r.avgIntake,
      targetKcal: current.targetKcal,
      avgProteinG: s.avgProteinLastWeek(),
      targetProteinG: current.proteinG,
    );
    final patterns = s.mealPatterns();
    final focusText = switch (focus.kind) {
      WeeklyFocusKind.logMore => t.focusLogMore(fmt0(focus.amount)),
      WeeklyFocusKind.weighMore => t.focusWeighMore(fmt0(focus.amount)),
      WeeklyFocusKind.keepTarget => t.focusKeepTarget(fmt0(focus.amount)),
      WeeklyFocusKind.moreProtein => t.focusMoreProtein(
        fmt0(focus.amount),
        fmt0(focus.target),
      ),
      WeeklyFocusKind.keepGoing => t.focusKeepGoing,
    };
    final steps = <(String, String)>[
      if (o != null) ...[
        (t.reportAte, t.reportAteValue('${o.windowDays}', fmt0(o.avgIntake))),
        (
          t.reportTrend,
          t.reportTrendValue(
            signed1(o.trendChangeKg),
            fmt0(o.dailyImbalance.abs()),
            o.dailyImbalance < 0 ? t.reportDeficit : t.reportSurplus,
          ),
        ),
        (
          t.reportObserved,
          t.reportObservedValue(
            fmt0(o.avgIntake),
            o.dailyImbalance < 0 ? '+' : '−',
            fmt0(o.dailyImbalance.abs()),
            fmt0(o.tdee),
          ),
        ),
        (
          t.reportEstimate,
          t.reportEstimateValue(
            fmt0(r.tdeeFormula),
            fmt0(r.previousTdee),
            fmt0(r.tdeeEstimate),
          ),
        ),
      ],
      (
        t.reportTarget,
        (gap >= 0 ? t.reportTargetValue : t.reportTargetSurplus)(
          fmt0(r.tdeeEstimate),
          fmt0(gap.abs()),
          fmt0(r.proposal.kcal),
          signed1(kgPerWeek),
        ),
      ),
    ];
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_rounded, color: AppColors.lilac),
              const SizedBox(width: 8),
              Text(
                t.reportTitle,
                style: const TextStyle(
                  fontFamily: headingFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (o == null) ...[
            Text(
              t.reportNoObserved(fmt0(r.tdeeFormula)),
              style: const TextStyle(fontSize: 13.5, height: 1.5),
            ),
            const SizedBox(height: 10),
          ],
          for (final (i, (label, value)) in steps.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.lilacSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.lilac,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (patterns.isNotEmpty) ...[
            const Divider(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.insights_rounded,
                  color: AppColors.sky,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.patternsTitle,
                        style: const TextStyle(
                          fontFamily: headingFont,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      for (final p in patterns.take(2))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            switch (p.kind) {
                              MealPatternKind.weekendHigher => t.patternWeekend(
                                fmt0(p.amount),
                              ),
                              MealPatternKind.snackHeavy => t.patternSnack(
                                fmt0(p.amount),
                                p.food ?? '',
                              ),
                              MealPatternKind.skipBreakfast =>
                                t.patternSkipBreakfast(fmt0(p.amount)),
                            },
                            style: const TextStyle(fontSize: 13.5, height: 1.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.flag_rounded, color: AppColors.mint, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.focusTitle,
                      style: const TextStyle(
                        fontFamily: headingFont,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      focusText,
                      style: const TextStyle(fontSize: 13.5, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkoutSuggestion extends StatelessWidget {
  final (int, int) sug;
  const _WorkoutSuggestion({required this.sug});

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final s = AppScope.of(context);
    final p = s.profile!;
    return SoftCard(
      color: AppColors.mintSoft,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center_rounded, color: AppColors.mint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.workoutSuggestTitle,
                  style: const TextStyle(
                    fontFamily: headingFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            t.workoutSuggestBody(
              '${sug.$1}',
              '${sug.$2}',
              '${p.strengthPerWeek + p.cardioPerWeek}',
            ),
            style: const TextStyle(fontSize: 14, height: 1.55),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.mint),
              onPressed: () async {
                await s.applyWorkoutSuggestion();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.workoutSuggestApplied)),
                );
              },
              child: Text(t.workoutSuggestApply),
            ),
          ),
        ],
      ),
    );
  }
}
