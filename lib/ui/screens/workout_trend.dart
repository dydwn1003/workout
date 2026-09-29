import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../motion.dart';
import '../theme.dart';
import '../widgets.dart';
import 'workout_tips.dart';

/// Weekly training sessions (stacked strength/cardio bars) for the last
/// 8 weeks, with the profile's planned sessions as a dashed line.
class WorkoutTrendCard extends StatelessWidget {
  const WorkoutTrendCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final s = AppScope.of(context);
    final weeks = s.workoutWeeks();
    final p = s.profile!;
    final planned = p.strengthPerWeek + p.cardioPerWeek;
    final last = weeks.last;
    final last4 = weeks.sublist(weeks.length - 4);
    final avg = last4.fold(0, (a, w) => a + w.sessions) / 4;
    final locale = Localizations.localeOf(context).toString();
    final hasData = weeks.any((w) => w.sessions > 0);

    Widget stat(
      String label,
      String value,
      Color c,
      Color soft,
      IconData icon,
    ) => Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: soft.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: c),
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
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontFamily: headingFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: c,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    Widget legend(Color c, String label, {bool dashed = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dashed ? 16 : 10,
          height: dashed ? 3 : 10,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
        ),
      ],
    );

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: !hasData
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                t.noWorkoutData,
                style: const TextStyle(color: AppColors.inkSoft),
              ),
            )
          : Column(
              children: [
                Row(
                  children: [
                    stat(
                      t.workoutThisWeek,
                      t.workoutThisWeekValue(
                        '${last.sessions}',
                        '${last.minutes}',
                      ),
                      AppColors.mint,
                      AppColors.mintSoft,
                      Icons.local_fire_department_rounded,
                    ),
                    const SizedBox(width: 10),
                    stat(
                      t.workoutAvg4w,
                      t.workoutAvgValue(avg.toStringAsFixed(1)),
                      AppColors.sky,
                      AppColors.skySoft,
                      Icons.insights_rounded,
                    ),
                  ],
                ),
                if (planned > 0) ...[
                  const SizedBox(height: 12),
                  _GoalProgress(
                    label: t.workoutWeeklyGoal,
                    value: t.workoutGoalValue('${last.sessions}', '$planned'),
                    progress: last.sessions / planned,
                  ),
                ],
                const SizedBox(height: 14),
                for (final (i, tip) in s.workoutTips().take(4).indexed) ...[
                  WorkoutTipRow(tip: tip, index: i),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 6),
                SizedBox(
                  height: 150,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Motion.slow,
                    curve: Motion.emphasized,
                    builder: (context, v, _) => CustomPaint(
                      size: Size.infinite,
                      painter: _WorkoutBarsPainter(
                        weeks,
                        planned,
                        v,
                        DateFormat.Md(locale),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    legend(AppColors.mint, t.strength),
                    legend(AppColors.sky, t.cardio),
                    legend(AppColors.peach, t.legendPlanned, dashed: true),
                  ],
                ),
              ],
            ),
    );
  }
}

/// "주간 목표 달성 3/4회" with a rounded bar that fills in.
class _GoalProgress extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  const _GoalProgress({
    required this.label,
    required this.value,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final done = progress >= 1;
    final c = done ? AppColors.mint : AppColors.peach;
    return Column(
      children: [
        Row(
          children: [
            if (done) ...[
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppColors.mint,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontFamily: headingFont,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: c,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
              duration: Motion.slow,
              curve: Motion.emphasized,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                backgroundColor: AppColors.line,
                valueColor: AlwaysStoppedAnimation(c),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkoutBarsPainter extends CustomPainter {
  final List<WorkoutWeek> weeks;
  final int planned;
  final double progress;
  final DateFormat fmt;

  _WorkoutBarsPainter(this.weeks, this.planned, this.progress, this.fmt);

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 22.0, bottomPad = 20.0, topPad = 6.0;
    final chart = Rect.fromLTRB(
      leftPad,
      topPad,
      size.width,
      size.height - bottomPad,
    );
    final maxV = math.max(
      planned,
      weeks.map((w) => w.sessions).fold(0, math.max),
    );
    final top = math.max(4, (maxV + 1)).toDouble();
    double y(num v) => chart.bottom - chart.height * v / top;

    // Grid + y labels at 0, half, top.
    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (final v in {0, (top / 2).round(), top.round()}) {
      canvas.drawLine(
        Offset(chart.left, y(v)),
        Offset(chart.right, y(v)),
        grid,
      );
      _text(
        canvas,
        '$v',
        Offset(0, y(v) - 7),
        width: leftPad - 6,
        align: TextAlign.right,
      );
    }

    final slot = chart.width / weeks.length;
    final barW = math.min(22.0, slot * 0.55);
    for (var i = 0; i < weeks.length; i++) {
      final w = weeks[i];
      // Stagger bar growth left to right.
      final local = ((progress * 1.4) - i * 0.05).clamp(0.0, 1.0);
      final cx = chart.left + slot * (i + 0.5);
      final sH = chart.height * w.strength / top * local;
      final cH = chart.height * w.cardio / top * local;
      final r = const Radius.circular(7);
      final latest = i == weeks.length - 1;
      // Faint full-height track behind every bar.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - barW / 2, chart.top, barW, chart.height),
          r,
        ),
        Paint()..color = AppColors.line.withValues(alpha: 0.6),
      );
      // Past weeks a little softer so this week stands out.
      final a = latest ? 1.0 : 0.62;
      if (latest && w.sessions > 0 && local >= 1) {
        _text(
          canvas,
          '${w.sessions}',
          Offset(cx - 20, chart.bottom - sH - cH - 17),
          width: 40,
          align: TextAlign.center,
          color: AppColors.ink,
          bold: true,
        );
      }
      if (w.cardio > 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(cx - barW / 2, chart.bottom - sH - cH, barW, cH),
            topLeft: r,
            topRight: r,
            bottomLeft: w.strength == 0 ? r : Radius.zero,
            bottomRight: w.strength == 0 ? r : Radius.zero,
          ),
          Paint()..color = AppColors.sky.withValues(alpha: a),
        );
      }
      if (w.strength > 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(cx - barW / 2, chart.bottom - sH, barW, sH),
            topLeft: w.cardio == 0 ? r : Radius.zero,
            topRight: w.cardio == 0 ? r : Radius.zero,
            bottomLeft: r,
            bottomRight: r,
          ),
          Paint()..color = AppColors.mint.withValues(alpha: a),
        );
      }
      if (i == 0 || i == weeks.length - 1 || i == weeks.length ~/ 2) {
        _text(
          canvas,
          fmt.format(w.start),
          Offset(cx - 24, chart.bottom + 6),
          width: 48,
          align: TextAlign.center,
        );
      }
    }

    if (planned > 0) {
      final py = y(planned);
      final dash = Paint()
        ..color = AppColors.peach
        ..strokeWidth = 2;
      for (var dx = chart.left; dx < chart.right; dx += 9) {
        canvas.drawLine(
          Offset(dx, py),
          Offset(math.min(dx + 5, chart.right), py),
          dash,
        );
      }
    }
  }

  void _text(
    Canvas c,
    String s,
    Offset o, {
    double width = 40,
    TextAlign align = TextAlign.left,
    Color color = AppColors.inkSoft,
    bool bold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: bold ? 12 : 11,
          color: color,
          fontFamily: bold ? headingFont : bodyFont,
          fontWeight: bold ? FontWeight.w800 : bodyWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(minWidth: width, maxWidth: width);
    tp.paint(c, o);
  }

  @override
  bool shouldRepaint(_WorkoutBarsPainter old) =>
      old.progress != progress || old.weeks != weeks || old.planned != planned;
}
