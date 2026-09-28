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
                _howCalculated(t, r),
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

  Widget _howCalculated(L t, CheckinResult r) {
    final o = r.observed;
    final body = o == null
        ? t.noObservedYet(fmt0(r.tdeeFormula))
        : t.howCalculatedBody(
            '${o.windowDays}',
            fmt0(o.avgIntake),
            signed1(o.trendChangeKg),
            fmt0(o.tdee),
            fmt0(r.tdeeFormula),
            fmt0(r.tdeeEstimate),
          );
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: SoftCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(),
          leading: const Icon(Icons.calculate_rounded, color: AppColors.lilac),
          title: Text(
            t.howCalculated,
            style: const TextStyle(
              fontFamily: headingFont,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          children: [
            Text(body, style: const TextStyle(height: 1.6, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
